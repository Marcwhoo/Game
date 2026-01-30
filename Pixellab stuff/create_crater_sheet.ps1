# PixelLab v2 ODER Offline: 8 Variationen eines 32x32 Kraters, Sheet 256x32
# Mit -ReferenceImage: kein API-Call, 8 Variationen aus einer Vorlage (Kopie/Spiegel)
# Ohne: 8x generate-image-v2 (kann von Content Policy blockiert werden)
# Aufruf: .\create_crater_sheet.ps1 -ReferenceImage "ui_frame_punchhole_sheet (1).png"
#         .\create_crater_sheet.ps1

param(
    [string]$OutputDir = "",
    [string]$OutputName = "",
    [string]$ReferenceImage = "",
    [ValidateRange(2, 16)]
    [int]$Count = 8
)

$cellSize = 32
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $OutputDir) { $OutputDir = $scriptDir }
if (-not [IO.Path]::IsPathRooted($OutputDir)) { $OutputDir = Join-Path $scriptDir $OutputDir }
if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

if ($ReferenceImage) {
    $refPath = $ReferenceImage
    if (-not [IO.Path]::IsPathRooted($refPath)) { $refPath = Join-Path $scriptDir $refPath }
    if (-not (Test-Path -LiteralPath $refPath)) { Write-Host "Referenzbild nicht gefunden: $refPath"; exit 1 }
    Add-Type -AssemblyName System.Drawing
    $sheetWidth = $Count * $cellSize
    $sheetHeight = $cellSize
    $bmp = New-Object System.Drawing.Bitmap($sheetWidth, $sheetHeight)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Black)
    $src = [System.Drawing.Bitmap]::FromFile($refPath)
    $variations = @(
        @{ flipX = $false; flipY = $false },
        @{ flipX = $true;  flipY = $false },
        @{ flipX = $false; flipY = $true },
        @{ flipX = $true;  flipY = $true }
    )
    for ($i = 0; $i -lt $Count; $i++) {
        $v = $variations[$i % $variations.Count]
        $cell = New-Object System.Drawing.Bitmap($cellSize, $cellSize)
        $gc = [System.Drawing.Graphics]::FromImage($cell)
        $gc.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        if ($v.flipX) { $gc.ScaleTransform(-1, 1) }
        if ($v.flipY) { $gc.ScaleTransform(1, -1) }
        $dx = if ($v.flipX) { -$cellSize } else { 0 }
        $dy = if ($v.flipY) { -$cellSize } else { 0 }
        $gc.DrawImage($src, $dx, $dy, $cellSize, $cellSize)
        $gc.Dispose()
        $g.DrawImage($cell, $i * $cellSize, 0, $cellSize, $cellSize)
        $cell.Dispose()
    }
    $src.Dispose()
    $g.Dispose()
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $outFileName = if ($OutputName) { if (-not $OutputName.EndsWith(".png")) { "${OutputName}.png" } else { $OutputName } } else { "ui_frame_punchhole_sheet_8_${timestamp}.png" }
    $outFile = Join-Path $OutputDir $outFileName
    if (Test-Path -LiteralPath $outFile) { $base = [IO.Path]::GetFileNameWithoutExtension($outFileName); $outFileName = "${base}_${timestamp}.png"; $outFile = Join-Path $OutputDir $outFileName }
    $bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Gespeichert: $outFile (${sheetWidth}x${sheetHeight}, $Count Variationen aus Referenz)"
    Write-Host "Fertig."
    exit 0
}

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
    Write-Host "Fehler: PIXELLAB_API_TOKEN nicht gesetzt."
    exit 1
}

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$description = "Pixel art, 32x32, dark grey irregular circular shape on solid black background, like a round indentation or depression, jagged pixel edges, rough outline, game asset, very similar style each time, slight natural variation only."

$body = @{
    description   = $description
    image_size    = @{ width = $cellSize; height = $cellSize }
    no_background = $false
} | ConvertTo-Json -Depth 3 -Compress

function Get-ImageBytesFromResponse {
    param($r)
    $b64 = $null
    if ($r.images -and $r.images[0].base64) { $b64 = $r.images[0].base64 }
    if ($r.data -and $r.data.images -and $r.data.images[0].base64) { $b64 = $r.data.images[0].base64 }
    if ($b64) { return [Convert]::FromBase64String($b64) }
    return $null
}

