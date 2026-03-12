# Unit Test Template for C Libraries

Professional template for unit testing C libraries with CMocka framework, designed for embedded systems development with cross-compiler support.

## 📋 Features

- ✅ **CMocka Integration** - Professional C unit testing framework
- ✅ **CMake Build System** - Cross-platform, cross-compiler support
- ✅ **Code Coverage** - Integrated gcov support with HTML reports
- ✅ **VS Code Integration** - Debug configuration and build tasks
- ✅ **Embedded-Friendly** - Install sources for embedded integration
- ✅ **Modular Structure** - Professional directory organization
- ✅ **Automated Scripts** - PowerShell build, coverage, and release automation
- ✅ **Version Management** - Automated semantic versioning and Git tagging

## 🚀 Quick Start

### Prerequisites

- CMake 3.10+
- GCC or compatible C compiler
- gcov (for coverage analysis)
- (Optional) Ninja build system for faster builds

### Build and Test

```powershell
# Build project
.\build.ps1

# Build with tests
.\build.ps1 -RunTests

# Clean build
.\build.ps1 -Clean

# Build with coverage
.\build.ps1 -Coverage -RunTests

# Generate coverage report
.\coverage.ps1 -GenerateHtml
```

**Build System Configuration:**

The build script supports both MinGW Makefiles and Ninja generators. Edit the `$CMAKE_GENERATOR` variable at the top of `build.ps1` to switch:

```powershell
# In build.ps1 (line ~68)
$CMAKE_GENERATOR = "MinGW Makefiles"  # Default, always available
$CMAKE_GENERATOR = "Ninja"            # Faster, requires Ninja installed
```

### VS Code

- **Build**: `Ctrl+Shift+B`
- **Debug Tests**: `F5`
- **Run Tests**: Select "test" task

## 📁 Directory Structure

The template is organized into two main parts: the **core library** (deliverable) and the **development infrastructure** (testing & tooling).

### Core Library Structure (Installable)

This is what gets installed and integrated into your application:

```
unit_test_template/
├── include/mylib/          # Public API headers
│   └── mylib.h             # Public interface
├── src/                    # Library implementation
│   ├── mylib.c             # Implementation files
│   └── private/            # Private implementation (not installed)
└── config/                 # Configuration templates
    └── mylib_config.h.template  # Configuration example
```

**Why this structure?**
- `include/mylib/` - Uses namespace subfolder to avoid header name collisions
- `src/` - Contains implementation; installable for embedded integration
- `src/private/` - Internal implementation details (excluded from install)
- `config/` - Template for application-specific configuration

### Development Infrastructure (Non-installable)

Tools and tests for library development:

```
unit_test_template/
├── cfg/                    # Configuration for this build
│   └── mylib_config.h      # Actual config used during development/testing
├── test/                   # Testing framework
│   ├── unit/               # Unit test files
│   │   └── test_mylib.c
│   ├── mocks/              # Mock implementations
│   ├── fixtures/           # Test fixtures
│   └── data/               # Test data files
├── external/               # External dependencies
│   └── cmocka/             # CMocka test framework (embedded)
│       ├── include/
│       └── src/
├── cmake/                  # Build system configuration
│   ├── toolchain-mingw.cmake
│   └── README.md
├── build/                  # Build artifacts (gitignored)
├── bin/                    # Test executables (gitignored)
├── lib/                    # Compiled libraries (gitignored)
├── coverage/               # Coverage reports (gitignored)
├── .vscode/                # VS Code integration
├── build.ps1               # Build automation script
├── coverage.ps1            # Coverage report generator
├── release.ps1             # Version bump and release automation
├── rename-library.ps1      # Library renaming utility
└── CMakeLists.txt          # Build configuration
```

**Development vs Production:**
- Test infrastructure stays in the library repository
- `cfg/` contains the actual config used for testing (NOT installed)
- `config/` contains templates for applications to copy and customize
- Only `include/`, `src/`, and `config/` templates are installed
- Application gets clean library without test dependencies

## 🛠️ Renaming the Template Library

### Simple Automatic Rename ✨ (Recommended)

Thanks to CMake's `${PROJECT_NAME}` pattern, renaming is now **much simpler**:

```powershell
# 1. Clone this template
git clone <repo-url> my-new-library
cd my-new-library

# 2. Run rename script - it's now much faster and simpler!
.\rename-library.ps1 -NewName "sensor_driver"

# 3. Build and test
.\build.ps1 -Clean -RunTests

# 4. Implement your library code
#    - Edit src/sensor_driver.c
#    - Edit include/sensor_driver/sensor_driver.h
#    - Write tests in test/unit/test_sensor_driver.c
```

