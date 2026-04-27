#!/bin/bash

# Test the complete API flow
# Usage: ./bin/api/test_flow.sh
#
# This script tests the entire API workflow:
#   1. Register two test users
#   2. Login and authenticate
#   3. Deposit funds
#   4. Check balance
#   5. Withdraw funds
#   6. Transfer between users
#   7. View transaction history
#
# Prerequisites:
#   - Server running at localhost:3000 (or set API_URL)
#   - jq installed for JSON parsing
#
# Example:
#   ./bin/api/test_flow.sh
#   API_URL=http://localhost:3001 ./bin/api/test_flow.sh

BASE_URL="${API_URL:-http://localhost:3000}"
TOKEN_FILE="/tmp/financial_api_token"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test users
USER1_EMAIL="testuser1_$(date +%s)@example.com"
USER1_PASSWORD="password123"
USER2_EMAIL="testuser2_$(date +%s)@example.com"
USER2_PASSWORD="password123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0

print_header() {
  echo ""
  echo -e "${BLUE}========================================${NC}"
  echo -e "${BLUE}$1${NC}"
  echo -e "${BLUE}========================================${NC}"
}

print_step() {
  echo ""
  echo -e "${YELLOW}>>> $1${NC}"
}

print_success() {
  echo -e "${GREEN}[PASS]${NC} $1"
  PASSED=$((PASSED + 1))
}

print_failure() {
  echo -e "${RED}[FAIL]${NC} $1"
  FAILED=$((FAILED + 1))
}

check_response() {
  local response="$1"
  local expected_key="$2"
  local expected_value="$3"
  local description="$4"

  actual_value=$(echo "$response" | jq -r ".$expected_key // empty")

  if [ "$actual_value" == "$expected_value" ]; then
    print_success "$description"
  else
    print_failure "$description (expected: $expected_value, got: $actual_value)"
  fi
}

check_response_contains() {
  local response="$1"
  local key="$2"
  local description="$3"

  actual_value=$(echo "$response" | jq -r ".$key // empty")

  if [ -n "$actual_value" ] && [ "$actual_value" != "null" ]; then
    print_success "$description"
  else
    print_failure "$description (key '$key' not found or empty)"
  fi
}

# ============================================
# START TESTS
# ============================================

print_header "Financial API Integration Test"
echo "Base URL: $BASE_URL"
echo "Test User 1: $USER1_EMAIL"
echo "Test User 2: $USER2_EMAIL"

# ============================================
# Test 1: Register User 1
# ============================================
print_step "1. Registering User 1"

RESPONSE=$(curl -s -X POST "$BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$USER1_EMAIL\",
      \"password\": \"$USER1_PASSWORD\"
    }
  }")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "message" "Signed up" "User 1 registration"
check_response "$RESPONSE" "user.email" "$USER1_EMAIL" "User 1 email returned"

# ============================================
# Test 2: Register User 2
# ============================================
print_step "2. Registering User 2"

RESPONSE=$(curl -s -X POST "$BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$USER2_EMAIL\",
      \"password\": \"$USER2_PASSWORD\"
    }
  }")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "message" "Signed up" "User 2 registration"

# ============================================
# Test 3: Login as User 1
# ============================================
print_step "3. Logging in as User 1"

FULL_RESPONSE=$(curl -s -i -X POST "$BASE_URL/users/sign_in" \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$USER1_EMAIL\",
      \"password\": \"$USER1_PASSWORD\"
    }
  }")

TOKEN1=$(echo "$FULL_RESPONSE" | grep -i "Authorization:" | awk '{print $3}' | tr -d '\r')
RESPONSE=$(echo "$FULL_RESPONSE" | tail -n 1)

echo "$RESPONSE" | jq .

if [ -n "$TOKEN1" ]; then
  print_success "User 1 received JWT token"
  echo "$TOKEN1" > "$TOKEN_FILE"
else
  print_failure "User 1 JWT token not received"
fi

check_response_contains "$RESPONSE" "message" "Login response contains message"

# ============================================
# Test 4: Check Initial Balance (should be 0)
# ============================================
print_step "4. Checking User 1 initial balance"

