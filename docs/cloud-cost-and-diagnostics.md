# Free runner selection and diagnostic procedure

Verified documentation on 28 October 2026:
- https://docs.github.com/en/actions/concepts/billing-and-usage
- https://docs.github.com/en/billing/concepts/product-billing/github-actions
- https://github.blog/changelog/2026-09-10-xcode-27-runner-image-now-runs-on-macos-27/
- https://github.com/actions/runner-images/blob/main/images/macos/xcode-27-arm64-Readme.md

Standard hosted compute is free in public repositories. Larger runners are
charged even in public repositories. This project only permits a public repo and
uses the standard arm64 `xcode-27` label matching upstream's pinned Xcode 27.1.
It never selects large/xlarge runners. The older macos-26 image's documented Xcode
26 versions do not meet this source revision's requirements, so it is not an
appropriate initial matrix axis. Another image is tested only for a specific,
documented toolchain hypothesis.

Actions artifact storage shares the account allowance with Packages. Free plans
document 500 MB; the current remaining balance, payment configuration and budget
have not been verified. A 45 MiB artifact cap and 1-day retention reduce usage but
do not alone guarantee zero charges. Uploads default OFF. Before enabling uploads,
verify remaining free storage and a zero-spending/blocking budget in the account
billing settings. Do not change payment/security settings automatically. Use
`-NoArtifacts` to test free public compute first; logs remain readable through the
Actions run without creating a downloadable artifact. No cache is created.

Workflow: manual dispatch only, one queued build at a time, 40-minute server timeout,
three compiler jobs via upstream smoke script, read-only contents permission,
commit-pinned actions and upstream SHA. A source pin is fetched rather than copied
from another experiment. No private files, device inputs or secrets are accepted.
Hosted VM Metal execution tests are omitted because upstream documents that its
Metal 4 runtime is unavailable there. Compilation is still meaningful.

The approved compute-only run 40690973131 passed. It built/linked and packaged the
synthetic ARM64 iOS fixture on Xcode 27.1 / iPhoneOS SDK 27.1, with the expected
Metal compiler 32023.921. Eight selected Python test files and all 5,334 texture
checks passed on macOS. Its artifact API reports zero retained artifacts; the
complete text log was downloaded. A read-only billing summary request required an
additional OAuth user scope, which was not granted or requested. No account
billing/security configuration was changed; artifact upload remains off.

For a failure, download/read the complete logs, then identify the first actionable
compiler/linker error rather than the final summary. Classify: missing dependency,
compiler incompatibility, SDK mismatch, unsupported architecture, linker failure,
missing framework, signing failure, entitlement limitation, unsupported target or
upstream limitation. Record the command and source/tool versions. Make a minimal
change on a development branch, rerun only the affected stage, and compare logs.
Never repeat an identical failing job without a new hypothesis, disable emulator
features, or override the shader compiler lock to claim success.

Account permission/Actions policy/image availability, compilation and artifact
download are VERIFIED only when that particular run provides evidence. Local YAML,
script tests and upstream CI cannot substitute for running this repository's job.
