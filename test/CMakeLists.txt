# ==============================================================================
# Test CMakeLists.txt
# ==============================================================================
# Build configuration for unit tests with CMocka
# ==============================================================================

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

# Test: math_utils
add_executable(test_math_utils
    unit/test_math_utils.c
)

target_link_libraries(test_math_utils
    PRIVATE
        mylib
        cmocka
)

target_include_directories(test_math_utils
    PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/test/fixtures
        ${CMAKE_SOURCE_DIR}/test/mocks
)

# Code coverage for tests
if(ENABLE_COVERAGE)
    target_compile_options(test_math_utils PRIVATE --coverage)
    target_link_options(test_math_utils PRIVATE --coverage)
endif()

# ==============================================================================
# CTest integration
# ==============================================================================

# Register test with CTest
add_test(
    NAME test_math_utils
    COMMAND test_math_utils
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

# Test properties
set_tests_properties(test_math_utils PROPERTIES
    TIMEOUT 30
    LABELS "unit;math"
)

# ==============================================================================
# Custom test targets
# ==============================================================================

# Custom target: run all tests with verbose output
add_custom_target(check
    COMMAND ${CMAKE_CTEST_COMMAND} --verbose --output-on-failure
    DEPENDS test_math_utils
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
            DEPENDS test_math_utils
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