RESPONSE=$(curl -s -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "balance" "0.0" "Initial balance is 0"

# ============================================
# Test 5: Deposit $500
# ============================================
print_step "5. Depositing \$500"

RESPONSE=$(curl -s -X POST "$BASE_URL/v1/account/deposit" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"amount": 500.00}')

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "message" "Deposit successful" "Deposit message"
check_response "$RESPONSE" "balance" "500.0" "Balance after deposit"

# ============================================
# Test 6: Check Balance After Deposit
# ============================================
print_step "6. Checking balance after deposit"

RESPONSE=$(curl -s -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "balance" "500.0" "Balance is 500"

# ============================================
# Test 7: Withdraw $100
# ============================================
print_step "7. Withdrawing \$100"

RESPONSE=$(curl -s -X POST "$BASE_URL/v1/account/withdraw" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100.00}')

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "message" "Withdrawal successful" "Withdrawal message"
check_response "$RESPONSE" "balance" "400.0" "Balance after withdrawal"

# ============================================
# Test 8: Try to withdraw more than balance (should fail)
# ============================================
print_step "8. Attempting to withdraw more than balance (should fail)"

RESPONSE=$(curl -s -X POST "$BASE_URL/v1/account/withdraw" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000.00}')

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "error" "Insufficient funds" "Insufficient funds error"

# ============================================
# Test 9: Login as User 2
# ============================================
print_step "9. Logging in as User 2"

FULL_RESPONSE=$(curl -s -i -X POST "$BASE_URL/users/sign_in" \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$USER2_EMAIL\",
      \"password\": \"$USER2_PASSWORD\"
    }
  }")

TOKEN2=$(echo "$FULL_RESPONSE" | grep -i "Authorization:" | awk '{print $3}' | tr -d '\r')
RESPONSE=$(echo "$FULL_RESPONSE" | tail -n 1)

echo "$RESPONSE" | jq .

if [ -n "$TOKEN2" ]; then
  print_success "User 2 received JWT token"
else
  print_failure "User 2 JWT token not received"
fi

# ============================================
# Test 10: Check User 2 Initial Balance
# ============================================
print_step "10. Checking User 2 initial balance"

RESPONSE=$(curl -s -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN2" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "balance" "0.0" "User 2 initial balance is 0"

# ============================================
# Test 11: Transfer $150 from User 1 to User 2
# ============================================
print_step "11. Transferring \$150 from User 1 to User 2"

# Use User 1's token
RESPONSE=$(curl -s -X POST "$BASE_URL/v1/account/transfer" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": 150.00,
    \"recipient_email\": \"$USER2_EMAIL\"
  }")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "message" "Transfer successful" "Transfer message"
check_response "$RESPONSE" "amount" "150.0" "Transfer amount"
check_response "$RESPONSE" "balance" "250.0" "User 1 balance after transfer"

# ============================================
# Test 12: Check User 1 Balance After Transfer
# ============================================
print_step "12. Checking User 1 balance after transfer"

RESPONSE=$(curl -s -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "balance" "250.0" "User 1 balance is 250"

# ============================================
# Test 13: Check User 2 Balance After Transfer
# ============================================
print_step "13. Checking User 2 balance after transfer"

RESPONSE=$(curl -s -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN2" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "balance" "150.0" "User 2 balance is 150"

# ============================================
# Test 14: Try to transfer to self (should fail)
# ============================================
print_step "14. Attempting self-transfer (should fail)"

RESPONSE=$(curl -s -X POST "$BASE_URL/v1/account/transfer" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": 50.00,
    \"recipient_email\": \"$USER1_EMAIL\"
  }")

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "error" "Cannot transfer to yourself" "Self-transfer error"

# ============================================
# Test 15: Try to transfer to non-existent user (should fail)
# ============================================
print_step "15. Attempting transfer to non-existent user (should fail)"

RESPONSE=$(curl -s -X POST "$BASE_URL/v1/account/transfer" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50.00,
    "recipient_email": "nonexistent@example.com"
  }')

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "error" "Recipient not found" "Recipient not found error"

# ============================================
# Test 16: View User 1 Transaction History
# ============================================
print_step "16. Viewing User 1 transaction history"

RESPONSE=$(curl -s -X GET "$BASE_URL/v1/account/transactions" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq .
check_response_contains "$RESPONSE" "transactions" "Transactions array returned"

TRANSACTION_COUNT=$(echo "$RESPONSE" | jq '.transactions | length')
if [ "$TRANSACTION_COUNT" -eq 3 ]; then
  print_success "User 1 has 3 transactions (deposit, withdrawal, transfer_out)"
else
  print_failure "User 1 should have 3 transactions (got: $TRANSACTION_COUNT)"
fi

# ============================================
# Test 17: View User 2 Transaction History
# ============================================
print_step "17. Viewing User 2 transaction history"

RESPONSE=$(curl -s -X GET "$BASE_URL/v1/account/transactions" \
  -H "Authorization: Bearer $TOKEN2" \
  -H "Content-Type: application/json")

echo "$RESPONSE" | jq .

TRANSACTION_COUNT=$(echo "$RESPONSE" | jq '.transactions | length')
if [ "$TRANSACTION_COUNT" -eq 1 ]; then
  print_success "User 2 has 1 transaction (transfer_in)"
else
  print_failure "User 2 should have 1 transaction (got: $TRANSACTION_COUNT)"
fi

# ============================================
# Test 18: Deposit with invalid amount (should fail)
# ============================================
print_step "18. Attempting deposit with zero amount (should fail)"

RESPONSE=$(curl -s -X POST "$BASE_URL/v1/account/deposit" \
  -H "Authorization: Bearer $TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"amount": 0}')

echo "$RESPONSE" | jq .
check_response "$RESPONSE" "error" "Amount must be greater than 0" "Zero amount error"

# ============================================
# Test 19: Access without token (should fail)
# ============================================
print_step "19. Attempting to access balance without token (should fail)"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/v1/account/balance" \
  -H "Content-Type: application/json")

if [ "$HTTP_STATUS" -eq 401 ]; then
  print_success "Unauthorized request returns 401"
else
  print_failure "Unauthorized request should return 401 (got: $HTTP_STATUS)"
fi

# ============================================
# Test 20: Invalid login (should fail)
# ============================================
print_step "20. Attempting login with wrong password (should fail)"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/users/sign_in" \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$USER1_EMAIL\",
      \"password\": \"wrongpassword\"
    }
  }")

if [ "$HTTP_STATUS" -eq 401 ]; then
  print_success "Wrong password returns 401"
else
  print_failure "Wrong password should return 401 (got: $HTTP_STATUS)"
fi

# ============================================
# SUMMARY
# ============================================
print_header "Test Summary"

TOTAL=$((PASSED + FAILED))
TOTAL=${TOTAL:-0}
echo ""
echo -e "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed!${NC}"
  exit 1
fi
