"""Run selected real upstream tests individually, preserving complete output.

This is a portable subset, not upstream's full macOS/GPU regression suite.
"""
import argparse
import json
import os
import re
from pathlib import Path
import subprocess
import sys

TESTS = [
    'dm/tools/tests/test_nro_header.py',
    'dm/tools/tests/test_nso_match.py',
    'dm/tools/tests/test_nsp_env_checks.py',
    'dm/tools/tests/test_ci_toolchain.py',
    'dm/tools/tests/test_settings.py',
    'dm/tools/tests/test_romfs_identity.py',
    'dm/tools/tests/test_nsp_scan.py',
    'dm/ios/tests/test_launcher_storage.py',
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--logs', type=Path, required=True)
    args = parser.parse_args()
    source, logs = args.source.resolve(), args.logs.resolve()
    logs.mkdir(parents=True, exist_ok=True)
    results = []
    env = dict(os.environ, PYTHONUTF8='1', DM_GAME='0100F2C0115B6000')
    for test in TESTS:
        command = [sys.executable, '-m', 'unittest', '-v', test]
        try:
            run = subprocess.run(command, cwd=source, env=env, capture_output=True,
                                 encoding='utf-8', errors='replace', timeout=120)
            output = run.stdout + run.stderr
            code = run.returncode
        except subprocess.TimeoutExpired as exc:
            output = str(exc)
            code = 124
        logfile = logs / (Path(test).stem + '.log')
        logfile.write_text(output, encoding='utf-8')
        count = re.search(r'Ran (\d+) tests?', output)
        skip = re.search(r'OK \(skipped=(\d+)\)', output)
        ran = int(count[1]) if count else 0
        skipped = int(skip[1]) if skip else 0
        status = 'FAIL' if code else ('NOT TESTED' if ran == skipped else 'PASS')
        row = dict(test=test, command=command, result=status, tests_run=ran,
                   skipped=skipped, exit_code=code, log=logfile.name)
        results.append(row)
        print(f"{row['result']}: {test}", flush=True)
    (logs / 'portable-results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    return int(any(row['exit_code'] for row in results))

if __name__ == '__main__':
    sys.exit(main())
