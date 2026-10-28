"""Negative and positive validator tests using invented bytes, not compiled apps."""
import hashlib
import importlib.util
import json
from pathlib import Path
import plistlib
import struct
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('validator', ROOT / 'scripts/validate-artifact.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class ArtifactValidation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)

    def fixture(self, *, extra=None, cpu=0x100000c, platform='iPhoneOS'):
        cfg = json.loads((ROOT / 'config/upstream.json').read_text())
        files = {
            'Payload/DmIOS.app/Info.plist': plistlib.dumps(dict(
                CFBundleExecutable='DmIOS', MinimumOSVersion='26.0', CFBundleSupportedPlatforms=[platform])),
            'Payload/DmIOS.app/DmIOS': struct.pack('<II', 0xfeedfacf, cpu) + bytes(24),
        }
        if extra: files.update(extra)
        ipa = self.folder / 'nxnative-synthetic.ipa'
        with zipfile.ZipFile(ipa, 'w') as archive:
            for name, data in files.items(): archive.writestr(name, data)
        manifest = dict(kind=cfg['artifact_kind'], revision=cfg['revision'], profile=cfg['profile'],
                        platform='iOS', architecture='arm64', sha256=hashlib.sha256(ipa.read_bytes()).hexdigest())
        (self.folder / 'manifest.json').write_text(json.dumps(manifest))

    def test_expected_structure_is_accepted(self):
        self.fixture()
        self.assertEqual(module.validate(self.folder)['architecture'], 'arm64')

    def test_wrong_architecture_is_rejected(self):
        self.fixture(cpu=0x1000007)
        with self.assertRaisesRegex(ValueError, 'ARM64'): module.validate(self.folder)

    def test_simulator_is_rejected(self):
        self.fixture(platform='iPhoneSimulator')
        with self.assertRaisesRegex(ValueError, 'platform'): module.validate(self.folder)

    def test_traversal_is_rejected(self):
        self.fixture(extra={'Payload/DmIOS.app/../../evil': b'x'})
        with self.assertRaisesRegex(ValueError, 'Unsafe'): module.validate(self.folder)

    def test_signature_is_rejected(self):
        self.fixture(extra={'Payload/DmIOS.app/_CodeSignature/CodeResources': b'x'})
        with self.assertRaisesRegex(ValueError, 'unsigned'): module.validate(self.folder)

    def test_tampered_hash_is_rejected(self):
        self.fixture()
        with (self.folder / 'nxnative-synthetic.ipa').open('ab') as f: f.write(b'tampered')
        with self.assertRaisesRegex(ValueError, 'SHA256'): module.validate(self.folder)

    def test_revision_mismatch_is_rejected(self):
        self.fixture()
        p = self.folder / 'manifest.json'
        data = json.loads(p.read_text()); data['revision'] = '0'*40; p.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, 'revision'): module.validate(self.folder)

if __name__ == '__main__': unittest.main()
