"""Validate a synthetic IPA structurally on Windows; never claim installability.

Mach-O/iOS-platform, architecture, minimum OS and dependencies are checked on
macOS before packaging. Here we verify hashes, zip integrity, paths and plist.
"""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import struct
import zipfile

def validate(folder):
    folder = Path(folder)
    manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    if manifest.get('kind') != 'synthetic-compile-link-fixture-not-a-game':
        raise ValueError('Unexpected artifact kind')
    pin = json.loads((Path(__file__).resolve().parents[1] / 'config/upstream.json').read_text())
    if manifest.get('revision') != pin['revision'] or manifest.get('profile') != pin['profile']:
        raise ValueError('Artifact upstream revision/profile mismatch')
    if manifest.get('platform') != 'iOS' or manifest.get('architecture') != 'arm64':
        raise ValueError('Manifest platform/architecture mismatch')
    ipa = folder / 'nxnative-synthetic.ipa'
    if hashlib.sha256(ipa.read_bytes()).hexdigest() != manifest['sha256']:
        raise ValueError('SHA256 mismatch')
    with zipfile.ZipFile(ipa) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError('Duplicate zip entries')
        for name in names:
            p = PurePosixPath(name)
            if p.is_absolute() or '..' in p.parts or '\\' in name or ':' in name:
                raise ValueError('Unsafe archive path')
            if not name.startswith('Payload/DmIOS.app/'):
                raise ValueError('Unexpected archive member')
        if archive.testzip():
            raise ValueError('Corrupt zip')
        info = plistlib.loads(archive.read('Payload/DmIOS.app/Info.plist'))
        if info.get('MinimumOSVersion') != '26.0':
            raise ValueError('Unexpected minimum iOS version')
        if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
            raise ValueError('Unexpected bundle platform')
        exe_name = info['CFBundleExecutable']
        if PurePosixPath(exe_name).name != exe_name or not exe_name:
            raise ValueError('Unsafe executable name')
        exe = archive.read('Payload/DmIOS.app/' + exe_name)
        if len(exe) < 32 or struct.unpack_from('<II', exe) != (0xfeedfacf, 0x100000c):
            raise ValueError('Expected thin ARM64 Mach-O executable')
        if any('embedded.mobileprovision' in n or '/_CodeSignature/' in n for n in names):
            raise ValueError('Expected unsigned fixture without provisioning')
    return manifest

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('folder', type=Path)
    args = parser.parse_args()
    result = validate(args.folder)
    print('PASS: synthetic ARM64 iOS fixture integrity; NOT an installable or playable game.')
