# PixelLab v2: Vielseitiges UI-Element im Medieval-Style
# Parameter beim Ausfuehren: Type, Description, Groesse, Output.
# Benoetigt: .env mit PIXELLAB_API_TOKEN
#
# Beispiele:
#   .\create_ui_element.ps1 -Type frame
#   .\create_ui_element.ps1 -Type panel -Width 128
#   .\create_ui_element.ps1 -Type background -Size 64
#   .\create_ui_element.ps1 -Description "button, raised stone, slightly rounded"
#   .\create_ui_element.ps1 -Description "inventory slot, empty, stone border" -Width 64 -Height 64

param(
    [ValidateSet("frame", "panel", "background")]
    [string]$Type = "",
    [string]$Description = "",
    [string]$OutputDir = "",
    [string]$OutputName = "",
    [ValidateSet(32, 64, 128, 256)]
    [int]$Size = 128,
    [int]$Width = 0,
    [int]$Height = 0
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputDir) { $OutputDir = $scriptDir }
if (-not [IO.Path]::IsPathRooted($OutputDir)) { $OutputDir = Join-Path $scriptDir $OutputDir }
if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

if ($Width -eq 0) { $Width = $Size }
if ($Height -eq 0) { $Height = $Size }
$validSizes = @(32, 64, 128, 256)
if ($Width -notin $validSizes) { $Width = 128 }
if ($Height -notin $validSizes) { $Height = 128 }

$token = $env:PIXELLAB_API_TOKEN
if (-not $token) {
    $envPath = Join-Path $scriptDir ".env"
    if (Test-Path -LiteralPath $envPath) {
        Get-Content -LiteralPath $envPath | ForEach-Object {
            if ($_ -match '^\s*PIXELLAB_API_TOKEN\s*=\s*["'']?([^"''\s]+)["'']?') { $token = $Matches[1] }
            elseif ($_ -match '^\s*([a-zA-Z0-9_-]{20,})\s*$') { $token = $Matches[1] }
        }
    }
}
if (-not $token) {
    Write-Host "Fehler: PIXELLAB_API_TOKEN nicht gesetzt. Leg .env an oder setze Umgebung."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$baseStyle = "Medieval game UI, stone or metal (not wood), pixel art, minimal detail, transparent background, flat front view."

$presets = @{
    frame     = "Panel frame, stone or metal border, simple and clean. Interior: subtle stone wall texture, dark grey or brown, not too busy, not flat. Small arrow on the outer right side of the frame, pointing right, centered vertically, protruding outward (arrow outside panel)."
    panel     = "Panel frame for settings or dialog, stone or metal border, no arrow. Interior: subtle stone texture, not flat."
    background = "Only the inner panel background: dark grey cracked stone, fine crack network, uniformly textured, recessed look, no frame no border no arrow. Seamless tileable: left edge matches right edge, top matches bottom, so tile repeats without visible seam for tileset painting. Same style as medieval stone UI panel interior."
}

if ($Description.Trim()) {
    $description = "$baseStyle $($Description.Trim())"
} elseif ($Type) {
    $description = "$baseStyle $($presets[$Type])"
} else {
    Write-Host "Fehler: -Type (frame, panel, background) oder -Description angeben."
    exit 1
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
if ($OutputName) {
    if (-not $OutputName.EndsWith(".png")) { $OutputName = "${OutputName}.png" }
    $outFileName = $OutputName
} else {
    $typeLabel = if ($Type) { $Type } else { "custom" }
    $outFileName = "ui_${typeLabel}_${timestamp}.png"
}

$body = @{
    description   = $description
    image_size    = @{ width = $Width; height = $Height }
    no_background = $true
} | ConvertTo-Json -Depth 3 -Compress

try {
    $r = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/generate-image-v2" -Method POST -Headers $headers -Body $body
} catch {
    Write-Host "Fehler: $_"
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
    exit 1
}

$outFile = Join-Path $OutputDir $outFileName
$b64 = $null
if ($r.images -and $r.images[0].base64) { $b64 = $r.images[0].base64 }
if ($r.data -and $r.data.images -and $r.data.images[0].base64) { $b64 = $r.data.images[0].base64 }
if ($b64) {
    [IO.File]::WriteAllBytes($outFile, [Convert]::FromBase64String($b64))
    Write-Host "Gespeichert: $outFile"
    Write-Host "Fertig."
    exit 0
}

if ($r.background_job_id) {
    $jobId = $r.background_job_id
    Write-Host "Job gestartet (async). Job-ID: $jobId"
    Write-Host "Warte auf Abschluss (Poll alle 8 Sekunden)..."
    $maxAttempts = 60
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        Start-Sleep -Seconds 8
        $attempt++
        try {
            $jobResp = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/background-jobs/$jobId" -Method GET -Headers $headers
        } catch { Write-Host "  Poll Fehler: $_"; continue }
        $status = $jobResp.status
        Write-Host "  [$attempt] Status: $status"
        if ($status -eq "completed") {
            $imgBase64 = $null
            if ($jobResp.data -and $jobResp.data.images -and $jobResp.data.images[0].base64) { $imgBase64 = $jobResp.data.images[0].base64 }
            elseif ($jobResp.result -and $jobResp.result.images -and $jobResp.result.images[0].base64) { $imgBase64 = $jobResp.result.images[0].base64 }
            elseif ($jobResp.images -and $jobResp.images[0].base64) { $imgBase64 = $jobResp.images[0].base64 }
            if ($jobResp.data -and $jobResp.data.result -and $jobResp.data.result.images) { $imgBase64 = $jobResp.data.result.images[0].base64 }
            if ($jobResp.data -and $jobResp.data.result -and $jobResp.data.result.base64) { $imgBase64 = $jobResp.data.result.base64 }
            if ($imgBase64) {
                [IO.File]::WriteAllBytes($outFile, [Convert]::FromBase64String($imgBase64))
                Write-Host "Gespeichert: $outFile"
            } else {
                $url = $jobResp.data.images[0].url; if (-not $url) { $url = $jobResp.result.images[0].url }
                if ($url) { Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing; Write-Host "Gespeichert: $outFile" }
                else { Write-Host "Job fertig, aber kein Bild in Response."; exit 1 }
            }
            Write-Host "Fertig."
            exit 0
        }
        if ($status -eq "failed") {
            Write-Host "Job fehlgeschlagen: $($jobResp.error | ConvertTo-Json -Compress)"
            exit 1
        }
    }
    Write-Host "Timeout nach $maxAttempts Versuchen."
    exit 1
}

Write-Host "Kein Bild in Response."
exit 1
