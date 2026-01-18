# ==============================================================================
# Unit Test Template - Main CMakeLists.txt
# ==============================================================================
# Professional template for C library unit testing with CMocka
# ==============================================================================

cmake_minimum_required(VERSION 3.10)

# ==============================================================================
# PROJECT CONFIGURATION
# ==============================================================================
# To rename this library, change the project name below and rename:
#   - include/mylib/ → include/<new_name>/
#   - src/mylib.c → src/<new_name>.c (if using single-module convention)
#   - test/unit/test_mylib.c → test/unit/test_<new_name>.c
#
# All CMake targets, exports, and install paths will automatically use the
# new project name via ${PROJECT_NAME} variable.

project(mylib
    VERSION 1.0.0
    DESCRIPTION "Example library with unit testing template"
    LANGUAGES C
)

# Derived variables (auto-configured from project name)
string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER)

# C Standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

# Build options
option(BUILD_TESTING "Build unit tests" ON)
option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(INSTALL_SOURCES "Install source files for embedded integration" ON)
option(ENABLE_COVERAGE "Enable code coverage analysis" OFF)

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib)

# ==============================================================================
# Compiler flags
# ==============================================================================

# Warning flags
set(WARNING_FLAGS
    -Wall
    -Wextra
    -Wpedantic
    -Wformat=2
    -Wno-unused-parameter
)

# Debug flags
set(CMAKE_C_FLAGS_DEBUG "-g -O0 -DDEBUG")

# Release flags
set(CMAKE_C_FLAGS_RELEASE "-O3 -DNDEBUG")

# ==============================================================================
# Library: ${PROJECT_NAME}
# ==============================================================================

# Source files
# Note: For single-module libraries, name your main file src/${PROJECT_NAME}.c
# For multi-module libraries, list all source files explicitly
# Example shown below uses math_utils.c - rename to match your library
set(${PROJECT_NAME_UPPER}_SOURCES
    src/math_utils.c
)

# Header files (for IDE support)
# Example shown below uses math_utils.h - rename to match your library
set(${PROJECT_NAME_UPPER}_HEADERS
    include/${PROJECT_NAME}/math_utils.h
)

# Create library
add_library(${PROJECT_NAME} ${${PROJECT_NAME_UPPER}_SOURCES} ${${PROJECT_NAME_UPPER}_HEADERS})

# Include directories
target_include_directories(${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/private
)

# Compiler flags for library
target_compile_options(${PROJECT_NAME} PRIVATE ${WARNING_FLAGS})

# Code coverage support
if(ENABLE_COVERAGE)
    message(STATUS "Code coverage enabled")
    target_compile_options(${PROJECT_NAME} PRIVATE --coverage -fprofile-arcs -ftest-coverage)
    target_link_options(${PROJECT_NAME} PRIVATE --coverage)
endif()

# Set library properties
set_target_properties(${PROJECT_NAME} PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    PUBLIC_HEADER "${${PROJECT_NAME_UPPER}_HEADERS}"
)

# ==============================================================================
# Installation
# ==============================================================================

include(GNUInstallDirs)

# Install library
install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
)

# Install headers
install(DIRECTORY include/${PROJECT_NAME}
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.h"
)

# Install sources (for embedded projects)
if(INSTALL_SOURCES)
    install(DIRECTORY src/
        DESTINATION ${CMAKE_INSTALL_PREFIX}/src/${PROJECT_NAME}
        FILES_MATCHING PATTERN "*.c"
        PATTERN "private" EXCLUDE
    )
    message(STATUS "Source installation enabled (for embedded integration)")
endif()

# Install CMake config files
install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)

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
message(STATUS "Install sources:  ${INSTALL_SOURCES}")
message(STATUS "========================================")
message(STATUS "")
