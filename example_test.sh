#!/usr/bin/env bash

# ============================================================================
# Example Test Script - Shell Unit Test Framework
# ============================================================================
#
# This is an example test script demonstrating the usage of the Shell Unit
# Test Framework. You can use this as a template for your own test scripts.
#
# Usage:
#   ./example_test.sh                    # Run with console output
#   ./example_test.sh --format=json      # Output JSON format
#   ./example_test.sh --format=junit     # Output JUnit XML
#   ./example_test.sh --quiet            # Suppress console output
#
# ============================================================================

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the testing framework
source "${SCRIPT_DIR}/unittest.sh"

# Initialize the framework with command-line arguments
initialize_test_framework "$@"

# ============================================================================
# Start Test Suite
# ============================================================================

print_test_header "Shell Unit Test Framework - Example Tests"

# ============================================================================
# Section 1: String Equality Tests
# ============================================================================

print_section "String Equality Tests"

assert_equals "hello" "hello" "Should match identical strings"
assert_equals "123" "123" "Should match identical numbers as strings"
assert_equals "" "" "Should match empty strings"

# This test will fail to demonstrate failure output
# assert_equals "expected" "actual" "This test demonstrates a failure"

# ============================================================================
# Section 2: String Contains Tests
# ============================================================================

print_section "String Contains Tests"

assert_contains "hello world" "world" "Should find 'world' in 'hello world'"
assert_contains "The quick brown fox" "quick" "Should find 'quick' in sentence"
assert_contains "test123test" "123" "Should find numbers in string"

# ============================================================================
# Section 3: File Operations Tests
# ============================================================================

print_section "File Operations Tests"

# Create a temporary test file
TEST_FILE=$(mktemp)
echo "This is a test file" > "$TEST_FILE"
echo "It contains multiple lines" >> "$TEST_FILE"
echo "config=enabled" >> "$TEST_FILE"

# Test file existence
assert_file_exists "$TEST_FILE" "Temporary test file should exist"

# Test file contains specific content
assert_file_contains "$TEST_FILE" "test file" "File should contain 'test file'"
assert_file_contains "$TEST_FILE" "config=enabled" "File should contain config line"

# Test file does not contain specific content
assert_file_not_contains "$TEST_FILE" "nonexistent" "File should not contain 'nonexistent'"

# Clean up
rm "$TEST_FILE"

# ============================================================================
# Section 4: Command Exit Code Tests
# ============================================================================

print_section "Command Exit Code Tests"

# Test successful command
true
assert_success "The 'true' command should succeed"

# Test command with specific exit code
(exit 0)
exit_code=$?
assert_exit_code 0 $exit_code "Command should return exit code 0"

# Test command that returns non-zero (simulate a specific exit code)
false || true  # Prevent script from exiting
(exit 2)
exit_code=$?
assert_exit_code 2 $exit_code "Command should return exit code 2"

# ============================================================================
# Section 5: Variable and Expression Tests
# ============================================================================

print_section "Variable and Expression Tests"

# Test arithmetic
result=$((5 + 5))
assert_equals "10" "$result" "5 + 5 should equal 10"

# Test string concatenation
str1="hello"
str2="world"
result="${str1} ${str2}"
assert_equals "hello world" "$result" "String concatenation should work"

# Test variable substitution
name="Alice"
greeting="Hello, $name!"
assert_contains "$greeting" "Alice" "Greeting should contain name"

# ============================================================================
# Section 6: Command Output Tests
# ============================================================================

print_section "Command Output Tests"

# Test echo output
output=$(echo "test output")
assert_equals "test output" "$output" "Echo should return expected output"

# Test command substitution
date_output=$(date +%Y)
assert_contains "$date_output" "202" "Year should start with 202"

# Test pipeline
result=$(echo "HELLO" | tr '[:upper:]' '[:lower:]')
assert_equals "hello" "$result" "Pipeline should convert to lowercase"

# ============================================================================
# Print Test Summary
# ============================================================================

# This will print the summary and exit with appropriate code
# Exit code 0 if all tests passed, 1 if any failed
print_summary

