# PixelLab v2 API: Character mit allen Ausruestungsgegenstaenden (ein Bild)
# Prompts pro Slot uebergebbar. Benoetigt: $env:PIXELLAB_API_TOKEN
# Beispiel: .\edit_character_equipment_full.ps1 -ImagePath ".\south-east (1).png" -Armour "simple iron armour" -Mainhand "1 wooden sword" -Offhand "1 wooden shield"

param(
    [Parameter(Mandatory = $true)]
    [string]$ImagePath,
    [string]$Armour = "",
    [string]$Helm = "",
    [string]$Hosen = "",
    [string]$Handschuhe = "",
    [string]$Schuhe = "",
    [string]$Mainhand = "",
    [string]$Zweihand = "",
    [string]$Offhand = "",
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
    $OutputPath = Join-Path $scriptDir "${baseName}_full_equipped.png"
}

$parts = @()
if ($Armour.Trim())     { $parts += $Armour.Trim() }
if ($Helm.Trim())       { $parts += "helmet: $($Helm.Trim())" }
if ($Hosen.Trim())      { $parts += "pants/legs: $($Hosen.Trim())" }
if ($Handschuhe.Trim()) { $parts += "gloves: $($Handschuhe.Trim())" }
if ($Schuhe.Trim())     { $parts += "boots: $($Schuhe.Trim())" }
if ($Mainhand.Trim())   { $parts += "main hand: $($Mainhand.Trim())" }
if ($Zweihand.Trim())   { $parts += "two-handed: $($Zweihand.Trim())" }
if ($Offhand.Trim())   { $parts += "off hand: $($Offhand.Trim())" }

if ($parts.Count -eq 0) {
    Write-Host "Fehler: Mindestens ein Ausruestungs-Prompt angeben (z.B. -Armour, -Mainhand, -Offhand)."
    exit 1
}

$equipText = $parts -join ", "
$description = "Same character with $equipText. Keep exact same pixel art style and exact same proportions: do not change head size, body size or limb proportions. Helmet and all equipment must fit the character proportionally (1:1). Output ${Size}x${Size} pixels."

$token = $env:PIXELLAB_API_TOKEN
if (-not $token) {
    Write-Host "Fehler: PIXELLAB_API_TOKEN nicht gesetzt."
    exit 1
}

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ImagePath))
$body = @{
    method        = "edit_with_text"
    edit_images   = @(
        @{
            image  = @{ type = "base64"; base64 = $base64; format = "png" }
            width  = $Size
            height = $Size
        }
    )
    image_size    = @{ width = $Size; height = $Size }
    description   = $description
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
