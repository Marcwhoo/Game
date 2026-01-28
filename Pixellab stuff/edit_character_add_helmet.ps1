# PixelLab v2 API: Character + Helm (Edit mit Referenzbild)
# Benoetigt: $env:PIXELLAB_API_TOKEN muss gesetzt sein (oder Token unten eintragen)
# Aufruf: .\edit_character_add_helmet.ps1

$charPath = Join-Path $PSScriptRoot "south-east (1).png"
$outPath = Join-Path $PSScriptRoot "character_with_helmet_edit.png"

$token = $env:PIXELLAB_API_TOKEN
if (-not $token) {
    Write-Host "Fehler: PIXELLAB_API_TOKEN nicht gesetzt."
    Write-Host "Setze den Token z.B. mit: `$env:PIXELLAB_API_TOKEN = 'dein-token'"
    Write-Host "Token findest du unter: https://api.pixellab.ai/mcp"
    exit 1
}

$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($charPath))

$body = @{
    method = "edit_with_text"
    edit_images = @(
        @{
            image = @{ type = "base64"; base64 = $base64; format = "png" }
            width = 64
            height = 64
        }
    )
    image_size = @{ width = 64; height = 64 }
    description = "Same character with a simple medieval knight helmet on his head. Keep exact same pixel art style, proportions and 64x64 size."
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
        [IO.File]::WriteAllBytes($outPath, [Convert]::FromBase64String($imgBase64))
        Write-Host "Gespeichert: $outPath"
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
                    [IO.File]::WriteAllBytes($outPath, [Convert]::FromBase64String($imgBase64))
                    Write-Host "Gespeichert: $outPath"
                } else {
                    $url = $jobResp.data.images[0].url; if (-not $url) { $url = $jobResp.result.images[0].url }
                    if ($url) {
                        Invoke-WebRequest -Uri $url -OutFile $outPath
                        Write-Host "Gespeichert: $outPath"
                    } else {
                        Write-Host "Job fertig, aber kein Bild in Response. Response: $($jobResp | ConvertTo-Json -Depth 4 -Compress)"
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
