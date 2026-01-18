# ==============================================================================
# Test CMakeLists.txt
# ==============================================================================
# Build configuration for unit tests with CMocka
#
# Test naming convention: test_<module_name>
# The test executable will automatically link against ${PROJECT_NAME} library
# ==============================================================================

# Get project name from parent scope
# This allows tests to automatically adapt when project is renamed
set(LIB_NAME ${PROJECT_NAME})

# ==============================================================================
# CMocka library
# ==============================================================================

# Build cmocka as a static library
add_library(cmocka STATIC
    ${CMAKE_SOURCE_DIR}/external/cmocka/src/cmocka.c
)

target_include_directories(cmocka
    PUBLIC
        ${CMAKE_SOURCE_DIR}/external/cmocka/include
)

# Disable warnings for cmocka (third-party code)
target_compile_options(cmocka PRIVATE
    -w  # Disable all warnings
)

# ==============================================================================
# Test executables
# ==============================================================================
# NOTE: Test executable naming convention: test_<module_name>
# The example below uses test_math_utils - rename to match your module
# After renaming library, update this section or use rename-library.ps1 script

# Auto-detect test files and create executables
# For now, using explicit declaration (example: math_utils module)
set(TEST_MODULE_NAME "math_utils")  # TODO: Update when renaming library

add_executable(test_${TEST_MODULE_NAME}
    unit/test_${TEST_MODULE_NAME}.c
)

target_link_libraries(test_${TEST_MODULE_NAME}
    PRIVATE
        ${LIB_NAME}  # Uses project name automatically
        cmocka
)

target_include_directories(test_${TEST_MODULE_NAME}
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/test/fixtures
        ${CMAKE_SOURCE_DIR}/test/mocks
)

# Code coverage for tests
if(ENABLE_COVERAGE)
    target_compile_options(test_${TEST_MODULE_NAME} PRIVATE --coverage)
    target_link_options(test_${TEST_MODULE_NAME} PRIVATE --coverage)
endif()

# ==============================================================================
# CTest integration
# ==============================================================================

# Register test with CTest
add_test(
    NAME test_${TEST_MODULE_NAME}
    COMMAND test_${TEST_MODULE_NAME}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

# Test properties
set_tests_properties(test_${TEST_MODULE_NAME} PROPERTIES
    TIMEOUT 30
    LABELS "unit;${TEST_MODULE_NAME}"
)

# ==============================================================================
# Custom test targets
# ==============================================================================

# Custom target: run all tests with verbose output
add_custom_target(check
    COMMAND ${CMAKE_CTEST_COMMAND} --verbose --output-on-failure
    DEPENDS test_${TEST_MODULE_NAME}
    COMMENT "Running all unit tests..."
)

# Custom target: run tests with coverage
if(ENABLE_COVERAGE)
    find_program(GCOV_EXECUTABLE gcov)
    find_program(LCOV_EXECUTABLE lcov)
    find_program(GENHTML_EXECUTABLE genhtml)
    
    if(GCOV_EXECUTABLE AND LCOV_EXECUTABLE AND GENHTML_EXECUTABLE)
        add_custom_target(coverage
            COMMAND ${CMAKE_COMMAND} -E echo "Running tests for coverage..."
            COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
            COMMAND ${CMAKE_COMMAND} -E echo "Generating coverage report..."
            COMMAND ${LCOV_EXECUTABLE} --capture --directory . --output-file coverage.info
            COMMAND ${LCOV_EXECUTABLE} --remove coverage.info '/usr/*' '*/external/*' '*/test/*' --output-file coverage_filtered.info
            COMMAND ${GENHTML_EXECUTABLE} coverage_filtered.info --output-directory coverage_html
            COMMAND ${CMAKE_COMMAND} -E echo "Coverage report generated in: coverage_html/index.html"
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
            DEPENDS test_${TEST_MODULE_NAME}
            COMMENT "Generating code coverage report..."
        )
        message(STATUS "Coverage target available: make coverage")
    else()
        message(WARNING "Coverage tools not found (gcov, lcov, genhtml)")
    endif()
endif()

# ==============================================================================
# Test summary
# ==============================================================================

message(STATUS "")
message(STATUS "Test configuration:")
message(STATUS "  Test executables: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(STATUS "  CMocka version:   stub (replace with full version)")
message(STATUS "")
