# ==============================================================================
# mylib - Library CMakeLists.txt (self-contained)
# ==============================================================================
# This file is self-sufficient on purpose: after a `git subtree split
# --prefix=mylib`, this directory becomes the root of an exported branch and
# must be configurable/buildable on its own (cmake -S mylib -B build), without
# the test/dev infrastructure that lives in the parent repository.
#
# To rename this library, change the project name below and rename:
#   - inc/mylib.h -> inc/<new_name>.h
#   - src/mylib.c -> src/<new_name>.c (if using single-module convention)
#
# All CMake targets, exports, and install paths automatically follow the new
# project name via ${PROJECT_NAME}.
# ==============================================================================

cmake_minimum_required(VERSION 3.16)

project(mylib
    VERSION 2.1.0
    DESCRIPTION "Example library with unit testing template"
    LANGUAGES C
)

string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
option(INSTALL_SOURCES "Install source files for embedded integration" ON)
option(ENABLE_COVERAGE "Enable code coverage analysis" OFF)

# Directory containing the application-specific mylib_config.h (NOT part of this
# folder: per the library/app split, the real config lives in the consuming
# project). Defaults to the bundled template so mylib/ still configures
# standalone; set this BEFORE add_subdirectory(mylib) to point at your own cfg/.
set(${PROJECT_NAME_UPPER}_CONFIG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/config"
    CACHE PATH "Directory containing ${PROJECT_NAME}_config.h")

set(WARNING_FLAGS
    -Wall
    -Wextra
    -Wpedantic
    -Wformat=2
    -Wno-unused-parameter
)

set(${PROJECT_NAME_UPPER}_SOURCES
    src/mylib.c
)

set(${PROJECT_NAME_UPPER}_HEADERS
    inc/mylib.h
)

add_library(${PROJECT_NAME} ${${PROJECT_NAME_UPPER}_SOURCES} ${${PROJECT_NAME_UPPER}_HEADERS})

target_include_directories(${PROJECT_NAME}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/inc>
        $<BUILD_INTERFACE:${${PROJECT_NAME_UPPER}_CONFIG_DIR}>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/private
)

target_compile_options(${PROJECT_NAME} PRIVATE ${WARNING_FLAGS})

if(ENABLE_COVERAGE)
    message(STATUS "Code coverage enabled")
    target_compile_options(${PROJECT_NAME} PRIVATE --coverage -fprofile-arcs -ftest-coverage)
    target_link_options(${PROJECT_NAME} PRIVATE --coverage)
endif()

set_target_properties(${PROJECT_NAME} PROPERTIES
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR}
    PUBLIC_HEADER "${${PROJECT_NAME_UPPER}_HEADERS}"
)

# ==============================================================================
# Installation
# ==============================================================================

include(GNUInstallDirs)

install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME}Targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/${PROJECT_NAME}
)

if(INSTALL_SOURCES)
    install(DIRECTORY src/
        DESTINATION ${CMAKE_INSTALL_PREFIX}/src/${PROJECT_NAME}
        FILES_MATCHING PATTERN "*.c"
        PATTERN "private" EXCLUDE
    )
    message(STATUS "Source installation enabled (for embedded integration)")
endif()

install(DIRECTORY config/
    DESTINATION ${CMAKE_INSTALL_PREFIX}/config/${PROJECT_NAME}
    FILES_MATCHING PATTERN "*.template"
)

install(EXPORT ${PROJECT_NAME}Targets
    FILE ${PROJECT_NAME}Targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}
)
