# Erzeugt ein einheitliches, kachelbares Hintergrund-Muster (kein AI).
# Gleicher Stil: dunkelgrau, steinig. Muster wiederholt sich exakt, Kanten matchen.
# Aufruf: .\create_tileable_background.ps1
# Optional: -CellSize 8 -TileSize 64 -OutputPath ".\ui_bg_tile.png"

param(
    [string]$OutputPath = "",
    [int]$CellSize = 8,
    [int]$TileSize = 64
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputPath) { $OutputPath = Join-Path $scriptDir "ui_background_tileable.png" }
if (-not [IO.Path]::IsPathRooted($OutputPath)) { $OutputPath = Join-Path $scriptDir $OutputPath }

Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap($TileSize, $TileSize)

$colors = @(
    [System.Drawing.Color]::FromArgb(255, 38, 38, 42),
    [System.Drawing.Color]::FromArgb(255, 45, 45, 50),
    [System.Drawing.Color]::FromArgb(255, 42, 42, 46),
    [System.Drawing.Color]::FromArgb(255, 50, 50, 54),
    [System.Drawing.Color]::FromArgb(255, 35, 35, 40),
    [System.Drawing.Color]::FromArgb(255, 28, 28, 32)
)
$crackIdx = $colors.Length - 1

$rnd = New-Object System.Random(42)
$cell = New-Object 'int[,]' $CellSize, $CellSize
for ($y = 0; $y -lt $CellSize; $y++) {
    for ($x = 0; $x -lt $CellSize; $x++) {
        $cell[$x, $y] = $rnd.Next(0, $crackIdx)
    }
}
$crackPositions = @(@(1,1), @(4,2), @(2,5), @(6,3), @(3,6), @(5,5))
foreach ($p in $crackPositions) {
    $cx = $p[0] % $CellSize
    $cy = $p[1] % $CellSize
    $cell[$cx, $cy] = $crackIdx
}

for ($py = 0; $py -lt $TileSize; $py++) {
    for ($px = 0; $px -lt $TileSize; $px++) {
        $cx = $px % $CellSize
        $cy = $py % $CellSize
        $c = $colors[$cell[$cx, $cy]]
        $bmp.SetPixel($px, $py, $c)
    }
}

$bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Host "Kachelbares Muster gespeichert: $OutputPath (${TileSize}x${TileSize}, Zelle ${CellSize}x${CellSize})"
Write-Host "In Godot als TileSet-Texture nutzen, Kanten matchen exakt."
