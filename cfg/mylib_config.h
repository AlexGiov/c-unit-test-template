/**
 * @file mylib_config.h
 * @brief Configuration for mylib library (test/development build)
 *
 * This is the actual configuration used when building and testing this library.
 *
 * In a real application, this file would be in the application's cfg/ directory,
 * NOT in the library repository.
 *
 * See config/mylib_config.h.template for available options and documentation.
 */

#ifndef MYLIB_CONFIG_H
#define MYLIB_CONFIG_H

/* ===========================================================================
 * DIVISION BY ZERO HANDLING
 * ===========================================================================
 * For testing, we use the safe default value of 0
 */
#define MYLIB_DIV_BY_ZERO_RETURN 0

/* ===========================================================================
 * DEBUG ASSERTIONS
 * ===========================================================================
 * Enable assertions during development and testing
 */
#define MYLIB_ENABLE_ASSERTIONS

/* ===========================================================================
 * OVERFLOW DETECTION
 * ===========================================================================
 * Disabled for performance during testing
 */
// #define MYLIB_CHECK_OVERFLOW

/* ===========================================================================
 * LOGGING
 * ===========================================================================
 * Disabled - no logging framework in test environment
 */
// #define MYLIB_ENABLE_LOGGING

#endif /* MYLIB_CONFIG_H */
