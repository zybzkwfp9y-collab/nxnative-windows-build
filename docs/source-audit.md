# Source audit — 28 October 2026

Authentic upstream: https://github.com/seedds/nxnative (also linked by https://nxnative.dev).
Fresh clone pinned to `6c4a81d40d200bbfe65ad0027ab093405367ada6`.
No previous repository or workflow was read or reused. Source retrieval logs are in `logs/`.
The checkout's own agent instructions were read. No source edits or commits were made upstream.

## Architecture and build requirements

| Question | Evidence at the pinned revision | Finding |
|---|---|---|
| Languages | `dm/host`, `dm/gfx`, `dm/ios/Sources`, `dm/tools`, `.csproj` files | C, Objective-C, ARM64 assembly, Swift, Metal shaders, Python, shell, C#; third-party C/C++ |
| Execution | `dm/tools/patch_nso.py`; `dm/host/loader.c:501` onward; `dm/ios/tools/gen_embed.py` | Offline NSO/NRO rewriting, Horizon HLE services, native guest ARM64 execution; iOS embeds rewritten code into the app's Mach-O |
| Graphics | `dm/gfx/nvn`, `dm/gfx/vk`, `dm/gfx/gl`, `dm/gfx/tools` | NVN/Vulkan/OpenGL compatibility layers over Metal; Maxwell → SPIR-V → Metal shader chain |
| Build system | `dm/host/Makefile`; `dm/ios/project.yml`; upstream Actions | GNU Make plus XcodeGen/Xcode, Python pipeline and .NET tooling. No top-level CMake/Ninja build exists |
| Supported full hosts | Makefile's frameworks and `front_mac.m`/`front_ios.m` | Apple silicon macOS and iOS; full Windows/Linux application builds are not implemented |
| Apple toolchain | `README.md`; `.github/workflows/tests.yml`; `own_compilers.py`; `dmsh_chain.lock` | Xcode 27.1; documented build-host minimum macOS 26.6; iOS platform SDK and matching Apple Metal compiler required |
| Device minimum | `dm/ios/project.yml` | iOS deployment target 26.0; uses Metal 4; ARM64 and `-mcpu=apple-a18` |
| Frontend | `dm/ios/Sources` and `project.yml` | Actual UIKit/SwiftUI app with touch/controller frontend, resource staging and file sharing exists; this inspection does not certify every frontend feature |
| Packaging | `dm/ios/tools/build_ipa.sh`; `pack_ipa.py` | Real per-game IPA packaging exists, requires rewritten game executable and compiled shaders; unsigned/re-signable artifact differs from provisioned installable app |
| Game-free check | `dm/ios/tools/build_smoke.py` | Real production app compile/link fixture with synthetic embedded modules, explicitly not a runnable game |
| Entitlements | `build_ipa.sh:123–173` | Increased Memory Limit is requested; production IPA embeds it in an ad-hoc executable signature for the sideloader to replace. Smoke fixture disables signing entirely |
| Tests | `dm/tools/tests`, `dm/host/tests`, `dm/gfx/tests`, `dm/ios/tests` | Extensive unit/structural/CPU, Apple runtime and GPU tests. GPU execution is unavailable on hosted macOS runners according to upstream CI |
| Public dependencies | README, csproj files and vendored licenses | Python lz4/capstone/fonttools/nsz/backports.zstd (as applicable), XcodeGen, zstd, glslang; .NET 10, LibHac 0.19.0; vendored Ryujinx, SPIRV-Cross, Vulkan headers, libvpx/stb_vorbis etc. |
| Submodules | `.gitmodules` absent at pin | Vendored dependencies are already in the checkout; fetch script initializes submodules if a later reviewed pin adds them |

The shader-chain lock fingerprints the translator, SPIRV-Cross and exact Metal
compiler. Recompiling the C# translator is a portability test and does not prove
its outputs match that locked distribution. We do not weaken that lock.

## Windows and WSL findings

The initial environment had Git and a bundled Python 3.12.14. Python Store aliases
on PATH were not counted as working Python. No CMake, Ninja, Clang, LLVM, GitHub
CLI or VS Build Tools was found on PATH; standard VS/SDK directories were absent.
`dotnet --list-sdks` was empty. `wsl --status` explicitly reported not installed.
CIM inventory access was restricted; hardware specs are user supplied rather than
independently re-measured. Approximately 79 GB was free at the initial check.

Workspace-only LLVM-MinGW, GitHub CLI and Microsoft .NET SDK were fetched with
publisher release hashes. They do not change PATH globally. Python dependencies
were isolated. The native texture test passed all 5,334 checks. ARM64 Windows COFF
object generation passed; this is not an iOS Mach-O binary. Full-host compilation
fails on an Apple SDK header after generating the required profile header. An iOS
target probe lacks even the target C SDK headers. Do not fake Apple frameworks or
disable graphics to make that pass. MSVC/clang-cl and CMake/Ninja are irrelevant
to the unported full Apple host; installing multi-GB Visual Studio tools would not
provide Apple's frameworks.

WSL installation would enable Windows features/virtualization, download a distro,
consume disk and potentially require administrator access and a reboot. No WSL,
boot, partition or Windows security changes were made. WSL could run portable
Python/.NET/C tools; Objective-C++/Swift language support alone supplies no Apple
UIKit/Metal SDK or code-signing toolchain. No unauthorized SDK was downloaded.

## Reproducibility boundary

The source revision, action commits, Python versions and selected Xcode are pinned.
Hosted runner images and Homebrew XcodeGen remain mutable public infrastructure;
the job logs their versions and rejects missing Xcode or Metal lock mismatches.
This is repeatable source/build configuration, not a claim of byte-for-byte
reproducibility. No C++/Swift cross compiler on Windows substitutes for Xcode here.

Pinned source links:
- https://github.com/seedds/nxnative/blob/6c4a81d40d200bbfe65ad0027ab093405367ada6/dm/ios/project.yml
- https://github.com/seedds/nxnative/blob/6c4a81d40d200bbfe65ad0027ab093405367ada6/dm/ios/tools/build_smoke.py
- https://github.com/seedds/nxnative/blob/6c4a81d40d200bbfe65ad0027ab093405367ada6/dm/host/loader.c
- https://github.com/seedds/nxnative/blob/6c4a81d40d200bbfe65ad0027ab093405367ada6/.github/workflows/tests.yml
