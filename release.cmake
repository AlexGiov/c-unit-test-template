# ==============================================================================
# Release Script - CMake Cross-Platform
# ==============================================================================
# Automates version bumping, Git tagging, and GitHub release creation
# Cross-platform: Works on Windows, Linux, macOS
# ==============================================================================

cmake_minimum_required(VERSION 3.16)

# ==============================================================================
# USAGE
# ==============================================================================
#
# SYNTAX:
#   cmake [options] -P release.cmake
#
# OPTIONS (set via -D flag BEFORE -P):
#   -DBUMP_VERSION=<type>       Automatically increment version (patch, minor, major)
#                               patch: 1.0.0 → 1.0.1
#                               minor: 1.0.0 → 1.1.0
#                               major: 1.0.0 → 2.0.0
#   -DVERSION=<version>         Manually specify version (e.g., 2.0.0)
#   -DCREATE_GITHUB_RELEASE=ON  Create GitHub release (requires gh CLI)
#   -DRELEASE_NOTES=<notes>     Custom release notes (optional)
#   -DDRY_RUN=ON                Show what would happen without making changes
#   -DHELP=ON                   Show this help message
#
# EXAMPLES:
#   cmake -DBUMP_VERSION=patch -P release.cmake                                    # Bump patch version
#   cmake -DBUMP_VERSION=minor -DCREATE_GITHUB_RELEASE=ON -P release.cmake        # Bump + GitHub
#   cmake -DVERSION=2.0.0 -P release.cmake                                         # Set specific version
#   cmake -DBUMP_VERSION=major -DDRY_RUN=ON -P release.cmake                      # Preview changes
#
# WORKFLOW:
#   1. Script reads current version from CMakeLists.txt
#   2. Bumps version according to semantic versioning
#   3. Updates CMakeLists.txt with new version
#   4. Creates Git commit with version change
#   5. Creates Git tag (e.g., v1.0.0)
#   6. Pushes commit and tag to remote
#   7. Optionally creates GitHub release
#
# REQUIREMENTS:
#   - Git (for tagging)
#   - gh CLI (only if using -DCREATE_GITHUB_RELEASE=ON)
#     Install: https://cli.github.com/
#
# ==============================================================================

# Show help
if(DEFINED HELP)
    message("")
    message("USAGE:")
    message("  cmake [options] -P release.cmake")
    message("")
    message("OPTIONS:")
    message("  -DBUMP_VERSION=<type>       Automatically increment version (patch, minor, major)")
    message("                              patch: 1.0.0 → 1.0.1")
    message("                              minor: 1.0.0 → 1.1.0")
    message("                              major: 1.0.0 → 2.0.0")
    message("  -DVERSION=<version>         Manually specify version (e.g., 2.0.0)")
    message("  -DCREATE_GITHUB_RELEASE=ON  Create GitHub release (requires gh CLI)")
    message("  -DRELEASE_NOTES=<notes>     Custom release notes (optional)")
    message("  -DDRY_RUN=ON                Show what would happen without making changes")
    message("  -DHELP=ON                   Show this help message")
    message("")
    message("EXAMPLES:")
    message("  cmake -DBUMP_VERSION=patch -P release.cmake                                    # Bump patch")
    message("  cmake -DBUMP_VERSION=minor -DCREATE_GITHUB_RELEASE=ON -P release.cmake        # Bump + GitHub")
    message("  cmake -DVERSION=2.0.0 -P release.cmake                                         # Set version")
    message("  cmake -DBUMP_VERSION=major -DDRY_RUN=ON -P release.cmake                      # Preview")
    message("")
    return()
endif()

# ==============================================================================
# Validate Parameters
# ==============================================================================

if(NOT DEFINED BUMP_VERSION AND NOT DEFINED VERSION)
    message(FATAL_ERROR "\n[ERROR] You must specify either -DBUMP_VERSION or -DVERSION\n\nExamples:\n  cmake -P release.cmake -DBUMP_VERSION=patch\n  cmake -P release.cmake -DVERSION=2.0.0\n")
endif()

if(DEFINED BUMP_VERSION AND DEFINED VERSION)
    message(FATAL_ERROR "\n[ERROR] Cannot specify both -DBUMP_VERSION and -DVERSION\n")
endif()

if(DEFINED BUMP_VERSION)
    if(NOT BUMP_VERSION MATCHES "^(patch|minor|major)$")
        message(FATAL_ERROR "[ERROR] Invalid BUMP_VERSION: ${BUMP_VERSION}\n  Must be: patch, minor, or major")
    endif()
endif()

# ==============================================================================
# Helper Functions
# ==============================================================================

