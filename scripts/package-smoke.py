"""macOS-only validation and unsigned packaging of upstream's synthetic build."""
import hashlib
import json
from pathlib import Path
import plistlib
import re
import subprocess
import sys
import zipfile

def main(app, output):
    app, output = Path(app).resolve(), Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    cfg = json.loads((Path(__file__).resolve().parents[1] / 'config/upstream.json').read_text())
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS'] or info.get('MinimumOSVersion') != '26.0':
        raise ValueError('Unexpected platform or minimum OS')
    exe = app / info['CFBundleExecutable']
    reports = {}
    for name, command in {
        'architecture': ['lipo', '-archs', str(exe)],
        'dependencies': ['otool', '-L', str(exe)],
        'load-commands': ['otool', '-l', str(exe)],
        'build-version': ['xcrun', 'vtool', '-show-build', str(exe)],
    }.items():
        reports[name] = subprocess.check_output(command, text=True, stderr=subprocess.STDOUT)
        (output / f'{name}.txt').write_text(reports[name])
    if reports['architecture'].strip() != 'arm64':
        raise ValueError('Expected arm64 device binary')
    if not re.search(r'platform\s+IOS\b', reports['build-version']) or not re.search(r'minos\s+26\.0\b', reports['build-version']):
        raise ValueError('Mach-O platform/minimum OS mismatch')
    for line in reports['dependencies'].splitlines()[1:]:
        dep = line.strip().split(' (')[0]
        if dep.startswith(('/System/Library/', '/usr/lib/')):
            continue
        relative = dep.replace('@rpath/', '', 1) if dep.startswith('@rpath/') else None
        if relative and (app / 'Frameworks' / relative).is_file():
            continue
        raise ValueError(f'Unresolved non-system dependency: {dep}')
    sign = subprocess.run(['codesign', '-d', '--entitlements', ':-', str(exe)], capture_output=True, text=True)
    (output / 'code-signing.txt').write_text(sign.stdout + sign.stderr)
    # The upstream smoke build explicitly disables signing and provisioning.
    if sign.returncode == 0 or (app / '_CodeSignature').exists() or (app / 'embedded.mobileprovision').exists():
        raise ValueError('Expected unsigned fixture')
    ipa = output / 'nxnative-synthetic.ipa'
    with zipfile.ZipFile(ipa, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(app.rglob('*')):
            if path.is_symlink():
                raise ValueError(f'Unexpected symlink in device app: {path}')
            if path.is_file():
                archive.write(path, 'Payload/DmIOS.app/' + path.relative_to(app).as_posix())
    manifest = dict(kind=cfg['artifact_kind'], revision=cfg['revision'], profile=cfg['profile'],
                    platform='iOS', architecture='arm64', min_ios='26.0',
                    signed=False, runnable_game=False, sha256=hashlib.sha256(ipa.read_bytes()).hexdigest())
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2))
    (output / 'READ-ME-FIRST.txt').write_text('SYNTHETIC COMPILE/LINK FIXTURE. No game code or playable game. Do not install.\n')
    if sum(p.stat().st_size for p in output.rglob('*') if p.is_file()) > 40 * 1024**2:
        raise ValueError('Artifact exceeds 40 MiB storage cap')
    print('Validated and packaged unsigned synthetic ARM64 iOS fixture.')

if __name__ == '__main__':
    main(*sys.argv[1:])
