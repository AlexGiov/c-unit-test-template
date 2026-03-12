/**
 * @file mylib.c
 * @brief Implementation of mylib library
 */

#include "mylib/mylib.h"

/* Optional configuration support */
#ifdef __has_include
#if __has_include("mylib_config.h")
#include "mylib_config.h"
#endif
#endif

/* Default configuration values if not provided by config file */
#ifndef MYLIB_DIV_BY_ZERO_RETURN
#define MYLIB_DIV_BY_ZERO_RETURN 0
#endif

int add(int a, int b) { return a + b; }

int subtract(int a, int b) { return a - b; }

int multiply(int a, int b) { return a * b; }

int divide(int a, int b) {
	if (b == 0) {
		return MYLIB_DIV_BY_ZERO_RETURN;  // Configurable behavior
	}
	return a / b;
}
