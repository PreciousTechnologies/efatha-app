# PowerShell script to download KJV Bible from scrollmapper
$url = "https://raw.githubusercontent.com/scrollmapper/bible_databases/master/json/en_kjv.json"
$output = "c:\Users\MAXFYNN\Desktop\efatha_app\assets\data\english_bible_raw.json"

Write-Host "Downloading KJV Bible JSON from scrollmapper..."
try {
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing  
    Write-Host "Download complete! File saved to: $output" -ForegroundColor Green
    
    # Check file size
    $fileSize = (Get-Item $output).Length / 1MB
    Write-Host "File size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
} catch {
    Write-Host "Error downloading file: $_" -ForegroundColor Red
}
