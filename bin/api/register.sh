#!/bin/bash

# Register a new user
# Usage: ./bin/api/register.sh [email] [password]
#
# Parameters:
#   email    - User's email address (default: test@example.com)
#   password - User's password, min 6 characters (default: password123)
#
# Example:
#   ./bin/api/register.sh user@example.com mypassword

BASE_URL="${API_URL:-http://localhost:3000}"
EMAIL="${1:-test@example.com}"
PASSWORD="${2:-password123}"

echo "Registering user: $EMAIL"
echo ""

curl -X POST "$BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d "{
    \"user\": {
      \"email\": \"$EMAIL\",
      \"password\": \"$PASSWORD\"
    }
  }" | jq .

echo ""
