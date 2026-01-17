# ==============================================================================
# Code Coverage Script - PowerShell
# ==============================================================================
# Generates code coverage reports using gcov
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$GenerateHtml,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$UnknownArgs
)

# Show help
function Show-Help {
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Cyan
    Write-Host "  .\coverage.ps1 [-GenerateHtml] [-Help]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Cyan
    Write-Host "  -GenerateHtml    Generate HTML coverage report and open in browser" -ForegroundColor Yellow
    Write-Host "  -Help            Show this help message" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  .\coverage.ps1                    # Generate .gcov files only" -ForegroundColor Gray
    Write-Host "  .\coverage.ps1 -GenerateHtml      # Generate .gcov + HTML report" -ForegroundColor Gray
    Write-Host ""
    Write-Host "REQUIREMENTS:" -ForegroundColor Cyan
    Write-Host "  - Build project with coverage:  .\build.ps1 -Coverage -RunTests" -ForegroundColor Gray
    Write-Host ""
    exit 0
}

# Check for help
if ($Help) {
    Show-Help
}

# Check for unknown arguments
if ($UnknownArgs.Count -gt 0) {
    Write-Host ""
    Write-Host "[ERROR] Unknown argument(s): $($UnknownArgs -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "Did you mean:" -ForegroundColor Yellow
    Write-Host "  .\coverage.ps1 -GenerateHtml" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Use -Help for usage information." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Configuration
$GCOV_PATH = "C:/devbin/mingw/mingw64/8.1.0/bin/gcov.exe"
$BUILD_DIR = "build"
$COVERAGE_DIR = "coverage"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Code Coverage Report Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if build with coverage exists
if (-not (Test-Path "$BUILD_DIR/CMakeCache.txt")) {
    Write-Host "[ERROR] Build directory not found. Run build first:" -ForegroundColor Red
    Write-Host "  .\build.ps1 -Coverage -RunTests" -ForegroundColor Yellow
    exit 1
}

# Check if tests have been run
$gcnoFiles = Get-ChildItem -Path $BUILD_DIR -Filter "*.gcno" -Recurse
if ($gcnoFiles.Count -eq 0) {
    Write-Host "[ERROR] No coverage data files found (.gcno)" -ForegroundColor Red
    Write-Host "  Make sure to build with -Coverage flag:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 -Coverage" -ForegroundColor Yellow
    exit 1
}

$gcdaFiles = Get-ChildItem -Path $BUILD_DIR -Filter "*.gcda" -Recurse
if ($gcdaFiles.Count -eq 0) {
    Write-Host "[ERROR] No coverage execution data found (.gcda)" -ForegroundColor Red
    Write-Host "  Make sure to run tests:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 -Coverage -RunTests" -ForegroundColor Yellow
    exit 1
}

# Create coverage directory
Write-Host "[COVERAGE] Creating coverage directory..." -ForegroundColor Yellow
if (Test-Path $COVERAGE_DIR) {
    Remove-Item -Recurse -Force $COVERAGE_DIR
}
New-Item -ItemType Directory -Path $COVERAGE_DIR | Out-Null

# Process coverage data for library sources
Write-Host "[COVERAGE] Processing coverage data..." -ForegroundColor Yellow
$sourceFiles = Get-ChildItem -Path "src" -Filter "*.c" -Recurse
$workDir = Get-Location

foreach ($file in $sourceFiles) {
    $fileName = $file.Name
    
    Write-Host "  Processing: $fileName" -ForegroundColor Gray
    
    # Find corresponding .gcno file
    $gcnoFile = Get-ChildItem -Path "$BUILD_DIR/CMakeFiles/mylib.dir/src" -Filter "$fileName.gcno" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($gcnoFile) {
        $objDir = $gcnoFile.DirectoryName
        $gcnoFileName = $gcnoFile.Name
        
        # Run gcov - pass the .gcno filename
        Push-Location $objDir
        $gcovOutput = & $GCOV_PATH $gcnoFileName 2>&1
        Write-Host "    $gcovOutput" -ForegroundColor DarkGray
        
        # Move .gcov files to coverage directory
        $gcovFiles = Get-ChildItem -Filter "*.gcov" -File
        if ($gcovFiles.Count -gt 0) {
            foreach ($gcovFile in $gcovFiles) {
                $destPath = Join-Path $workDir $COVERAGE_DIR
                Move-Item $gcovFile.FullName $destPath -Force
                Write-Host "    Moved: $($gcovFile.Name)" -ForegroundColor DarkGray
            }
        }
        else {
            Write-Host "    No .gcov files generated!" -ForegroundColor Red
        }
        Pop-Location
    }
    else {
        Write-Host "  Warning: No coverage data for $fileName" -ForegroundColor DarkYellow
    }
}

# Analyze coverage results
Write-Host ""
Write-Host "[COVERAGE] Coverage Summary:" -ForegroundColor Yellow
Write-Host ""

$gcovFiles = Get-ChildItem -Path $COVERAGE_DIR -Filter "*.gcov"
$totalLines = 0
$executedLines = 0
$allFileResults = @()

foreach ($gcovFile in $gcovFiles) {
    $content = Get-Content $gcovFile.FullName
    $fileName = $gcovFile.Name -replace '\.gcov$', ''
    
    $fileLines = 0
    $fileExecuted = 0
    
    foreach ($line in $content) {
        # Match executable lines: those with a number or ##### at the start
        if ($line -match '^\s*(\d+|\#\#\#\#\#):') {
            $fileLines++
            $totalLines++
            
            # Match executed lines: those with a number (not #####)
            if ($line -match '^\s*(\d+):') {
                $fileExecuted++
                $executedLines++
            }
        }
    }
    
    if ($fileLines -gt 0) {
        $coverage = [math]::Round(($fileExecuted / $fileLines) * 100, 2)
        
        # Store results for HTML generation
        $allFileResults += [PSCustomObject]@{
            Name     = $fileName
            Coverage = $coverage
            Executed = $fileExecuted
            Total    = $fileLines
            GcovFile = $gcovFile.Name
        }
        
        Write-Host "  $fileName" -NoNewline
        
        if ($coverage -ge 80) {
            Write-Host " : $coverage% ($fileExecuted/$fileLines)" -ForegroundColor Green
        }
        elseif ($coverage -ge 50) {
            Write-Host " : $coverage% ($fileExecuted/$fileLines)" -ForegroundColor Yellow
        }
        else {
            Write-Host " : $coverage% ($fileExecuted/$fileLines)" -ForegroundColor Red
        }
    }
}

Write-Host ""
if ($totalLines -gt 0) {
    $overallCoverage = [math]::Round(($executedLines / $totalLines) * 100, 2)
    Write-Host "Overall Coverage: " -NoNewline
    
    if ($overallCoverage -ge 80) {
        Write-Host "$overallCoverage% ($executedLines/$totalLines lines)" -ForegroundColor Green
    }
    elseif ($overallCoverage -ge 50) {
        Write-Host "$overallCoverage% ($executedLines/$totalLines lines)" -ForegroundColor Yellow
    }
    else {
        Write-Host "$overallCoverage% ($executedLines/$totalLines lines)" -ForegroundColor Red
    }
}
else {
    $overallCoverage = 0
}

Write-Host ""
Write-Host "[COVERAGE] Detailed reports available in: $COVERAGE_DIR/" -ForegroundColor Green

# Generate HTML report if requested
if ($GenerateHtml) {
    Write-Host ""
    Write-Host "[HTML] Generating HTML report..." -ForegroundColor Yellow
    
    $htmlFile = "$COVERAGE_DIR\index.html"
    
    # Determine coverage class
    $coverageClass = "low"
    if ($overallCoverage -ge 80) { $coverageClass = "high" }
    elseif ($overallCoverage -ge 50) { $coverageClass = "medium" }
    
    $dateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Build HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Code Coverage Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #f5f5f5; }
        .header { background: #2c3e50; color: white; padding: 20px; border-radius: 5px; }
        .summary { background: white; padding: 20px; margin: 20px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .file-list { background: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .coverage-high { color: #27ae60; font-weight: bold; }
        .coverage-medium { color: #f39c12; font-weight: bold; }
        .coverage-low { color: #e74c3c; font-weight: bold; }
        .bar { height: 20px; background: #ecf0f1; border-radius: 3px; overflow: hidden; margin: 5px 0; }
        .bar-fill { height: 100%; background: #3498db; transition: width 0.3s; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 12px; text-align: left; }
        th { background: #34495e; color: white; }
        tr:nth-child(even) { background: #f9f9f9; }
        a { text-decoration: none; color: #2c3e50; }
        a:hover { text-decoration: underline; color: #3498db; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Code Coverage Report</h1>
        <p>Generated: $dateStr</p>
    </div>
    
    <div class="summary">
        <h2>Overall Coverage</h2>
        <div class="bar">
            <div class="bar-fill" style="width: $overallCoverage%;"></div>
        </div>
        <p>Coverage: <span class="coverage-$coverageClass">$overallCoverage%</span></p>
        <p>Lines: $executedLines / $totalLines</p>
    </div>
    
    <div class="file-list">
        <h2>File Coverage</h2>
        <table>
            <thead>
                <tr>
                    <th>File</th>
                    <th>Coverage</th>
                    <th>Lines</th>
                </tr>
            </thead>
            <tbody>
"@

    # Add file rows
    foreach ($fileResult in $allFileResults) {
        $fileCssClass = "low"
        if ($fileResult.Coverage -ge 80) { $fileCssClass = "high" }
        elseif ($fileResult.Coverage -ge 50) { $fileCssClass = "medium" }
        
        $html += @"

                <tr>
                    <td><a href="$($fileResult.GcovFile)">$($fileResult.Name)</a></td>
                    <td><span class="coverage-$fileCssClass">$($fileResult.Coverage)%</span></td>
                    <td>$($fileResult.Executed) / $($fileResult.Total)</td>
                </tr>
"@
    }

    # Close HTML
    $html += @"

            </tbody>
        </table>
    </div>
</body>
</html>
"@

    Set-Content -Path $htmlFile -Value $html -Encoding UTF8
    Write-Host "[HTML] Report generated: $htmlFile" -ForegroundColor Green
    
    # Open in browser
    Start-Process $htmlFile
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Coverage analysis complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