**What the script does (simplified):**
1. ✅ Changes `project(mylib)` → `project(sensor_driver)` in CMakeLists.txt
2. ✅ Renames `include/mylib/` → `include/sensor_driver/`
3. ✅ Renames source files: `mylib.*` → `sensor_driver.*`
4. ✅ Updates `#include` statements in C files
5. ✅ Updates README.md references

**What happens automatically (via `${PROJECT_NAME}`):**
- ✨ All CMake library targets
- ✨ All install paths and exports
- ✨ Package configuration files
- ✨ Test linkage

**Key Insight:** Because CMakeLists.txt now uses `${PROJECT_NAME}` everywhere, you only need to change the `project()` declaration and the rest updates automatically!

### Manual Rename (If You Prefer)

<details>
<summary>Click to expand manual steps</summary>

If you prefer to do it manually:

### 1. Update CMakeLists.txt

```cmake
# Change only this line:
project(mylib VERSION 1.0.0 LANGUAGES C)  
# to:
project(your_library_name VERSION 1.0.0 LANGUAGES C)

# Everything else updates automatically via ${PROJECT_NAME}!
```

### 2. Rename Directories and Files

```powershell
# Rename include directory
mv include/mylib include/your_library_name

# Rename source files (if single-module library)
mv src/mylib.c src/your_library_name.c
mv include/your_library_name/mylib.h include/your_library_name/your_library_name.h
mv test/unit/test_mylib.c test/unit/test_your_library_name.c
```

### 3. Update #include Statements

```c
// In src/your_library_name.c
#include "your_library_name/your_library_name.h"

// In test/unit/test_your_library_name.c
#include "your_library_name/your_library_name.h"
```

### 4. Update README.md

Replace all references to `mylib` with `your_library_name`.

</details>

## 💡 Template Design Philosophy

This template follows **CMake best practices** for relocatable packages:

- **Single Source of Truth**: Library name defined once in `project()` declaration
- **Variable-Based Configuration**: All targets/paths use `${PROJECT_NAME}` variable
- **Auto-Derived Values**: `${PROJECT_NAME_UPPER}` generated automatically
- **Minimal Renaming**: Only need to change project name + rename directories/files
- **Professional Structure**: Follows cmake-packages(7) documentation patterns

### File Naming Convention

For **single-module libraries** (most common):
- Use: `src/${PROJECT_NAME}.c` and `include/${PROJECT_NAME}/${PROJECT_NAME}.h`
- Example: `sensor_driver` → `src/sensor_driver.c`

For **multi-module libraries**:
- Use descriptive module names
- Example: `uart_driver` → `src/uart_tx.c`, `src/uart_rx.c`, `src/uart_config.c`

### How It Works Under the Hood

The template leverages CMake variables for maximum flexibility:

```cmake
# In CMakeLists.txt - Single source of truth:
project(mylib VERSION 1.0.0 LANGUAGES C)

# Auto-derived variable:
string(TOUPPER ${PROJECT_NAME} PROJECT_NAME_UPPER)

# All targets use variables:
add_library(${PROJECT_NAME} ...)
target_include_directories(${PROJECT_NAME} ...)
install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets ...)

# Install paths use variables:
install(DIRECTORY include/${PROJECT_NAME}/ ...)
install(FILES ... DESTINATION cmake/${PROJECT_NAME})
```

This means changing `project(mylib)` to `project(your_lib)` automatically updates:
- Library target name
- All install paths
- Export configurations  
- Package configs
- Test linkage (via inherited `${LIB_NAME}`)

## 🔧 Usage

### 1. Clone and Customize

```bash
# Clone this template
git clone <repo-url> my-library-tests
cd my-library-tests

# Update library name
# Edit CMakeLists.txt: project(mylib) -> project(your_lib_name)
```

### 2. Add Your Library Sources

```bash
# Add headers
include/your_lib_name/your_module.h

# Add implementation
src/your_module.c

# Update CMakeLists.txt MYLIB_SOURCES variable
```

### 3. Write Tests

```bash
# Create test file
test/unit/test_your_module.c

# Update test/CMakeLists.txt to add new test executable
```

### 4. Build and Test

```powershell
.\build.ps1 -RunTests
```

</details>

## 📊 Code Coverage

The template includes integrated code coverage support:

```powershell
# Build with coverage enabled
.\build.ps1 -Clean -Coverage -RunTests

# Generate HTML coverage report
.\coverage.ps1 -GenerateHtml

# View report
start coverage\index.html
```

