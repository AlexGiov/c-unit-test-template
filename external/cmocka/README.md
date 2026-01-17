# CMocka Unit Testing Framework

## Quick Start: Getting CMocka Files

CMocka is a lightweight C unit testing framework. You need only 2 files to get started.

### Option 1: Download from Official Source (Recommended)

1. Go to: https://cmocka.org/files/
2. Download latest version (e.g., `cmocka-1.1.7.tar.xz`)
3. Extract and copy these files to this directory:
   - `include/cmocka.h` → `external/cmocka/include/cmocka.h`
   - `src/cmocka.c` → `external/cmocka/src/cmocka.c`

### Option 2: Git Clone (Alternative)

```bash
# Clone full repository
git clone https://gitlab.com/cmocka/cmocka.git temp_cmocka
cd temp_cmocka

# Copy only needed files
cp include/cmocka.h ../external/cmocka/include/
cp src/cmocka.c ../external/cmocka/src/

# Cleanup
cd ..
rm -rf temp_cmocka
```

### Option 3: Use Stub (For Quick Testing)

For now, you can use the minimal stub files provided in this directory to verify the build system works.
**Note:** Replace with full CMocka implementation before running real tests!

## CMocka Version

- **Required:** CMocka 1.1.5 or later
- **Tested with:** CMocka 1.1.7
- **License:** Apache License 2.0

## Documentation

- Official site: https://cmocka.org/
- API Documentation: https://api.cmocka.org/
- Examples: https://git.cryptomilk.org/projects/cmocka.git/tree/example

## Integration

CMocka is compiled as a static library and linked with test executables.
See `test/CMakeLists.txt` for build configuration.
