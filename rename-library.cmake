# ==============================================================================
# Rename Library Script - CMake Cross-Platform
# ==============================================================================
# Renames the template library to a new name
# 
# With the new CMake-based approach, renaming is much simpler:
# - Change project() name in CMakeLists.txt AND mylib/CMakeLists.txt (both must
#   stay in sync, see mylib/CMakeLists.txt header comment)
# - Rename mylib/include/ directory
# - Rename source files (optional, recommended for single-module libraries)
# - Update #include statements
# - Update README references
#
# Usage: cmake -DNEW_NAME=my_new_library -P rename-library.cmake
# ==============================================================================

cmake_minimum_required(VERSION 3.16)

# ==============================================================================
# USAGE
# ==============================================================================
# 
# SYNTAX:
#   cmake -DNEW_NAME=<library_name> -P rename-library.cmake
#
# PARAMETERS (set via -D flag BEFORE -P):
#   -DNEW_NAME=<name>    New library name (letters, numbers, underscores only)
#                        Must start with letter or underscore
#   -DHELP=ON            Show this help message
#
# EXAMPLES:
#   cmake -DNEW_NAME=sensor_driver -P rename-library.cmake
#   cmake -DNEW_NAME=uart_hal -P rename-library.cmake
#
# WHAT IT DOES (Simplified with CMake variables):
#   1. Updates project() name in CMakeLists.txt and mylib/CMakeLists.txt
#   2. Renames mylib/include/mylib.h -> mylib/include/<NEW_NAME>.h
#   3. Renames source files (recommended for single-module)
#   4. Updates #include statements and README.md references
#
#   All CMake targets auto-update via ${PROJECT_NAME}!
#
# NOTE: Run this in a fresh clone of the template!
#
# ==============================================================================

# Show help
if(DEFINED HELP)
    message("")
    message("USAGE:")
    message("  cmake -DNEW_NAME=<library_name> -P rename-library.cmake")
    message("")
    message("PARAMETERS:")
    message("  -DNEW_NAME=<name>    New library name (letters, numbers, underscores only)")
    message("                       Must start with letter or underscore")
    message("  -DHELP=ON            Show this help message")
    message("")
    message("EXAMPLES:")
    message("  cmake -DNEW_NAME=sensor_driver -P rename-library.cmake")
    message("  cmake -DNEW_NAME=uart_hal -P rename-library.cmake")
    message("")
    message("WHAT IT DOES (Simplified with CMake variables):")
    message("  1. Updates project() name in CMakeLists.txt and mylib/CMakeLists.txt")
    message("  2. Renames mylib/include/mylib.h -> mylib/include/<NEW_NAME>.h")
    message("  3. Renames source files (recommended for single-module)")
    message("  4. Updates #include statements and README.md references")
    message("")
    message("  All CMake targets auto-update via \${PROJECT_NAME}!")
    message("")
    message("NOTE: Run this in a fresh clone of the template!")
    message("")
    return()
endif()

# Check if NEW_NAME is provided
if(NOT DEFINED NEW_NAME)
    message("")
    message(FATAL_ERROR 
        "[ERROR] Missing required parameter: -DNEW_NAME\n"
        "\n"
        "Use -DHELP=ON for usage information.\n"
    )
endif()

# Validate NEW_NAME format (must be valid C identifier)
if(NOT NEW_NAME MATCHES "^[a-zA-Z_][a-zA-Z0-9_]*$")
    message(FATAL_ERROR 
        "[ERROR] Invalid library name: ${NEW_NAME}\n"
        "  Name must:\n"
        "  - Start with letter or underscore\n"
        "  - Contain only letters, numbers, underscores\n"
        "  Examples: sensor_driver, uart_hal, MyLib\n"
    )
endif()

