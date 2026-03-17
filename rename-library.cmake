# ==============================================================================
# Rename Library Script - CMake Cross-Platform
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
#   1. Updates project() name in CMakeLists.txt
#   2. Renames include/mylib/ -> include/<NEW_NAME>/
#   3. Renames source files (recommended for single-module)
#   4. Updates #include statements
#   5. Updates README.md references
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
    message("  1. Updates project() name in CMakeLists.txt")
    message("  2. Renames include/mylib/ -> include/<NEW_NAME>/")
    message("  3. Renames source files (recommended for single-module)")
    message("  4. Updates #include statements")
    message("  5. Updates README.md references")
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
    # Find first .c file in src/ directory
    file(GLOB SRC_FILES "${CMAKE_CURRENT_LIST_DIR}/src/*.c")
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
message("[1/5] Updating CMakeLists.txt project() declaration...")

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

# Update header references - handle multiple formats:
# 1. include/${PROJECT_NAME}/oldfile.h (variable-based)
# 2. include/oldname/oldfile.h (hardcoded old name)
# Both should become: include/${PROJECT_NAME}/newfile.h

# For hardcoded paths (include/mylib/mylib.h -> include/${PROJECT_NAME}/sensor_driver.h)
string(REGEX REPLACE 
    "include/${OLD_NAME}/${OLD_MODULE}\\.h"
    "include/\${PROJECT_NAME}/${NEW_NAME}.h"
    ROOT_CMAKE 
    "${ROOT_CMAKE}"
)

# For variable-based paths (include/${PROJECT_NAME}/mylib.h -> include/${PROJECT_NAME}/sensor_driver.h)
string(REGEX REPLACE 
    "include/\\\$\\{PROJECT_NAME\\}/${OLD_MODULE}\\.h"
    "include/\${PROJECT_NAME}/${NEW_NAME}.h"
    ROOT_CMAKE 
    "${ROOT_CMAKE}"
)

file(WRITE "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt" "${ROOT_CMAKE}")
message("  - Changed project(${OLD_NAME}) -> project(${NEW_NAME})")
message("    All CMake targets auto-update via \${PROJECT_NAME}!")

# ==============================================================================
# STEP 2: Rename include directory
# ==============================================================================
message("[2/5] Renaming include directory...")

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/include/${OLD_NAME}")
    message("  include/${OLD_NAME} -> include/${NEW_NAME}")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/include/${OLD_NAME}" 
        "${CMAKE_CURRENT_LIST_DIR}/include/${NEW_NAME}"
    )
endif()

# ==============================================================================
# STEP 3: Rename source files (recommended for single-module libraries)
# ==============================================================================
message("[3/5] Renaming source files...")

# Rename header file
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/include/${NEW_NAME}/${OLD_MODULE}.h")
    message("  include/${NEW_NAME}/${OLD_MODULE}.h -> ${NEW_NAME}.h")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/include/${NEW_NAME}/${OLD_MODULE}.h"
        "${CMAKE_CURRENT_LIST_DIR}/include/${NEW_NAME}/${NEW_NAME}.h"
    )
endif()

# Rename source file
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/src/${OLD_MODULE}.c")
    message("  src/${OLD_MODULE}.c -> ${NEW_NAME}.c")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/src/${OLD_MODULE}.c"
        "${CMAKE_CURRENT_LIST_DIR}/src/${NEW_NAME}.c"
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
# STEP 4: Rename configuration files
# ==============================================================================
message("[4/5] Renaming configuration files...")

# Rename config template file
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/config/${OLD_MODULE}_config.h.template")
    message("  config/${OLD_MODULE}_config.h.template -> ${NEW_NAME}_config.h.template")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/config/${OLD_MODULE}_config.h.template"
        "${CMAKE_CURRENT_LIST_DIR}/config/${NEW_NAME}_config.h.template"
    )
endif()

# Rename actual config file
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/cfg/${OLD_MODULE}_config.h")
    message("  cfg/${OLD_MODULE}_config.h -> ${NEW_NAME}_config.h")
    file(RENAME 
        "${CMAKE_CURRENT_LIST_DIR}/cfg/${OLD_MODULE}_config.h"
        "${CMAKE_CURRENT_LIST_DIR}/cfg/${NEW_NAME}_config.h"
    )
endif()

# ==============================================================================
# STEP 5: Update #include statements and file contents
# ==============================================================================
message("[5/5] Updating file contents...")

