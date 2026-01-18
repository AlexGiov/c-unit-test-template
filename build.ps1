# ==============================================================================
# Build Script - PowerShell
# ==============================================================================
# Automates the CMake build process for the unit test template
# ==============================================================================

[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release", "RelWithDebInfo", "MinSizeRel")]
    [string]$BuildType = "Debug",
    [switch]$Clean,
    [switch]$RunTests,
    [switch]$Coverage,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$UnknownArgs
)

# Show help
function Show-Help {
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Cyan
    Write-Host "  .\build.ps1 [-BuildType <type>] [-Clean] [-RunTests] [-Coverage] [-Help]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Cyan
    Write-Host "  -BuildType <type>    Build configuration (Debug, Release, RelWithDebInfo, MinSizeRel)" -ForegroundColor Yellow
    Write-Host "                       Default: Debug" -ForegroundColor Gray
    Write-Host "  -Clean               Clean build directory before building" -ForegroundColor Yellow
    Write-Host "  -RunTests            Run unit tests after building" -ForegroundColor Yellow
    Write-Host "  -Coverage            Enable code coverage (requires -RunTests for report)" -ForegroundColor Yellow
    Write-Host "  -Help                Show this help message" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  .\build.ps1                              # Build in Debug mode" -ForegroundColor Gray
    Write-Host "  .\build.ps1 -RunTests                    # Build and run tests" -ForegroundColor Gray
    Write-Host "  .\build.ps1 -Clean -RunTests             # Clean build and test" -ForegroundColor Gray
    Write-Host "  .\build.ps1 -Coverage -RunTests          # Build with coverage and test" -ForegroundColor Gray
    Write-Host "  .\build.ps1 -BuildType Release           # Build in Release mode" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WORKFLOW:" -ForegroundColor Cyan
    Write-Host "  1. Build with coverage:  .\build.ps1 -Coverage -RunTests" -ForegroundColor Gray
    Write-Host "  2. Generate report:      .\coverage.ps1 -GenerateHtml" -ForegroundColor Gray
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
    Write-Host "Use -Help for usage information." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# CMake Generator: "MinGW Makefiles" or "Ninja"
# Note: Ninja is faster but requires separate installation
$CMAKE_GENERATOR = "MinGW Makefiles"  # Default, widely available
#$CMAKE_GENERATOR = "Ninja"           # Faster, requires Ninja installed

# Tool paths
$CMAKE_PATH = "C:\devbin\cmake\v3.16.5\bin"
$GCC_PATH = "C:/devbin/mingw/mingw64/8.1.0/bin/gcc.exe"

# ==============================================================================
# Helper Functions
# ==============================================================================

# Extract project name from CMakeLists.txt
function Get-ProjectName {
    if (Test-Path "CMakeLists.txt") {
        $content = Get-Content "CMakeLists.txt" -Raw
        if ($content -match 'project\s*\(\s*(\w+)') {
            return $Matches[1]
        }
    }
    return $null
}

# Extract project name from CMake cache (after configuration)
function Get-ProjectNameFromCache {
    if (Test-Path "build/CMakeCache.txt") {
        $cacheLine = Get-Content "build/CMakeCache.txt" | Select-String "CMAKE_PROJECT_NAME:STATIC=(.+)"
        if ($cacheLine) {
            return $cacheLine.Matches.Groups[1].Value
        }
    }
    return $null
}

# Setup environment
$env:PATH = "$CMAKE_PATH;$env:PATH"

# Remove Cygwin from PATH (conflicts with MinGW)
$env:PATH = $env:PATH -replace 'C:/devbin/cygwin/v1a/bin;?', ''
$env:PATH = $env:PATH -replace 'C:\\devbin\\cygwin\\v1a\\bin;?', ''

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Unit Test Template - Build Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Clean build directory if requested
if ($Clean) {
    Write-Host "[CLEAN] Removing build directory..." -ForegroundColor Yellow
    if (Test-Path "build") {
        Remove-Item -Recurse -Force "build"
    }
    if (Test-Path "bin") {
        Remove-Item -Recurse -Force "bin"
    }
    if (Test-Path "lib") {
        Remove-Item -Recurse -Force "lib"
    }
    Write-Host "[CLEAN] Done" -ForegroundColor Green
    Write-Host ""
}

# Configure
Write-Host "[CMAKE] Configuring project..." -ForegroundColor Yellow
$cmakeArgs = @(
    "-G", $CMAKE_GENERATOR,
    "-S", ".",
    "-B", "build",
    "-DCMAKE_C_COMPILER=$GCC_PATH",
    "-DCMAKE_BUILD_TYPE=$BuildType"
)

if ($Coverage) {
    $cmakeArgs += "-DENABLE_COVERAGE=ON"
}

& cmake @cmakeArgs

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] CMake configuration failed!" -ForegroundColor Red
    exit 1
}

Write-Host "[CMAKE] Configuration complete" -ForegroundColor Green
Write-Host ""

# Build
Write-Host "[BUILD] Compiling project..." -ForegroundColor Yellow
cmake --build build

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "[BUILD] Build complete" -ForegroundColor Green
Write-Host ""

# Run tests if requested
if ($RunTests) {
    Write-Host "[TEST] Running unit tests..." -ForegroundColor Yellow
    
    # Auto-detect test executables in bin/ directory
    $testExecutables = Get-ChildItem "bin\test_*.exe" -ErrorAction SilentlyContinue
    
    if ($testExecutables) {
        foreach ($testExe in $testExecutables) {
            $testPath = $testExe.FullName
            Write-Host "  Executable: $testPath" -ForegroundColor Gray
            Write-Host ""
            
            & $testPath
            
            if ($LASTEXITCODE -ne 0) {
                Write-Host ""
                Write-Host "[ERROR] Tests failed in $($testExe.Name)!" -ForegroundColor Red
                exit 1
            }
            Write-Host ""
        }
        
        Write-Host "[TEST] All tests passed!" -ForegroundColor Green
    }
    else {
        Write-Host "[ERROR] No test executables found in bin/ directory" -ForegroundColor Red
        Write-Host "  Expected: bin/test_*.exe" -ForegroundColor Gray
        exit 1
    }
}

# Coverage report if requested
if ($Coverage -and $RunTests) {
    Write-Host ""
    Write-Host "[COVERAGE] Generating coverage report..." -ForegroundColor Yellow
    
    Push-Location build
    
    # Run lcov if available
    $lcov = Get-Command lcov -ErrorAction SilentlyContinue
    if ($lcov) {
        lcov --capture --directory . --output-file coverage.info
        lcov --remove coverage.info '/usr/*' '*/external/*' '*/test/*' --output-file coverage_filtered.info
        genhtml coverage_filtered.info --output-directory coverage_html
        Write-Host "[COVERAGE] Report generated in: build/coverage_html/index.html" -ForegroundColor Green
    }
    else {
        Write-Host "[WARNING] lcov not found. Install lcov for HTML coverage reports." -ForegroundColor Yellow
    }
    
    Pop-Location
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Build Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Get project name for summary
$projectName = Get-ProjectNameFromCache
if (-not $projectName) {
    $projectName = Get-ProjectName
}
if ($projectName) {
    Write-Host "Project:       $projectName" -ForegroundColor White
}

Write-Host "Build Type:    $BuildType" -ForegroundColor White
Write-Host "Output:        bin/" -ForegroundColor White
Write-Host "Status:        SUCCESS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Usage examples
if (-not $RunTests) {
    Write-Host "Tip: Run tests with:  .\build.ps1 -RunTests" -ForegroundColor Gray
}
