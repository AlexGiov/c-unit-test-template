# ==============================================================================
# Rename Library Script - PowerShell
# ==============================================================================
# Renames the template library to a new name
# 
# With the new CMake-based approach, renaming is much simpler:
# - Change project() name in CMakeLists.txt (automatic via CMake variables)
# - Rename include/ directory
# - Rename source files (optional, recommended for single-module libraries)
# - Update #include statements
# - Update README references
#
# Usage: .\rename-library.ps1 -NewName "my_new_library"
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidatePattern('^[a-zA-Z_][a-zA-Z0-9_]*$')]
    [string]$NewName,
    
    [switch]$Help
)

# Show help
function Show-Help {
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Cyan
    Write-Host "  .\rename-library.ps1 -NewName <library_name>" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "PARAMETERS:" -ForegroundColor Cyan
    Write-Host "  -NewName <name>    New library name (letters, numbers, underscores only)" -ForegroundColor Yellow
    Write-Host "                     Must start with letter or underscore" -ForegroundColor Gray
    Write-Host "  -Help              Show this help message" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  .\rename-library.ps1 -NewName sensor_driver" -ForegroundColor Gray
    Write-Host "  .\rename-library.ps1 -NewName uart_hal" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WHAT IT DOES (Simplified with CMake variables):" -ForegroundColor Cyan
    Write-Host "  1. Updates project() name in CMakeLists.txt" -ForegroundColor Gray
    Write-Host "  2. Renames include/mylib/ -> include/<NewName>/" -ForegroundColor Gray
    Write-Host "  3. Renames source files (recommended for single-module)" -ForegroundColor Gray
    Write-Host "  4. Updates #include statements" -ForegroundColor Gray
    Write-Host "  5. Updates README.md references" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  All CMake targets auto-update via \${PROJECT_NAME}!" -ForegroundColor Green
    Write-Host ""
    Write-Host "NOTE: Run this in a fresh clone of the template!" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}

if ($Help) {
    Show-Help
}

