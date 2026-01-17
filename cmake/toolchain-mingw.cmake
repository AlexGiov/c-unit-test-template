# ==============================================================================
# MinGW-w64 Toolchain File
# ==============================================================================
# This file configures CMake to use MinGW-w64 GCC compiler
#
# Usage:
#   cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw.cmake
#
# Note: Adjust paths if your MinGW installation is in a different location
# ==============================================================================

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# Compiler paths - Update these if your MinGW is installed elsewhere
set(MINGW_ROOT "C:/devbin/mingw/mingw64/8.1.0")

# Compilers
set(CMAKE_C_COMPILER   "${MINGW_ROOT}/bin/gcc.exe")
set(CMAKE_CXX_COMPILER "${MINGW_ROOT}/bin/g++.exe")
set(CMAKE_AR           "${MINGW_ROOT}/bin/ar.exe")
set(CMAKE_RANLIB       "${MINGW_ROOT}/bin/ranlib.exe")

# Debugger (optional, for reference)
set(CMAKE_GDB          "${MINGW_ROOT}/bin/gdb.exe")

# Search paths
set(CMAKE_FIND_ROOT_PATH "${MINGW_ROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Compiler flags
set(CMAKE_C_FLAGS_INIT "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_INIT "-Wall -Wextra")

# Build type defaults
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type (Debug, Release, RelWithDebInfo, MinSizeRel)" FORCE)
endif()

message(STATUS "Using MinGW-w64 toolchain from: ${MINGW_ROOT}")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
