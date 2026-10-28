<# Reproduce native portability probes. Full Apple-host failure is recorded explicitly. #>
[CmdletBinding()]
param(
    [string]$Python = 'python',
    [Parameter(Mandatory)][string]$LlvmBin,
    [string]$DotNet
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$src = Join-Path $root 'source/nxnative'
$out = Join-Path $root 'artifacts/windows'
$logs = Join-Path $root 'logs/windows'
New-Item -ItemType Directory -Force $out,$logs,"$out/temp","$out/probe" | Out-Null
$oldPath=$env:PATH; $oldTemp=$env:TEMP; $oldTmp=$env:TMP
$oldRoot=$env:DOTNET_ROOT; $oldCli=$env:DOTNET_CLI_HOME; $oldCert=$env:DOTNET_GENERATE_ASPNET_CERTIFICATE
$results = [System.Collections.Generic.List[object]]::new()
function Probe([string]$Name,[string]$Exe,[string[]]$Arguments) {
    & $Exe @Arguments 2>&1 | Tee-Object "$logs/$Name.log" | Out-Host
    $code=$LASTEXITCODE
    "Exit code: $code" | Add-Content "$logs/$Name.log"
    $results.Add([pscustomobject]@{name=$Name;command=(@($Exe)+$Arguments);exit_code=$code;result=$(if($code -eq 0){'PASS'}else{'FAIL'})})
    return $code
}
try {
    $env:PATH="$LlvmBin;$oldPath"; $env:TEMP="$out/temp"; $env:TMP=$env:TEMP
    $clang=Join-Path $LlvmBin 'clang.exe'
    if (!(Test-Path $clang)) { throw "clang.exe missing in $LlvmBin" }
    $code=Probe 'texture-build' $clang @('-O2','-g','-Wall','-Wextra','-o',"$out/t_tex.exe","$src/dm/gfx/tex/tests/t_tex.c","$src/dm/gfx/tex/nvn_deswizzle.c","$src/dm/gfx/nvn/nvn_tex.c",'-lm')
    if ($code -eq 0) { $null=Probe 'texture-run' "$out/t_tex.exe" @() }
    $null=Probe 'arm64-object' $clang @('--target=aarch64-w64-windows-gnu','-O2','-c',"$src/dm/gfx/tex/nvn_deswizzle.c",'-o',"$out/nvn_deswizzle-arm64.obj")
    $null=Probe 'arm64-inspection' "$LlvmBin/llvm-readobj.exe" @('--file-headers',"$out/nvn_deswizzle-arm64.obj")
    $null=Probe 'profile-header' $Python @("$src/dm/games/game.py",'header','0100F2C0115B6000',"$out/probe/game_profile.h")
    $null=Probe 'full-host-expected-apple-sdk-failure' $clang @('-fsyntax-only',"$src/dm/host/loader.c",'-I',"$src/dm/host",'-I',"$out/probe")
    $null=Probe 'ios-target-expected-sdk-failure' $clang @('--target=arm64-apple-ios26.0','-c',"$src/dm/gfx/tex/nvn_deswizzle.c",'-o',"$out/ios-probe.o")
    $null=Probe 'upstream-python-tests' $Python @("$root/scripts/run-portable-tests.py",'--source',$src,'--logs',"$logs/python")
    if ($DotNet) {
        $env:DOTNET_ROOT=Split-Path $DotNet -Parent; $env:DOTNET_CLI_HOME=$out
        $env:DOTNET_GENERATE_ASPNET_CERTIFICATE='false'
        foreach ($item in @(@('extract',"$src/dm/tools/nx_extract/nx_extract.csproj"),@('translator',"$src/dm/gfx/tools/dmsh_xlate/dmsh_xlate.csproj"))) {
            $null=Probe "dotnet-$($item[0])" $DotNet @('publish',$item[1],'-c','Release','--source','https://api.nuget.org/v3/index.json','-o',"$out/$($item[0])")
        }
    } else { $results.Add([pscustomobject]@{name='dotnet-tools';result='BLOCKED';reason='Supply -DotNet with an installed or portable .NET 10 SDK executable'}) }
} finally {
    $env:PATH=$oldPath; $env:TEMP=$oldTemp; $env:TMP=$oldTmp
    $env:DOTNET_ROOT=$oldRoot; $env:DOTNET_CLI_HOME=$oldCli; $env:DOTNET_GENERATE_ASPNET_CERTIFICATE=$oldCert
    $results | ConvertTo-Json -Depth 5 | Set-Content "$logs/results.json" -Encoding utf8
}
Write-Host "Diagnostics recorded at $logs. Apple-host/SDK probes are expected to FAIL; inspect individual results."