# Safety check: warn if running in template repository
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/.git")
    execute_process(
        COMMAND git remote get-url origin
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE GIT_REMOTE
        ERROR_QUIET
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    if(GIT_REMOTE MATCHES "unit.?test.?template")
        message("")
        message(WARNING 
            "[WARNING] You appear to be in the template repository!\n"
            "This script should be run in a CLONE of the template, not the template itself.\n"
            "\n"
            "Expected workflow:\n"
            "  1. git clone <template-url> my-new-library\n"
            "  2. cd my-new-library\n"
            "  3. cmake -DNEW_NAME=my_new_library -P rename-library.cmake\n"
        )
        message("")
        message("Press Ctrl+C to abort or wait 5 seconds to continue...")
        execute_process(COMMAND ${CMAKE_COMMAND} -E sleep 5)
    endif()
endif()

# ==============================================================================
# Helper Functions
# ==============================================================================

function(get_current_project_name OUTPUT_VAR)
    # Read project name from CMakeLists.txt
    if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt")
        file(READ "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" CONTENT)
        if(CONTENT MATCHES "project[ \t]*\\([ \t]*([A-Za-z0-9_]+)")
            set(${OUTPUT_VAR} "${CMAKE_MATCH_1}" PARENT_SCOPE)
        else()
            set(${OUTPUT_VAR} "mylib" PARENT_SCOPE)
        endif()
    else()
        set(${OUTPUT_VAR} "mylib" PARENT_SCOPE)
    endif()
endfunction()

function(get_current_module_name OUTPUT_VAR)
    # Find first .c file in mylib/src/ directory
    file(GLOB SRC_FILES "${CMAKE_CURRENT_LIST_DIR}/mylib/src/*.c")
    if(SRC_FILES)
        list(GET SRC_FILES 0 FIRST_FILE)
        get_filename_component(MODULE_NAME "${FIRST_FILE}" NAME_WE)
        set(${OUTPUT_VAR} "${MODULE_NAME}" PARENT_SCOPE)
    else()
        set(${OUTPUT_VAR} "mylib" PARENT_SCOPE)
    endif()
endfunction()

# ==============================================================================
# Auto-detect current names
# ==============================================================================

get_current_project_name(OLD_NAME)
get_current_module_name(OLD_MODULE)

string(TOUPPER ${OLD_NAME} OLD_NAME_UPPER)
string(TOUPPER ${NEW_NAME} NEW_NAME_UPPER)

message("")
message("========================================")
message("  Library Rename Tool (Cross-Platform)")
message("========================================")
message("")
message("Detected current library: '${OLD_NAME}' (module: '${OLD_MODULE}')")
message("Renaming to: '${NEW_NAME}'")
message("")

# ==============================================================================
# STEP 1: Update project() declaration in CMakeLists.txt
# ==============================================================================
message("[1/4] Updating CMakeLists.txt project() declaration...")

file(READ "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" ROOT_CMAKE)

# Update project() declaration - handle newlines and whitespace
# Match: project(OLD_NAME followed by newline, space, tab, or closing paren
string(REGEX REPLACE 
    "project[ \t]*\\([ \t\n]*${OLD_NAME}([ \t\n])"
    "project(${NEW_NAME}\\1"
    ROOT_CMAKE 
    "${ROOT_CMAKE}"
)

# Update source file references
string(REPLACE "src/${OLD_MODULE}.c" "src/${NEW_NAME}.c" ROOT_CMAKE "${ROOT_CMAKE}")

file(WRITE "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" "${ROOT_CMAKE}")
message("  - Changed project(${OLD_NAME}) -> project(${NEW_NAME}) in CMakeLists.txt")

# mylib/CMakeLists.txt must stay in sync (it is self-sufficient, see its header comment)
file(READ "${CMAKE_CURRENT_LIST_DIR}/mylib/CMakeLists.txt" MYLIB_CMAKE)

string(REGEX REPLACE 
    "project[ \t]*\\([ \t\n]*${OLD_NAME}([ \t\n])"
    "project(${NEW_NAME}\\1"
    MYLIB_CMAKE 
    "${MYLIB_CMAKE}"
)

# Update source/header references (include/oldfile.h -> include/newfile.h, flat - no namespace subfolder)
string(REPLACE "src/${OLD_MODULE}.c" "src/${NEW_NAME}.c" MYLIB_CMAKE "${MYLIB_CMAKE}")
string(REPLACE "include/${OLD_MODULE}.h" "include/${NEW_NAME}.h" MYLIB_CMAKE "${MYLIB_CMAKE}")

file(WRITE "${CMAKE_CURRENT_LIST_DIR}/mylib/CMakeLists.txt" "${MYLIB_CMAKE}")
message("  - Changed project(${OLD_NAME}) -> project(${NEW_NAME}) in mylib/CMakeLists.txt")
message("    All CMake targets auto-update via \${PROJECT_NAME}!")

# ==============================================================================
# STEP 2: Rename source and header files (recommended for single-module libraries)
# ==============================================================================
message("[2/4] Renaming source and header files...")

# Rename header file (flat, directly under mylib/include/ - no namespace subfolder)
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/mylib/include/${OLD_MODULE}.h")
    message("  mylib/include/${OLD_MODULE}.h -> ${NEW_NAME}.h")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/mylib/include/${OLD_MODULE}.h"
        "${CMAKE_CURRENT_LIST_DIR}/mylib/include/${NEW_NAME}.h"
    )
