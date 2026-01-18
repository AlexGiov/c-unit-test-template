# ==============================================================================
# Rename Library Script - PowerShell
# ==============================================================================
# Automatically renames the template library to a new name
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
    Write-Host "  .\rename-library.ps1 -NewName MyLibrary" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WHAT IT DOES:" -ForegroundColor Cyan
    Write-Host "  1. Renames directories (include/mylib -> include/<NewName>)" -ForegroundColor Gray
    Write-Host "  2. Renames files (math_utils.* -> <NewName>.*)" -ForegroundColor Gray
    Write-Host "  3. Updates all references in CMakeLists.txt files" -ForegroundColor Gray
    Write-Host "  4. Updates README.md with new library name" -ForegroundColor Gray
    Write-Host "  5. Updates test files and file contents" -ForegroundColor Gray
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

# Constants
$OLD_NAME = "mylib"
$OLD_NAME_UPPER = "MYLIB"
$OLD_MODULE = "math_utils"

$NEW_NAME_UPPER = $NewName.ToUpper()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Library Rename Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Renaming library from '$OLD_NAME' to '$NewName'..." -ForegroundColor Yellow
Write-Host ""

# ==============================================================================
# STEP 1: Rename Directories
# ==============================================================================
Write-Host "[1/5] Renaming directories..." -ForegroundColor Cyan

if (Test-Path "include\$OLD_NAME") {
    Write-Host "  include\$OLD_NAME -> include\$NewName" -ForegroundColor Gray
    Rename-Item -Path "include\$OLD_NAME" -NewName $NewName
}

# ==============================================================================
# STEP 2: Rename Files
# ==============================================================================
Write-Host "[2/5] Renaming files..." -ForegroundColor Cyan

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
# STEP 3: Update CMakeLists.txt (root)
# ==============================================================================
Write-Host "[3/5] Updating root CMakeLists.txt..." -ForegroundColor Cyan

$rootCMake = Get-Content "CMakeLists.txt" -Raw

# Replace project name
$rootCMake = $rootCMake -replace "project\($OLD_NAME\s", "project($NewName "

# Replace variable names
$rootCMake = $rootCMake -replace "${OLD_NAME_UPPER}_SOURCES", "${NEW_NAME_UPPER}_SOURCES"
$rootCMake = $rootCMake -replace "${OLD_NAME_UPPER}_HEADERS", "${NEW_NAME_UPPER}_HEADERS"

# Replace library target
$rootCMake = $rootCMake -replace "add_library\($OLD_NAME", "add_library($NewName"
$rootCMake = $rootCMake -replace "target_include_directories\($OLD_NAME", "target_include_directories($NewName"
$rootCMake = $rootCMake -replace "target_compile_options\($OLD_NAME", "target_compile_options($NewName"

# Replace file references
$rootCMake = $rootCMake -replace "src/$OLD_MODULE\.c", "src/$NewName.c"
$rootCMake = $rootCMake -replace "include/$OLD_NAME/$OLD_MODULE\.h", "include/$NewName/$NewName.h"

# Replace install paths
$rootCMake = $rootCMake -replace "DESTINATION \`${CMAKE_INSTALL_PREFIX}/include/$OLD_NAME", "DESTINATION `${CMAKE_INSTALL_PREFIX}/include/$NewName"
$rootCMake = $rootCMake -replace "DESTINATION \`${CMAKE_INSTALL_PREFIX}/src/$OLD_NAME", "DESTINATION `${CMAKE_INSTALL_PREFIX}/src/$NewName"

# Replace install targets
$rootCMake = $rootCMake -replace "install\(TARGETS $OLD_NAME", "install(TARGETS $NewName"

Set-Content "CMakeLists.txt" -Value $rootCMake -NoNewline

# ==============================================================================
# STEP 4: Update test/CMakeLists.txt
# ==============================================================================
Write-Host "[4/5] Updating test/CMakeLists.txt..." -ForegroundColor Cyan

$testCMake = Get-Content "test\CMakeLists.txt" -Raw

