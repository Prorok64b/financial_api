#!/bin/bash

# Login and get JWT token
# Usage: ./bin/api/login.sh [email] [password]
#
# Parameters:
#   email    - User's email address (default: demo@example.com)
#   password - User's password (default: demo1234)
#
# The token is saved to /tmp/financial_api_token for use by other scripts
#
# Example:
#   ./bin/api/login.sh demo@example.com demo1234

BASE_URL="${API_URL:-http://localhost:3000}"
TOKEN_FILE="/tmp/financial_api_token"
EMAIL="${1:-demo@example.com}"
PASSWORD="${2:-demo1234}"

echo "Logging in as: $EMAIL"
echo ""

RESPONSE=$(curl -s -i -X POST "$BASE_URL/users/sign_in" \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$EMAIL\",
      \"password\": \"$PASSWORD\"
    }
  }")

# Extract token from Authorization header
TOKEN=$(echo "$RESPONSE" | grep -i "Authorization:" | awk '{print $3}' | tr -d '\r')

if [ -n "$TOKEN" ]; then
  echo "$TOKEN" > "$TOKEN_FILE"
  echo "Login successful!"
  echo ""
  echo "Token saved to: $TOKEN_FILE"
  echo ""
  echo "Token: $TOKEN"
else
  echo "Login failed!"
  echo ""
  echo "$RESPONSE" | tail -n 1
fi

echo ""
