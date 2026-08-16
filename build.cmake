# ==============================================================================
# Build Script - CMake Cross-Platform
# ==============================================================================
# Automates the CMake build process for the unit test template
# Cross-platform: Works on Windows, Linux, macOS
# ==============================================================================

cmake_minimum_required(VERSION 3.24)

# ==============================================================================
# USAGE
# ==============================================================================
# 
# This script is a thin wrapper around CMakePresets.json: the actual generator
# and compiler are defined there (preset "ucrt64" on Windows, "linux-gcc" on
# Linux). Use -DPRESET=<name> to force a specific preset.
#
# SYNTAX:
#   cmake [options] -P build.cmake
#
# OPTIONS (set via -D flag BEFORE -P):
#   -DPRESET=<name>          Force a specific CMakePresets.json preset
#                            Default: ucrt64 (Windows) / linux-gcc (Linux)
#   -DBUILD_TYPE=<type>      Build configuration (Debug, Release, RelWithDebInfo, MinSizeRel)
#                            Default: Debug
#   -DCLEAN=ON               Clean build directory before building
#   -DCLEAN_ONLY=ON          Clean build directory and exit (no rebuild)
#   -DRUN_TESTS=ON           Run unit tests after building
#   -DCOVERAGE=ON            Enable code coverage (requires RUN_TESTS for report)
#   -DHELP=ON                Show this help message
#
# EXAMPLES:
#   cmake -P build.cmake                                     # Build in Debug mode
#   cmake -DRUN_TESTS=ON -P build.cmake                      # Build and run tests
#   cmake -DCLEAN=ON -DRUN_TESTS=ON -P build.cmake           # Clean build and test
#   cmake -DCLEAN_ONLY=ON -P build.cmake                     # Clean without rebuilding
#   cmake -DCOVERAGE=ON -DRUN_TESTS=ON -P build.cmake        # Build with coverage
#   cmake -DBUILD_TYPE=Release -P build.cmake                # Build in Release mode
#
# EQUIVALENT MANUAL COMMANDS (no wrapper, direct preset usage):
#   cmake --preset ucrt64        (Windows)   |  cmake --preset linux-gcc   (Linux)
#   cmake --build --preset ucrt64            |  cmake --build --preset linux-gcc
#
# WORKFLOW:
#   1. Build with coverage:  cmake -DCOVERAGE=ON -DRUN_TESTS=ON -P build.cmake
#   2. Generate report:      cmake -P coverage.cmake -DGENERATE_HTML=ON
#
# ==============================================================================

# Show help
if(DEFINED HELP)
    message("")
    message("USAGE:")
    message("  cmake [options] -P build.cmake")
    message("")
    message("OPTIONS:")
    message("  -DPRESET=<name>          Force a specific CMakePresets.json preset")
    message("                           Default: ucrt64 (Windows) / linux-gcc (Linux)")
    message("  -DBUILD_TYPE=<type>      Build configuration (Debug, Release, RelWithDebInfo, MinSizeRel)")
    message("                           Default: Debug")
    message("  -DCLEAN=ON               Clean build directory before building")
    message("  -DCLEAN_ONLY=ON          Clean build directory and exit (no rebuild)")
    message("  -DRUN_TESTS=ON           Run unit tests after building")
    message("  -DCOVERAGE=ON            Enable code coverage (requires RUN_TESTS for report)")
    message("  -DHELP=ON                Show this help message")
    message("")
    message("EXAMPLES:")
    message("  cmake -P build.cmake                                     # Build in Debug mode")
    message("  cmake -DRUN_TESTS=ON -P build.cmake                      # Build and run tests")
    message("  cmake -DCLEAN=ON -DRUN_TESTS=ON -P build.cmake           # Clean build and test")
    message("  cmake -DCLEAN_ONLY=ON -P build.cmake                     # Clean without rebuilding")
    message("  cmake -DCOVERAGE=ON -DRUN_TESTS=ON -P build.cmake        # Build with coverage")
    message("  cmake -DBUILD_TYPE=Release -P build.cmake                # Build in Release mode")
    message("")
    message("WORKFLOW:")
    message("  1. Build with coverage:  cmake -DCOVERAGE=ON -DRUN_TESTS=ON -P build.cmake")
    message("  2. Generate report:      cmake -P coverage.cmake")
    message("")
    return()
endif()

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Default values
if(NOT DEFINED BUILD_TYPE)
    set(BUILD_TYPE "Debug")
endif()

