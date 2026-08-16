# ==============================================================================
# Unit Test Template - Main CMakeLists.txt
# ==============================================================================
# Professional template for C library unit testing with CMocka
#
# The library itself lives entirely under mylib/ (mylib/inc, mylib/src,
# mylib/config, mylib/CMakeLists.txt) so that folder alone is self-sufficient
# and can be exported to other repositories (e.g. via `git subtree split
# --prefix=mylib`) without dragging along this test/dev infrastructure.
#
# This root CMakeLists.txt is a thin orchestrator: it wires the dev-only
# configuration (cfg/) to the library and builds the CMocka-based test suite.
#
# The project() declaration below must stay in sync with the one in
# mylib/CMakeLists.txt (name + version). Renaming: update both files, plus
# mylib/inc/<old_name>/ -> mylib/inc/<new_name>/.
# ==============================================================================

cmake_minimum_required(VERSION 3.10)

project(mylib
    VERSION 3.0.0
    DESCRIPTION "Example library with unit testing template"
    LANGUAGES C
)

string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER)

# Build options
option(BUILD_TESTING "Build unit tests" ON)
option(ENABLE_COVERAGE "Enable code coverage analysis" OFF)

# Verify Ninja generator is being used
if(NOT CMAKE_GENERATOR MATCHES "Ninja")
    message(WARNING 
        "This project requires Ninja build system.\n"
        "  Current generator: ${CMAKE_GENERATOR}\n"
        "  Use a preset instead: cmake --preset ucrt64 (Windows) / cmake --preset linux-gcc (Linux)\n"
    )
endif()

# C Standard (inherited by mylib/ and test/ subdirectories)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Output directories (shared by mylib/ and test/)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)

# Debug/Release flags
set(CMAKE_C_FLAGS_DEBUG "-g -O0 -DDEBUG")
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")

# ==============================================================================
# Library: mylib/ (self-contained, see mylib/CMakeLists.txt)
# ==============================================================================
# cfg/ is the dev/test-only configuration (NOT part of the mylib/ deliverable,
# see README_LIBRARY_STRUCTURE.md): point mylib at it before adding the subdirectory.
set(${PROJECT_NAME_UPPER}_CONFIG_DIR "${CMAKE_SOURCE_DIR}/cfg"
    CACHE PATH "Directory containing ${PROJECT_NAME}_config.h" FORCE)

add_subdirectory(mylib)

# ==============================================================================
# Testing
# ==============================================================================

if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(test)
    message(STATUS "Unit testing enabled")
endif()

# ==============================================================================
# Summary
# ==============================================================================

message(STATUS "")
message(STATUS "========================================")
message(STATUS "  ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "========================================")
message(STATUS "Build type:       ${CMAKE_BUILD_TYPE}")
message(STATUS "C Compiler:       ${CMAKE_C_COMPILER}")
message(STATUS "Install prefix:   ${CMAKE_INSTALL_PREFIX}")
message(STATUS "Build testing:    ${BUILD_TESTING}")
message(STATUS "Code coverage:    ${ENABLE_COVERAGE}")
message(STATUS "========================================")
message(STATUS "")