# Update header file
set(HEADER_PATH "${CMAKE_CURRENT_LIST_DIR}/include/${NEW_NAME}/${NEW_NAME}.h")
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
set(SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}/src/${NEW_NAME}.c")
if(EXISTS "${SOURCE_PATH}")
    file(READ "${SOURCE_PATH}" SOURCE_CONTENT)
    
    string(REPLACE "#include \"${OLD_NAME}/${OLD_MODULE}.h\"" "#include \"${NEW_NAME}/${NEW_NAME}.h\"" SOURCE_CONTENT "${SOURCE_CONTENT}")
    string(REGEX REPLACE "\\* @file[ \t]+${OLD_MODULE}\\.c" "* @file ${NEW_NAME}.c" SOURCE_CONTENT "${SOURCE_CONTENT}")
    
    file(WRITE "${SOURCE_PATH}" "${SOURCE_CONTENT}")
    message("  - Updated ${SOURCE_PATH}")
endif()

# Update test file
set(TEST_PATH "${CMAKE_CURRENT_LIST_DIR}/test/unit/test_${NEW_NAME}.c")
if(EXISTS "${TEST_PATH}")
    file(READ "${TEST_PATH}" TEST_CONTENT)
    
    string(REPLACE "#include \"${OLD_NAME}/${OLD_MODULE}.h\"" "#include \"${NEW_NAME}/${NEW_NAME}.h\"" TEST_CONTENT "${TEST_CONTENT}")
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

# Update config template file
set(CONFIG_TEMPLATE_PATH "${CMAKE_CURRENT_LIST_DIR}/config/${NEW_NAME}_config.h.template")
if(EXISTS "${CONFIG_TEMPLATE_PATH}")
    file(READ "${CONFIG_TEMPLATE_PATH}" CONFIG_TEMPLATE_CONTENT)
    
    # Update header guard
    string(TOUPPER "${OLD_MODULE}" OLD_MODULE_UPPER)
    string(TOUPPER "${NEW_NAME}" NEW_CONFIG_UPPER)
    string(REPLACE "${OLD_MODULE_UPPER}_CONFIG_H" "${NEW_CONFIG_UPPER}_CONFIG_H" CONFIG_TEMPLATE_CONTENT "${CONFIG_TEMPLATE_CONTENT}")
    
    # Update file name references in comments
    string(REPLACE "${OLD_MODULE}_config.h" "${NEW_NAME}_config.h" CONFIG_TEMPLATE_CONTENT "${CONFIG_TEMPLATE_CONTENT}")
    
    # Update library name references
    string(REPLACE "${OLD_MODULE}" "${NEW_NAME}" CONFIG_TEMPLATE_CONTENT "${CONFIG_TEMPLATE_CONTENT}")
    
    # Update macro prefixes (e.g., MYLIB_DIV_BY_ZERO_RETURN -> NEWNAME_DIV_BY_ZERO_RETURN)
    string(REPLACE "${OLD_MODULE_UPPER}_" "${NEW_CONFIG_UPPER}_" CONFIG_TEMPLATE_CONTENT "${CONFIG_TEMPLATE_CONTENT}")
    
    file(WRITE "${CONFIG_TEMPLATE_PATH}" "${CONFIG_TEMPLATE_CONTENT}")
    message("  - Updated ${CONFIG_TEMPLATE_PATH}")
endif()

# Update actual config file
set(CONFIG_PATH "${CMAKE_CURRENT_LIST_DIR}/cfg/${NEW_NAME}_config.h")
if(EXISTS "${CONFIG_PATH}")
    file(READ "${CONFIG_PATH}" CONFIG_CONTENT)
    
    # Update header guard
    string(TOUPPER "${OLD_MODULE}" OLD_MODULE_UPPER)
    string(TOUPPER "${NEW_NAME}" NEW_CONFIG_UPPER)
    string(REPLACE "${OLD_MODULE_UPPER}_CONFIG_H" "${NEW_CONFIG_UPPER}_CONFIG_H" CONFIG_CONTENT "${CONFIG_CONTENT}")
    
    # Update file name references in comments
    string(REPLACE "${OLD_MODULE}_config.h" "${NEW_NAME}_config.h" CONFIG_CONTENT "${CONFIG_CONTENT}")
    
    # Update library name references
    string(REPLACE "${OLD_MODULE}" "${NEW_NAME}" CONFIG_CONTENT "${CONFIG_CONTENT}")
    
    # Update macro prefixes (e.g., MYLIB_DIV_BY_ZERO_RETURN -> NEWNAME_DIV_BY_ZERO_RETURN)
    string(REPLACE "${OLD_MODULE_UPPER}_" "${NEW_CONFIG_UPPER}_" CONFIG_CONTENT "${CONFIG_CONTENT}")
    
    file(WRITE "${CONFIG_PATH}" "${CONFIG_CONTENT}")
    message("  - Updated ${CONFIG_PATH}")
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
message("  - project() declaration in CMakeLists.txt")
message("  - Source file references in CMakeLists.txt")
message("  - TEST_MODULE_NAME in test/CMakeLists.txt")
message("  - include/${OLD_NAME}/ directory -> include/${NEW_NAME}/")
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
message("  4. Implement your functions in src/${NEW_NAME}.c")
message("")
message("NOTE: Build directories cleaned - fresh build will be performed")
message("")
