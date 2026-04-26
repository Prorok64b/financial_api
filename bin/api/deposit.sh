#!/bin/bash

# Deposit funds to account
# Usage: ./bin/api/deposit.sh [amount]
#
# Parameters:
#   amount - Amount to deposit, must be > 0 (default: 100.00)
#
# Requires: Login first using login.sh
#
# Response (success):
#   {
#     "message": "Deposit successful",
#     "balance": "200.0"
#   }
#
# Response (error):
#   {
#     "error": "Amount must be greater than 0"
#   }
#
# Example:
#   ./bin/api/login.sh demo@example.com demo1234
#   ./bin/api/deposit.sh 100.50

BASE_URL="${API_URL:-http://localhost:3000}"
TOKEN_FILE="/tmp/financial_api_token"
AMOUNT="${1:-100.00}"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Error: No token found. Please login first:"
  echo "  ./bin/api/login.sh"
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

echo "Depositing: \$$AMOUNT"
echo ""

curl -X POST "$BASE_URL/v1/account/deposit" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": $AMOUNT
  }" | jq .

echo ""
