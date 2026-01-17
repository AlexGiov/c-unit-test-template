# CMake Configuration Files

This directory contains CMake configuration files and modules.

## Files

### `toolchain-mingw.cmake`
Toolchain file for MinGW-w64 GCC compiler on Windows.

**Usage:**
```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw.cmake
```

**Configuration:**
If your MinGW installation is in a different location, edit the `MINGW_ROOT` variable in the file.

### `CodeCoverage.cmake` (TODO)
CMake module for code coverage analysis with gcov/lcov.

## Build Types

- **Debug**: Debug symbols, no optimization (`-g -O0`)
- **Release**: Full optimization, no debug symbols (`-O3 -DNDEBUG`)
- **RelWithDebInfo**: Optimization + debug symbols (`-O2 -g -DNDEBUG`)
- **MinSizeRel**: Size optimization (`-Os -DNDEBUG`)

**Example:**
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw.cmake
```
