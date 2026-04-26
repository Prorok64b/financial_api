#!/bin/bash

# Transfer funds to another user
# Usage: ./bin/api/transfer.sh [amount] [recipient_email]
#
# Parameters:
#   amount          - Amount to transfer, must be > 0 and <= balance (default: 25.00)
#   recipient_email - Email of the recipient user (default: alice@example.com)
#
# Requires: Login first using login.sh
#
# Response (success):
#   {
#     "message": "Transfer successful",
#     "amount": "25.0",
#     "recipient": "alice@example.com",
#     "balance": "75.0"
#   }
#
# Response (recipient not found):
#   {
#     "error": "Recipient not found"
#   }
#
# Response (self-transfer):
#   {
#     "error": "Cannot transfer to yourself"
#   }
#
# Response (insufficient funds):
#   {
#     "error": "Insufficient funds"
#   }
#
# Example:
#   ./bin/api/login.sh demo@example.com demo1234
#   ./bin/api/transfer.sh 50.00 bob@example.com

BASE_URL="${API_URL:-http://localhost:3000}"
TOKEN_FILE="/tmp/financial_api_token"
AMOUNT="${1:-25.00}"
RECIPIENT="${2:-alice@example.com}"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "Error: No token found. Please login first:"
  echo "  ./bin/api/login.sh"
  exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")

echo "Transferring: \$$AMOUNT to $RECIPIENT"
echo ""

curl -X POST "$BASE_URL/v1/account/transfer" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": $AMOUNT,
    \"recipient_email\": \"$RECIPIENT\"
  }" | jq .

echo ""
