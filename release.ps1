# ==============================================================================
# Release Script - PowerShell
# ==============================================================================
# Automates version bumping, Git tagging, and GitHub release creation
# ==============================================================================

[CmdletBinding()]
param(
    [ValidateSet("patch", "minor", "major")]
    [string]$BumpVersion,
    
    [string]$Version,
    
    [switch]$CreateGitHubRelease,
    
    [string]$ReleaseNotes,
    
    [switch]$DryRun,
    
    [switch]$Help,
    
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$UnknownArgs
)

# Show help
function Show-Help {
    Write-Host ""
    Write-Host "USAGE:" -ForegroundColor Cyan
    Write-Host "  .\release.ps1 [-BumpVersion <type>] [-Version <version>] [-CreateGitHubRelease] [-ReleaseNotes <notes>] [-DryRun] [-Help]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Cyan
    Write-Host "  -BumpVersion <type>      Automatically increment version (patch, minor, major)" -ForegroundColor Yellow
    Write-Host "                           patch: 1.0.0 → 1.0.1" -ForegroundColor Gray
    Write-Host "                           minor: 1.0.0 → 1.1.0" -ForegroundColor Gray
    Write-Host "                           major: 1.0.0 → 2.0.0" -ForegroundColor Gray
    Write-Host "  -Version <version>       Manually specify version (e.g., 2.0.0)" -ForegroundColor Yellow
    Write-Host "  -CreateGitHubRelease     Create GitHub release (requires gh CLI)" -ForegroundColor Yellow
    Write-Host "  -ReleaseNotes <notes>    Custom release notes (optional)" -ForegroundColor Yellow
    Write-Host "  -DryRun                  Show what would happen without making changes" -ForegroundColor Yellow
    Write-Host "  -Help                    Show this help message" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "EXAMPLES:" -ForegroundColor Cyan
    Write-Host "  .\release.ps1 -BumpVersion patch                    # Bump patch version and tag" -ForegroundColor Gray
    Write-Host "  .\release.ps1 -BumpVersion minor -CreateGitHubRelease  # Bump minor + GitHub release" -ForegroundColor Gray
    Write-Host "  .\release.ps1 -Version 2.0.0                        # Set specific version" -ForegroundColor Gray
    Write-Host "  .\release.ps1 -BumpVersion major -DryRun            # Preview without changes" -ForegroundColor Gray
    Write-Host ""
    Write-Host "WORKFLOW:" -ForegroundColor Cyan
    Write-Host "  1. Script reads current version from CMakeLists.txt" -ForegroundColor Gray
    Write-Host "  2. Bumps version according to semantic versioning" -ForegroundColor Gray
    Write-Host "  3. Updates CMakeLists.txt with new version" -ForegroundColor Gray
    Write-Host "  4. Creates Git tag (e.g., v1.0.0)" -ForegroundColor Gray
    Write-Host "  5. Pushes tag to remote" -ForegroundColor Gray
    Write-Host "  6. Optionally creates GitHub release" -ForegroundColor Gray
    Write-Host ""
    Write-Host "REQUIREMENTS:" -ForegroundColor Cyan
    Write-Host "  - Git (for tagging)" -ForegroundColor Gray
    Write-Host "  - gh CLI (only if using -CreateGitHubRelease)" -ForegroundColor Gray
    Write-Host "    Install: https://cli.github.com/" -ForegroundColor Gray
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

# Validate parameters
if (-not $BumpVersion -and -not $Version) {
    Write-Host ""
    Write-Host "[ERROR] You must specify either -BumpVersion or -Version" -ForegroundColor Red
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\release.ps1 -BumpVersion patch" -ForegroundColor Gray
    Write-Host "  .\release.ps1 -Version 2.0.0" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Use -Help for more information." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

if ($BumpVersion -and $Version) {
    Write-Host ""
    Write-Host "[ERROR] Cannot specify both -BumpVersion and -Version" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# ==============================================================================
# Helper Functions
# ==============================================================================

function Get-CurrentVersion {
    if (-not (Test-Path "CMakeLists.txt")) {
        Write-Host "[ERROR] CMakeLists.txt not found" -ForegroundColor Red
        exit 1
    }
    
    $content = Get-Content "CMakeLists.txt" -Raw
    if ($content -match 'project\s*\([^)]*VERSION\s+(\d+)\.(\d+)\.(\d+)') {
        return @{
            Major  = [int]$Matches[1]
            Minor  = [int]$Matches[2]
            Patch  = [int]$Matches[3]
            String = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
        }
    }
    
    Write-Host "[ERROR] Could not parse version from CMakeLists.txt" -ForegroundColor Red
    exit 1
}

function Get-BumpedVersion {
    param(
        [hashtable]$CurrentVersion,
        [string]$BumpType
    )
    
    $major = $CurrentVersion.Major
    $minor = $CurrentVersion.Minor
    $patch = $CurrentVersion.Patch
    
    switch ($BumpType) {
        "patch" {
            $patch++
        }
        "minor" {
            $minor++
            $patch = 0
        }
        "major" {
            $major++
            $minor = 0
            $patch = 0
        }
    }
    
    return @{
        Major  = $major
        Minor  = $minor
        Patch  = $patch
        String = "$major.$minor.$patch"
    }
}

function Update-CMakeVersion {
    param(
        [string]$NewVersion
    )
    
    $content = Get-Content "CMakeLists.txt" -Raw
    
    if ($content -match '(project\s*\([^)]*VERSION\s+)(\d+\.\d+\.\d+)') {
        $newContent = $content -replace '(project\s*\([^)]*VERSION\s+)\d+\.\d+\.\d+', "`${1}$NewVersion"
        
        if (-not $DryRun) {
            Set-Content "CMakeLists.txt" -Value $newContent -NoNewline
            Write-Host "[UPDATE] CMakeLists.txt version updated to $NewVersion" -ForegroundColor Green
        }
        else {
            Write-Host "[DRY RUN] Would update CMakeLists.txt version to $NewVersion" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "[ERROR] Could not update version in CMakeLists.txt" -ForegroundColor Red
        exit 1
    }
}

function Test-GitStatus {
    $status = git status --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Git not available or not a git repository" -ForegroundColor Red
        exit 1
    }
    
    if ($status) {
        Write-Host "[ERROR] Working directory is not clean. Please commit or stash changes first." -ForegroundColor Red
        Write-Host ""
        Write-Host "Uncommitted changes:" -ForegroundColor Yellow
        git status --short
        Write-Host ""
        exit 1
    }
}

function Test-GitHubCLI {
    $ghVersion = gh --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] GitHub CLI (gh) not found" -ForegroundColor Red
        Write-Host "        Install from: https://cli.github.com/" -ForegroundColor Yellow
        exit 1
    }
    
    # Check if authenticated
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] GitHub CLI not authenticated" -ForegroundColor Red
        Write-Host "        Run: gh auth login" -ForegroundColor Yellow
        exit 1
    }
}

