/**
 * @file test_math_utils.c
 * @brief Unit tests for math_utils library
 *
 * This demonstrates basic unit testing with cmocka.
 */

#include <cmocka.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>

#include "mylib/math_utils.h"


/* Test fixtures */
static int setup(void** state) {
	(void)state; /* unused */
	return 0;
}

static int teardown(void** state) {
	(void)state; /* unused */
	return 0;
}

/* Test: add positive numbers */
static void test_add_positive(void** state) {
	(void)state; /* unused */

	assert_int_equal(add(2, 3), 5);
	assert_int_equal(add(10, 20), 30);
	assert_int_equal(add(100, 200), 300);
}

/* Test: add negative numbers */
static void test_add_negative(void** state) {
	(void)state; /* unused */

	assert_int_equal(add(-2, -3), -5);
	assert_int_equal(add(-10, -20), -30);
}

/* Test: add mixed (positive and negative) */
static void test_add_mixed(void** state) {
	(void)state; /* unused */

	assert_int_equal(add(5, -3), 2);
	assert_int_equal(add(-5, 3), -2);
	assert_int_equal(add(10, -10), 0);
}

/* Test: add zero */
static void test_add_zero(void** state) {
	(void)state; /* unused */

	assert_int_equal(add(0, 0), 0);
	assert_int_equal(add(5, 0), 5);
	assert_int_equal(add(0, 5), 5);
}

/* Test: subtract */
static void test_subtract(void** state) {
	(void)state; /* unused */

	assert_int_equal(subtract(5, 3), 2);
	assert_int_equal(subtract(10, 7), 3);
	assert_int_equal(subtract(5, 5), 0);
	assert_int_equal(subtract(3, 5), -2);
}

/* Test: multiply */
static void test_multiply(void** state) {
	(void)state; /* unused */

	assert_int_equal(multiply(2, 3), 6);
	assert_int_equal(multiply(5, 4), 20);
	assert_int_equal(multiply(0, 100), 0);
	assert_int_equal(multiply(-2, 3), -6);
	assert_int_equal(multiply(-2, -3), 6);
}

/* Test: divide */
static void test_divide(void** state) {
	(void)state; /* unused */

	assert_int_equal(divide(10, 2), 5);
	assert_int_equal(divide(20, 4), 5);
	assert_int_equal(divide(7, 2), 3);	// Integer division
}

/* Test: divide by zero (should return 0) */
static void test_divide_by_zero(void** state) {
	(void)state; /* unused */

	assert_int_equal(divide(10, 0), 0);
	assert_int_equal(divide(100, 0), 0);
}

/* Main test runner */
int main(void) {
	const struct CMUnitTest tests[] = {
		cmocka_unit_test(test_add_positive), cmocka_unit_test(test_add_negative),	cmocka_unit_test(test_add_mixed),
		cmocka_unit_test(test_add_zero),	 cmocka_unit_test(test_subtract),		cmocka_unit_test(test_multiply),
		cmocka_unit_test(test_divide),		 cmocka_unit_test(test_divide_by_zero),
	};

	return cmocka_run_group_tests(tests, setup, teardown);
}
