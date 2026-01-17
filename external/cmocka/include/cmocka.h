/*
 * CMocka - Minimal Stub Header
 *
 * This is a MINIMAL stub for build verification only.
 * Replace with full cmocka.h from: https://cmocka.org/
 *
 * Full file: ~2400 lines
 * This stub: Basic macros only
 */

#ifndef CMOCKA_H_
#define CMOCKA_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>


/* Test function prototype */
typedef void (*CMUnitTestFunction)(void** state);

/* Test fixture function prototypes */
typedef int (*CMFixtureFunction)(void** state);

/* Test structure */
struct CMUnitTest {
	const char* name;
	CMUnitTestFunction test_func;
	CMFixtureFunction setup_func;
	CMFixtureFunction teardown_func;
	void* initial_state;
};

/* Assert macros */
#define assert_true(c) _assert_true(c, #c, __FILE__, __LINE__)
#define assert_false(c) _assert_true(!(c), #c, __FILE__, __LINE__)
#define assert_int_equal(a, b) _assert_int_equal(a, b, __FILE__, __LINE__)
#define assert_int_not_equal(a, b) _assert_int_not_equal(a, b, __FILE__, __LINE__)
#define assert_string_equal(a, b) _assert_string_equal(a, b, __FILE__, __LINE__)
#define assert_string_not_equal(a, b) _assert_string_not_equal(a, b, __FILE__, __LINE__)
#define assert_ptr_equal(a, b) _assert_ptr_equal(a, b, __FILE__, __LINE__)
#define assert_ptr_not_equal(a, b) _assert_ptr_not_equal(a, b, __FILE__, __LINE__)
#define assert_null(c) _assert_ptr_equal(c, NULL, __FILE__, __LINE__)
#define assert_non_null(c) _assert_ptr_not_equal(c, NULL, __FILE__, __LINE__)

/* Test definition macros */
#define cmocka_unit_test(f) {#f, f, NULL, NULL, NULL}
#define cmocka_unit_test_setup(f, setup) {#f, f, setup, NULL, NULL}
#define cmocka_unit_test_teardown(f, teardown) {#f, f, NULL, teardown, NULL}
#define cmocka_unit_test_setup_teardown(f, setup, teardown) {#f, f, setup, teardown, NULL}

/* Mock macros - basic stubs */
#define expect_value(function, parameter, value) _expect_value(#function, #parameter, __FILE__, __LINE__, value, 1)
#define expect_function_call(function) _expect_function_call(#function, __FILE__, __LINE__, 1)
#define will_return(function, value) _will_return(#function, __FILE__, __LINE__, value, 1)
#define mock() _mock(__func__, __FILE__, __LINE__)
#define function_called() _function_called(__func__, __FILE__, __LINE__)

/* Core functions */
void _assert_true(int condition, const char* expr, const char* file, int line);
void _assert_int_equal(intmax_t a, intmax_t b, const char* file, int line);
void _assert_int_not_equal(intmax_t a, intmax_t b, const char* file, int line);
void _assert_string_equal(const char* a, const char* b, const char* file, int line);
void _assert_string_not_equal(const char* a, const char* b, const char* file, int line);
void _assert_ptr_equal(const void* a, const void* b, const char* file, int line);
void _assert_ptr_not_equal(const void* a, const void* b, const char* file, int line);

/* Mock functions */
void _expect_value(const char* function, const char* parameter, const char* file, int line, uintmax_t value, int count);
void _expect_function_call(const char* function, const char* file, int line, int count);
void _will_return(const char* function, const char* file, int line, uintmax_t value, int count);
uintmax_t _mock(const char* function, const char* file, int line);
void _function_called(const char* function, const char* file, int line);

/* Test runner */
int _cmocka_run_group_tests(const char* group_name, const struct CMUnitTest* const tests, const size_t num_tests,
							CMFixtureFunction group_setup, CMFixtureFunction group_teardown);

#define cmocka_run_group_tests(tests, group_setup, group_teardown) \
	_cmocka_run_group_tests(#tests, tests, sizeof(tests) / sizeof((tests)[0]), group_setup, group_teardown)

#ifdef __cplusplus
}
#endif

#endif /* CMOCKA_H_ */
