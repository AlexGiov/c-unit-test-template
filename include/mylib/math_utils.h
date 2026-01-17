/**
 * @file math_utils.h
 * @brief Simple math utility functions for testing
 *
 * This is a simple example library to demonstrate the unit testing template.
 */

#ifndef MYLIB_MATH_UTILS_H
#define MYLIB_MATH_UTILS_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Add two integers
 *
 * @param a First operand
 * @param b Second operand
 * @return Sum of a and b
 */
int add(int a, int b);

/**
 * @brief Subtract two integers
 *
 * @param a First operand (minuend)
 * @param b Second operand (subtrahend)
 * @return Difference (a - b)
 */
int subtract(int a, int b);

/**
 * @brief Multiply two integers
 *
 * @param a First operand
 * @param b Second operand
 * @return Product of a and b
 */
int multiply(int a, int b);

/**
 * @brief Divide two integers
 *
 * @param a Dividend
 * @param b Divisor
 * @return Quotient (a / b), or 0 if b is 0
 */
int divide(int a, int b);

#ifdef __cplusplus
}
#endif

#endif /* MYLIB_MATH_UTILS_H */
