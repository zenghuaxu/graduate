param(
  [string]$doc
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$logFile = Join-Path $scriptDir "lw-wrapper.log"
$buildDrive = "X:"

if (-not $doc) {
  $doc = "main.tex"
}

if (Test-Path -LiteralPath $doc -PathType Container) {
  $doc = Join-Path $doc "main.tex"
}

try {
  $fullPath = (Resolve-Path -LiteralPath $doc -ErrorAction Stop).Path
} catch {
  $fallback = Join-Path $scriptDir "main.tex"
  if (Test-Path -LiteralPath $fallback) {
    $fullPath = (Resolve-Path -LiteralPath $fallback -ErrorAction Stop).Path
    Add-Content -Path $logFile -Value ("[{0}] Resolve fallback. doc={1} fallback={2} cwd={3}" -f (Get-Date -Format s), $doc, $fullPath, (Get-Location).Path)
  } else {
  Add-Content -Path $logFile -Value ("[{0}] Resolve failed. doc={1} cwd={2}" -f (Get-Date -Format s), $doc, (Get-Location).Path)
  Write-Error ("Cannot resolve document path: {0}" -f $doc)
  exit 2
  }
}

$dir = Split-Path -Parent $fullPath
$base = Split-Path -Leaf $fullPath

Add-Content -Path $logFile -Value ("[{0}] Build start. doc={1} dir={2} cwd={3}" -f (Get-Date -Format s), $fullPath, $dir, (Get-Location).Path)

# Prevent concurrent build processes from writing the same log/output files.
$mutexName = "Global\BUAAThesisLatexBuild"
$mutex = $null
$hasLock = $false
try {
  $mutex = New-Object System.Threading.Mutex($false, $mutexName)
  $hasLock = $mutex.WaitOne(0)
} catch {
  Add-Content -Path $logFile -Value ("[{0}] Mutex init failed, continue without lock: {1}" -f (Get-Date -Format s), $_.Exception.Message)
}
if ($mutex -and (-not $hasLock)) {
  Add-Content -Path $logFile -Value ("[{0}] Build skipped (another build is running)." -f (Get-Date -Format s))
  exit 0
}

# Always build from an ASCII-only drive path to avoid TeX write failures on Unicode paths.
try {
  $substOutput = cmd /c subst
  $mappedLine = $substOutput | Where-Object { $_ -match "^$buildDrive\\s*=>\\s*(.+)$" } | Select-Object -First 1
  if ($mappedLine) {
    $mappedPath = ($mappedLine -replace "^$buildDrive\\s*=>\\s*", "").Trim()
    if ($mappedPath -ne $dir) {
      cmd /c "subst $buildDrive /d" | Out-Null
      cmd /c "subst $buildDrive \"$dir\"" | Out-Null
    }
  } else {
    cmd /c "subst $buildDrive \"$dir\"" | Out-Null
  }
} catch {
  Add-Content -Path $logFile -Value ("[{0}] subst failed: {1}" -f (Get-Date -Format s), $_.Exception.Message)
}

if (Test-Path "$buildDrive\\") {
  $buildPath = "$buildDrive\\"
} else {
  $buildPath = $dir
}

try {
  Push-Location $buildPath
  try {
    if (-not (Test-Path ".\\tmp")) {
      New-Item -ItemType Directory -Path ".\\tmp" | Out-Null
    }
    & latexmk.exe -pdf -xelatex -outdir=tmp -synctex=1 -interaction=nonstopmode -file-line-error "$base"
    $code = $LASTEXITCODE
    if ($code -eq 0) {
      $pdfName = [System.IO.Path]::ChangeExtension($base, ".pdf")
      $tmpPdf = Join-Path ".\tmp" $pdfName
      if (Test-Path -LiteralPath $tmpPdf) {
        Copy-Item -LiteralPath $tmpPdf -Destination ".\$pdfName" -Force
      }
    }
    Add-Content -Path $logFile -Value ("[{0}] Build end. drive={1} exit={2}" -f (Get-Date -Format s), $buildDrive, $code)
    exit $code
  } finally {
    Pop-Location
  }
} finally {
  if ($mutex -and $hasLock) {
    $mutex.ReleaseMutex() | Out-Null
  }
  if ($mutex) {
    $mutex.Dispose()
  }
}
