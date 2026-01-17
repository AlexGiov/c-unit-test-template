/*
 * CMocka - Minimal Stub Implementation
 *
 * This is a MINIMAL stub for build verification only.
 * Replace with full cmocka.c from: https://cmocka.org/
 *
 * Full implementation: ~3000 lines
 * This stub: Basic functionality for simple tests
 */

#include "../include/cmocka.h"

#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* Simple test state */
static int tests_run = 0;
static int tests_failed = 0;

void _assert_true(int condition, const char* expr, const char* file, int line) {
	if (!condition) {
		printf("[ FAILED  ] %s:%d: assert_true(%s)\n", file, line, expr);
		tests_failed++;
		exit(1);
	}
}

void _assert_int_equal(intmax_t a, intmax_t b, const char* file, int line) {
	if (a != b) {
		printf("[ FAILED  ] %s:%d: Expected %" PRIdMAX " but got %" PRIdMAX "\n", file, line, b, a);
		tests_failed++;
		exit(1);
	}
}

void _assert_int_not_equal(intmax_t a, intmax_t b, const char* file, int line) {
	if (a == b) {
		printf("[ FAILED  ] %s:%d: Expected values to differ but both are %" PRIdMAX "\n", file, line, a);
		tests_failed++;
		exit(1);
	}
}

void _assert_string_equal(const char* a, const char* b, const char* file, int line) {
	if (strcmp(a, b) != 0) {
		printf("[ FAILED  ] %s:%d: Expected \"%s\" but got \"%s\"\n", file, line, b, a);
		tests_failed++;
		exit(1);
	}
}

void _assert_string_not_equal(const char* a, const char* b, const char* file, int line) {
	if (strcmp(a, b) == 0) {
		printf("[ FAILED  ] %s:%d: Expected strings to differ but both are \"%s\"\n", file, line, a);
		tests_failed++;
		exit(1);
	}
}

void _assert_ptr_equal(const void* a, const void* b, const char* file, int line) {
	if (a != b) {
		printf("[ FAILED  ] %s:%d: Expected %p but got %p\n", file, line, b, a);
		tests_failed++;
		exit(1);
	}
}

void _assert_ptr_not_equal(const void* a, const void* b, const char* file, int line) {
	if (a == b) {
		printf("[ FAILED  ] %s:%d: Expected pointers to differ but both are %p\n", file, line, a);
		tests_failed++;
		exit(1);
	}
}

/* Mock functions - stubs (full implementation needed for real mocking) */
void _expect_value(const char* function, const char* parameter, const char* file, int line, uintmax_t value,
				   int count) {
	(void)function;
	(void)parameter;
	(void)file;
	(void)line;
	(void)value;
	(void)count;
}

void _expect_function_call(const char* function, const char* file, int line, int count) {
	(void)function;
	(void)file;
	(void)line;
	(void)count;
}

void _will_return(const char* function, const char* file, int line, uintmax_t value, int count) {
	(void)function;
	(void)file;
	(void)line;
	(void)value;
	(void)count;
}

uintmax_t _mock(const char* function, const char* file, int line) {
	(void)function;
	(void)file;
	(void)line;
	return 0;
}

void _function_called(const char* function, const char* file, int line) {
	(void)function;
	(void)file;
	(void)line;
}

/* Test runner */
int _cmocka_run_group_tests(const char* group_name, const struct CMUnitTest* const tests, const size_t num_tests,
							CMFixtureFunction group_setup, CMFixtureFunction group_teardown) {
	size_t i;

	printf("[==========] Running %zu test(s) from %s.\n", num_tests, group_name);

	if (group_setup && group_setup(NULL) != 0) {
		printf("[ ERROR    ] Group setup failed\n");
		return 1;
	}

	for (i = 0; i < num_tests; i++) {
		const struct CMUnitTest* test = &tests[i];
		void* state = test->initial_state;

		printf("[ RUN      ] %s\n", test->name);
		tests_run++;

		if (test->setup_func && test->setup_func(&state) != 0) {
			printf("[ FAILED   ] Setup failed\n");
			tests_failed++;
			continue;
		}

		test->test_func(&state);

		if (test->teardown_func) {
			test->teardown_func(&state);
		}

		printf("[       OK ] %s\n", test->name);
	}

	if (group_teardown) {
		group_teardown(NULL);
	}

	printf("[==========] %d test(s) run.\n", tests_run);
	printf("[  PASSED  ] %d test(s).\n", tests_run - tests_failed);
	if (tests_failed > 0) {
		printf("[  FAILED  ] %d test(s).\n", tests_failed);
	}

	return tests_failed;
}
