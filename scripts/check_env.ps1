$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswhere) {
    $vc = & $vswhere -products * -property installationPath
    Write-Host "VS Installations:" ($vc -join "; ")
} else {
    Write-Host "vswhere not found"
}

$cargoInUser = "$env:USERPROFILE\.cargo\bin\cargo.exe"
Write-Host "Cargo in user profile:" (Test-Path $cargoInUser)

$isccPaths = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
)
foreach ($p in $isccPaths) {
    if (Test-Path $p) {
        Write-Host "Found ISCC:" $p
    }
}
