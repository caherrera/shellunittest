#!/usr/bin/env bash

# ============================================================================
# Test Framework Base - Centralized Testing Infrastructure
# ============================================================================

# ============================================================================
# OS Detection and GNU Tools Validation
# ============================================================================

detect_os_and_tools() {
    OS_TYPE=$(uname -s)
    GREP_CMD=""
    SED_CMD=""

    case "$OS_TYPE" in
        Darwin)
            if [ "$QUIET_MODE" != "true" ]; then
                echo "Detected macOS system"
            fi

            # Check for GNU grep (ggrep)
            if [ -x "/opt/homebrew/bin/ggrep" ]; then
                GREP_CMD="/opt/homebrew/bin/ggrep"
            elif [ -x "/usr/local/bin/ggrep" ]; then
                GREP_CMD="/usr/local/bin/ggrep"
            elif command -v ggrep &> /dev/null; then
                GREP_CMD="ggrep"
            else
                echo "❌ ERROR: GNU grep is not installed"
                echo ""
                echo "On macOS, you need to install GNU grep with Homebrew:"
                echo "  brew install grep"
                echo ""
                exit 1
            fi

            # Check for GNU sed (gsed)
            if [ -x "/opt/homebrew/bin/gsed" ]; then
                SED_CMD="/opt/homebrew/bin/gsed"
            elif [ -x "/usr/local/bin/gsed" ]; then
                SED_CMD="/usr/local/bin/gsed"
            elif command -v gsed &> /dev/null; then
                SED_CMD="gsed"
            else
                echo "❌ ERROR: GNU sed is not installed"
                echo ""
                echo "On macOS, you need to install GNU sed with Homebrew:"
                echo "  brew install gnu-sed"
                echo ""
                exit 1
            fi

            if [ "$QUIET_MODE" != "true" ]; then
                echo "✓ Found GNU grep: $GREP_CMD"
                echo "✓ Found GNU sed: $SED_CMD"
            fi
            ;;

        Linux)
            if [ "$QUIET_MODE" != "true" ]; then
                echo "Detected Linux system"
            fi
            GREP_CMD="grep"
            SED_CMD="sed"

            # Verify they are available
            if ! command -v grep &> /dev/null; then
                echo "❌ ERROR: grep command not found"
                exit 1
            fi

            if ! command -v sed &> /dev/null; then
                echo "❌ ERROR: sed command not found"
                exit 1
            fi

            if [ "$QUIET_MODE" != "true" ]; then
                echo "✓ Using system grep (GNU)"
                echo "✓ Using system sed (GNU)"
            fi
            ;;

        *)
            echo "❌ ERROR: Unsupported operating system: $OS_TYPE"
            echo "This test suite only supports Linux and macOS"
            exit 1
            ;;
    esac

    export GREP_CMD
    export SED_CMD
    if [ "$QUIET_MODE" != "true" ]; then
        echo ""
    fi
}

# ============================================================================
# Color Codes
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Test State Variables
# ============================================================================

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TEST_START_TIME=""
TEST_SUITE_NAME="Test Suite"
TEST_RESULTS=()

# Output format (none, json, yaml, csv, junit)
OUTPUT_FORMAT="${TEST_OUTPUT_FORMAT:-none}"
OUTPUT_FILE=""
QUIET_MODE="${TEST_QUIET_MODE:-false}"

# ============================================================================
# Utility Functions
# ============================================================================

get_timestamp() {
    date +"%Y-%m-%dT%H:%M:%S%z"
}

get_epoch_ms() {
    if command -v gdate &> /dev/null; then
        gdate +%s%3N
    elif date --version 2>/dev/null | grep -q GNU; then
        date +%s%3N
    else
        echo $(($(date +%s) * 1000))
    fi
}

escape_json() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\"/\\\"}"
    str="${str//$'\n'/\\n}"
    str="${str//$'\r'/\\r}"
    str="${str//$'\t'/\\t}"
    echo "$str"
}

escape_xml() {
    local str="$1"
    str="${str//&/&amp;}"
    str="${str//</&lt;}"
    str="${str//>/&gt;}"
    str="${str//\"/&quot;}"
    str="${str//\'/&apos;}"
    echo "$str"
}

