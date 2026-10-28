# nxnative from Windows — fresh investigation and build harness

**Current result:** the [first cloud build passed](https://github.com/zybzkwfp9y-collab/nxnative-windows-build/actions/runs/40690973131).
It compiled/linked the production app and validated an unsigned ARM64 iOS
**synthetic fixture IPA** using Xcode 27.1 and iPhoneOS SDK 27.1. Artifact uploads
were disabled; only logs were downloaded. Portable Windows C/C# builds also passed.
No playable per-game IPA, installation or game launch is claimed.
See `reports/final-verification.md` for the actual stage-by-stage results.

This project was created from scratch on 28 October 2026. It does not use the
previous nxnative-test project. Original code is pinned in `config/upstream.json`.
The local source clone is in `source/nxnative` and is intentionally not republished.
No games, keys, certificates or credentials belong in this repository.

## What the cloud workflow can establish

It fetches the exact authentic upstream revision, enforces Xcode 27.1 on the
standard free public-repository `xcode-27` runner, runs selected upstream tests,
compiles and links the production iOS app using upstream's **synthetic modules**,
inspects architecture/iOS platform/minimum OS/dependencies/signing and packages
an explicitly labelled unsigned fixture IPA. It does not contain a game or usable
guest code. **Do not install that fixture.**

nxnative builds one app per game, embedding rewritten game executable code.
Because this task excludes games/keys from Actions, a playable per-game cloud
build is blocked. Adding only RomFS later cannot turn this fixture into a game.
Read `docs/signing-and-runtime.md` before considering installation.

## Local tools and source

Use PowerShell 7. No Windows execution-policy, security, WSL, boot or registry
changes are required. Use a working Python 3.12+; the Microsoft Store alias is not
an interpreter. This session's bundled interpreter path is recorded in
`reports/windows-environment.txt`; it is app-specific, not a general prerequisite.

```powershell
# Run from this project directory. Choose your actual working Python path.
./scripts/setup-python.ps1 -Python 'C:/path/to/python.exe'
./scripts/fetch-source.ps1
./scripts/setup-tools.ps1 -Tools gh
# Optional portable compiler/SDK experiments:
./scripts/setup-tools.ps1 -Tools llvm,dotnet
```

Tools are downloaded to `tools/` with pinned release hashes, without global PATH
changes. The initial investigation's tools are in the enclosing chat's
`work/tools/`; command logs record their exact versions. Python packages and build
outputs are isolated. No unauthorized Apple SDK is supplied.

```powershell
# Avoid sandbox temporary-directory restrictions by using a project directory.
New-Item -ItemType Directory -Force artifacts/test-temp | Out-Null
$env:TEMP = (Resolve-Path artifacts/test-temp).Path
$env:TMP = $env:TEMP
./.venv/Scripts/python.exe scripts/run-portable-tests.py --source source/nxnative --logs logs/portable
./.venv/Scripts/python.exe -m unittest discover -s tests -v
```

The selected upstream suite includes a POSIX C identity test that fails on Windows
because `pread` is not provided by this CRT; a Swift test skips without Apple's
Swift toolchain. Those are reported, not hidden. Full upstream Apple/GPU regression
testing has not occurred. See the matrix and full logs for scope and failures.

Reproduce C/ARM64/Apple-SDK probes (and optionally C# builds) with:

```powershell
./scripts/test-windows.ps1 -Python ./.venv/Scripts/python.exe -LlvmBin 'C:/path/to/llvm/bin' -DotNet 'C:/path/to/dotnet.exe'
```

The full-host/iOS-SDK negative probes record their real failures. The C# translator
source fingerprint initially differed because Windows converted LF to CRLF. The
fetcher now disables that conversion before checkout. Restoring the two embedded
files from exact Git blob bytes and rebuilding produced the locked source digest
`f21af1efa737a270`; this does not certify the compiled translator DLLs' byte-level
fingerprints or any Metal shader outputs.

## Repository approval and account authentication

No repository is created automatically. After the user explicitly approves the
new repository name, **visibility and permissions**, publish only the reviewed
wrapper files; exclude source, logs, binaries and private inputs using `.gitignore`.
Use official GitHub CLI `gh auth login --hostname github.com --web`, authenticate
directly with GitHub, then verify `gh api user --jq .login` is the intended account.
Never put credentials in scripts. The connected GitHub app and CLI have separate
authentication. Keep actions manual-only and read-only (`contents: read`).

## One command after the approved project is published

With GitHub CLI on PATH and a working Python:

```powershell
./build-nxnative.ps1 -Repository zybzkwfp9y-collab/nxnative-windows-build -NoArtifacts
```

This permits only free standard public-repository compute and downloads text logs.
For artifact download, first verify free storage and a zero-spending account
budget; then replace `-NoArtifacts` with `-ConfirmFreeArtifactStorage`.
Pass `-Gh C:/path/to/gh.exe -Python C:/path/to/python.exe` when tools aren't on PATH.
The launcher checks account, visibility, permissions and published file contents,
dispatches a uniquely identified run, monitors with a bounded timeout, records
logs, downloads the matching artifact and validates its manifest/hash/bundle.
It raises errors on failed jobs or validation and never reports device success.

The runner checks the exact Xcode version and shader Metal compiler lock. Changing
either needs a reviewed, evidence-based configuration change. The source/actions
and Python dependencies are pinned; hosted OS images and Homebrew remain mutable,
so byte-for-byte reproducibility is not claimed. Automatic retries are disabled.

## Evidence and next stages

- `docs/source-audit.md`: architecture, tools, platform boundaries and source links.
- `docs/cloud-cost-and-diagnostics.md`: runner/billing conditions and bounded debugging.
- `docs/signing-and-runtime.md`: free signing, native execution, iPhone 16/TOTK limits.
- `reports/build-matrix.csv`: A–L test configurations, commands and root causes.
- `reports/final-verification.md`: all 15 requested outcome classifications.
- `logs/`: full local diagnostic evidence; kept local and excluded from publication.
- `artifacts/`: locally built portable tools/object files; no claimed iOS binary yet.

Wrapper scripts and documentation are provided under the MIT license in `LICENSE`.
The source checkout retains seedds' MIT license and third-party licenses.
