# PixelLab v2: UI-Element "Punchhole" – Rahmen wie Impact-Krater/Durchschuss, Loch transparent
# Loch exakt HoleSize x HoleSize (z.B. 32x32), Rahmen FrameWidth px drumherum (5-10).
# Stil: Durchschuss/Krater, zerbrochene Kanten, Trümmer, Risse – nicht saubere Mauer.
# Aufruf: .\create_ui_punchhole.ps1
# Optional: .\create_ui_punchhole.ps1 -FrameWidth 10 -OutputName "ui_punchhole_52.png"

param(
    [string]$OutputDir = "",
    [string]$OutputName = "",
    [int]$HoleSize = 32,
    [int]$FrameWidth = 16
)
# API erlaubt nur 32/64/128/256. Loch HoleSize + Rahmen 2*FrameWidth = Gesamt. Bei 64x64 und Loch 32: FrameWidth=16.

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputDir) { $OutputDir = $scriptDir }
if (-not [IO.Path]::IsPathRooted($OutputDir)) { $OutputDir = Join-Path $scriptDir $OutputDir }
if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$token = $env:PIXELLAB_API_TOKEN
if (-not $token) {
    $envCandidates = @(
        (Join-Path $scriptDir ".env"),
        (Join-Path (Split-Path -Parent $scriptDir) "Pixellab stuff\.env"),
        (Join-Path (Split-Path -Parent $scriptDir) ".env")
    )
    foreach ($envPath in $envCandidates) {
        if (Test-Path -LiteralPath $envPath) {
            Get-Content -LiteralPath $envPath -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_ -match '^\s*PIXELLAB_API_TOKEN\s*=\s*["'']?([^"''\s]+)["'']?') { $token = $Matches[1] }
                elseif ($_ -match '^\s*([a-zA-Z0-9_-]{20,})\s*$') { $token = $Matches[1] }
            }
            if ($token) { break }
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

$Size = $HoleSize + 2 * $FrameWidth
$allowed = @(32, 64, 128, 256)
if ($Size -notin $allowed) {
    $next = $allowed | Where-Object { $_ -ge $Size } | Select-Object -First 1
    $Size = if ($next) { [int]$next } else { 64 }
}
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
if ($OutputName) {
    if (-not $OutputName.EndsWith(".png")) { $OutputName = "${OutputName}.png" }
    $outFileName = $OutputName
} else {
    $outFileName = "ui_frame_punchhole_${Size}_${timestamp}.png"
}
$outFile = Join-Path $OutputDir $outFileName
if (Test-Path -LiteralPath $outFile) {
    $base = [IO.Path]::GetFileNameWithoutExtension($outFileName)
    $outFileName = "${base}_${timestamp}.png"
    $outFile = Join-Path $OutputDir $outFileName
}

$description = "Pixel art, flat front view. Stone or masonry IMPACT CRATER / THROUGH-SHOT: something punched or shot through the wall. NOT clean brickwork. Only the broken frame ring; the center hole must be a SQUARE, exactly 32x32 pixels, equal width and height, fully transparent. The border: shattered jagged edges, irregular fracture lines, rubble and stone chips, debris along the inner edge, cracks radiating from the hole, dark shadow at the break. Looks like violent impact, bullet hole or punch-through, chaotic breakage. Medieval dark grey stone. Transparent background. The transparent hole is a perfect square in the middle, not a rectangle; the frame is equal thickness on all sides around it."

$body = @{
    description   = $description
    image_size    = @{ width = $Size; height = $Size }
    no_background = $true
} | ConvertTo-Json -Depth 3 -Compress

function Save-ImageFromResponse {
    param($jobResp)
    $imgBase64 = $null
    if ($jobResp.data -and $jobResp.data.images -and $jobResp.data.images[0].base64) { $imgBase64 = $jobResp.data.images[0].base64 }
    elseif ($jobResp.result -and $jobResp.result.images -and $jobResp.result.images[0].base64) { $imgBase64 = $jobResp.result.images[0].base64 }
    elseif ($jobResp.images -and $jobResp.images[0].base64) { $imgBase64 = $jobResp.images[0].base64 }
    if ($jobResp.data -and $jobResp.data.result -and $jobResp.data.result.images) { $imgBase64 = $jobResp.data.result.images[0].base64 }
    if ($jobResp.data -and $jobResp.data.result -and $jobResp.data.result.base64) { $imgBase64 = $jobResp.data.result.base64 }
    if ($imgBase64) {
        [IO.File]::WriteAllBytes($outFile, [Convert]::FromBase64String($imgBase64))
        Write-Host "Gespeichert: $outFile"
        return $true
    }
    $url = $null
    if ($jobResp.data -and $jobResp.data.images -and $jobResp.data.images[0].url) { $url = $jobResp.data.images[0].url }
    if (-not $url -and $jobResp.result -and $jobResp.result.images -and $jobResp.result.images[0].url) { $url = $jobResp.result.images[0].url }
    if (-not $url -and $jobResp.images -and $jobResp.images[0].url) { $url = $jobResp.images[0].url }
    if ($url) {
        Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
        Write-Host "Gespeichert: $outFile"
        return $true
    }
    return $false
}

try {
    $r = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/generate-image-v2" -Method POST -Headers $headers -Body $body
} catch {
    Write-Host "Fehler: $_"
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
    exit 1
}

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
        } catch {
            Write-Host "  Poll Fehler: $_"
            continue
        }
        $status = $jobResp.status
        Write-Host "  [$attempt] Status: $status"
        if ($status -eq "completed") {
            if (Save-ImageFromResponse -jobResp $jobResp) { Write-Host "Fertig."; exit 0 }
            Write-Host "Job fertig, aber kein Bild in Response."
            exit 1
        }
        if ($status -eq "failed") {
            Write-Host "Job fehlgeschlagen: $($jobResp.error | ConvertTo-Json -Compress)"
            exit 1
        }
    }
    Write-Host "Timeout nach $maxAttempts Versuchen."
    exit 1
}

Write-Host "Kein Bild und kein background_job_id in Response."
exit 1