# Check if NewName is provided
if (-not $NewName) {
    Write-Host ""
    Write-Host "[ERROR] Missing required parameter: -NewName" -ForegroundColor Red
    Write-Host ""
    Write-Host "Use -Help for usage information." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Safety check: warn if running in a git repository with remote "origin"
if (Test-Path ".git") {
    $gitRemote = git remote get-url origin 2>$null
    if ($gitRemote -and $gitRemote -match "unit.?test.?template") {
        Write-Host ""
        Write-Host "[WARNING] You appear to be in the template repository!" -ForegroundColor Yellow
        Write-Host "This script should be run in a CLONE of the template, not the template itself." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Expected workflow:" -ForegroundColor Cyan
        Write-Host "  1. git clone <template-url> my-new-library" -ForegroundColor Gray
        Write-Host "  2. cd my-new-library" -ForegroundColor Gray
        Write-Host "  3. .\rename-library.ps1 -NewName my_new_library" -ForegroundColor Gray
        Write-Host ""
        $response = Read-Host "Do you really want to continue? (yes/no)"
        if ($response -ne "yes") {
            Write-Host "Aborted." -ForegroundColor Yellow
            exit 1
        }
    }
}

# ==============================================================================
# Helper Functions
# ==============================================================================

function Get-CurrentProjectName {
    # Read project name from CMakeLists.txt
    if (Test-Path "CMakeLists.txt") {
        $cmakeContent = Get-Content "CMakeLists.txt" -Raw
        if ($cmakeContent -match 'project\s*\(\s*(\w+)') {
            return $matches[1]
        }
    }
    return "mylib"  # fallback default
}

function Get-CurrentModuleName {
    # Find first .c file in src/ directory (excluding template default)
    $srcFiles = Get-ChildItem "src\*.c" -ErrorAction SilentlyContinue
    if ($srcFiles) {
        $firstFile = $srcFiles[0].BaseName
        return $firstFile
    }
    return "math_utils"  # fallback default
}

# ==============================================================================
# Auto-detect current names
# ==============================================================================

$OLD_NAME = Get-CurrentProjectName
$OLD_MODULE = Get-CurrentModuleName
$OLD_NAME_UPPER = $OLD_NAME.ToUpper()
$NEW_NAME_UPPER = $NewName.ToUpper()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Library Rename Tool (Simplified)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Detected current library: '$OLD_NAME' (module: '$OLD_MODULE')" -ForegroundColor Gray
Write-Host "Renaming to: '$NewName'" -ForegroundColor Yellow
Write-Host ""

# ==============================================================================
# STEP 1: Update project() declaration in CMakeLists.txt
# ==============================================================================
Write-Host "[1/4] Updating CMakeLists.txt project() declaration..." -ForegroundColor Cyan

$rootCMake = Get-Content "CMakeLists.txt" -Raw

# Update project() declaration - this is the ONLY change needed in CMakeLists.txt!
# All targets, exports, and paths use ${PROJECT_NAME} so they update automatically
$rootCMake = $rootCMake -replace "project\s*\(\s*$OLD_NAME\s", "project($NewName "

Set-Content "CMakeLists.txt" -Value $rootCMake -NoNewline
Write-Host "  - Changed project($OLD_NAME) -> project($NewName)" -ForegroundColor Green
Write-Host "    All CMake targets auto-update via \${PROJECT_NAME}!" -ForegroundColor Gray

# ==============================================================================
# STEP 2: Rename include directory
# ==============================================================================
Write-Host "[2/4] Renaming include directory..." -ForegroundColor Cyan

if (Test-Path "include\$OLD_NAME") {
    Write-Host "  include\$OLD_NAME -> include\$NewName" -ForegroundColor Gray
    Rename-Item -Path "include\$OLD_NAME" -NewName $NewName
}

# ==============================================================================
# STEP 3: Rename source files (recommended for single-module libraries)
# ==============================================================================
Write-Host "[3/4] Renaming source files..." -ForegroundColor Cyan

# Rename header file
if (Test-Path "include\$NewName\$OLD_MODULE.h") {
    Write-Host "  include\$NewName\$OLD_MODULE.h -> $NewName.h" -ForegroundColor Gray
    Rename-Item -Path "include\$NewName\$OLD_MODULE.h" -NewName "$NewName.h"
}

# Rename source file
if (Test-Path "src\$OLD_MODULE.c") {
    Write-Host "  src\$OLD_MODULE.c -> $NewName.c" -ForegroundColor Gray
    Rename-Item -Path "src\$OLD_MODULE.c" -NewName "$NewName.c"
}

# Rename test file
if (Test-Path "test\unit\test_$OLD_MODULE.c") {
    Write-Host "  test\unit\test_$OLD_MODULE.c -> test_$NewName.c" -ForegroundColor Gray
    Rename-Item -Path "test\unit\test_$OLD_MODULE.c" -NewName "test_$NewName.c"
}

# ==============================================================================
# STEP 4: Update #include statements and file contents
# ==============================================================================
Write-Host "[4/4] Updating file contents..." -ForegroundColor Cyan

# Update header file
$headerPath = "include\$NewName\$NewName.h"
if (Test-Path $headerPath) {
    $headerContent = Get-Content $headerPath -Raw
    $headerGuard = "${NEW_NAME_UPPER}_H"
    $oldHeaderGuard = "${OLD_MODULE}_H".ToUpper()
    
    $headerContent = $headerContent -replace $oldHeaderGuard, $headerGuard
    $headerContent = $headerContent -replace "\* @file\s+$OLD_MODULE\.h", "* @file $NewName.h"
    
    Set-Content $headerPath -Value $headerContent -NoNewline
    Write-Host "  - Updated $headerPath" -ForegroundColor Gray
}

# Update source file
$sourcePath = "src\$NewName.c"
if (Test-Path $sourcePath) {
    $sourceContent = Get-Content $sourcePath -Raw
    $sourceContent = $sourceContent -replace "#include `"$OLD_NAME/$OLD_MODULE\.h`"", "#include `"$NewName/$NewName.h`""
    $sourceContent = $sourceContent -replace "\* @file\s+$OLD_MODULE\.c", "* @file $NewName.c"
    
    Set-Content $sourcePath -Value $sourceContent -NoNewline
    Write-Host "  - Updated $sourcePath" -ForegroundColor Gray
}

# Update test file
$testPath = "test\unit\test_$NewName.c"
if (Test-Path $testPath) {
    $testContent = Get-Content $testPath -Raw
    $testContent = $testContent -replace "#include `"$OLD_NAME/$OLD_MODULE\.h`"", "#include `"$NewName/$NewName.h`""
    $testContent = $testContent -replace "\* @file\s+test_$OLD_MODULE\.c", "* @file test_$NewName.c"
    
    Set-Content $testPath -Value $testContent -NoNewline
    Write-Host "  - Updated $testPath" -ForegroundColor Gray
}

# Update root CMakeLists.txt - update source file references
$rootCMake = Get-Content "CMakeLists.txt" -Raw
$rootCMake = $rootCMake -replace "src/$OLD_MODULE\.c", "src/$NewName.c"
$rootCMake = $rootCMake -replace "include/\$\{PROJECT_NAME\}/$OLD_MODULE\.h", "include/`${PROJECT_NAME}/$NewName.h"
Set-Content "CMakeLists.txt" -Value $rootCMake -NoNewline
Write-Host "  - Updated CMakeLists.txt (source file references)" -ForegroundColor Gray

# Update README.md
if (Test-Path "README.md") {
    $readmeContent = Get-Content "README.md" -Raw
    
    $readmeContent = $readmeContent -replace "\b$OLD_NAME\b", $NewName
    $readmeContent = $readmeContent -replace "\b$OLD_MODULE\b", $NewName
    
    Set-Content "README.md" -Value $readmeContent -NoNewline
    Write-Host "  - Updated README.md" -ForegroundColor Gray
}

# Update test/CMakeLists.txt - set TEST_MODULE_NAME variable
if (Test-Path "test\CMakeLists.txt") {
    $testCMake = Get-Content "test\CMakeLists.txt" -Raw
    
    # Update TEST_MODULE_NAME variable
    $testCMake = $testCMake -replace 'set\(TEST_MODULE_NAME\s+"[^"]+"\)', "set(TEST_MODULE_NAME `"$NewName`")"
    
    Set-Content "test\CMakeLists.txt" -Value $testCMake -NoNewline
    Write-Host "  - Updated test/CMakeLists.txt (TEST_MODULE_NAME)" -ForegroundColor Gray
}

# Update .vscode/launch.json
if (Test-Path ".vscode\launch.json") {
    $launchJson = Get-Content ".vscode\launch.json" -Raw
    
    # Update test executable paths
    $launchJson = $launchJson -replace "test_$OLD_MODULE\.exe", "test_$NewName.exe"
    
    Set-Content ".vscode\launch.json" -Value $launchJson -NoNewline
    Write-Host "  - Updated .vscode/launch.json" -ForegroundColor Gray
}

# ==============================================================================
# COMPLETION
# ==============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Rename Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Library renamed: '$OLD_NAME' -> '$NewName'" -ForegroundColor Green
Write-Host ""
Write-Host "What was changed:" -ForegroundColor Cyan
Write-Host "  - project() declaration in CMakeLists.txt" -ForegroundColor Gray
Write-Host "  - Source file references in CMakeLists.txt" -ForegroundColor Gray
Write-Host "  - TEST_MODULE_NAME in test/CMakeLists.txt" -ForegroundColor Gray
Write-Host "  - include/$OLD_NAME/ directory -> include/$NewName/" -ForegroundColor Gray
Write-Host "  - Source files: $OLD_MODULE.* -> $NewName.*" -ForegroundColor Gray
Write-Host "  - #include statements updated" -ForegroundColor Gray
Write-Host "  - .vscode/launch.json test executable paths" -ForegroundColor Gray
Write-Host "  - README.md references updated" -ForegroundColor Gray
Write-Host ""
Write-Host "What updated automatically (via \${PROJECT_NAME}):" -ForegroundColor Cyan
Write-Host "  - All CMake library targets" -ForegroundColor Gray
Write-Host "  - All install paths and exports" -ForegroundColor Gray
Write-Host "  - Package configuration files" -ForegroundColor Gray
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Test the build:    .\build.ps1 -Clean -RunTests" -ForegroundColor Yellow
Write-Host "  2. Review changes:    git status" -ForegroundColor Yellow
Write-Host "  3. Update README.md with library-specific details" -ForegroundColor Yellow
Write-Host "  4. Implement your functions in src\$NewName.c" -ForegroundColor Yellow
Write-Host ""
