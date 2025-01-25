#!/usr/bin/env bash

# Colors for test output
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Utility function to print test results
print_test_result() {
    local test_name="$1"
    local result="$2"
    local message="${3:-}"
    
    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${RESET}: $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAIL${RESET}: $test_name"
        if [ -n "$message" ]; then
            echo "  Error: $message"
        fi
        ((TESTS_FAILED++))
    fi
}

# Test the offline safe transaction hash calculation
test_offline_tx_hash() {
    # Run the script and capture output
    local output=$(./safe_hashes.sh --offline \
        --network sepolia \
        --address 0x86D46EcD553d25da0E3b96A9a1B442ac72fa9e9F \
        --nonce 6 \
        --to 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9 \
        --data 0x095ea7b3000000000000000000000000fe2f653f6579de62aaf8b186e618887d03fa31260000000000000000000000000000000000000000000000000000000000000001) || true
    
    # Test each hash exactly once
    if echo "$output" | grep -q "0xE411DFD2D178C853945BE30E1CEFBE090E56900073377BA8B8D0B47BAEC31EDB"; then
        print_test_result "Domain Hash Check" 0
    else
        print_test_result "Domain Hash Check" 1
    fi
    
    if echo "$output" | grep -q "0x4BBDE73F23B1792683730E7AE534A56A0EFAA8B7B467FF605202763CE2124DBC"; then
        print_test_result "Message Hash Check" 0
    else
        print_test_result "Message Hash Check" 1
    fi
    
    if echo "$output" | grep -q "0x213be037275c94449a28b4edead76b0d63c7e12b52257f9d5686d98b9a1a5ff4"; then
        print_test_result "Safe Transaction Hash Check" 0
    else
        print_test_result "Safe Transaction Hash Check" 1
    fi
}

# Run test
test_offline_tx_hash

# Print final results
echo
echo "Test Results:"
echo "============"
echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${RESET}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${RESET}"

# Exit with failure if any tests failed
[ "$TESTS_FAILED" -eq 0 ] || exit 1