# ============================================================================
# Print Functions (only show if not in quiet mode)
# ============================================================================

print_test_header() {
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}$1${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    fi
    TEST_SUITE_NAME="$1"
    TEST_START_TIME=$(get_epoch_ms)
}

print_section() {
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "\n${CYAN}▶ $1${NC}"
    fi
}

print_test_name() {
    if [ "$QUIET_MODE" != "true" ]; then
        echo -e "${YELLOW}  TEST $TESTS_RUN: $1${NC}"
    fi
}

# ============================================================================
# Test Result Recording
# ============================================================================

record_test_result() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "❌ ERROR: record_test_result requires at least 2 arguments: status and name"
        exit 1
    fi
    local status="$1"
    local name="$2"
    local message="${3:-}"
    local duration="${4:-0}"

    TEST_RESULTS+=("$status|$name|$message|$duration")
}

# ============================================================================
# Assertion Functions
# ============================================================================

assert_equals() {
  if [ $# -lt 3 ]; then
        echo "❌ ERROR: assert_equals requires 3 arguments: expected, actual, description"
        exit 1
    fi
    local expected="$1"
    local actual="$2"
    local description="$3"
    local test_start
    test_start=$(get_epoch_ms)

    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$expected" == "$actual" ]; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${GREEN}  ✓ PASSED: $description${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "passed" "$description" "" $((test_end - test_start))
        return 0
    else
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${RED}  ✗ FAILED: $description${NC}"
            echo -e "${RED}    Expected: '$expected'${NC}"
            echo -e "${RED}    Got:      '$actual'${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "failed" "$description" "Expected: '$expected', Got: '$actual'" $((test_end - test_start))
        return 1
    fi
}

assert_contains() {
  if [ $# -lt 3 ]; then
        echo "❌ ERROR: assert_contains requires 3 arguments: haystack, needle, description"
        exit 1
    fi
    local haystack="$1"
    local needle="$2"
    local description="$3"
    local test_start
    test_start=$(get_epoch_ms)

    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ "$haystack" == *"$needle"* ]]; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${GREEN}  ✓ PASSED: $description${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "passed" "$description" "" $((test_end - test_start))
        return 0
    else
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${RED}  ✗ FAILED: $description${NC}"
            echo -e "${RED}    Expected to find: '$needle'${NC}"
            echo -e "${RED}    In string:        '$haystack'${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "failed" "$description" "Expected to find: '$needle' in '$haystack'" $((test_end - test_start))
        return 1
    fi
}

assert_file_contains() {
  if [ $# -lt 3 ]; then
        echo "❌ ERROR: assert_file_contains requires 3 arguments: file, pattern, description"
        exit 1
    fi
    local file="$1"
    local pattern="$2"
    local description="$3"
    local test_start; test_start=$(get_epoch_ms)

    TESTS_RUN=$((TESTS_RUN + 1))
    if $GREP_CMD -qF -- "$pattern" "$file"; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${GREEN}  ✓ PASSED: $description${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "passed" "$description" "" $((test_end - test_start))
        return 0
    else
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${RED}  ✗ FAILED: $description${NC}"
            echo -e "${RED}    Expected to find: '$pattern' in file: $file${NC}"
            echo -e "${YELLOW}    File contents:${NC}"
            cat "$file" | sed 's/^/      /'
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "failed" "$description" "Pattern '$pattern' not found in file" $((test_end - test_start))
        return 1
    fi
}

assert_file_not_contains() {
  if [ $# -lt 3 ]; then
        echo "❌ ERROR: assert_file_not_contains requires 3 arguments: file, pattern, description"
        exit 1
    fi
    local file="$1"
    local pattern="$2"
    local description="$3"
    local test_start; test_start=$(get_epoch_ms)

    TESTS_RUN=$((TESTS_RUN + 1))
    if ! $GREP_CMD -qF -- "$pattern" "$file"; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${GREEN}  ✓ PASSED: $description${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "passed" "$description" "" $((test_end - test_start))
        return 0
    else
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${RED}  ✗ FAILED: $description${NC}"
            echo -e "${RED}    Did not expect to find: '$pattern' in file: $file${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "failed" "$description" "Unexpected pattern '$pattern' found in file" $((test_end - test_start))
        return 1
    fi
}

assert_file_exists() {
  if [ $# -lt 2 ]; then
        echo "❌ ERROR: assert_file_exists requires 2 arguments: file, description"
        exit 1
    fi
    local file="$1"
    local description="$2"
    local test_start; test_start=$(get_epoch_ms)

    TESTS_RUN=$((TESTS_RUN + 1))
    if [ -f "$file" ]; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${GREEN}  ✓ PASSED: $description${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "passed" "$description" "" $((test_end - test_start))
        return 0
    else
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${RED}  ✗ FAILED: $description${NC}"
            echo -e "${RED}    File does not exist: $file${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "failed" "$description" "File does not exist: $file" $((test_end - test_start))
        return 1
    fi
}

assert_success() {
  if [ $# -lt 1 ]; then
        echo "❌ ERROR: assert_success requires 1 argument: description"
        exit 1
    fi
    local description="$1"
    local test_start; test_start=$(get_epoch_ms)

    TESTS_RUN=$((TESTS_RUN + 1))
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${GREEN}  ✓ PASSED: $description${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "passed" "$description" "" $((test_end - test_start))
        return 0
    else
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${RED}  ✗ FAILED: $description${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "failed" "$description" "Command returned non-zero exit code" $((test_end - test_start))
        return 1
    fi
}

assert_exit_code() {
  if [ $# -lt 3 ]; then
        echo "❌ ERROR: assert_exit_code requires 3 arguments: expected_code, actual_code, description"
        exit 1
    fi
    local expected_code="$1"
    local actual_code="$2"
    local description="$3"
    local test_start; test_start=$(get_epoch_ms)

    TESTS_RUN=$((TESTS_RUN + 1))
    if [ "$actual_code" -eq "$expected_code" ]; then
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${GREEN}  ✓ PASSED: $description${NC}"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "passed" "$description" "" $((test_end - test_start))
        return 0
    else
        if [ "$QUIET_MODE" != "true" ]; then
            echo -e "${RED}  ✗ FAILED: $description${NC}"
            echo -e "${RED}    Expected exit code: $expected_code${NC}"
            echo -e "${RED}    Got exit code:      $actual_code${NC}"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        local test_end; test_end=$(get_epoch_ms);
        record_test_result "failed" "$description" "Expected exit code: $expected_code, Got: $actual_code" $((test_end - test_start))
        return 1
    fi
}

# ============================================================================
# Output Formatters
# ============================================================================

output_console_summary() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 TEST SUMMARY ${0##*/} ${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Total tests run: $TESTS_RUN"
    echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}"
    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Tests failed: $TESTS_FAILED${NC}"
    else
        echo -e "Tests failed: $TESTS_FAILED"
    fi

    if [ $TESTS_PASSED -gt 0 ] && [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

output_json() {
    local test_end; test_end=$(get_epoch_ms);
    local duration=$((test_end - TEST_START_TIME))

    # Build tests array
    local tests_json="[]"
    for result in "${TEST_RESULTS[@]}"; do
        IFS='|' read -r status name message test_duration <<< "$result"
        
        if [ -n "$message" ]; then
            tests_json=$(echo "$tests_json" | jq \
                --arg name "$name" \
                --arg status "$status" \
                --argjson duration "$test_duration" \
                --arg message "$message" \
                '. += [{name: $name, status: $status, duration: $duration, message: $message}]')
        else
            tests_json=$(echo "$tests_json" | jq \
                --arg name "$name" \
                --arg status "$status" \
                --argjson duration "$test_duration" \
                '. += [{name: $name, status: $status, duration: $duration}]')
        fi
    done

    # Build final JSON object
    jq -n \
        --arg testSuite "$TEST_SUITE_NAME" \
        --arg timestamp "$(get_timestamp)" \
        --argjson duration "$duration" \
        --argjson total "$TESTS_RUN" \
        --argjson passed "$TESTS_PASSED" \
        --argjson failed "$TESTS_FAILED" \
        --argjson tests "$tests_json" \
        '{
            testSuite: $testSuite,
            timestamp: $timestamp,
            duration: $duration,
            summary: {
                total: $total,
                passed: $passed,
                failed: $failed
            },
            tests: $tests
        }'
}

output_yaml() {
    # Convert JSON to YAML using yq
    output_json | yq -P
}

output_csv() {
    # Convert JSON to CSV using jq
    output_json | jq -r '
        # CSV header
        ["Test Name", "Status", "Duration (ms)", "Message"],
        # CSV rows
        (.tests[] | [.name, .status, .duration, (.message // "")])
        | @csv'
}

output_junit() {
    # Convert JSON to JUnit XML format using jq and yq
    output_json | jq '{
        testsuite: {
            "@name": .testSuite,
            "@tests": .summary.total,
            "@failures": .summary.failed,
            "@time": (.duration / 1000),
            "@timestamp": .timestamp,
            testcase: [
                .tests[] | {
                    "@name": .name,
                    "@time": (.duration / 1000)
                } + (
                    if .status == "failed" then
                        {
                            failure: {
                                "@message": .message,
                                "#text": .message
                            }
                        }
                    else
                        {}
                    end
                )
            ]
        }
    }' | yq -p json -o xml --xml-attribute-prefix @ --xml-content-name '#text'
}

# ============================================================================
# File Output Helper
# ============================================================================

write_output_to_file() {
    local format="$1"
    local output_file="$2"
    local content="$3"

    echo "$content" > "$output_file"

    if [ "$QUIET_MODE" != "true" ]; then
        echo ""
        echo -e "${GREEN}✓ Test results written to: $output_file${NC}"
    fi
}

get_output_file_extension() {
    local format="$1"
    case "$format" in
        json) echo ".json" ;;
        yaml) echo ".yaml" ;;
        csv) echo ".csv" ;;
        junit) echo ".xml" ;;
        *) echo ".txt" ;;
    esac
}

generate_default_output_filename() {
    local format="$1"
    local test_script="${BASH_SOURCE[2]}"

    # Get the base name without extension
    local base_name
    base_name=$(basename "$test_script" .sh)
    local extension
    extension=$(get_output_file_extension "$format")

    # Generate filename in format: test-results-<test-name>.<extension>
    echo "test-results-${base_name}${extension}"
}

# ============================================================================
# Summary and Output
# ============================================================================

print_summary() {
    local output_content=""

    # Always show console summary unless in quiet mode
    if [ "$QUIET_MODE" != "true" ]; then
        output_console_summary
    fi

    # Generate structured format if specified
    if [ "$OUTPUT_FORMAT" != "none" ]; then
        case "$OUTPUT_FORMAT" in
            json)
                output_content=$(output_json)
                ;;
            yaml)
                output_content=$(output_yaml)
                ;;
            csv)
                output_content=$(output_csv)
                ;;
            junit)
                output_content=$(output_junit)
                ;;
        esac

        # Determine output file
        if [ -n "$OUTPUT_FILE" ]; then
            # User specified output file
            write_output_to_file "$OUTPUT_FORMAT" "$OUTPUT_FILE" "$output_content"
        elif [ "$OUTPUT_FORMAT" != "none" ]; then
            # Auto-generate output filename based on test script name
            local auto_filename
            auto_filename=$(generate_default_output_filename "$OUTPUT_FORMAT")
            write_output_to_file "$OUTPUT_FORMAT" "$auto_filename" "$output_content"
        else
            # No file output, just print to stdout
            echo "$output_content"
        fi
    fi

    if [ $TESTS_FAILED -gt 0 ]; then
        exit 1
    fi
}

# ============================================================================
# Initialize Framework
# ============================================================================

initialize_test_framework() {
    # Parse command line options
    while [ $# -gt 0 ]; do
        case "$1" in
            --format=*)
                OUTPUT_FORMAT="${1#*=}"
                shift
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --output=*)
                OUTPUT_FILE="${1#*=}"
                shift
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            --quiet|-q)
                QUIET_MODE="true"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Detect OS and tools
    detect_os_and_tools
}

# Export functions
export -f get_timestamp
export -f get_epoch_ms
export -f escape_json
export -f escape_xml
export -f print_test_header
export -f print_section
export -f print_test_name
export -f record_test_result
export -f assert_equals
export -f assert_contains
export -f assert_file_contains
export -f assert_file_not_contains
export -f assert_file_exists
export -f assert_success
export -f assert_exit_code
export -f print_summary
export -f write_output_to_file
export -f get_output_file_extension
export -f generate_default_output_filename