function New-GitTag {
    param(
        [string]$Version,
        [string]$Message
    )
    
    $tagName = "v$Version"
    
    # Check if tag already exists
    $existingTag = git tag -l $tagName
    if ($existingTag) {
        Write-Host "[ERROR] Tag $tagName already exists" -ForegroundColor Red
        exit 1
    }
    
    if (-not $DryRun) {
        git tag -a $tagName -m $Message
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to create Git tag" -ForegroundColor Red
            exit 1
        }
        Write-Host "[TAG] Created Git tag: $tagName" -ForegroundColor Green
        
        # Push tag
        git push origin $tagName
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to push Git tag" -ForegroundColor Red
            exit 1
        }
        Write-Host "[PUSH] Pushed tag to remote: $tagName" -ForegroundColor Green
    }
    else {
        Write-Host "[DRY RUN] Would create and push Git tag: $tagName" -ForegroundColor Yellow
    }
}

function New-GitHubRelease {
    param(
        [string]$Version,
        [string]$Notes
    )
    
    $tagName = "v$Version"
    
    if (-not $Notes) {
        $Notes = "Release $Version"
    }
    
    if (-not $DryRun) {
        gh release create $tagName --title "Release $Version" --notes $Notes
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to create GitHub release" -ForegroundColor Red
            exit 1
        }
        Write-Host "[RELEASE] Created GitHub release: $tagName" -ForegroundColor Green
    }
    else {
        Write-Host "[DRY RUN] Would create GitHub release: $tagName" -ForegroundColor Yellow
    }
}

# ==============================================================================
# Main Script
# ==============================================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Release Automation Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN MODE] No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Get current version
$currentVersion = Get-CurrentVersion
Write-Host "[INFO] Current version: $($currentVersion.String)" -ForegroundColor Cyan

# Determine new version
if ($BumpVersion) {
    $newVersionObj = Get-BumpedVersion -CurrentVersion $currentVersion -BumpType $BumpVersion
    $newVersion = $newVersionObj.String
    Write-Host "[INFO] Bumping version ($BumpVersion): $($currentVersion.String) → $newVersion" -ForegroundColor Cyan
}
else {
    # Validate manual version format
    if ($Version -notmatch '^\d+\.\d+\.\d+$') {
        Write-Host "[ERROR] Invalid version format: $Version" -ForegroundColor Red
        Write-Host "        Expected format: X.Y.Z (e.g., 1.0.0)" -ForegroundColor Yellow
        exit 1
    }
    $newVersion = $Version
    Write-Host "[INFO] Setting version to: $newVersion" -ForegroundColor Cyan
}

Write-Host ""

# Check Git status (skip in dry run for testing)
if (-not $DryRun) {
    Write-Host "[CHECK] Verifying Git status..." -ForegroundColor Yellow
    Test-GitStatus
    Write-Host "[CHECK] Working directory is clean" -ForegroundColor Green
    Write-Host ""
}

# Update CMakeLists.txt
Write-Host "[STEP 1] Updating CMakeLists.txt..." -ForegroundColor Yellow
Update-CMakeVersion -NewVersion $newVersion
Write-Host ""

# Commit version change
if (-not $DryRun) {
    Write-Host "[STEP 2] Committing version change..." -ForegroundColor Yellow
    git add CMakeLists.txt
    git commit -m "Bump version to $newVersion"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to commit version change" -ForegroundColor Red
        exit 1
    }
    Write-Host "[COMMIT] Version change committed" -ForegroundColor Green
    Write-Host ""
}
else {
    Write-Host "[DRY RUN] Would commit: Bump version to $newVersion" -ForegroundColor Yellow
    Write-Host ""
}

# Create Git tag
Write-Host "[STEP 3] Creating Git tag..." -ForegroundColor Yellow
$tagMessage = "Release version $newVersion"
New-GitTag -Version $newVersion -Message $tagMessage
Write-Host ""

# Create GitHub release (if requested)
if ($CreateGitHubRelease) {
    Write-Host "[STEP 4] Creating GitHub release..." -ForegroundColor Yellow
    Test-GitHubCLI
    New-GitHubRelease -Version $newVersion -Notes $ReleaseNotes
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Release Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Version: $newVersion" -ForegroundColor Green
Write-Host "Tag:     v$newVersion" -ForegroundColor Green

if ($CreateGitHubRelease) {
    Write-Host "GitHub:  Release created" -ForegroundColor Green
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] No actual changes were made" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to execute the release" -ForegroundColor Yellow
}

Write-Host ""