Coverage reports show:
- Line-by-line coverage with gcov
- Overall coverage percentage
- Per-file coverage breakdown
- HTML report with color-coded results

## 🎯 CMake Options

| Option              | Default | Description                         |
| ------------------- | ------- | ----------------------------------- |
| `BUILD_TESTING`     | `ON`    | Build unit tests                    |
| `ENABLE_COVERAGE`   | `OFF`   | Enable code coverage                |
| `INSTALL_SOURCES`   | `ON`    | Install source files (for embedded) |
| `BUILD_SHARED_LIBS` | `OFF`   | Build shared libraries              |

Example:

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF
```

## 🔧 Embedded Integration

This template is designed for embedded systems where you often need source files, not just compiled libraries.

### Installation Options

Control what gets installed with CMake options:

| Option            | Default | Description                            |
| ----------------- | ------- | -------------------------------------- |
| `INSTALL_SOURCES` | `ON`    | Install .c files for embedded projects |
| `BUILD_TESTING`   | `ON`    | Enable test building (dev only)        |

### Install Library Files

```bash
# Configure with install prefix
cmake -B build -DCMAKE_INSTALL_PREFIX=install

# Build and install
cmake --build build
cmake --install build

# Installed structure:
install/
├── include/mylib/          # Public headers
│   └── mylib.h
├── src/mylib/              # Source files (if INSTALL_SOURCES=ON)
│   └── mylib.c
├── config/mylib/           # Configuration template
│   └── mylib_config.h.template
└── lib/cmake/mylib/        # CMake package config
    ├── mylibTargets.cmake
    └── mylibConfig.cmake
```

### Configuration Template Usage

1. **Copy template to your application:**

```bash
cp install/config/mylib/mylib_config.h.template myapp/cfg/mylib_config.h
```

2. **Customize configuration:**

```c
// myapp/cfg/mylib_config.h
#ifndef MYLIB_CONFIG_H
#define MYLIB_CONFIG_H

#define MYLIB_DIV_BY_ZERO_RETURN -1  // Return error code
#define MYLIB_ENABLE_ASSERTIONS      // Enable debug checks

#endif
```

3. **Add config directory to your build:**

```cmake
# In your application CMakeLists.txt
target_include_directories(myapp PRIVATE
    ${CMAKE_SOURCE_DIR}/cfg  # Your config directory
)
```

The library will automatically detect and use `mylib_config.h` if available.

### Use in Embedded Project

**Option 1: Link installed library**

```cmake
find_package(mylib REQUIRED)
target_link_libraries(myapp PRIVATE mylib::mylib)
```

**Option 2: Include sources directly (embedded)**

```cmake
add_library(mylib
    ${VENDOR_DIR}/mylib/src/mylib.c
)

target_include_directories(mylib PUBLIC
    ${VENDOR_DIR}/mylib/include
    ${CMAKE_SOURCE_DIR}/cfg  # Your config
)
```

### Versioning and Releases

#### Automated Release (Recommended)

Use the included `release.ps1` script for automated version management:

```powershell
# Bump patch version (1.0.0 → 1.0.1)
.\release.ps1 -BumpVersion patch

# Bump minor version (1.0.0 → 1.1.0)
.\release.ps1 -BumpVersion minor

# Bump major version (1.0.0 → 2.0.0)
.\release.ps1 -BumpVersion major

# Set specific version
.\release.ps1 -Version 2.0.0

# Create GitHub release (requires gh CLI)
.\release.ps1 -BumpVersion patch -CreateGitHubRelease

# Preview changes without executing
.\release.ps1 -BumpVersion minor -DryRun
```

**What the script does:**
1. ✅ Reads current version from CMakeLists.txt
2. ✅ Bumps version following semantic versioning
3. ✅ Updates CMakeLists.txt with new version
4. ✅ Commits the version change
5. ✅ Creates annotated Git tag (e.g., v1.0.0)
6. ✅ Pushes tag to remote
7. ✅ Optionally creates GitHub release (with `-CreateGitHubRelease`)

**Requirements:**
- Git (always required)
- GitHub CLI (`gh`) - only if using `-CreateGitHubRelease`
  - Install from: https://cli.github.com/

#### Manual Git Tagging

If you prefer manual tagging:

```bash
# Update version in CMakeLists.txt manually
# Then create and push tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

#### Using Specific Versions in Embedded Projects

```bash
# Clone specific version into vendor directory
git clone --branch v1.0.0 <repo-url> vendor/mylib
```

### Library Structure Best Practices

This template follows professional C library organization:

