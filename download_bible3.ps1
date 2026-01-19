# PowerShell script to download KJV Bible JSON compatible with Pasaka structure
$url = "https://raw.githubusercontent.com/yashLadha/The_Holy_Bible_JSON/master/The%20Holy%20Bible.json"
$output = "c:\Users\MAXFYNN\Desktop\efatha_app\assets\data\english_bible.json"

Write-Host "Downloading KJV Bible JSON (compatible format)..."
try {
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
    Write-Host "Download complete! File saved to: $output" -ForegroundColor Green
    
    # Check file size
    $fileSize = (Get-Item $output).Length / 1MB
    Write-Host "File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
    
    # Show first few lines
    Write-Host "`nFirst 10 lines of the file:" -ForegroundColor Yellow
    Get-Content $output | Select-Object -First 10
} catch {
    Write-Host "Error downloading file: $_" -ForegroundColor Red
}
