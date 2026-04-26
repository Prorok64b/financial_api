# Financial API

A Rails API for managing user funds with deposit, withdrawal, and transfer functionality.

## Ruby Version

- Ruby 3.4.1
- Rails 8.0.5

## Setup

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Run the server
rails s
```

## Running Tests

```bash
bundle exec rspec
```

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
  -i | grep -i "Authorization:" | awk '{print $2}' | tr -d '\r')
```

---

### Account Endpoints

#### Get Balance

Returns the current balance of the authenticated user.

```bash
curl -X GET http://localhost:3000/v1/account/balance \
  -H "Authorization: $TOKEN" \
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

---

#### Deposit

Adds funds to the authenticated user's account.

```bash
curl -X POST http://localhost:3000/v1/account/deposit \
  -H "Authorization: $TOKEN" \
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

---

#### Withdraw

Removes funds from the authenticated user's account.

```bash
curl -X POST http://localhost:3000/v1/account/withdraw \
  -H "Authorization: $TOKEN" \
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

---

#### Transfer

Transfers funds from the authenticated user to another user.

```bash
curl -X POST http://localhost:3000/v1/account/transfer \
  -H "Authorization: $TOKEN" \
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

---

#### Transaction History

Returns the transaction history for the authenticated user.

```bash
curl -X GET http://localhost:3000/v1/account/transactions \
  -H "Authorization: $TOKEN" \
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
  -i | grep -i "Authorization:" | awk '{print $2}' | tr -d '\r')
echo "Token: $TOKEN"
echo -e "\n"

# 3. Check initial balance
echo "=== Checking balance ==="
curl -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json"
echo -e "\n"

# 4. Deposit funds
echo "=== Depositing 100.50 ==="
curl -X POST "$BASE_URL/v1/account/deposit" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 100.50}'
echo -e "\n"

# 5. Withdraw funds
echo "=== Withdrawing 25.00 ==="
curl -X POST "$BASE_URL/v1/account/withdraw" \
  -H "Authorization: $TOKEN" \
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
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 10.00, "recipient_email": "recipient@example.com"}'
echo -e "\n"

# 8. Check transaction history
echo "=== Transaction history ==="
curl -X GET "$BASE_URL/v1/account/transactions" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json"
echo -e "\n"

# 9. Final balance
echo "=== Final balance ==="
curl -X GET "$BASE_URL/v1/account/balance" \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json"
echo -e "\n"
```

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
