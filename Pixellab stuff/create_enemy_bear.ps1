# PixelLab v2: Gegner (humanoid) im gleichen Stil wie Held – 8 Richtungen
# Fuer VIERBEINER (Baer, Wolf etc.) -> create_enemy_bear_quadruped.ps1 verwenden
# POST /create-character-with-8-directions, dann Job poll, dann Character abrufen
# Benoetigt: $env:PIXELLAB_API_TOKEN

param(
    [string]$Description = "wild bear, enemy creature, low top-down view, pixel art, same style as medieval game character",
    [string]$OutputDir = "",
    [int]$Width = 64,
    [int]$Height = 64
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

$body = @{
    description   = $Description
    image_size    = @{ width = $Width; height = $Height }
    view          = "low top-down"
    text_guidance_scale = 8
} | ConvertTo-Json -Depth 3 -Compress

try {
    $response = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/create-character-with-8-directions" -Method POST -Headers $headers -Body $body
} catch {
    Write-Host "Fehler beim Erstellen: $_"
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
    exit 1
}

$jobId = $response.background_job_id
$characterId = $response.character_id
if (-not $jobId -or -not $characterId) {
    Write-Host "Response enthaelt kein background_job_id oder character_id: $($response | ConvertTo-Json -Depth 2)"
    exit 1
}

Write-Host "Character-ID: $characterId"
Write-Host "Job-ID: $jobId"
Write-Host "Warte auf Abschluss (Poll alle 10 Sekunden)..."

$maxAttempts = 40
$attempt = 0
while ($attempt -lt $maxAttempts) {
    Start-Sleep -Seconds 10
    $attempt++
    try {
        $jobResp = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/background-jobs/$jobId" -Method GET -Headers @{ "Authorization" = "Bearer $token" }
    } catch {
        Write-Host "  Poll Fehler: $_"
        continue
    }
    $status = $jobResp.status
    Write-Host "  [$attempt] Status: $status"
    if ($status -eq "completed") { break }
    if ($status -eq "failed") {
        Write-Host "Job fehlgeschlagen: $($jobResp | ConvertTo-Json -Depth 2 -Compress)"
        exit 1
    }
}

if ($status -ne "completed") {
    Write-Host "Timeout. Character spaeter abrufen: GET https://api.pixellab.ai/v2/characters/$characterId"
    exit 1
}

Write-Host "Hole Character-Daten..."
try {
    $charResp = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/characters/$characterId" -Method GET -Headers @{ "Authorization" = "Bearer $token" }
} catch {
    Write-Host "Fehler beim Abrufen des Characters: $_"
    exit 1
}

$saved = 0
if ($charResp.zip_download_url) {
    $zipPath = Join-Path $OutputDir "bear_character.zip"
    try {
        Invoke-WebRequest -Uri $charResp.zip_download_url -OutFile $zipPath
        Write-Host "ZIP gespeichert: $zipPath"
        $saved++
    } catch { Write-Host "ZIP-Download fehlgeschlagen: $_" }
}
if ($charResp.data -and $charResp.data.zip_download_url) {
    $zipPath = Join-Path $OutputDir "bear_character.zip"
    try {
        Invoke-WebRequest -Uri $charResp.data.zip_download_url -OutFile $zipPath
        Write-Host "ZIP gespeichert: $zipPath"
        $saved++
    } catch { Write-Host "ZIP-Download fehlgeschlagen: $_" }
}
$rotationUrls = $null
if ($charResp.rotation_urls) { $rotationUrls = $charResp.rotation_urls }
if ($charResp.data -and $charResp.data.rotation_urls) { $rotationUrls = $charResp.data.rotation_urls }
if ($rotationUrls) {
    $rotationUrls.PSObject.Properties | ForEach-Object {
        $dir = $_.Name
        $url = $_.Value
        if ($url -and $dir) {
            $safeName = $dir -replace '[^a-zA-Z0-9_-]', '_'
            $outFile = Join-Path $OutputDir "bear_${safeName}.png"
            try {
                Invoke-WebRequest -Uri $url -OutFile $outFile
                Write-Host "Gespeichert: $outFile"
                $saved++
            } catch { Write-Host "Download fehlgeschlagen fuer $dir : $_" }
        }
    }
}
$rotations = $null
if ($charResp.rotations) { $rotations = $charResp.rotations }
if ($charResp.data -and $charResp.data.rotations) { $rotations = $charResp.data.rotations }
if ($rotations) {
    foreach ($r in $rotations) {
        $url = $r.url; if (-not $url) { $url = $r.image_url }
        $dir = $r.direction; if (-not $dir) { $dir = $r.name }
        if ($url -and $dir) {
            $safeName = $dir -replace '[^a-zA-Z0-9_-]', '_'
            $outFile = Join-Path $OutputDir "bear_${safeName}.png"
            try {
                Invoke-WebRequest -Uri $url -OutFile $outFile
                Write-Host "Gespeichert: $outFile"
                $saved++
            } catch { Write-Host "Download fehlgeschlagen fuer $dir : $_" }
        }
    }
}

if ($saved -eq 0) {
    Write-Host "Keine Bilder/ZIP in Response. Character-ID: $characterId"
    Write-Host "Response (Auszug): $($charResp | ConvertTo-Json -Depth 3 -Compress)"
    Write-Host "Du kannst den Character unter https://pixellab.ai/create-character mit dieser ID oeffnen oder die API-Doku pruefen."
}

Write-Host "Fertig. Character-ID: $characterId"
