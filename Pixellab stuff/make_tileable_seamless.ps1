# Macht eine Textur nahtlos kachelbar (Cut-and-Swap).
# Methode: Vertikal halbieren, linke/rechte Haelfte tauschen; dann horizontal halbieren, oben/unten tauschen.
# Die neuen Kanten stammen aus der Bildmitte und matchen beim Kacheln.
# Quelle: cmichel.io/creating-seamless-textures-the-easy-way
#
# Aufruf: .\make_tileable_seamless.ps1 -ImagePath ".\ui_frame_medieval_20260130_092711_background_only.png"
# Optional: -OutputPath ".\ui_bg_seamless.png" -TileSize 64 (crop to center 64x64 first, then swap)

param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,
    [string]$OutputPath = "",
    [int]$TileSize = 0
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not [IO.Path]::IsPathRooted($ImagePath)) { $ImagePath = Join-Path $scriptDir $ImagePath }
if (-not (Test-Path -LiteralPath $ImagePath)) { Write-Host "Fehler: Bild nicht gefunden: $ImagePath"; exit 1 }

if (-not $OutputPath) {
    $baseName = [IO.Path]::GetFileNameWithoutExtension($ImagePath)
    $OutputPath = Join-Path $scriptDir "${baseName}_seamless.png"
}
if (-not [IO.Path]::IsPathRooted($OutputPath)) { $OutputPath = Join-Path $scriptDir $OutputPath }

Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $ImagePath))
$w = $img.Width
$h = $img.Height

if ($TileSize -gt 0 -and ($w -gt $TileSize -or $h -gt $TileSize)) {
    $x0 = [Math]::Max(0, [Math]::Floor(($w - $TileSize) / 2))
    $y0 = [Math]::Max(0, [Math]::Floor(($h - $TileSize) / 2))
    $crop = $img.Clone([System.Drawing.Rectangle]::new($x0, $y0, $TileSize, $TileSize), $img.PixelFormat)
    $img.Dispose()
    $img = $crop
    $w = $TileSize
    $h = $TileSize
}

$halfW = [Math]::Floor($w / 2)
$halfH = [Math]::Floor($h / 2)
$out = New-Object System.Drawing.Bitmap($w, $h, $img.PixelFormat)

for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $sx = if ($x -lt $halfW) { $x + $halfW } else { $x - $halfW }
        $sy = $y
        $c = $img.GetPixel($sx, $sy)
        $out.SetPixel($x, $y, $c)
    }
}
$img.Dispose()
$img = $out
$out = New-Object System.Drawing.Bitmap($w, $h, $img.PixelFormat)
for ($y = 0; $y -lt $h; $y++) {
    for ($x = 0; $x -lt $w; $x++) {
        $sx = $x
        $sy = if ($y -lt $halfH) { $y + $halfH } else { $y - $halfH }
        $c = $img.GetPixel($sx, $sy)
        $out.SetPixel($x, $y, $c)
    }
}
$img.Dispose()
$out.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$out.Dispose()

Write-Host "Nahtlose Kachel gespeichert: $OutputPath (${w}x${h})"
Write-Host "In Godot: Als TileSet-Texture nutzen, Kanten matchen."
