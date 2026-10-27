Add-Type -AssemblyName System.Drawing
$srcPath = "C:\Users\Mohamed\.gemini\antigravity-ide\brain\8e1a921c-d96e-49f4-ae24-f990aa68b430\mdm_logo_icon_1792932785010.jpg"
$src = [System.Drawing.Bitmap]::FromFile($srcPath)

function Resize-Img($bmp, $w, $h) {
    $dest = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.DrawImage($bmp, 0, 0, $w, $h)
    $g.Dispose()
    return $dest
}

# 1. icon.png (512x512)
$i512 = Resize-Img $src 512 512
$i512.Save("c:\Users\Mohamed\Desktop\MDM3\ezoo-download-main\crates\app\ui\icon.png", [System.Drawing.Imaging.ImageFormat]::Png)
$i512.Dispose()

# 2. icon-window.png (64x64)
$i64 = Resize-Img $src 64 64
$i64.Save("c:\Users\Mohamed\Desktop\MDM3\ezoo-download-main\crates\app\ui\icon-window.png", [System.Drawing.Imaging.ImageFormat]::Png)
$i64.Dispose()

# 3. extension icons
foreach ($sz in @(16, 32, 48, 128)) {
    $i = Resize-Img $src $sz $sz
    $i.Save("c:\Users\Mohamed\Desktop\MDM3\ezoo-download-main\extension\icons\icon$sz.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $i.Dispose()
}

# 4. tray32.rgba (32x32 raw RGBA)
$t32 = Resize-Img $src 32 32
$bytes = New-Object byte[] (32 * 32 * 4)
$idx = 0
for ($y = 0; $y -lt 32; $y++) {
    for ($x = 0; $x -lt 32; $x++) {
        $pixel = $t32.GetPixel($x, $y)
        $bytes[$idx++] = $pixel.R
        $bytes[$idx++] = $pixel.G
        $bytes[$idx++] = $pixel.B
        $bytes[$idx++] = $pixel.A
    }
}
$t32.Dispose()
[System.IO.File]::WriteAllBytes("c:\Users\Mohamed\Desktop\MDM3\ezoo-download-main\crates\app\ui\tray32.rgba", $bytes)

# 5. icon.ico with sizes (256, 128, 64, 48, 32, 16)
$sizes = @(256, 128, 64, 48, 32, 16)
$pngStreams = @()
foreach ($s in $sizes) {
    $bmp = Resize-Img $src $s $s
    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $pngStreams += ,$ms.ToArray()
    $ms.Dispose()
}

$icoMs = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($icoMs)
$bw.Write([uint16]0) # reserved
$bw.Write([uint16]1) # ICO type
$bw.Write([uint16]$sizes.Count)

$offset = 6 + ($sizes.Count * 16)
for ($k = 0; $k -lt $sizes.Count; $k++) {
    $s = $sizes[$k]
    $len = $pngStreams[$k].Length
    $w = if ($s -eq 256) { 0 } else { $s }
    $h = if ($s -eq 256) { 0 } else { $s }
    $bw.Write([byte]$w)
    $bw.Write([byte]$h)
    $bw.Write([byte]0) # colors
    $bw.Write([byte]0) # reserved
    $bw.Write([uint16]1) # planes
    $bw.Write([uint16]32) # bpp
    $bw.Write([uint32]$len)
    $bw.Write([uint32]$offset)
    $offset += $len
}
for ($k = 0; $k -lt $sizes.Count; $k++) {
    $bw.Write($pngStreams[$k])
}
$bw.Flush()
[System.IO.File]::WriteAllBytes("c:\Users\Mohamed\Desktop\MDM3\ezoo-download-main\crates\app\icon.ico", $icoMs.ToArray())
$bw.Dispose()
$icoMs.Dispose()
$src.Dispose()
Write-Host "All icons generated successfully!"
