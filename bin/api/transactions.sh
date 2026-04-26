#!/bin/bash

# Get transaction history
# Usage: ./bin/api/transactions.sh
#
# Requires: Login first using login.sh
#
# Response:
#   {
#     "transactions": [
#       {
#         "id": 1,
#         "amount": "100.0",
#         "type": "deposit",
#         "balance_after": "100.0",
#         "created_at": "2024-01-15T10:00:00.000Z"
#       },
#       {
#         "id": 2,
#         "amount": "25.0",
#         "type": "transfer_out",
#         "balance_after": "75.0",
#         "counterparty_email": "alice@example.com",
#         "created_at": "2024-01-15T11:00:00.000Z"
#       }
#     ]
#   }
#
# Transaction types:
#   - deposit      : Funds added to account
#   - withdrawal   : Funds removed from account
#   - transfer_in  : Funds received from another user
#   - transfer_out : Funds sent to another user
#
# Example:
#   ./bin/api/login.sh demo@example.com demo1234
#   ./bin/api/transactions.sh

BASE_URL="${API_URL:-http://localhost:3000}"
TOKEN_FILE="/tmp/financial_api_token"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Error: No token found. Please login first:"
  echo "  ./bin/api/login.sh"
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

echo "Getting transaction history..."
echo ""

curl -X GET "$BASE_URL/v1/account/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq .

echo ""
