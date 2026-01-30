# Schneidet nur den Innenbereich (Hintergrund) aus einem Frame-Bild aus.
# Kein AI, exakt die Textur aus dem angegebenen Bild.
# Aufruf: .\extract_background_from_frame.ps1 -ImagePath ".\ui_frame_medieval_20260130_092711.png" -Margin 24
# Optional: -OutputPath ".\ui_background.png" -Margin 20

param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,
    [string]$OutputPath = "",
    [int]$Margin = 24
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not [IO.Path]::IsPathRooted($ImagePath)) { $ImagePath = Join-Path $scriptDir $ImagePath }
if (-not (Test-Path -LiteralPath $ImagePath)) { Write-Host "Fehler: Bild nicht gefunden: $ImagePath"; exit 1 }

if (-not $OutputPath) {
    $baseName = [IO.Path]::GetFileNameWithoutExtension($ImagePath)
    $OutputPath = Join-Path $scriptDir "${baseName}_background_only.png"
}
if (-not [IO.Path]::IsPathRooted($OutputPath)) { $OutputPath = Join-Path $scriptDir $OutputPath }
$outDir = [IO.Path]::GetDirectoryName($OutputPath)
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $ImagePath))
$w = $img.Width
$h = $img.Height

$innerW = $w - 2 * $Margin
$innerH = $h - 2 * $Margin
if ($innerW -lt 8 -or $innerH -lt 8) { Write-Host "Fehler: Margin zu gross, Innenbereich zu klein."; $img.Dispose(); exit 1 }

$rect = [System.Drawing.Rectangle]::new($Margin, $Margin, $innerW, $innerH)
$part = $img.Clone($rect, $img.PixelFormat)
$part.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$part.Dispose()
$img.Dispose()

Write-Host "Hintergrund extrahiert: $OutputPath (${innerW}x${innerH} px)"
Write-Host "Fuer Tileset: In Godot importieren. Wenn Kanten sichtbar sind, in GIMP mit Make Seamless nachbearbeiten."
