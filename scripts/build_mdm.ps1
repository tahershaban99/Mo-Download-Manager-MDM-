$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $root

$gccBin = Join-Path $root "build-cache\w64devkit\bin"
$cargoBin = Join-Path $env:USERPROFILE ".cargo\bin"

# Prepend gcc and cargo to PATH
$env:Path = "$gccBin;$cargoBin;$env:Path"

# Point CC and AR directly to gcc and ar
$env:CC = Join-Path $gccBin "gcc.exe"
$env:CXX = Join-Path $gccBin "g++.exe"
$env:AR = Join-Path $gccBin "ar.exe"
$env:RC = Join-Path $gccBin "windres.exe"

# Fix missing libgcc_eh.a for rustc gnu linker
$dir64 = Join-Path $root "build-cache\w64devkit\lib\gcc\x86_64-w64-mingw32\16.2.0"
$dir32 = Join-Path $dir64 "32"
if ((Test-Path (Join-Path $dir64 "libgcc.a")) -and -not (Test-Path (Join-Path $dir64 "libgcc_eh.a"))) {
    Copy-Item (Join-Path $dir64 "libgcc.a") (Join-Path $dir64 "libgcc_eh.a") -Force
}
if ((Test-Path (Join-Path $dir32 "libgcc.a")) -and -not (Test-Path (Join-Path $dir32 "libgcc_eh.a"))) {
    Copy-Item (Join-Path $dir32 "libgcc.a") (Join-Path $dir32 "libgcc_eh.a") -Force
}

Write-Host "Running cargo check on crates/app..."
& (Join-Path $cargoBin "cargo.exe") check --manifest-path crates/app/Cargo.toml
