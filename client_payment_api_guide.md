# Client Payment API Guide

This guide documents the API endpoints related to payment management for clients
---

## 1. Authentication

**Requirement:**
- Base URL prefix: `/api`
---

## 2. API Endpoints

### 2.1 Create Payment

- **Endpoint:** `POST /payments/create`
- **Method:** `POST`
- **Request Body:**
```json
{
  "order_id": "string",
  "user_id": "string",
  "payment_type": "client_payment",
  "amount": 0,
  "currency": "ZAR",
  "payment_method": "credit_card",
  "transaction_id": "string",
  "transaction_details": {}
}
```
- **Response (201 Created):**
```json
{
  "id": "string",
  "order_id": "string",
  "user_id": "string",
  "payment_type": "client_payment",
  "amount": "string",
  "currency": "string",
  "payment_method": "credit_card",
  "status": "pending",
  "transaction_id": "string",
  "created_at": "2025-08-14T00:11:44.239Z",
  "updated_at": "2025-08-14T00:11:44.239Z"
}
```

### 2.3 Get Order Payments

- **Endpoint:** `GET /api/payments/order/{order_id}`
- **Method:** `GET`
- **Path Parameters:**
  - `order_id ` (string, required) — ID of the order
- **Response (200 OK):**
```json
[
  {
    "id": "string",
    "order_id": "string",
    "user_id": "string",
    "payment_type": "client_payment",
    "amount": "string",
    "currency": "string",
    "payment_method": "credit_card",
    "status": "pending",
    "transaction_id": "string",
    "created_at": "2025-08-14T00:54:20.629Z",
    "updated_at": "2025-08-14T00:54:20.629Z"
  }
]}
```

## 3. Data Types and Enums

### Payment Status
- `"pending"` — Payment initiated, awaiting confirmation
- `"completed"` — Payment successfully processed
- `"failed"` — Payment failed
- `"refunded"` — Payment refunded
- `"cancelled"` — Payment cancelled

### Payment Methods
- `"card"` — Credit/Debit Card
- `"paypal"` — PayPal
- `"bank_transfer"` — Bank Transfer
- `"mobile_money"` — Mobile Money

---

## 4. Error Responses

### 400 Bad Request
```json
{
  "error": "Bad Request",
  "message": "Invalid input data or missing required fields"
}
```

### 403 Forbidden
```json
{
  "error": "Forbidden",
  "message": "Invalid or missing authentication key"
}
```

### 404 Not Found
```json
{
  "error": "Not Found",
  "message": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

---


## 6. Notes

- All endpoints require HTTPS in production.
- Timestamps are in ISO 8601 format (UTC).
- All numeric values (amount, earnings) are stored as strings to maintain precision.
