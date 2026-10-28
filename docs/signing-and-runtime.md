# Signing, runtime and iPhone 16 feasibility

Checked 28 October 2026. No iPhone installation, signing or game test has occurred.

## A crucial boundary: a cloud fixture cannot become your game

The Actions project builds upstream's production iOS application with synthetic
code pages. Its IPA is only a compile/link/packaging fixture. Do not install it.
nxnative is a per-game native port builder: real guest code must be rewritten and
embedded in the signed executable. RomFS transfer after installation does not add
the missing executable code or translated shaders.

Your constraints prohibit uploading games or keys to Actions. Consequently this
cloud workflow cannot produce a playable Tears of the Kingdom application. A real
per-game build requires an authorized Apple build environment that can privately
access your own game inputs. No free, private, authorized Mac with the required
inputs has been established in this session. Windows/WSL lack the Apple framework
and Metal toolchain required by upstream. We do not replace nxnative with a stub
launcher or label the synthetic fixture a functional emulator.

## JIT

Source evidence: `dm/tools/patch_nso.py`, `dm/ios/tools/gen_embed.py`, and the
`TARGET_OS_IPHONE` path in `dm/host/loader.c` around lines 501–553. The iOS build
embeds pre-rewritten executable sections in Mach-O `__TEXT`, then uses `vm_remap`
to place those signed executable pages at their guest-relative positions. This
avoids loading newly generated executable code. The inspected path is not a CPU
JIT/dynamic-recompilation backend and has no conventional interpreter fallback.
The shader translation is performed at build time. Metal pipeline preparation is
separate from a guest CPU JIT entitlement.

No JIT activation utility is needed for that intended iOS execution path. Windows
JIT enablers cannot supply the missing rewritten game, Metal SDK, provisioning or
memory allowance. General JIT/debugger access on current stock iOS is a different
device/version-dependent topic; none was enabled or tested here. No JIT, unsigned
executable memory, private entitlement or jailbreak is being promised.

## Free Windows signing options (documented, not locally verified)

| Method | Current first-party documentation | Limits relevant here |
|---|---|---|
| AltStore Classic + AltServer Windows | https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows | Windows route exists, Apple iTunes/iCloud prerequisites; free apps expire after 7 days; 3 sideloaded apps; AltStore uses one slot |
| Sideloadly Windows | https://sideloadly.io/faq and https://sideloadly.io/ | Free Apple Accounts supported; 7-day expiry and refresh daemon; Windows Apple software prerequisites; tool documents iOS 26/27 support |
| SideStore | https://github.com/SideStore/SideStore/issues/1616 | Maintainer issue reports free-account Increased Memory Limit provisioning differences; do not infer every sideloader preserves it |

These sources establish available methods, not that this particular nxnative
binary can be provisioned or launched on your iPhone. No paid membership is
inherently needed for ordinary personal sideloading. Upstream asks for
`com.apple.developer.kernel.increased-memory-limit`. Apple documents that higher
memory is device dependent and must be checked with `os_proc_available_memory`:
https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.kernel.increased-memory-limit

A free-account signing tool may strip unsupported entitlements or fail to enable
the capability. Neither an ad-hoc signature nor a checkbox proves the installed
provisioning profile grants it. Inspect the final signature/profile and device
memory allowance before claiming compatibility. An upstream/SideStore issue
reports success with AltStore and Personal Teams, but this is third-party test
evidence, not a test on your account/device.

For a future REAL per-game IPA: install an official supported sideloader locally,
pair the phone with Windows, authenticate directly in that tool, select the IPA,
and verify signing/provisioning and launch. Trust/developer-mode prompts can change
device security settings: review them yourself; none was changed automatically.
Keep credentials/certificates local, refresh before expiry and back up saves.
Do not upload signing credentials to GitHub or paste them into chat. No sideloader
was installed because there is not yet a real playable artifact to test.

## iPhone 16 and Tears of the Kingdom 1.0.0

Apple's specs confirm A18, a 6-core CPU and 5-core GPU:
https://support.apple.com/en-gb/121029. This is the relevant ARM64/Metal hardware
family, but CPU instruction compatibility is only one requirement. The installed
iOS version, available storage, per-process memory, Metal capabilities and actual
runtime behavior have not been measured. No RAM capacity claim was inferred from
Apple's specification (it does not list RAM). No FPS estimates are offered.

Upstream requires iOS 26+ and BC-texture-capable A17 Pro-or-later hardware. Its
TOTK profile `dm/games/0100F2C0115B6000/game.tsv` registers **1.4.3**, SDK 20.5.22,
and specific NSO build IDs. Its README reports iPhone gameplay for that build.
This is an upstream claim, not independent validation. It does not establish
support for 1.0.0. Upstream documents deriving profiles for unregistered builds;
build-specific patches must never be applied blindly to different executable
addresses. Version 1.0.0 compatibility remains UNKNOWN.

The profile reserves a 5 GiB virtual guest layout; virtual reservation is not
resident RAM usage. Its note documents a 2.1 GiB guest heap and significant memory
pressure, plus fixed upload-staging growth with **iOS validation pending** for that
fix. CPU/native guest execution, host HLE coverage, shader correctness, Metal
rendering, cache growth, thermals and Jetsam limits all need device testing. Cloud
VM compile success cannot validate GPU execution, sustained performance or game
compatibility. No game dumps or keys were searched for, uploaded or processed.

Pinned game evidence:
https://github.com/seedds/nxnative/blob/6c4a81d40d200bbfe65ad0027ab093405367ada6/dm/games/0100F2C0115B6000/README.md
