<#
.SYNOPSIS
Dispatch, monitor and download a game-free nxnative iOS build from Windows.
.DESCRIPTION
Requires GitHub CLI authentication and an already-published copy of this project.
No repository creation, signing or game upload is performed by this launcher.
Artifact storage must be confirmed separately to preserve the zero-cost requirement.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^zybzkwfp9y-collab/[A-Za-z0-9_.-]+$')][string]$Repository,
    [string]$Gh = 'gh',
    [string]$Python = 'python',
    [switch]$ConfirmFreeArtifactStorage,
    [switch]$NoArtifacts,
    [ValidateRange(1,60)][int]$TimeoutMinutes = 50
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
function Invoke-Gh {
    $text = & $Gh @args
    if ($LASTEXITCODE -ne 0) { throw "GitHub CLI failed: $args" }
    return $text
}
if ($Repository -match '(?i)/nxnative-test$') { throw 'The previous nxnative-test repository is forbidden.' }
if (!$NoArtifacts -and !$ConfirmFreeArtifactStorage) {
    throw 'Before uploading artifacts, confirm available free storage and a zero spending budget. Then use -ConfirmFreeArtifactStorage, or -NoArtifacts for compute/logs only.'
}
Get-Command $Gh -ErrorAction Stop | Out-Null
Get-Command $Python -ErrorAction Stop | Out-Null
Invoke-Gh auth status | Out-Host
$login = Invoke-Gh api user --jq .login
if ($login -ne 'zybzkwfp9y-collab') { throw "Unexpected authenticated account: $login" }
$repo = Invoke-Gh repo view $Repository --json 'nameWithOwner,isPrivate,defaultBranchRef,viewerPermission' | ConvertFrom-Json
if ($repo.nameWithOwner -ne $Repository -or $repo.isPrivate) { throw 'Only the approved public repository is allowed for the zero-cost standard runner route.' }
if ($repo.viewerPermission -notin @('ADMIN','MAINTAIN','WRITE')) { throw 'Write access is required.' }
$branch = $repo.defaultBranchRef.name
if (!$branch) { throw 'Repository has no default branch. Publish the reviewed project first.' }
foreach ($file in @('.github/workflows/ios-smoke.yml','config/upstream.json','config/requirements-windows.lock.txt','scripts/package-smoke.py','scripts/validate-artifact.py','scripts/run-portable-tests.py')) {
    $remote = Invoke-Gh api "repos/$Repository/contents/${file}?ref=$branch" | ConvertFrom-Json
    $remoteBytes = [Convert]::FromBase64String($remote.content)
    $localBytes = [System.IO.File]::ReadAllBytes((Join-Path $root $file))
    $sha = [System.Security.Cryptography.SHA256]::Create()
    if ([Convert]::ToBase64String($sha.ComputeHash($remoteBytes)) -ne [Convert]::ToBase64String($sha.ComputeHash($localBytes))) {
        throw "Published file differs from reviewed local version: $file"
    }
}
$id = [guid]::NewGuid().ToString('N')
$upload = if ($NoArtifacts) { 'false' } else { 'true' }
Invoke-Gh workflow run ios-smoke.yml --repo $Repository --ref $branch -f "request_id=$id" -f "upload_artifacts=$upload" | Out-Host
$deadline = [DateTime]::UtcNow.AddMinutes($TimeoutMinutes)
$run = $null
while ([DateTime]::UtcNow -lt $deadline) {
    $runs = Invoke-Gh run list --repo $Repository --workflow ios-smoke.yml --limit 30 --json 'databaseId,displayTitle,status,conclusion,url' | ConvertFrom-Json
    $run = $runs | Where-Object displayTitle -eq "nxnative-$id" | Select-Object -First 1
    if ($run) {
        Write-Host "$($run.status): $($run.url)"
        if ($run.status -eq 'completed') { break }
    }
    Start-Sleep -Seconds 15
}
if (!$run -or $run.status -ne 'completed') { throw 'Monitoring timed out. The bounded server job may still be running; inspect GitHub before retrying.' }
$dest = Join-Path $root "artifacts/run-$($run.databaseId)"
New-Item -ItemType Directory -Force $dest | Out-Null
Invoke-Gh run view $run.databaseId --repo $Repository --log | Set-Content "$dest/workflow.log" -Encoding utf8
if (!$NoArtifacts) {
    Invoke-Gh run download $run.databaseId --repo $Repository --name "nxnative-synthetic-$($run.databaseId)" --dir $dest | Out-Host
}
if ($run.conclusion -ne 'success') { throw "Cloud build failed: $($run.conclusion). Inspect $dest/workflow.log for the first root-cause error." }
if ($NoArtifacts) { Write-Host 'Cloud job succeeded; artifact download was disabled. Device/runtime behavior remains unverified.'; return }
& $Python "$root/scripts/validate-artifact.py" "$dest/artifacts"
if ($LASTEXITCODE -ne 0) { throw 'Downloaded artifact validation failed.' }
Write-Host "PASS: synthetic compile/link fixture downloaded and validated at $dest. This is not a playable game; do not install it. See docs/signing-and-runtime.md."
