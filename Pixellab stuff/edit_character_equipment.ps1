# PixelLab v2 API: Character + Ausruestung (Edit mit Referenzbild)
# Benoetigt: $env:PIXELLAB_API_TOKEN
# Aufruf: .\edit_character_equipment.ps1 -ImagePath ".\south-east (1).png" -Item helm

param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,
    [Parameter(Mandatory = $true)]
    [ValidateSet("helm", "hosen", "brustpanzer", "handschuhe", "schuhe", "mainhand", "zweihand", "offhand")]
    [string]$Item,
    [string]$OutputPath = "",
    [int]$Size = 64
)

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not [IO.Path]::IsPathRooted($ImagePath)) { $ImagePath = Join-Path $scriptDir $ImagePath }
if (-not (Test-Path -LiteralPath $ImagePath)) { Write-Host "Fehler: Bild nicht gefunden: $ImagePath"; exit 1 }

if ($OutputPath) {
    if (-not [IO.Path]::IsPathRooted($OutputPath)) { $OutputPath = Join-Path $scriptDir $OutputPath }
} else {
    $baseName = [IO.Path]::GetFileNameWithoutExtension($ImagePath)
    $OutputPath = Join-Path $scriptDir "${baseName}_${Item}.png"
}

$descriptions = @{
    helm         = "Same character with a simple medieval knight helmet on his head. Keep exact same pixel art style, proportions and ${Size}x${Size} size."
    hosen        = "Same character wearing simple medieval pants or leg armor. Keep exact same pixel art style, proportions and ${Size}x${Size} size."
    brustpanzer  = "Same character wearing a simple medieval chest armor or breastplate. Keep exact same pixel art style, proportions and ${Size}x${Size} size."
    handschuhe   = "Same character wearing simple medieval gauntlets or gloves. Keep exact same pixel art style, proportions and ${Size}x${Size} size."
    schuhe       = "Same character wearing simple medieval boots or shoes. Keep exact same pixel art style, proportions and ${Size}x${Size} size."
    mainhand     = "Same character holding a simple one-handed weapon (e.g. sword or mace) in main hand. Keep exact same pixel art style, proportions and ${Size}x${Size} size."
    zweihand     = "Same character holding a simple two-handed weapon (e.g. greatsword or staff). Keep exact same pixel art style, proportions and ${Size}x${Size} size."
    offhand      = "Same character holding a simple off-hand item (e.g. shield or torch). Keep exact same pixel art style, proportions and ${Size}x${Size} size."
}

$token = $env:PIXELLAB_API_TOKEN
if (-not $token) {
    Write-Host "Fehler: PIXELLAB_API_TOKEN nicht gesetzt."
    exit 1
}

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ImagePath))
$body = @{
    method       = "edit_with_text"
    edit_images  = @(
        @{
            image  = @{ type = "base64"; base64 = $base64; format = "png" }
            width  = $Size
            height = $Size
        }
    )
    image_size   = @{ width = $Size; height = $Size }
    description  = $descriptions[$Item]
    no_background = $true
} | ConvertTo-Json -Depth 5 -Compress

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/edit-images-v2" -Method POST -Headers $headers -Body $body
    $imgBase64 = $null
    if ($response.data -and $response.data.images -and $response.data.images[0].base64) { $imgBase64 = $response.data.images[0].base64 }
    elseif ($response.images -and $response.images[0].base64) { $imgBase64 = $response.images[0].base64 }
    if ($imgBase64) {
        [IO.File]::WriteAllBytes($OutputPath, [Convert]::FromBase64String($imgBase64))
        Write-Host "Gespeichert: $OutputPath"
    }
    elseif ($response.background_job_id) {
        $jobId = $response.background_job_id
        Write-Host "Job gestartet (async). Job-ID: $jobId"
        Write-Host "Warte auf Abschluss (Poll alle 8 Sekunden)..."
        $maxAttempts = 60
        $attempt = 0
        while ($attempt -lt $maxAttempts) {
            Start-Sleep -Seconds 8
            $attempt++
            $jobResp = Invoke-RestMethod -Uri "https://api.pixellab.ai/v2/background-jobs/$jobId" -Method GET -Headers @{ "Authorization" = "Bearer $token" }
            $status = $jobResp.status
            Write-Host "  [$attempt] Status: $status"
            if ($status -eq "completed") {
                $imgBase64 = $null
                if ($jobResp.data.images -and $jobResp.data.images[0].base64) { $imgBase64 = $jobResp.data.images[0].base64 }
                elseif ($jobResp.result.images -and $jobResp.result.images[0].base64) { $imgBase64 = $jobResp.result.images[0].base64 }
                elseif ($jobResp.images -and $jobResp.images[0].base64) { $imgBase64 = $jobResp.images[0].base64 }
                if ($jobResp.data.result -and $jobResp.data.result.images) { $imgBase64 = $jobResp.data.result.images[0].base64 }
                if ($jobResp.data.result -and $jobResp.data.result.base64) { $imgBase64 = $jobResp.data.result.base64 }
                if ($imgBase64) {
                    [IO.File]::WriteAllBytes($OutputPath, [Convert]::FromBase64String($imgBase64))
                    Write-Host "Gespeichert: $OutputPath"
                } else {
                    $url = $jobResp.data.images[0].url; if (-not $url) { $url = $jobResp.result.images[0].url }
                    if ($url) {
                        Invoke-WebRequest -Uri $url -OutFile $OutputPath
                        Write-Host "Gespeichert: $OutputPath"
                    } else {
                        Write-Host "Job fertig, aber kein Bild in Response."
                    }
                }
                break
            }
            if ($status -eq "failed") {
                Write-Host "Job fehlgeschlagen: $($jobResp.error | ConvertTo-Json -Compress)"
                break
            }
        }
        if ($attempt -ge $maxAttempts) { Write-Host "Timeout nach $maxAttempts Versuchen." }
    } else {
        Write-Host "Response: $($response | ConvertTo-Json -Depth 3)"
    }
} catch {
    Write-Host "Fehler: $_"
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
}
