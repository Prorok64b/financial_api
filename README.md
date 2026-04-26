# Financial API

A Rails API for managing user funds with deposit, withdrawal, and transfer functionality.

## Table of Contents

- [Ruby Version](#ruby-version)
- [Setup](#setup)
- [Running Tests](#running-tests)
- [Seed Data](#seed-data)
- [Testing Scripts](#testing-scripts)
  - [Available Scripts](#available-scripts)
  - [Quick Start](#quick-start)
  - [Script Parameters](#script-parameters)
  - [Environment Variables](#environment-variables)
- [API Endpoints](#api-endpoints)
  - [Authentication](#authentication)
    - [Register a New User](#register-a-new-user)
    - [Login](#login)
  - [Account Endpoints](#account-endpoints)
    - [Get Balance](#get-balance)
    - [Deposit](#deposit)
    - [Withdraw](#withdraw)
    - [Transfer](#transfer)
    - [Transaction History](#transaction-history)
- [Complete Testing Script](#complete-testing-script)
- [Error Handling](#error-handling)

---

## Ruby Version

- Ruby 3.4.1
- Rails 8.0.5

[Back to Table of Contents](#table-of-contents)

---

## Setup

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Run the server
rails s
```

[Back to Table of Contents](#table-of-contents)

---

## Running Tests

```bash
bundle exec rspec
```

[Back to Table of Contents](#table-of-contents)

---

## Seed Data

Load test users and sample transactions:

```bash
rails db:seed
```

**Seeded test users:**

| Email | Password | Description |
|-------|----------|-------------|
| alice@example.com | password123 | User with transaction history |
| bob@example.com | password123 | User with transaction history |
| charlie@example.com | password123 | User with transaction history |
| demo@example.com | demo1234 | Demo account for testing |

[Back to Table of Contents](#table-of-contents)

---

## Testing Scripts

The `bin/api/` directory contains shell scripts for testing each API endpoint.

### Available Scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `register.sh` | Register a new user | `./bin/api/register.sh [email] [password]` |
| `login.sh` | Login and save token | `./bin/api/login.sh [email] [password]` |
| `balance.sh` | Get current balance | `./bin/api/balance.sh` |
| `deposit.sh` | Deposit funds | `./bin/api/deposit.sh [amount]` |
| `withdraw.sh` | Withdraw funds | `./bin/api/withdraw.sh [amount]` |
| `transfer.sh` | Transfer to another user | `./bin/api/transfer.sh [amount] [recipient_email]` |
| `transactions.sh` | Get transaction history | `./bin/api/transactions.sh` |

### Quick Start

```bash
# 1. Start the server
rails s

# 2. Login (uses demo@example.com by default)
./bin/api/login.sh

# 3. Check your balance
./bin/api/balance.sh

# 4. Make a deposit
./bin/api/deposit.sh 100

# 5. Make a withdrawal
./bin/api/withdraw.sh 25

# 6. Transfer to another user
./bin/api/transfer.sh 10 alice@example.com

# 7. View transaction history
./bin/api/transactions.sh
```

### Script Parameters

#### register.sh
```bash
./bin/api/register.sh [email] [password]

# Examples:
./bin/api/register.sh                           # Uses test@example.com / password123
./bin/api/register.sh user@example.com secret   # Custom credentials
```

#### login.sh
```bash
./bin/api/login.sh [email] [password]

# Examples:
./bin/api/login.sh                              # Uses demo@example.com / demo1234
./bin/api/login.sh alice@example.com password123
```

The token is automatically saved to `/tmp/financial_api_token` and used by other scripts.

#### deposit.sh
```bash
./bin/api/deposit.sh [amount]

# Examples:
./bin/api/deposit.sh          # Deposits $100.00
./bin/api/deposit.sh 250.50   # Deposits $250.50
```

#### withdraw.sh
```bash
./bin/api/withdraw.sh [amount]

# Examples:
./bin/api/withdraw.sh         # Withdraws $50.00
./bin/api/withdraw.sh 75.25   # Withdraws $75.25
```

#### transfer.sh
```bash
./bin/api/transfer.sh [amount] [recipient_email]

# Examples:
./bin/api/transfer.sh                              # Transfers $25.00 to alice@example.com
./bin/api/transfer.sh 100 bob@example.com          # Transfers $100.00 to bob@example.com
```

### Environment Variables

Set `API_URL` to use a different server:

```bash
export API_URL=http://localhost:4000
./bin/api/login.sh
```

[Back to Table of Contents](#table-of-contents)

---

## API Endpoints

### Authentication

All account endpoints require JWT authentication. Include the token in the `Authorization` header.

#### Register a New User

```bash
curl -X POST http://localhost:3000/users \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123"
    }
  }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user[email] | string | Yes | User's email address |
| user[password] | string | Yes | User's password (min 6 characters) |

**Response (201 Created):**
```json
{
  "message": "Signed up successfully.",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

[Back to Table of Contents](#table-of-contents)

#### Login

```bash
curl -X POST http://localhost:3000/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123"
    }
  }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| user[email] | string | Yes | User's email address |
| user[password] | string | Yes | User's password |

**Response (200 OK):**

The JWT token is returned in the `Authorization` header.

```json
{
  "message": "Logged in successfully.",
  "user": {
    "id": 1,
    "email": "user@example.com"
  }
}
```

#### Store Token for Subsequent Requests

```bash
TOKEN=$(curl -s -X POST http://localhost:3000/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"user@example.com","password":"password123"}}' \
  -i | grep -i "Authorization:" | awk '{print $3}' | tr -d '\r')
```

[Back to Table of Contents](#table-of-contents)

---

### Account Endpoints

#### Get Balance

Returns the current balance of the authenticated user.

```bash
curl -X GET http://localhost:3000/v1/account/balance \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Parameters:** None

**Response (200 OK):**
```json
{
  "balance": "100.0"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| balance | string | Current account balance (decimal format) |

[Back to Table of Contents](#table-of-contents)

---

#### Deposit

Adds funds to the authenticated user's account.

```bash
curl -X POST http://localhost:3000/v1/account/deposit \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 100.50
  }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| amount | decimal | Yes | Amount to deposit (must be > 0) |

**Response (200 OK):**
```json
{
  "message": "Deposit successful",
  "balance": "100.5"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| message | string | Success message |
| balance | string | New account balance after deposit |

**Error Response (422 Unprocessable Entity):**
```json
{
  "error": "Amount must be greater than 0"
}
```

[Back to Table of Contents](#table-of-contents)

---

#### Withdraw

Removes funds from the authenticated user's account.

```bash
curl -X POST http://localhost:3000/v1/account/withdraw \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50.00
  }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| amount | decimal | Yes | Amount to withdraw (must be > 0 and <= current balance) |

**Response (200 OK):**
```json
{
  "message": "Withdrawal successful",
  "balance": "50.5"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| message | string | Success message |
| balance | string | New account balance after withdrawal |

**Error Responses:**

*Insufficient funds (422 Unprocessable Entity):*
```json
{
  "error": "Insufficient funds"
}
```

*Invalid amount (422 Unprocessable Entity):*
```json
{
  "error": "Amount must be greater than 0"
}
```

[Back to Table of Contents](#table-of-contents)

---

#### Transfer

Transfers funds from the authenticated user to another user.

```bash
curl -X POST http://localhost:3000/v1/account/transfer \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 25.00,
    "recipient_email": "recipient@example.com"
  }'
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| amount | decimal | Yes | Amount to transfer (must be > 0 and <= current balance) |
| recipient_email | string | Yes | Email address of the recipient user |

**Response (200 OK):**
```json
{
  "message": "Transfer successful",
  "amount": "25.0",
  "recipient": "recipient@example.com",
  "balance": "25.5"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| message | string | Success message |
| amount | string | Amount transferred |
| recipient | string | Recipient's email address |
| balance | string | Sender's new balance after transfer |

**Error Responses:**

*Recipient not found (404 Not Found):*
```json
{
  "error": "Recipient not found"
}
```

*Self-transfer (422 Unprocessable Entity):*
```json
{
  "error": "Cannot transfer to yourself"
}
```

*Insufficient funds (422 Unprocessable Entity):*
```json
{
  "error": "Insufficient funds"
}
```

*Invalid amount (422 Unprocessable Entity):*
```json
{
  "error": "Amount must be greater than 0"
}
```

[Back to Table of Contents](#table-of-contents)

---

#### Transaction History

Returns the transaction history for the authenticated user.

```bash
curl -X GET http://localhost:3000/v1/account/transactions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

**Parameters:** None

**Response (200 OK):**
```json
{
  "transactions": [
    {
      "id": 3,
      "amount": "25.0",
      "type": "transfer_out",
      "balance_after": "25.5",
      "counterparty_email": "recipient@example.com",
      "created_at": "2024-01-15T10:30:00.000Z"
    },
    {
      "id": 2,
      "amount": "50.0",
      "type": "withdrawal",
      "balance_after": "50.5",
      "created_at": "2024-01-15T10:20:00.000Z"
    },
    {
      "id": 1,
      "amount": "100.5",
      "type": "deposit",
      "balance_after": "100.5",
      "created_at": "2024-01-15T10:00:00.000Z"
    }
  ]
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| transactions | array | List of transactions (newest first) |

**Transaction Object Fields:**

| Field | Type | Description |
|-------|------|-------------|
| id | integer | Transaction ID |
| amount | string | Transaction amount |
| type | string | Transaction type: `deposit`, `withdrawal`, `transfer_in`, `transfer_out` |
| balance_after | string | Account balance after this transaction |
| counterparty_email | string | (Optional) For transfers, the other party's email |
| created_at | string | ISO 8601 timestamp of when transaction occurred |

[Back to Table of Contents](#table-of-contents)

---

## Complete Testing Script

```bash
#!/bin/bash

BASE_URL="http://localhost:3000"

# 1. Register a new user
echo "=== Registering user ==="
curl -X POST "$BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}'
echo -e "\n"

# 2. Login and get token
echo "=== Logging in ==="
TOKEN=$(curl -s -X POST "$BASE_URL/users/sign_in" \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}' \
  -i | grep -i "Authorization:" | awk '{print $3}' | tr -d '\r')
echo "Token: $TOKEN"
echo -e "\n"

# 3. Check initial balance
echo "=== Checking balance ==="
curl -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
echo -e "\n"

# 4. Deposit funds
echo "=== Depositing 100.50 ==="
curl -X POST "$BASE_URL/v1/account/deposit" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100.50}'
echo -e "\n"

# 5. Withdraw funds
echo "=== Withdrawing 25.00 ==="
curl -X POST "$BASE_URL/v1/account/withdraw" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 25.00}'
echo -e "\n"

# 6. Register another user for transfer
echo "=== Registering recipient ==="
curl -X POST "$BASE_URL/users" \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"recipient@example.com","password":"password123"}}'
echo -e "\n"

# 7. Transfer to another user
echo "=== Transferring 10.00 to recipient ==="
curl -X POST "$BASE_URL/v1/account/transfer" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 10.00, "recipient_email": "recipient@example.com"}'
echo -e "\n"

# 8. Check transaction history
echo "=== Transaction history ==="
curl -X GET "$BASE_URL/v1/account/transactions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
echo -e "\n"

# 9. Final balance
echo "=== Final balance ==="
curl -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
echo -e "\n"
```

[Back to Table of Contents](#table-of-contents)

---

## Error Handling

All error responses follow this format:

```json
{
  "error": "Error message here"
}
```

**Common HTTP Status Codes:**

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created (registration) |
| 401 | Unauthorized (missing or invalid token) |
| 404 | Not Found (recipient not found) |
| 422 | Unprocessable Entity (validation error) |

[Back to Table of Contents](#table-of-contents)
