# Generiert ein 128x128 (oder -Size) Muster, das an allen 4 Seiten nahtlos an sich selbst anlegbar ist.
# Linke Kante = rechte Kante, obere = untere (Grid mit gleichen Randzeilen/-spalten).
# Aufruf: .\generate_seamless_background.ps1 -Size 128
# Optional: -OutputPath ".\ui_bg_128.png" -Seed 42

param(
    [string]$OutputPath = "",
    [int]$Size = 128,
    [int]$Seed = 42
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputPath) { $OutputPath = Join-Path $scriptDir "ui_background_${Size}_seamless.png" }
if (-not [IO.Path]::IsPathRooted($OutputPath)) { $OutputPath = Join-Path $scriptDir $OutputPath }

Add-Type -AssemblyName System.Drawing

$rnd = New-Object System.Random($Seed)
$TileSize = [int]$Size
$last = $TileSize - 1
$grid = New-Object 'double[,]' $TileSize, $TileSize
for ($j = 0; $j -lt $TileSize; $j++) {
    for ($i = 0; $i -lt $TileSize; $i++) {
        $grid[$i, $j] = $rnd.NextDouble()
    }
}
for ($j = 0; $j -lt $TileSize; $j++) { $grid[$last, $j] = $grid[0, $j] }
for ($i = 0; $i -lt $TileSize; $i++) { $grid[$i, $last] = $grid[$i, 0] }

function Sample($x, $y) {
    $xn = $x % $TileSize
    $yn = $y % $TileSize
    if ($xn -lt 0) { $xn += $TileSize }
    if ($yn -lt 0) { $yn += $TileSize }
    $i0 = [Math]::Floor($xn) % $TileSize
    $j0 = [Math]::Floor($yn) % $TileSize
    $i1 = ($i0 + 1) % $TileSize
    $j1 = ($j0 + 1) % $TileSize
    $dx = $xn - [Math]::Floor($xn)
    $dy = $yn - [Math]::Floor($yn)
    $v00 = $grid[$i0, $j0]
    $v10 = $grid[$i1, $j0]
    $v01 = $grid[$i0, $j1]
    $v11 = $grid[$i1, $j1]
    $a = $v00 * (1 - $dx) + $v10 * $dx
    $b = $v01 * (1 - $dx) + $v11 * $dx
    return $a * (1 - $dy) + $b * $dy
}

$bmp = New-Object System.Drawing.Bitmap($TileSize, $TileSize)
$baseR = 38
$baseG = 38
$baseB = 42
$amp = 14

for ($py = 0; $py -lt $TileSize; $py++) {
    for ($px = 0; $px -lt $TileSize; $px++) {
        $x = $px + 0.5
        $y = $py + 0.5
        $n = Sample $x $y
        $n2 = Sample ($x * 2) ($y * 2)
        $v = $n * 0.7 + $n2 * 0.3
        $d = [Math]::Round(($v - 0.5) * $amp)
        $r = [Math]::Max(0, [Math]::Min(255, $baseR + $d))
        $g = [Math]::Max(0, [Math]::Min(255, $baseG + $d))
        $b = [Math]::Max(0, [Math]::Min(255, $baseB + $d))
        $bmp.SetPixel($px, $py, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
    }
}

$bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Seamless-Muster gespeichert: $OutputPath (${TileSize}x${TileSize})"
Write-Host "An allen 4 Seiten an sich selbst anlegbar, Muster geht nahtlos weiter."
