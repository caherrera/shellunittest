# Shell Unit Test Framework

A comprehensive, portable testing framework for Bash shell scripts with support for multiple output formats and cross-platform compatibility.

## Features

- ✅ **Rich Assertion Library**: Multiple assertion types for comprehensive testing
- 🎨 **Colorized Output**: Easy-to-read test results with ANSI color codes
- 📊 **Multiple Output Formats**: JSON, YAML, CSV, and JUnit XML
- 🖥️ **Cross-Platform**: Works on Linux and macOS with automatic tool detection
- 🔇 **Quiet Mode**: Machine-readable output without console clutter
- ⚡ **Performance Tracking**: Millisecond-precision timing for each test
- 📈 **Test Result Recording**: Detailed test metadata and statistics

## Table of Contents

- [Installation](#installation)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Assertion Functions](#assertion-functions)
- [Output Formats](#output-formats)
- [Command Line Options](#command-line-options)
- [Examples](#examples)
- [API Reference](#api-reference)

## Installation

1. Copy the `shellunittest` directory to your project
2. Source the framework in your test scripts:

```bash
#!/usr/bin/env bash
source ./shellunittest/unittest.sh

# Initialize the framework with any command-line options
initialize_test_framework "$@"
```

## Requirements

### Required Dependencies

- **Bash 4.0+**
- **GNU grep**: Standard on Linux, requires `brew install grep` on macOS
- **GNU sed**: Standard on Linux, requires `brew install gnu-sed` on macOS

### Optional Dependencies (for specific output formats)

- **jq**: Required for JSON, CSV, and JUnit XML output formats
  - Install: `brew install jq` (macOS) or `apt-get install jq` (Linux)
  
- **yq**: Required for YAML and JUnit XML output formats
  - Install: `brew install yq` (macOS) or `pip install yq` (Linux)

The framework automatically detects your operating system and validates that required tools are installed.

## Quick Start

Create a test file:

```bash
#!/usr/bin/env bash

# Source the testing framework
source ./shellunittest/unittest.sh
initialize_test_framework "$@"

# Start your test suite
print_test_header "My Test Suite"

# Run some tests
assert_equals "expected" "expected" "String equality test"
assert_contains "hello world" "world" "String contains test"

# Print summary and exit
print_summary
```

Run your tests:

```bash
chmod +x my_test.sh
./my_test.sh
```

## Usage

### Basic Test Structure

```bash
#!/usr/bin/env bash
source ./shellunittest/unittest.sh
initialize_test_framework "$@"

print_test_header "Test Suite Name"

print_section "Test Category 1"
assert_equals "foo" "foo" "Test description"
assert_contains "foobar" "foo" "Another test"

print_section "Test Category 2"
result=$(some_command)
assert_equals "expected_output" "$result" "Command output test"

print_summary
```

### Test Organization

```bash
print_test_header "API Tests"          # Main test suite header
print_section "Authentication Tests"   # Test category/section
print_test_name "Login validation"     # Individual test name (optional)
```

## Assertion Functions

### assert_equals

Tests if two values are exactly equal.

```bash
assert_equals "expected" "actual" "Description"
```

**Parameters:**
1. `expected` - The expected value
2. `actual` - The actual value to test
3. `description` - Test description

### assert_contains

Tests if a string contains a substring.

```bash
assert_contains "haystack" "needle" "Description"
```

**Parameters:**
1. `haystack` - The string to search in
2. `needle` - The substring to find
3. `description` - Test description

### assert_file_contains

Tests if a file contains a specific pattern.

```bash
assert_file_contains "/path/to/file" "pattern" "Description"
```

**Parameters:**
1. `file` - Path to the file
2. `pattern` - String pattern to find
3. `description` - Test description

### assert_file_not_contains

Tests that a file does NOT contain a specific pattern.

```bash
assert_file_not_contains "/path/to/file" "pattern" "Description"
```

**Parameters:**
1. `file` - Path to the file
2. `pattern` - String pattern that should not exist
3. `description` - Test description

### assert_file_exists

Tests if a file exists.

```bash
assert_file_exists "/path/to/file" "Description"
```

**Parameters:**
1. `file` - Path to the file
2. `description` - Test description

### assert_success

Tests if the previous command succeeded (exit code 0).

```bash
some_command
assert_success "Command should succeed"
```

**Parameters:**
1. `description` - Test description

### assert_exit_code

Tests if a command returned a specific exit code.

```bash
some_command
actual_code=$?
assert_exit_code 2 $actual_code "Should return exit code 2"
```

**Parameters:**
1. `expected_code` - Expected exit code
2. `actual_code` - Actual exit code to test
3. `description` - Test description

## Output Formats

The framework supports multiple output formats for integration with CI/CD systems.

### Console (Default)

Human-readable output with colors:

```bash
./my_test.sh
```

### JSON

Structured JSON output:

```bash
./my_test.sh --format=json
# Or with custom output file:
./my_test.sh --format=json --output=results.json
```

**Output structure:**
```json
{
  "testSuite": "Test Suite Name",
  "timestamp": "2025-10-27T10:30:45-0700",
  "duration": 1234,
  "summary": {
    "total": 10,
    "passed": 9,
    "failed": 1
  },
  "tests": [
    {
      "name": "Test description",
      "status": "passed",
      "duration": 123
    }
  ]
}
```

### YAML

YAML format for easy reading:

```bash
./my_test.sh --format=yaml --output=results.yaml
```

### CSV

Comma-separated values for spreadsheet import:

```bash
./my_test.sh --format=csv --output=results.csv
```

### JUnit XML

Jenkins/GitLab CI compatible format:

```bash
./my_test.sh --format=junit --output=results.xml
```

## Command Line Options

### --format=FORMAT

Specifies the output format. Valid values:
- `none` (default): Console output only
- `json`: JSON format
- `yaml`: YAML format
- `csv`: CSV format
- `junit`: JUnit XML format

```bash
./test.sh --format=json
./test.sh --format junit  # Alternative syntax
```

### --output=FILE

Specifies the output file for structured formats. If omitted, a filename is auto-generated based on the test script name.

```bash
./test.sh --format=json --output=/path/to/results.json
```

### --quiet, -q

Suppresses console output, only produces file output. Useful for CI/CD systems.

```bash
./test.sh --format=json --quiet
```

## Environment Variables

### TEST_OUTPUT_FORMAT

Set default output format (overridden by `--format`):

```bash
export TEST_OUTPUT_FORMAT=json
./test.sh
```

### TEST_QUIET_MODE

Enable quiet mode by default (overridden by `--quiet`):

```bash
export TEST_QUIET_MODE=true
./test.sh
```

## Examples

### Example 1: Basic String Tests

```bash
#!/usr/bin/env bash
source ./shellunittest/unittest.sh
initialize_test_framework "$@"

print_test_header "String Manipulation Tests"

# Test string equality
result="hello"
assert_equals "hello" "$result" "String should be 'hello'"

# Test string contains
result="hello world"
assert_contains "$result" "world" "Should contain 'world'"

print_summary
```

### Example 2: File Testing

```bash
#!/usr/bin/env bash
source ./shellunittest/unittest.sh
initialize_test_framework "$@"

print_test_header "File Operation Tests"

# Create a test file
echo "config=true" > /tmp/test_config.txt

# Test file exists
assert_file_exists "/tmp/test_config.txt" "Config file should exist"

# Test file content
assert_file_contains "/tmp/test_config.txt" "config=true" "Should contain config"

# Cleanup
rm /tmp/test_config.txt

print_summary
```

### Example 3: Command Exit Code Testing

```bash
#!/usr/bin/env bash
source ./shellunittest/unittest.sh
initialize_test_framework "$@"

print_test_header "Command Tests"

# Test successful command
true
assert_success "True command should succeed"

# Test specific exit code
(exit 2)
exit_code=$?
assert_exit_code 2 $exit_code "Should return exit code 2"

print_summary
```

### Example 4: CI/CD Integration

```bash
#!/usr/bin/env bash
source ./shellunittest/unittest.sh
initialize_test_framework "$@"

print_test_header "API Integration Tests"

# Your tests here...
assert_equals "200" "$(curl -s -o /dev/null -w "%{http_code}" https://api.example.com)" \
    "API should return 200"

print_summary
```

Run in CI:
```bash
./api_tests.sh --format=junit --output=test-results.xml --quiet
```

## API Reference

### Initialization Functions

#### initialize_test_framework

Initializes the test framework and parses command-line options.

```bash
initialize_test_framework "$@"
```

Must be called before any test functions.

### Output Functions

#### print_test_header

Prints the main test suite header.

```bash
print_test_header "Test Suite Name"
```

#### print_section

Prints a section header for grouping related tests.

```bash
print_section "Section Name"
```

#### print_test_name

Prints an individual test name (optional, for additional clarity).

```bash
print_test_name "Specific test description"
```

#### print_summary

Prints the test summary and exits with appropriate exit code.

```bash
print_summary
```

- Exit code 0: All tests passed
- Exit code 1: One or more tests failed

### Utility Functions

#### get_timestamp

Returns current timestamp in ISO 8601 format.

```bash
timestamp=$(get_timestamp)
# Example: 2025-10-27T10:30:45-0700
```

#### get_epoch_ms

Returns current time in milliseconds since epoch.

```bash
start_time=$(get_epoch_ms)
# ... do something ...
end_time=$(get_epoch_ms)
duration=$((end_time - start_time))
```

## Platform-Specific Notes

### macOS

The framework requires GNU versions of `grep` and `sed`. Install via Homebrew:

```bash
brew install grep gnu-sed
```

The framework automatically detects and uses:
- `ggrep` (GNU grep)
- `gsed` (GNU sed)

### Linux

Standard `grep` and `sed` work out of the box.

## Advanced Usage

### Custom Test Result Recording

```bash
# Record a custom test result
record_test_result "passed" "Test name" "Optional message" 123

# Access test results array
for result in "${TEST_RESULTS[@]}"; do
    IFS='|' read -r status name message duration <<< "$result"
    echo "Test: $name - Status: $status"
done
```

### Test State Variables

The framework maintains these global variables:

- `TESTS_RUN`: Total number of tests executed
- `TESTS_PASSED`: Number of passed tests
- `TESTS_FAILED`: Number of failed tests
- `TEST_START_TIME`: Start time in milliseconds
- `TEST_SUITE_NAME`: Name of the test suite
- `TEST_RESULTS`: Array of test results

## Best Practices

1. **Always initialize the framework**:
   ```bash
   initialize_test_framework "$@"
   ```

2. **Use descriptive test descriptions**:
   ```bash
   # Good
   assert_equals "200" "$status_code" "API should return HTTP 200 for valid requests"
   
   # Avoid
   assert_equals "200" "$status_code" "test"
   ```

3. **Organize tests into sections**:
   ```bash
   print_section "User Authentication"
   # ... auth tests ...
   
   print_section "Data Validation"
   # ... validation tests ...
   ```

4. **Clean up after tests**:
   ```bash
   # Create temporary files in /tmp
   tempfile=$(mktemp)
   
   # Run your tests
   
   # Always clean up
   rm "$tempfile"
   ```

5. **Use quiet mode in CI/CD**:
   ```bash
   ./tests.sh --format=junit --output=results.xml --quiet
   ```

## Troubleshooting

### Error: GNU grep is not installed

**macOS users**: Install GNU grep via Homebrew:
```bash
brew install grep
```

### Error: GNU sed is not installed

**macOS users**: Install GNU sed via Homebrew:
```bash
brew install gnu-sed
```

### JSON output fails

Install `jq`:
```bash
# macOS
brew install jq

# Linux (Debian/Ubuntu)
apt-get install jq
```

### YAML/JUnit output fails

Install `yq`:
```bash
# macOS
brew install yq

# Linux
pip install yq
```

## License

This framework is provided as-is for use in shell script testing.

## Contributing

When contributing, ensure:
- All code is in English
- Functions are documented
- Cross-platform compatibility is maintained (Linux and macOS)
- New assertion types follow the existing pattern

## Version History

### 1.0.0
- Initial release
- Cross-platform support (Linux, macOS)
- Multiple output formats (JSON, YAML, CSV, JUnit)
- Comprehensive assertion library
- Quiet mode support
- Performance tracking

