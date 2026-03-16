# ==============================================================================
# Code Coverage Script - CMake Cross-Platform
# ==============================================================================
# Generates code coverage reports using gcov
# Cross-platform: Works on Windows, Linux, macOS
# ==============================================================================

cmake_minimum_required(VERSION 3.16)

# ==============================================================================
# USAGE
# ==============================================================================
#
# SYNTAX:
#   cmake [options] -P coverage.cmake
#
# OPTIONS (set via -D flag BEFORE -P):
#   -DGENERATE_HTML=ON    Generate HTML coverage report with visual charts
#   -DHELP=ON             Show this help message
#
# EXAMPLES:
#   cmake -P coverage.cmake                       # Generate .gcov files only
#   cmake -DGENERATE_HTML=ON -P coverage.cmake    # Generate .gcov + HTML report
#
# REQUIREMENTS:
#   - Build project with coverage:  cmake -DCOVERAGE=ON -DRUN_TESTS=ON -P build.cmake
#
# HTML REPORT FEATURES:
#   - Color-coded coverage levels (green ≥80%, yellow ≥50%, red <50%)
#   - Visual progress bars for each file
#   - Clickable links to detailed .gcov files
#   - Overall project coverage summary
#   - Automatic browser launch
#
# ==============================================================================

# Show help
if(DEFINED HELP)
    message("")
    message("USAGE:")
    message("  cmake [options] -P coverage.cmake")
    message("")
    message("OPTIONS:")
    message("  -DGENERATE_HTML=ON    Generate HTML coverage report with visual charts")
    message("  -DHELP=ON             Show this help message")
    message("")
    message("EXAMPLES:")
    message("  cmake -P coverage.cmake                       # Generate .gcov files only")
    message("  cmake -DGENERATE_HTML=ON -P coverage.cmake    # Generate .gcov + HTML report")
    message("")
    message("REQUIREMENTS:")
    message("  - Build project with coverage:  cmake -DCOVERAGE=ON -DRUN_TESTS=ON -P build.cmake")
    message("")
    message("HTML REPORT FEATURES:")
    message("  - Color-coded coverage levels (green >=80%, yellow >=50%, red <50%)")
    message("  - Visual progress bars")
    message("  - Clickable links to .gcov files")
    message("  - Automatic browser launch")
    message("")
    return()
endif()

# ==============================================================================
# CONFIGURATION
# ==============================================================================

set(BUILD_DIR "${CMAKE_CURRENT_LIST_DIR}/build")
set(COVERAGE_DIR "${CMAKE_CURRENT_LIST_DIR}/coverage")

# Auto-detect gcov
if(DEFINED ENV{GCOV_EXECUTABLE})
    set(GCOV_EXECUTABLE "$ENV{GCOV_EXECUTABLE}")
    message("[INFO] Using gcov from environment: ${GCOV_EXECUTABLE}")
else()
    if(WIN32)
        # Try to find gcov in common locations
        find_program(GCOV_EXECUTABLE
            NAMES gcov
            PATHS
                "C:/devbin/mingw/mingw64/8.1.0/bin"
                "C:/msys64/mingw64/bin"
                "C:/mingw-w64/x86_64-8.1.0-posix-seh-rt_v6-rev0/mingw64/bin"
                "C:/Program Files/mingw-w64/x86_64-8.1.0-posix-seh-rt_v6-rev0/mingw64/bin"
            NO_DEFAULT_PATH
        )
        
        # Fallback to system PATH
        if(NOT GCOV_EXECUTABLE)
            find_program(GCOV_EXECUTABLE gcov)
        endif()
        
        if(GCOV_EXECUTABLE)
            string(REPLACE "\\" "/" GCOV_EXECUTABLE "${GCOV_EXECUTABLE}")
            message("[INFO] Auto-detected gcov: ${GCOV_EXECUTABLE}")
        else()
            message(FATAL_ERROR "[ERROR] gcov not found. Install MinGW or set GCOV_EXECUTABLE environment variable")
        endif()
    else()
        # On Unix/Linux/macOS, use system gcov
        find_program(GCOV_EXECUTABLE gcov)
        if(NOT GCOV_EXECUTABLE)
            message(FATAL_ERROR "[ERROR] gcov not found. Install build-essential or gcc package.")
        endif()
    endif()
