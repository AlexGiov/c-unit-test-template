# ==============================================================================
# Unit Test Template - Main CMakeLists.txt
# ==============================================================================
# Professional template for C library unit testing with CMocka
# ==============================================================================

cmake_minimum_required(VERSION 3.10)

# Project information
project(mylib
    VERSION 1.0.0
    DESCRIPTION "Example library with unit testing template"
    LANGUAGES C
)

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
# Library: mylib
# ==============================================================================

# Source files
set(MYLIB_SOURCES
    src/math_utils.c
)

# Header files (for IDE support)
set(MYLIB_HEADERS
    include/mylib/math_utils.h
)

# Create library
add_library(mylib ${MYLIB_SOURCES} ${MYLIB_HEADERS})

# Include directories
target_include_directories(mylib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/private
)

# Compiler flags for library
target_compile_options(mylib PRIVATE ${WARNING_FLAGS})

# Code coverage support
if(ENABLE_COVERAGE)
    message(STATUS "Code coverage enabled")
    target_compile_options(mylib PRIVATE --coverage -fprofile-arcs -ftest-coverage)
    target_link_options(mylib PRIVATE --coverage)
endif()

# Set library properties
set_target_properties(mylib PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    PUBLIC_HEADER "${MYLIB_HEADERS}"
)

# ==============================================================================
# Installation
# ==============================================================================

include(GNUInstallDirs)

# Install library
install(TARGETS mylib
    EXPORT mylibTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/mylib
)

# Install headers
install(DIRECTORY include/mylib
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.h"
)

# Install sources (for embedded projects)
if(INSTALL_SOURCES)
    install(DIRECTORY src/
        DESTINATION ${CMAKE_INSTALL_PREFIX}/src/mylib
        FILES_MATCHING PATTERN "*.c"
        PATTERN "private" EXCLUDE
    )
    message(STATUS "Source installation enabled (for embedded integration)")
endif()

# Install CMake config files
install(EXPORT mylibTargets
    FILE mylibTargets.cmake
    NAMESPACE mylib::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mylib
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