# Replace test executable name
$testCMake = $testCMake -replace "add_executable\(test_$OLD_MODULE", "add_executable(test_$NewName"
$testCMake = $testCMake -replace "target_link_libraries\(test_$OLD_MODULE", "target_link_libraries(test_$NewName"
$testCMake = $testCMake -replace "set_target_properties\(test_$OLD_MODULE", "set_target_properties(test_$NewName"

# Replace file references
$testCMake = $testCMake -replace "unit/test_$OLD_MODULE\.c", "unit/test_$NewName.c"

# Replace library target
$testCMake = $testCMake -replace "PRIVATE $OLD_NAME", "PRIVATE $NewName"

Set-Content "test\CMakeLists.txt" -Value $testCMake -NoNewline

# ==============================================================================
# STEP 5: Update File Contents
# ==============================================================================
Write-Host "[5/5] Updating file contents..." -ForegroundColor Cyan

# Update header file
$headerPath = "include\$NewName\$NewName.h"
if (Test-Path $headerPath) {
    $headerContent = Get-Content $headerPath -Raw
    $headerGuard = "${NEW_NAME_UPPER}_H"
    $oldHeaderGuard = "${OLD_NAME_UPPER}_${OLD_MODULE}_H".ToUpper()
    
    $headerContent = $headerContent -replace $oldHeaderGuard, $headerGuard
    $headerContent = $headerContent -replace "\* @file\s+$OLD_MODULE\.h", "* @file $NewName.h"
    
    Set-Content $headerPath -Value $headerContent -NoNewline
    Write-Host "  Updated include\$NewName\$NewName.h" -ForegroundColor Gray
}

# Update source file
$sourcePath = "src\$NewName.c"
if (Test-Path $sourcePath) {
    $sourceContent = Get-Content $sourcePath -Raw
    $sourceContent = $sourceContent -replace "#include `"$OLD_NAME/$OLD_MODULE\.h`"", "#include `"$NewName/$NewName.h`""
    $sourceContent = $sourceContent -replace "\* @file\s+$OLD_MODULE\.c", "* @file $NewName.c"
    
    Set-Content $sourcePath -Value $sourceContent -NoNewline
    Write-Host "  Updated src\$NewName.c" -ForegroundColor Gray
}

# Update test file
$testPath = "test\unit\test_$NewName.c"
if (Test-Path $testPath) {
    $testContent = Get-Content $testPath -Raw
    $testContent = $testContent -replace "#include `"$OLD_NAME/$OLD_MODULE\.h`"", "#include `"$NewName/$NewName.h`""
    $testContent = $testContent -replace "\* @file\s+test_$OLD_MODULE\.c", "* @file test_$NewName.c"
    $testContent = $testContent -replace "test_$OLD_MODULE", "test_$NewName"
    
    Set-Content $testPath -Value $testContent -NoNewline
    Write-Host "  Updated test\unit\test_$NewName.c" -ForegroundColor Gray
}

# Update README.md
if (Test-Path "README.md") {
    $readmeContent = Get-Content "README.md" -Raw
    
    # Replace all instances of mylib (case-sensitive)
    $readmeContent = $readmeContent -replace "\b$OLD_NAME\b", $NewName
    $readmeContent = $readmeContent -replace "\b$OLD_NAME_UPPER\b", $NEW_NAME_UPPER
    $readmeContent = $readmeContent -replace "$OLD_MODULE", $NewName
    
    Set-Content "README.md" -Value $readmeContent -NoNewline
    Write-Host "  Updated README.md" -ForegroundColor Gray
}

# ==============================================================================
# COMPLETION
# ==============================================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Rename Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Library renamed from '$OLD_NAME' to '$NewName'" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Cyan
Write-Host "  1. Review changes:       git status" -ForegroundColor Yellow
Write-Host "  2. Test build:           .\build.ps1 -Clean -RunTests" -ForegroundColor Yellow
Write-Host "  3. Update README.md with library-specific information" -ForegroundColor Yellow
Write-Host "  4. Implement your library functions in src\$NewName.c" -ForegroundColor Yellow
Write-Host "  5. Write tests in test\unit\test_$NewName.c" -ForegroundColor Yellow
Write-Host ""
Write-Host "TIP: Clean the build directory before testing:" -ForegroundColor Gray
Write-Host "     .\build.ps1 -Clean" -ForegroundColor Gray
Write-Host ""