function Wait-JobAndGetBytes {
    param($jobId, $headers)
    $maxAttempts = 60
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        Start-Sleep -Seconds 8
        $attempt++
        try {
            $jobResp = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/background-jobs/$jobId" -Method GET -Headers $headers
        } catch { Write-Host "    Poll Fehler: $_"; continue }
        $status = $jobResp.status
        Write-Host "    [$attempt] Status: $status"
        if ($status -eq "completed") {
            $b64 = $null
            if ($jobResp.data -and $jobResp.data.images -and $jobResp.data.images[0].base64) { $b64 = $jobResp.data.images[0].base64 }
            elseif ($jobResp.result -and $jobResp.result.images -and $jobResp.result.images[0].base64) { $b64 = $jobResp.result.images[0].base64 }
            elseif ($jobResp.images -and $jobResp.images[0].base64) { $b64 = $jobResp.images[0].base64 }
            if ($jobResp.data -and $jobResp.data.result -and $jobResp.data.result.images) { $b64 = $jobResp.data.result.images[0].base64 }
            if ($jobResp.data -and $jobResp.data.result -and $jobResp.data.result.base64) { $b64 = $jobResp.data.result.base64 }
            if ($b64) { return [Convert]::FromBase64String($b64) }
            $url = $jobResp.data.images[0].url; if (-not $url) { $url = $jobResp.result.images[0].url }
            if ($url) {
                $temp = [IO.Path]::GetTempFileName() + ".png"
                Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing
                $bytes = [IO.File]::ReadAllBytes($temp)
                Remove-Item -LiteralPath $temp -Force -ErrorAction SilentlyContinue
                return $bytes
            }
            return $null
        }
        if ($status -eq "failed") {
            Write-Host "    Job fehlgeschlagen."
            return $null
        }
    }
    return $null
}

$tempFiles = @()
$images = @()
for ($i = 0; $i -lt $Count; $i++) {
    Write-Host "Generiere Variation $($i+1)/$Count..."
    try {
        $r = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/generate-image-v2" -Method POST -Headers $headers -Body $body
    } catch {
        Write-Host "Fehler: $_"
        exit 1
    }
    $bytes = Get-ImageBytesFromResponse -r $r
    if (-not $bytes -and $r.background_job_id) {
        $bytes = Wait-JobAndGetBytes -jobId $r.background_job_id -headers $headers
    }
    if (-not $bytes) {
        Write-Host "Kein Bild fuer Variation $($i+1)."
        exit 1
    }
    $tmp = Join-Path $OutputDir "crater_sheet_temp_$i.png"
    [IO.File]::WriteAllBytes($tmp, $bytes)
    $tempFiles += $tmp
    $images += $tmp
}

Add-Type -AssemblyName System.Drawing
$sheetWidth = $Count * $cellSize
$sheetHeight = $cellSize
$bmp = New-Object System.Drawing.Bitmap($sheetWidth, $sheetHeight)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::Black)
for ($i = 0; $i -lt $images.Count; $i++) {
    $img = [System.Drawing.Image]::FromFile($images[$i])
    $g.DrawImage($img, $i * $cellSize, 0, $cellSize, $cellSize)
    $img.Dispose()
}
$g.Dispose()

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
if ($OutputName) {
    if (-not $OutputName.EndsWith(".png")) { $OutputName = "${OutputName}.png" }
    $outFileName = $OutputName
} else {
    $outFileName = "ui_frame_punchhole_sheet_8_${timestamp}.png"
}
$outFile = Join-Path $OutputDir $outFileName
if (Test-Path -LiteralPath $outFile) {
    $base = [IO.Path]::GetFileNameWithoutExtension($outFileName)
    $outFileName = "${base}_${timestamp}.png"
    $outFile = Join-Path $OutputDir $outFileName
}

$bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

foreach ($f in $tempFiles) {
    if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
}

Write-Host "Gespeichert: $outFile (${sheetWidth}x${sheetHeight}, $Count Variationen)"
Write-Host "Fertig."