endif()

# Rename source file
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/mylib/src/${OLD_MODULE}.c")
    message("  mylib/src/${OLD_MODULE}.c -> ${NEW_NAME}.c")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/mylib/src/${OLD_MODULE}.c"
        "${CMAKE_CURRENT_LIST_DIR}/mylib/src/${NEW_NAME}.c"
    )
endif()

# Rename test file
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/test/unit/test_${OLD_MODULE}.c")
    message("  test/unit/test_${OLD_MODULE}.c -> test_${NEW_NAME}.c")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/test/unit/test_${OLD_MODULE}.c"
        "${CMAKE_CURRENT_LIST_DIR}/test/unit/test_${NEW_NAME}.c"
    )
endif()

# ==============================================================================
# STEP 3: Configuration files (intentionally NOT renamed)
# ==============================================================================
# mylib.h/mylib.c always do `#include "mylib_config.h"` (a fixed literal name,
# not derived from ${PROJECT_NAME}), and its macros (e.g. MYLIB_DIV_BY_ZERO_RETURN)
# are likewise fixed literals in the source. Renaming mylib_config.h or its
# macros here would silently break the build, so both mylib/config/mylib_config.h.template
# and cfg/mylib_config.h keep their name across a library rename.
message("[3/4] Configuration files: kept as mylib_config.h (see mylib.h #include)...")

# ==============================================================================
# STEP 4: Update #include statements and file contents
# ==============================================================================
message("[4/4] Updating file contents...")

# Update header file
set(HEADER_PATH "${CMAKE_CURRENT_LIST_DIR}/mylib/include/${NEW_NAME}.h")
if(EXISTS "${HEADER_PATH}")
    file(READ "${HEADER_PATH}" HEADER_CONTENT)
    
    string(TOUPPER "${OLD_MODULE}" OLD_MODULE_UPPER)
    set(OLD_GUARD "${OLD_MODULE_UPPER}_H")
    set(NEW_GUARD "${NEW_NAME_UPPER}_H")
    
    string(REPLACE "${OLD_GUARD}" "${NEW_GUARD}" HEADER_CONTENT "${HEADER_CONTENT}")
    string(REGEX REPLACE "\\* @file[ \t]+${OLD_MODULE}\\.h" "* @file ${NEW_NAME}.h" HEADER_CONTENT "${HEADER_CONTENT}")
    
    file(WRITE "${HEADER_PATH}" "${HEADER_CONTENT}")
    message("  - Updated ${HEADER_PATH}")
endif()

# Update source file
set(SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}/mylib/src/${NEW_NAME}.c")
if(EXISTS "${SOURCE_PATH}")
    file(READ "${SOURCE_PATH}" SOURCE_CONTENT)
    
    string(REPLACE "#include \"${OLD_MODULE}.h\"" "#include \"${NEW_NAME}.h\"" SOURCE_CONTENT "${SOURCE_CONTENT}")
    string(REGEX REPLACE "\\* @file[ \t]+${OLD_MODULE}\\.c" "* @file ${NEW_NAME}.c" SOURCE_CONTENT "${SOURCE_CONTENT}")
    
    file(WRITE "${SOURCE_PATH}" "${SOURCE_CONTENT}")
    message("  - Updated ${SOURCE_PATH}")
endif()

