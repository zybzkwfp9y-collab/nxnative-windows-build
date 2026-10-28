[CmdletBinding()]
param([string]$Python = 'python')
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
& $Python -c 'import sys; assert sys.version_info >= (3,12), "Python 3.12+ required"'
if ($LASTEXITCODE -ne 0) { throw 'A working Python 3.12+ interpreter is required; Windows Store aliases do not count.' }
if (!(Test-Path "$root/.venv/Scripts/python.exe")) {
    & $Python -m venv "$root/.venv"
    if ($LASTEXITCODE -ne 0) { throw 'venv creation failed' }
}
& "$root/.venv/Scripts/python.exe" -m pip install -r "$root/config/requirements-windows.lock.txt"
if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed' }
