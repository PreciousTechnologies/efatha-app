# PowerShell script to download KJV Bible JSON from getbible.net
$url = "https://getbible.net/v2/kjv/1/1.json"
$output = "c:\Users\MAXFYNN\Desktop\efatha_app\test_bible.json"

Write-Host "Testing GetBible API..."
try {
    Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
    Write-Host "Test download complete! Checking format..." -ForegroundColor Green
    Get-Content $output | Select-Object -First 20
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
