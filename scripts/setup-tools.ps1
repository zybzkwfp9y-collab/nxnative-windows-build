<# Downloads portable public tools into this project only. No PATH/system changes. #>
[CmdletBinding()]
param([ValidateSet('gh','llvm','dotnet')][string[]]$Tools = @('gh'))
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$spec = Get-Content "$root/config/tool-downloads.json" -Raw | ConvertFrom-Json
foreach ($name in $Tools) {
    $tool = $spec.$name
    $dest = Join-Path $root "tools/$name"
    if (Test-Path $dest) { throw "Preserve or rename existing tool directory before setup: $dest" }
    New-Item -ItemType Directory -Force "$root/tools" | Out-Null
    $zip = Join-Path $root "tools/$name.zip"
    Invoke-WebRequest $tool.url -OutFile $zip
    $actual = (Get-FileHash $zip -Algorithm $tool.algorithm).Hash.ToLowerInvariant()
    if ($actual -ne $tool.hash) { throw "Publisher release hash mismatch for $name" }
    Expand-Archive -LiteralPath $zip -DestinationPath $dest
    Write-Host "Verified and extracted $name at $dest. Add its bin directory to this shell's PATH only if needed."
}