- **Namespace headers** - `include/mylib/` prevents naming conflicts
- **Separate public/private** - Only `include/` is public API
- **Template config** - Library provides template, app provides actual config
- **Optional configuration** - Library works with or without config file
- **Source installation** - Enables embedded system integration

For detailed explanation of library structure patterns, see inline documentation in source files.

## 📝 Example: mylib Library

The template includes a simple `mylib` library as an example:

### Library Code

```c
// include/mylib/mylib.h
int add(int a, int b);
int subtract(int a, int b);
int multiply(int a, int b);
int divide(int a, int b);

// src/mylib.c
int add(int a, int b) { return a + b; }
int divide(int a, int b) {
    if (b == 0) return 0;  // Safety check
    return a / b;
}
```

### Test Code

```c
// test/unit/test_mylib.c
static void test_add_positive(void **state) {
    assert_int_equal(add(2, 3), 5);
}

static void test_divide_by_zero(void **state) {
    assert_int_equal(divide(10, 0), 0);  // Handles edge case
}
```

### Results

- **8 tests** - All passing
- **100% coverage** - All functions and branches tested
- **Edge cases** - Division by zero handled

## 🐛 Debugging

### Debug Tests in VS Code

1. Set breakpoint in test file or source
2. Press `F5`
3. Select "Debug Test: mylib"
4. Step through code with GDB

### Debug Configuration

The template includes two debug configurations:

- **Debug Test (with build)** - Builds before debugging
- **Debug Test (no build)** - Debugs existing executable

## 📦 CMocka Framework

### Current Status

The template includes a **minimal CMocka stub** for demonstration. For production use:

1. Download full CMocka from https://cmocka.org/
2. Extract to `external/cmocka/`
3. Follow instructions in `external/cmocka/README.md`

### CMocka Features

- Assertions: `assert_int_equal()`, `assert_true()`, etc.
- Mock functions with `will_return()`
- Setup/teardown fixtures
- Test groups and organization

## 🔍 Testing Best Practices

### Test Organization

```
test/
├── unit/           # Unit tests (functions, modules)
├── integration/    # Integration tests (multiple modules)
├── mocks/          # Mock implementations for dependencies
├── fixtures/       # Test setup/teardown helpers
└── data/           # Test data files
```

### Test Naming

```c
// Format: test_<function>_<scenario>
static void test_add_positive(void **state) { ... }
static void test_add_negative(void **state) { ... }
static void test_divide_by_zero(void **state) { ... }
```

### Coverage Goals

- **Minimum**: 80% line coverage
- **Recommended**: 90%+ line coverage
- **Best**: 100% line coverage + branch coverage

## 🚀 Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install CMake
        run: sudo apt-get install cmake
      - name: Build and Test
        run: |
          cmake -B build -DCMAKE_BUILD_TYPE=Debug -DENABLE_COVERAGE=ON
          cmake --build build
          ctest --test-dir build --output-on-failure
      - name: Generate Coverage
        run: |
          gcov build/CMakeFiles/mylib.dir/src/*.c.gcno
```

## 📖 Additional Documentation

- [CMake Configuration](cmake/README.md) - Build system details
- [CMocka Integration](external/cmocka/README.md) - Test framework setup
- [VS Code Setup](.vscode/README.md) - Editor integration

## 🤝 Contributing

When using this as a template for your projects:

1. Replace `mylib` with your library name
2. Update version in `CMakeLists.txt`
3. Add your source files
4. Write comprehensive tests
5. Maintain coverage above 80%
6. Document public APIs

## 📄 License

This template is provided as-is for use in your projects. Customize as needed.

## ✅ Checklist for New Projects

- [ ] Rename project in CMakeLists.txt
- [ ] Update library name in all files
- [ ] Add library source files to `src/`
- [ ] Add public headers to `include/<libname>/`
- [ ] Write unit tests in `test/unit/`
- [ ] Build and run tests: `.\build.ps1 -RunTests`
- [ ] Check coverage: `.\coverage.ps1 -GenerateHtml`
- [ ] Configure VS Code debugging
- [ ] Update README with library-specific details
- [ ] Tag first release: `git tag v0.1.0`

## 🎓 Resources

- [CMocka Documentation](https://api.cmocka.org/)
- [CMake Tutorial](https://cmake.org/cmake/help/latest/guide/tutorial/index.html)
- [GCC Coverage (gcov)](https://gcc.gnu.org/onlinedocs/gcc/Gcov.html)
- [Unit Testing Best Practices](https://github.com/testdouble/contributing-tests/wiki/Test-Driven-Development)

---

**Version**: 1.0.0  
**Last Updated**: 2026-01-17  
**Status**: ✅ Production Ready
