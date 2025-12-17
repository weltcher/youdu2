# Image optimization script
# This script compresses PNG images in assets folder

Write-Host "Optimizing images in assets folder..." -ForegroundColor Yellow

$bgImage = "assets\登录\背景图.png"

if (Test-Path $bgImage) {
    $originalSize = (Get-Item $bgImage).Length / 1KB
    Write-Host "Original size: $([math]::Round($originalSize, 2)) KB" -ForegroundColor Gray
    
    # Check if ImageMagick or similar tool is available
    try {
        # Try using built-in .NET image compression
        Add-Type -AssemblyName System.Drawing
        
        $img = [System.Drawing.Image]::FromFile((Resolve-Path $bgImage))
        $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/png' }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 75)
        
        $tempFile = "$bgImage.tmp"
        $img.Save($tempFile, $encoder, $encoderParams)
        $img.Dispose()
        
        $newSize = (Get-Item $tempFile).Length / 1KB
        
        if ($newSize -lt $originalSize) {
            Move-Item -Path $tempFile -Destination $bgImage -Force
            Write-Host "[OK] Compressed: $([math]::Round($originalSize, 2)) KB -> $([math]::Round($newSize, 2)) KB" -ForegroundColor Green
            Write-Host "Saved: $([math]::Round($originalSize - $newSize, 2)) KB" -ForegroundColor Green
        } else {
            Remove-Item $tempFile
            Write-Host "[SKIP] Compressed version is larger, keeping original" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[INFO] Could not compress image automatically" -ForegroundColor Yellow
        Write-Host "Suggestion: Use online tools like TinyPNG or ImageOptim to compress:" -ForegroundColor Cyan
        Write-Host "  - $bgImage (current: $([math]::Round($originalSize, 2)) KB)" -ForegroundColor Cyan
    }
} else {
    Write-Host "[SKIP] Background image not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Tip: You can also convert PNG to WebP format for better compression" -ForegroundColor Cyan