endif()

# ==============================================================================
# Helper Functions
# ==============================================================================

# Get project name
function(get_project_name OUTPUT_VAR)
    # Try cache first
    if(EXISTS "${BUILD_DIR}/CMakeCache.txt")
        file(STRINGS "${BUILD_DIR}/CMakeCache.txt" CACHE_LINES
             REGEX "CMAKE_PROJECT_NAME:STATIC=")
        if(CACHE_LINES)
            string(REGEX REPLACE "CMAKE_PROJECT_NAME:STATIC=(.*)" "\\1" PROJECT_NAME "${CACHE_LINES}")
            set(${OUTPUT_VAR} "${PROJECT_NAME}" PARENT_SCOPE)
            return()
        endif()
    endif()
    
    # Fallback: read from CMakeLists.txt
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt")
        file(READ "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" CONTENT)
        if(CONTENT MATCHES "project[ \\t]*\\([ \\t]*([A-Za-z0-9_]+)")
            set(${OUTPUT_VAR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
            return()
        endif()
    endif()
    
    # Default fallback
    set(${OUTPUT_VAR} "mylib" PARENT_SCOPE)
endfunction()

# ==============================================================================
# MAIN SCRIPT
# ==============================================================================

message("========================================")
message("  Code Coverage Report Generator")
message("========================================")
message("")

# Get project name
get_project_name(PROJECT_NAME)
message("[INFO] Project: ${PROJECT_NAME}")
message("")

# Check if build with coverage exists
if(NOT EXISTS "${BUILD_DIR}/CMakeCache.txt")
    message(FATAL_ERROR "[ERROR] Build directory not found. Run build first:\n  cmake -P build.cmake -DCOVERAGE=ON -DRUN_TESTS=ON")
endif()

# Check if coverage data exists
file(GLOB_RECURSE GCNO_FILES "${BUILD_DIR}/*.gcno")
if(NOT GCNO_FILES)
    message(FATAL_ERROR "[ERROR] No coverage data files found (.gcno)\n  Make sure to build with -DCOVERAGE=ON flag:\n  cmake -P build.cmake -DCOVERAGE=ON")
endif()

file(GLOB_RECURSE GCDA_FILES "${BUILD_DIR}/*.gcda")
if(NOT GCDA_FILES)
    message(FATAL_ERROR "[ERROR] No coverage execution data found (.gcda)\n  Make sure to run tests:\n  cmake -P build.cmake -DCOVERAGE=ON -DRUN_TESTS=ON")
endif()

# Create coverage directory
message("[COVERAGE] Creating coverage directory...")
file(REMOVE_RECURSE "${COVERAGE_DIR}")
file(MAKE_DIRECTORY "${COVERAGE_DIR}")

# Process coverage data for library sources
message("[COVERAGE] Processing coverage data...")

file(GLOB_RECURSE SOURCE_FILES "${CMAKE_CURRENT_LIST_DIR}/src/*.c")
set(CMAKE_OBJ_DIR "${BUILD_DIR}/CMakeFiles/${PROJECT_NAME}.dir/src")

set(TOTAL_LINES 0)
set(EXECUTED_LINES 0)
set(ALL_FILE_RESULTS "")

foreach(SOURCE_FILE ${SOURCE_FILES})
    get_filename_component(FILE_NAME ${SOURCE_FILE} NAME)
    
    message("  Processing: ${FILE_NAME}")
    
    # Find corresponding .gcno file
    file(GLOB GCNO_FILE "${CMAKE_OBJ_DIR}/${FILE_NAME}.gcno")
    
    if(GCNO_FILE)
        get_filename_component(OBJ_DIR ${GCNO_FILE} DIRECTORY)
        get_filename_component(GCNO_FILENAME ${GCNO_FILE} NAME)
        
        # Copy source file to object directory
        # gcov expects to find the source file at the path stored in .gcno
        # which is relative (../src/mylib.c), but from the object directory
        # that path doesn't work. Copying the source allows gcov to find it.
        file(COPY ${SOURCE_FILE} DESTINATION ${OBJ_DIR})
        
        # Run gcov from the object directory (like coverage.ps1 does)
        # gcov needs to be in the same directory as .gcno/.gcda files
        execute_process(
            COMMAND ${GCOV_EXECUTABLE} ${GCNO_FILENAME}
            WORKING_DIRECTORY ${OBJ_DIR}
            RESULT_VARIABLE RESULT
            OUTPUT_VARIABLE OUTPUT
            ERROR_VARIABLE ERROR_OUTPUT
        )
        
        if(NOT RESULT EQUAL 0)
            message("  [ERROR] gcov failed: ${ERROR_OUTPUT}")
        endif()
        
        # Move .gcov files from object directory to coverage directory
        file(GLOB GCOV_FILES "${OBJ_DIR}/*.gcov")
        foreach(GCOV_FILE ${GCOV_FILES})
            get_filename_component(GCOV_FILENAME ${GCOV_FILE} NAME)
            file(COPY ${GCOV_FILE} DESTINATION ${COVERAGE_DIR})
            file(REMOVE ${GCOV_FILE})
        endforeach()
        
        # Clean up the source file copy
        file(REMOVE "${OBJ_DIR}/${FILE_NAME}")
    else()
        message("  Warning: No coverage data for ${FILE_NAME}")
    endif()
endforeach()

# Analyze coverage results
message("")
message("[COVERAGE] Coverage Summary:")
message("")

file(GLOB GCOV_FILES "${COVERAGE_DIR}/*.gcov")

foreach(GCOV_FILE ${GCOV_FILES})
    file(READ ${GCOV_FILE} CONTENT)
    get_filename_component(FILE_NAME ${GCOV_FILE} NAME)
    string(REPLACE ".gcov" "" SOURCE_NAME "${FILE_NAME}")
    
    set(FILE_LINES 0)
    set(FILE_EXECUTED 0)
    
    # Parse gcov format: lines starting with number or ##### are executable
    string(REGEX MATCHALL "[ \t]*[0-9]+:" EXECUTED_MATCHES "${CONTENT}")
    string(REGEX MATCHALL "[ \t]*#####:" UNEXECUTED_MATCHES "${CONTENT}")
    
    list(LENGTH EXECUTED_MATCHES FILE_EXECUTED)
    list(LENGTH UNEXECUTED_MATCHES UNEXECUTED_COUNT)
    
    math(EXPR FILE_LINES "${FILE_EXECUTED} + ${UNEXECUTED_COUNT}")
    
    if(FILE_LINES GREATER 0)
        math(EXPR COVERAGE_PERCENT "(${FILE_EXECUTED} * 100) / ${FILE_LINES}")
        
        math(EXPR TOTAL_LINES "${TOTAL_LINES} + ${FILE_LINES}")
        math(EXPR EXECUTED_LINES "${EXECUTED_LINES} + ${FILE_EXECUTED}")
        
        message("  ${SOURCE_NAME}")
        message("    Lines:    ${FILE_LINES}")
        message("    Executed: ${FILE_EXECUTED}")
        message("    Coverage: ${COVERAGE_PERCENT}%")
        message("")
    endif()
endforeach()

# Overall coverage
if(TOTAL_LINES GREATER 0)
    math(EXPR OVERALL_COVERAGE "(${EXECUTED_LINES} * 100) / ${TOTAL_LINES}")
    
    message("========================================")
    message("  Overall Coverage: ${OVERALL_COVERAGE}%")
    message("========================================")
    message("  Total Lines:      ${TOTAL_LINES}")
    message("  Executed Lines:   ${EXECUTED_LINES}")
    message("  Unexecuted Lines: $((${TOTAL_LINES} - ${EXECUTED_LINES}))")
    message("========================================")
else()
    message("[WARNING] No coverage data analyzed")
endif()

message("")
message("[SUCCESS] Coverage files generated in: ${COVERAGE_DIR}/")
message("")

# HTML generation
if(DEFINED GENERATE_HTML)
    message("[HTML] Generating HTML report...")
    
    # Determine coverage class
    set(COVERAGE_CLASS "low")
    if(NOT OVERALL_COVERAGE LESS 80)
        set(COVERAGE_CLASS "high")
    elseif(NOT OVERALL_COVERAGE LESS 50)
        set(COVERAGE_CLASS "medium")
    endif()
    
    # Get current timestamp
    string(TIMESTAMP DATE_STR "%Y-%m-%d %H:%M:%S")
    
    # Build HTML header
    set(HTML_CONTENT "<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\">
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
    <div class=\"header\">
        <h1>Code Coverage Report</h1>
        <p>Project: ${PROJECT_NAME}</p>
        <p>Generated: ${DATE_STR}</p>
    </div>
    
    <div class=\"summary\">
        <h2>Overall Coverage</h2>
        <div class=\"bar\">
            <div class=\"bar-fill\" style=\"width: ${OVERALL_COVERAGE}%;\"></div>
        </div>
        <p>Coverage: <span class=\"coverage-${COVERAGE_CLASS}\">${OVERALL_COVERAGE}%</span></p>
        <p>Lines: ${EXECUTED_LINES} / ${TOTAL_LINES}</p>
    </div>
    
    <div class=\"file-list\">
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
")
    
    # Add file rows
    file(GLOB GCOV_FILES "${COVERAGE_DIR}/*.gcov")
    foreach(GCOV_FILE ${GCOV_FILES})
        file(READ ${GCOV_FILE} CONTENT)
        get_filename_component(FILE_NAME ${GCOV_FILE} NAME)
        string(REPLACE ".gcov" "" SOURCE_NAME "${FILE_NAME}")
        
        set(FILE_LINES 0)
        set(FILE_EXECUTED 0)
        
        # Parse gcov format
        string(REGEX MATCHALL "[ \t]*[0-9]+:" EXECUTED_MATCHES "${CONTENT}")
        string(REGEX MATCHALL "[ \t]*#####:" UNEXECUTED_MATCHES "${CONTENT}")
        
        list(LENGTH EXECUTED_MATCHES FILE_EXECUTED)
        list(LENGTH UNEXECUTED_MATCHES UNEXECUTED_COUNT)
        
        math(EXPR FILE_LINES "${FILE_EXECUTED} + ${UNEXECUTED_COUNT}")
        
        if(FILE_LINES GREATER 0)
            math(EXPR FILE_COVERAGE "${FILE_EXECUTED} * 100 / ${FILE_LINES}")
            
            # Determine CSS class
            set(FILE_CSS_CLASS "low")
            if(NOT FILE_COVERAGE LESS 80)
                set(FILE_CSS_CLASS "high")
            elseif(NOT FILE_COVERAGE LESS 50)
                set(FILE_CSS_CLASS "medium")
            endif()
            
            # Add row to HTML
            string(APPEND HTML_CONTENT "
                <tr>
                    <td><a href=\"${FILE_NAME}\">${SOURCE_NAME}</a></td>
                    <td><span class=\"coverage-${FILE_CSS_CLASS}\">${FILE_COVERAGE}%</span></td>
                    <td>${FILE_EXECUTED} / ${FILE_LINES}</td>
                </tr>")
        endif()
    endforeach()
    
    # Close HTML
    string(APPEND HTML_CONTENT "
            </tbody>
        </table>
    </div>
</body>
</html>
")
    
    # Write HTML file
    file(WRITE "${COVERAGE_DIR}/index.html" "${HTML_CONTENT}")
    message("[HTML] Report generated: ${COVERAGE_DIR}/index.html")
    
    # Open in browser (platform-specific)
    if(WIN32)
        execute_process(
            COMMAND cmd /c start "" "${COVERAGE_DIR}/index.html"
            OUTPUT_QUIET
            ERROR_QUIET
        )
    elseif(APPLE)
        execute_process(
            COMMAND open "${COVERAGE_DIR}/index.html"
            OUTPUT_QUIET
            ERROR_QUIET
        )
    else()
        # Linux - try common browsers
        execute_process(
            COMMAND xdg-open "${COVERAGE_DIR}/index.html"
            OUTPUT_QUIET
            ERROR_QUIET
        )
    endif()
    
    message("")
endif()

message("Tip: View coverage files with any text editor")
message("     Each .gcov file shows line-by-line execution counts")
if(DEFINED GENERATE_HTML)
    message("     HTML report: ${COVERAGE_DIR}/index.html")
endif()
