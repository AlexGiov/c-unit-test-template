# CMake Configuration Files

This directory contains CMake configuration files and modules.

## Files

### `CodeCoverage.cmake` (TODO)
CMake module for code coverage analysis with gcov/lcov.

## Toolchain / Presets

The compiler and generator are no longer configured through a toolchain file here.
They are defined in [`CMakePresets.json`](../CMakePresets.json) at the repository root:

- `ucrt64` (Windows): GCC/Ninja from MSYS2 UCRT64 (`C:/msys64/ucrt64/bin`)
- `linux-gcc` (Linux): system GCC/Ninja

```bash
cmake --preset ucrt64        # Windows
cmake --preset linux-gcc     # Linux
cmake --build --preset ucrt64
```

To use a different compiler location, create an untracked `CMakeUserPresets.json`
at the repository root that inherits from `ucrt64`/`linux-gcc` and overrides
`CMAKE_C_COMPILER`.

## Build Types

- **Debug**: Debug symbols, no optimization (`-g -O0`)
- **Release**: Full optimization, no debug symbols (`-O3 -DNDEBUG`)
- **RelWithDebInfo**: Optimization + debug symbols (`-O2 -g -DNDEBUG`)
- **MinSizeRel**: Size optimization (`-Os -DNDEBUG`)

**Example:**
```bash
cmake --preset ucrt64 -DCMAKE_BUILD_TYPE=Release
```
