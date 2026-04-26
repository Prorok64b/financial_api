#!/bin/bash

# Withdraw funds from account
# Usage: ./bin/api/withdraw.sh [amount]
#
# Parameters:
#   amount - Amount to withdraw, must be > 0 and <= balance (default: 50.00)
#
# Requires: Login first using login.sh
#
# Response (success):
#   {
#     "message": "Withdrawal successful",
#     "balance": "50.0"
#   }
#
# Response (insufficient funds):
#   {
#     "error": "Insufficient funds"
#   }
#
# Response (invalid amount):
#   {
#     "error": "Amount must be greater than 0"
#   }
#
# Example:
#   ./bin/api/login.sh demo@example.com demo1234
#   ./bin/api/withdraw.sh 50.00

BASE_URL="${API_URL:-http://localhost:3000}"
TOKEN_FILE="/tmp/financial_api_token"
AMOUNT="${1:-50.00}"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Error: No token found. Please login first:"
  echo "  ./bin/api/login.sh"
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

echo "Withdrawing: \$$AMOUNT"
echo ""

curl -X POST "$BASE_URL/v1/account/withdraw" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": $AMOUNT
  }" | jq .

echo ""