# Update test file
set(TEST_PATH "${CMAKE_CURRENT_LIST_DIR}/test/unit/test_${NEW_NAME}.c")
if(EXISTS "${TEST_PATH}")
    file(READ "${TEST_PATH}" TEST_CONTENT)
    
    string(REPLACE "#include \"${OLD_MODULE}.h\"" "#include \"${NEW_NAME}.h\"" TEST_CONTENT "${TEST_CONTENT}")
    string(REGEX REPLACE "\\* @file[ \t]+test_${OLD_MODULE}\\.c" "* @file test_${NEW_NAME}.c" TEST_CONTENT "${TEST_CONTENT}")
    
    file(WRITE "${TEST_PATH}" "${TEST_CONTENT}")
    message("  - Updated ${TEST_PATH}")
endif()

# Update README.md
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/README.md")
    file(READ "${CMAKE_CURRENT_LIST_DIR}/README.md" README_CONTENT)
    
    string(REPLACE "${OLD_NAME}" "${NEW_NAME}" README_CONTENT "${README_CONTENT}")
    string(REPLACE "${OLD_MODULE}" "${NEW_NAME}" README_CONTENT "${README_CONTENT}")
    
    file(WRITE "${CMAKE_CURRENT_LIST_DIR}/README.md" "${README_CONTENT}")
    message("  - Updated README.md")
endif()

# Update test/CMakeLists.txt - set TEST_MODULE_NAME variable
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/test/CMakeLists.txt")
    file(READ "${CMAKE_CURRENT_LIST_DIR}/test/CMakeLists.txt" TEST_CMAKE)
    
    # Update TEST_MODULE_NAME variable
    string(REGEX REPLACE "set\\(TEST_MODULE_NAME[ \t]+\"[^\"]+\"\\)" "set(TEST_MODULE_NAME \"${NEW_NAME}\")" TEST_CMAKE "${TEST_CMAKE}")
    
    file(WRITE "${CMAKE_CURRENT_LIST_DIR}/test/CMakeLists.txt" "${TEST_CMAKE}")
    message("  - Updated test/CMakeLists.txt (TEST_MODULE_NAME)")
endif()

# Update .vscode/launch.json
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/.vscode/launch.json")
    file(READ "${CMAKE_CURRENT_LIST_DIR}/.vscode/launch.json" LAUNCH_JSON)
    
    # Update test executable paths
    string(REPLACE "test_${OLD_MODULE}.exe" "test_${NEW_NAME}.exe" LAUNCH_JSON "${LAUNCH_JSON}")
    
    file(WRITE "${CMAKE_CURRENT_LIST_DIR}/.vscode/launch.json" "${LAUNCH_JSON}")
    message("  - Updated .vscode/launch.json")
endif()

# ==============================================================================
# Clean build directory (avoid CMakeCache conflicts)
# ==============================================================================
message("")
message("[CLEANUP] Removing build directory to avoid CMake cache conflicts...")

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/build")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/build")
    message("  - Removed build/ directory")
endif()

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/bin")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/bin")
    message("  - Removed bin/ directory")
endif()

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/lib")
    file(REMOVE_RECURSE "${CMAKE_CURRENT_LIST_DIR}/lib")
    message("  - Removed lib/ directory")
endif()

# ==============================================================================
# COMPLETION
# ==============================================================================
message("")
message("========================================")
message("  Rename Complete!")
message("========================================")
message("")
message("Library renamed: '${OLD_NAME}' -> '${NEW_NAME}'")
message("")
message("What was changed:")
message("  - project() declaration in CMakeLists.txt and mylib/CMakeLists.txt")
message("  - Source file references in mylib/CMakeLists.txt")
message("  - TEST_MODULE_NAME in test/CMakeLists.txt")
message("  - mylib/include/${OLD_NAME}.h -> mylib/include/${NEW_NAME}.h")
message("  - Source files: ${OLD_MODULE}.* -> ${NEW_NAME}.*")
message("  - #include statements updated")
message("  - .vscode/launch.json test executable paths")
message("  - README.md references updated")
message("")
message("What updated automatically (via \${PROJECT_NAME}):")
message("  - All CMake library targets")
message("  - All install paths and exports")
message("  - Package configuration files")
message("")
message("NEXT STEPS:")
message("  1. Test the build:    cmake -DRUN_TESTS=ON -P build.cmake")
message("  2. Review changes:    git status")
message("  3. Update README.md with library-specific details")
message("  4. Implement your functions in mylib/src/${NEW_NAME}.c")
message("")
message("NOTE: Build directories cleaned - fresh build will be performed")
message("")