# Validate BUILD_TYPE
if(NOT BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
    message(FATAL_ERROR "[ERROR] Invalid BUILD_TYPE: ${BUILD_TYPE}")
endif()

# Select the CMakePresets.json preset to use (generator/compiler are defined there)
if(NOT DEFINED PRESET)
    if(WIN32)
        set(PRESET "ucrt64")
    else()
        set(PRESET "linux-gcc")
    endif()
endif()
message("[INFO] Using preset: ${PRESET}")

# ==============================================================================
# Helper Functions
# ==============================================================================

# Get project name from CMakeLists.txt
function(get_project_name OUTPUT_VAR)
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt")
        file(READ "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" CONTENT)
        if(CONTENT MATCHES "project[ \\t]*\\([ \\t]*([A-Za-z0-9_]+)")
            set(${OUTPUT_VAR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        else()
            set(${OUTPUT_VAR} "" PARENT_SCOPE)
        endif()
    else()
        set(${OUTPUT_VAR} "" PARENT_SCOPE)
    endif()
endfunction()

# Get project name from CMake cache (after configuration)
function(get_project_name_from_cache OUTPUT_VAR)
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/build/CMakeCache.txt")
        file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/build/CMakeCache.txt" CACHE_LINES
             REGEX "CMAKE_PROJECT_NAME:STATIC=")
        if(CACHE_LINES)
            string(REGEX REPLACE "CMAKE_PROJECT_NAME:STATIC=(.*)" "\\1" PROJECT_NAME "${CACHE_LINES}")
            set(${OUTPUT_VAR} "${PROJECT_NAME}" PARENT_SCOPE)
        else()
            set(${OUTPUT_VAR} "" PARENT_SCOPE)
        endif()
    else()
        set(${OUTPUT_VAR} "" PARENT_SCOPE)
    endif()
endfunction()

# ==============================================================================
# MAIN SCRIPT
# ==============================================================================

message("========================================")
message("  Unit Test Template - Build Script")
message("========================================")
message("")

# Clean build directory if requested
if(DEFINED CLEAN OR DEFINED CLEAN_ONLY)
    message("[CLEAN] Removing build directory...")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/build")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/bin")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/lib")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/coverage")
    message("[CLEAN] Done")
    message("")
    
    # Exit if clean-only was requested
    if(DEFINED CLEAN_ONLY)
        message("[INFO] Clean-only mode: exiting without rebuild")
        return()
    endif()
endif()

# Configure
message("[CMAKE] Configuring project (preset: ${PRESET})...")

set(CONFIGURE_ARGS
    --preset ${PRESET}
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE}
)

# Allow overriding the compiler chosen by the preset (backward-compatible escape hatch)
if(DEFINED ENV{CMAKE_C_COMPILER})
    list(APPEND CONFIGURE_ARGS "-DCMAKE_C_COMPILER=$ENV{CMAKE_C_COMPILER}")
endif()

# Add coverage flag if requested
if(DEFINED COVERAGE)
    list(APPEND CONFIGURE_ARGS "-DENABLE_COVERAGE=ON")
endif()

execute_process(
    COMMAND ${CMAKE_COMMAND} ${CONFIGURE_ARGS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE RESULT
    ERROR_VARIABLE ERROR_OUTPUT
)

if(NOT RESULT EQUAL 0)
    message(FATAL_ERROR "[ERROR] CMake configuration failed (preset: ${PRESET})!\n${ERROR_OUTPUT}")
endif()

message("[CMAKE] Configuration complete")
message("")

# Build
message("[BUILD] Compiling project...")

execute_process(
    COMMAND ${CMAKE_COMMAND} --build --preset ${PRESET}
    WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
    RESULT_VARIABLE RESULT
)

if(NOT RESULT EQUAL 0)
    message(FATAL_ERROR "[ERROR] Build failed (preset: ${PRESET})!")
endif()

message("[BUILD] Build complete")
message("")

# Run tests if requested
if(DEFINED RUN_TESTS)
    message("[TEST] Running unit tests...")
    
    # Find test executables in bin/ directory
    file(GLOB TEST_EXECUTABLES "${CMAKE_CURRENT_LIST_DIR}/bin/test_*")
    
    # On Windows, also check for .exe extension
    if(WIN32 AND NOT TEST_EXECUTABLES)
        file(GLOB TEST_EXECUTABLES "${CMAKE_CURRENT_LIST_DIR}/bin/test_*.exe")
    endif()
    
    if(TEST_EXECUTABLES)
        foreach(TEST_EXE ${TEST_EXECUTABLES})
            get_filename_component(TEST_NAME ${TEST_EXE} NAME)
            message("  Executable: ${TEST_EXE}")
            message("")
            
            execute_process(
                COMMAND ${TEST_EXE}
                RESULT_VARIABLE RESULT
            )
            
            if(NOT RESULT EQUAL 0)
                message("")
                message(FATAL_ERROR "[ERROR] Tests failed in ${TEST_NAME}!")
            endif()
            message("")
        endforeach()
        
        message("[TEST] All tests passed!")
    else()
        message(FATAL_ERROR "[ERROR] No test executables found in bin/ directory\n  Expected: bin/test_*")
    endif()
endif()

# Build Summary
message("")
message("========================================")
message("  Build Summary")
message("========================================")

get_project_name_from_cache(PROJECT_NAME)
if(NOT PROJECT_NAME)
    get_project_name(PROJECT_NAME)
endif()

if(PROJECT_NAME)
    message("Project:       ${PROJECT_NAME}")
endif()

message("Build Type:    ${BUILD_TYPE}")
message("Preset:        ${PRESET}")
message("Output:        bin/")
message("Status:        SUCCESS")
message("========================================")
message("")

# Usage tip
if(NOT DEFINED RUN_TESTS)
    message("Tip: Run tests with:  cmake -DRUN_TESTS=ON -P build.cmake")
endif()
