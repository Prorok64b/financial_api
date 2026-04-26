#!/bin/bash

# Get current account balance
# Usage: ./bin/api/balance.sh
#
# Requires: Login first using login.sh
#
# Response:
#   {
#     "balance": "100.0"
#   }
#
# Example:
#   ./bin/api/login.sh demo@example.com demo1234
#   ./bin/api/balance.sh

BASE_URL="${API_URL:-http://localhost:3000}"
TOKEN_FILE="/tmp/financial_api_token"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Error: No token found. Please login first:"
  echo "  ./bin/api/login.sh"
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

echo "Getting balance..."
echo ""

curl -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq .

echo ""
