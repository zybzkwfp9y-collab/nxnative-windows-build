# Final verification — 28 October 2026

**Build status: SUCCESS for the synthetic compile/link/packaging fixture.** Portable Windows components also work; a playable per-game iOS build is blocked by the no-game/key cloud-upload boundary.

| # | Requested result | Classification | Evidence and limitation |
|---|---|---|---|
| 1 | Fresh Windows setup | **VERIFIED YES** | Fresh source/tools/harness under this chat workspace; no C:\ root directory or system setup needed. Environment and build logs recorded. |
| 2 | New GitHub project | **VERIFIED YES** | https://github.com/zybzkwfp9y-collab/nxnative-windows-build created public after explicit approval; wrapper published through connected GitHub app. |
| 3 | Authentic source retrieved | **VERIFIED YES** | Fresh git clone of seedds/nxnative at 6c4a81d40d200bbfe65ad0027ab093405367ada6; logs/source-clone-retry.log. |
| 4 | Windows compilation | **VERIFIED YES** | Portable subset only: 5334 C checks passed, ARM64 Windows object inspected, two C# tools compiled. Full Apple-host probe FAILED on TargetConditionals.h; no full iOS app built locally. |
| 5 | WSL compilation | **BLOCKED** | wsl --status says not installed. No Windows features/distro were installed. |
| 6 | GitHub Actions compilation | **VERIFIED YES** | Run 40690973131 SUCCESS on standard xcode-27; Xcode 27.1 / iPhoneOS SDK 27.1. Eight selected upstream Python test files and 5334 CPU texture checks passed. Production app compiled/linked using synthetic inputs; no GPU/game test. |
| 7 | iOS ARM64 binary produced | **VERIFIED YES** | Created on hosted runner; lipo, Mach-O iOS/minimum-version, dependencies, Info.plist and unsigned-state checks passed. Synthetic compile/link fixture only; not retained/downloaded. |
| 8 | IPA produced | **VERIFIED YES** | Unsigned SYNTHETIC fixture IPA created and zip/hash/plist/ARM64 validated on runner. Not a playable game. Upload disabled; API confirms zero retained artifacts; no IPA downloaded to Windows. |
| 9 | Can it be signed free | **UNKNOWN** | Official Windows tools support free accounts; this nxnative app and increased-memory provisioning were not signed/tested. |
| 10 | Can it be installed from Windows | **UNKNOWN** | Official installation routes documented; no real per-game artifact/device installation test. |
| 11 | Launches on this iPhone 16 | **UNKNOWN** | No installation or launch test; device iOS version unknown. |
| 12 | Required runtime capabilities available | **UNKNOWN** | Source implements ahead-of-time native guest execution without a conventional JIT; actual device Metal/memory/provisioning unverified. |
| 13 | Executes Nintendo Switch software | **UNKNOWN** | Upstream claims game support; no local or device game test in this session. Fixture contains no game. |
| 14 | TOTK 1.0.0 compatible | **UNKNOWN** | Pinned profile registers 1.4.3, not 1.0.0; no runtime/FPS result for your requested build. |
| 15 | Entire verified work free | **VERIFIED YES** | Local public tools and standard public GitHub compute only; uploads/caches disabled. Intended device/game workflow remains incomplete. No paid service was enabled; account invoice not inspected. |

## Local validation scope

43 selected upstream Python tests passed; the POSIX C identity test failed in setup on `pread`; one Swift test skipped. Seven wrapper validator tests passed. The real portable texture executable passed all 5,334 checks. Full logs and exact commands are in `logs/` and `reports/build-matrix.csv`.

## Exact blockers

- Full Windows/WSL app builds: upstream depends on Apple frameworks, Metal/Xcode and Apple ARM64 host conventions. Adding CMake/Ninja or a target triple cannot supply those.
- Playable cloud game build: upstream must embed rewritten game executable code and translated shaders, but game inputs and keys must stay out of Actions. No compliant free alternative Apple build environment with those private inputs has been established.
- Free signing/device: no real per-game app, no provisioned memory entitlement/device test; installed iOS version unknown.
- TOTK 1.0.0: upstream profile/patches are registered for different executable build IDs (1.4.3). No game test occurred.

## Preservation

No old nxnative-test project was inspected or modified. No WSL, partition, boot, security-policy or global PATH changes were made. .NET first-run created one untrusted localhost development certificate; only that exact newly created certificate was removed, and subsequent builds disabled that feature (logs/dotnet-first-run-cleanup.log). No signing credentials or game inputs were used.

## Cloud evidence

Successful run: https://github.com/zybzkwfp9y-collab/nxnative-windows-build/actions/runs/40690973131
Wrapper commit built: `80d1a499f99b567b4a3ad04f7eb1bf7b9013943b`; upstream pin remains `6c4a81d40d200bbfe65ad0027ab093405367ada6`.
Full 1.85 MB workflow log: artifacts/run-40690973131/workflow.log. Packaging and independent integrity validation both passed. Upload/cache stages were disabled; reports/cloud-artifact-count.json records total_count=0.
A read-only billing summary request required an additional OAuth user scope. No permission scope, budget or billing setting was changed; artifact upload remains off. Free public standard compute is documented by GitHub.
