# PixelLab v2: Vierbeiner-Baer, 4 echte Richtungen, wenig Tokens
# Character-Animation-API (animate-character) braucht character_id von create-character;
# create-character nutzt Humanoid-Template -> fuer Vierbeiner ungeeignet.
# Stattdessen: generate-image-v2 nur mit Text, 4x (south/north/east/west), kein Base64-Bild.

param(
    [string]$OutputDir = "",
    [int]$Size = 64
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputDir) { $OutputDir = $scriptDir }
if (-not [IO.Path]::IsPathRooted($OutputDir)) { $OutputDir = Join-Path $scriptDir $OutputDir }
if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$token = $env:PIXELLAB_API_TOKEN
if (-not $token) {
    Write-Host "Fehler: PIXELLAB_API_TOKEN nicht gesetzt."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$baseDesc = "Quadruped brown bear, four legs on ground, animal, low top-down view, pixel art game enemy"
$directions = @(
    @{ name = "south"; desc = "$baseDesc, facing south" }
    @{ name = "north"; desc = "$baseDesc, facing north" }
    @{ name = "east";  desc = "$baseDesc, facing east" }
    @{ name = "west";  desc = "$baseDesc, facing west" }
)

foreach ($d in $directions) {
    Write-Host "Generiere: $($d.name)..."
    $body = @{
        description   = $d.desc
        image_size    = @{ width = $Size; height = $Size }
        no_background = $true
    } | ConvertTo-Json -Depth 3 -Compress
    try {
        $r = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/generate-image-v2" -Method POST -Headers $headers -Body $body
    } catch {
        Write-Host "  Fehler: $_"
        if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
        continue
    }
    $b64 = $null
    if ($r.images -and $r.images[0].base64) { $b64 = $r.images[0].base64 }
    if ($r.data -and $r.data.images -and $r.data.images[0].base64) { $b64 = $r.data.images[0].base64 }
    if ($b64) {
        $outFile = Join-Path $OutputDir "bear_quadruped_$($d.name).png"
        [IO.File]::WriteAllBytes($outFile, [Convert]::FromBase64String($b64))
        Write-Host "  Gespeichert: $outFile"
    } else {
        Write-Host "  Kein Bild in Response."
    }
}

Write-Host "Fertig. 4 Richtungen in: $OutputDir"
