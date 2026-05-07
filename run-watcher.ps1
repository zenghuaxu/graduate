param(
  [string]$file = "main.tex"
)
$full = Resolve-Path $file
$dir = Split-Path $full
$base = Split-Path -Leaf $full
Write-Output "Watching $full for changes..."
$fsw = New-Object System.IO.FileSystemWatcher $dir, $base
$fsw.EnableRaisingEvents = $true
$fsw.NotifyFilter = [System.IO.NotifyFilters]'LastWrite'
$debounce = $false
Register-ObjectEvent $fsw Changed -Action {
    if ($debounce) { return }
    $debounce = $true
    Start-Sleep -Milliseconds 300
    try {
        Write-Output "Change detected at $(Get-Date -Format s). Running wrapper..."
        powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot\\build-wrapper.ps1" "$full"
    } catch {
        Write-Output "Watcher error: $_"
    }
    Start-Sleep -Milliseconds 500
    $debounce = $false
}
# keep the script running
while ($true) { Start-Sleep -Seconds 3600 }