# Get current version from CMakeLists.txt
function(get_current_version MAJOR MINOR PATCH VERSION_STRING)
    if(NOT EXISTS "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt")
        message(FATAL_ERROR "[ERROR] CMakeLists.txt not found")
    endif()
    
    file(READ "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" CONTENT)
    # Match multi-line project() declarations: project(name\n    VERSION X.Y.Z
    if(CONTENT MATCHES "project[^)]*VERSION[ \\t\\n]+([0-9]+)\\.([0-9]+)\\.([0-9]+)")
        set(${MAJOR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        set(${MINOR} "${CMAKE_MATCH_2}" PARENT_SCOPE)
        set(${PATCH} "${CMAKE_MATCH_3}" PARENT_SCOPE)
        set(${VERSION_STRING} "${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "[ERROR] Could not parse VERSION X.Y.Z from CMakeLists.txt project() declaration")
    endif()
endfunction()

# Calculate bumped version
function(get_bumped_version CURRENT_MAJOR CURRENT_MINOR CURRENT_PATCH BUMP_TYPE NEW_VERSION)
    set(MAJOR ${CURRENT_MAJOR})
    set(MINOR ${CURRENT_MINOR})
    set(PATCH ${CURRENT_PATCH})
    
    if(BUMP_TYPE STREQUAL "patch")
        math(EXPR PATCH "${PATCH} + 1")
    elseif(BUMP_TYPE STREQUAL "minor")
        math(EXPR MINOR "${MINOR} + 1")
        set(PATCH 0)
    elseif(BUMP_TYPE STREQUAL "major")
        math(EXPR MAJOR "${MAJOR} + 1")
        set(MINOR 0)
        set(PATCH 0)
    endif()
    
    set(${NEW_VERSION} "${MAJOR}.${MINOR}.${PATCH}" PARENT_SCOPE)
endfunction()

# Update version in CMakeLists.txt
function(update_cmake_version NEW_VERSION)
    file(READ "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" CONTENT)
    
    # Match VERSION with support for newlines (multiline project() declarations)
    # Matches: VERSION <spaces/newlines> X.Y.Z
    if(CONTENT MATCHES "(project[^)]*VERSION[ \t\n]+)[0-9]+\\.[0-9]+\\.[0-9]+")
        string(REGEX REPLACE "(project[^)]*VERSION[ \t\n]+)[0-9]+\\.[0-9]+\\.[0-9]+" 
               "\\1${NEW_VERSION}" NEW_CONTENT "${CONTENT}")
        
        if(NOT DEFINED DRY_RUN)
            file(WRITE "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" "${NEW_CONTENT}")
            message("[UPDATE] CMakeLists.txt version updated to ${NEW_VERSION}")
        else()
            message("[DRY RUN] Would update CMakeLists.txt version to ${NEW_VERSION}")
        endif()
    else()
        message(FATAL_ERROR "[ERROR] Could not find VERSION in CMakeLists.txt project() declaration")
    endif()
endfunction()

# Check Git status
function(check_git_status)
    execute_process(
        COMMAND git status --porcelain
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        RESULT_VARIABLE RESULT
        OUTPUT_VARIABLE OUTPUT
        ERROR_VARIABLE ERROR
    )
    
    if(NOT RESULT EQUAL 0)
        message(FATAL_ERROR "[ERROR] Git not available or not a git repository")
    endif()
    
    if(OUTPUT)
        message(FATAL_ERROR "[ERROR] Working directory is not clean. Please commit or stash changes first.\n\nUncommitted changes:\n${OUTPUT}")
    endif()
endfunction()

# Check GitHub CLI
function(check_github_cli)
    execute_process(
        COMMAND gh --version
        RESULT_VARIABLE RESULT
        OUTPUT_QUIET
        ERROR_QUIET
    )
    
    if(NOT RESULT EQUAL 0)
        message(FATAL_ERROR "[ERROR] GitHub CLI (gh) not found\n        Install from: https://cli.github.com/")
    endif()
    
    execute_process(
        COMMAND gh auth status
        RESULT_VARIABLE RESULT
        OUTPUT_QUIET
        ERROR_QUIET
    )
    
    if(NOT RESULT EQUAL 0)
        message(FATAL_ERROR "[ERROR] GitHub CLI not authenticated\n        Run: gh auth login")
    endif()
endfunction()

# Create Git tag
function(create_git_tag VERSION_STRING MESSAGE)
    set(TAG_NAME "v${VERSION_STRING}")
    
    # Check if tag exists
    execute_process(
        COMMAND git tag -l ${TAG_NAME}
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE EXISTING_TAG
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(EXISTING_TAG)
        message(FATAL_ERROR "[ERROR] Tag ${TAG_NAME} already exists")
    endif()
    
    if(NOT DEFINED DRY_RUN)
        # Create tag
        execute_process(
            COMMAND git tag -a ${TAG_NAME} -m "${MESSAGE}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            RESULT_VARIABLE RESULT
        )
        
        if(NOT RESULT EQUAL 0)
            message(FATAL_ERROR "[ERROR] Failed to create Git tag")
        endif()
        
        message("[TAG] Created Git tag: ${TAG_NAME}")
        
        # Push tag
        execute_process(
            COMMAND git push origin ${TAG_NAME}
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            RESULT_VARIABLE RESULT
        )
        
        if(NOT RESULT EQUAL 0)
            message(FATAL_ERROR "[ERROR] Failed to push Git tag")
        endif()
        
        message("[PUSH] Pushed tag to remote: ${TAG_NAME}")
    else()
        message("[DRY RUN] Would create and push Git tag: ${TAG_NAME}")
    endif()
endfunction()

# ==============================================================================
# MAIN SCRIPT
# ==============================================================================

message("========================================")
message("  Release Automation Script")
message("========================================")
message("")

if(DEFINED DRY_RUN)
    message("[DRY RUN MODE] No changes will be made")
    message("")
endif()

# Get current version
get_current_version(CURRENT_MAJOR CURRENT_MINOR CURRENT_PATCH CURRENT_VERSION)
message("[INFO] Current version: ${CURRENT_VERSION}")

# Determine new version
if(DEFINED BUMP_VERSION)
    get_bumped_version(${CURRENT_MAJOR} ${CURRENT_MINOR} ${CURRENT_PATCH} ${BUMP_VERSION} NEW_VERSION)
    message("[INFO] Bumping ${BUMP_VERSION} version to: ${NEW_VERSION}")
else()
    set(NEW_VERSION ${VERSION})
    message("[INFO] Setting version to: ${NEW_VERSION}")
endif()

message("")

# Check if version actually changed
if(NEW_VERSION STREQUAL CURRENT_VERSION)
    message(FATAL_ERROR "[ERROR] New version is the same as current version: ${NEW_VERSION}\n        No changes to make.")
endif()

# Check Git working directory is clean (skip in dry run)
if(NOT DEFINED DRY_RUN)
    message("[STEP 1] Checking Git status...")
    check_git_status()
    message("")
endif()

# Update CMakeLists.txt
message("[STEP 2] Updating CMakeLists.txt...")
update_cmake_version(${NEW_VERSION})
message("")

# Commit changes (skip in dry run)
if(NOT DEFINED DRY_RUN)
    execute_process(
        COMMAND git add CMakeLists.txt
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    )
    
    execute_process(
        COMMAND git commit -m "Bump version to ${NEW_VERSION}"
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        RESULT_VARIABLE RESULT
    )
    
    if(NOT RESULT EQUAL 0)
        message(FATAL_ERROR "[ERROR] Failed to commit version change")
    endif()
    
    message("[COMMIT] Committed version change")
else()
    message("[DRY RUN] Would commit: Bump version to ${NEW_VERSION}")
endif()

message("")

# Create Git tag
message("[STEP 3] Creating Git tag...")
create_git_tag(${NEW_VERSION} "Release ${NEW_VERSION}")
message("")

# Create GitHub release (optional)
if(DEFINED CREATE_GITHUB_RELEASE)
    message("[STEP 4] Creating GitHub release...")
    
    check_github_cli()
    
    set(TAG_NAME "v${NEW_VERSION}")
    
    if(NOT DEFINED RELEASE_NOTES)
        set(RELEASE_NOTES "Release ${NEW_VERSION}")
    endif()
    
    if(NOT DEFINED DRY_RUN)
        execute_process(
            COMMAND gh release create ${TAG_NAME} --title "Release ${NEW_VERSION}" --notes "${RELEASE_NOTES}"
            WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
            RESULT_VARIABLE RESULT
        )
        
        if(NOT RESULT EQUAL 0)
            message(FATAL_ERROR "[ERROR] Failed to create GitHub release")
        endif()
        
        message("[RELEASE] Created GitHub release: ${TAG_NAME}")
    else()
        message("[DRY RUN] Would create GitHub release: ${TAG_NAME}")
    endif()
    
    message("")
endif()

# Summary
message("========================================")
message("  Release Complete!")
message("========================================")
message("")
message("Version: ${NEW_VERSION}")
message("Tag:     v${NEW_VERSION}")
message("")

if(DEFINED DRY_RUN)
    message("[DRY RUN] No actual changes were made")
    message("Run without -DDRY_RUN=ON to execute the release")
    message("")
endif()
