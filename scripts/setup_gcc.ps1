$ErrorActionPreference = "Stop"
$cacheDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\build-cache"))
$w64Dir = Join-Path $cacheDir "w64devkit"
$binDir = Join-Path $w64Dir "bin"

$url = "https://github.com/skeeto/w64devkit/releases/download/v2.10.1/w64devkit-x64-2.10.1.7z.exe"
$sfx = Join-Path $env:TEMP "w64devkit-sfx.exe"

if (-not (Test-Path (Join-Path $binDir "gcc.exe"))) {
    if (Test-Path $w64Dir) { Remove-Item -Recurse -Force $w64Dir }
    if (-not (Test-Path $sfx)) {
        Write-Host "Downloading w64devkit MinGW gcc (67MB)..."
        Invoke-WebRequest $url -OutFile $sfx
    }
    Write-Host "Extracting to $cacheDir (waiting for completion)..."
    $p = Start-Process -FilePath $sfx -ArgumentList "-y", "-o$cacheDir" -Wait -PassThru
    Write-Host "Extraction exit code: $($p.ExitCode)"
    Remove-Item $sfx -Force -ErrorAction SilentlyContinue
}

if (Test-Path (Join-Path $binDir "gcc.exe")) {
    Write-Host "gcc is ready at: $binDir"
    & (Join-Path $binDir "gcc.exe") --version | Select-Object -First 1
} else {
    Write-Error "gcc.exe not found at $binDir"
}
