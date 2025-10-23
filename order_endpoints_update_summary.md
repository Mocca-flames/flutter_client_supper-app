# Order Endpoints Update Summary

## Overview
This document outlines the necessary updates to the order-related API endpoints in our mobile client application. These changes are required to align our client with the updated API documentation.

## Files to Update
1. lib/services/api_service.dart
2. lib/constants/api_constants.dart

## Required Changes

### 1. Order Creation Endpoint
- **Current:** `${ApiConstants.apiPrefix}${ApiConstants.createOrderEndpoint}`
- **New:** `${ApiConstants.apiPrefix}/client/orders`
- **File:** lib/services/api_service.dart
- **Line:** ~207
- **Action:** Update the `endpoint` constant in the `createOrder` method

Additionally, update the `ApiConstants` class:
- **File:** lib/constants/api_constants.dart
- **Action:** Update `static const String createOrderEndpoint = '/client/orders';`

### 2. Order Retrieval Endpoints
- **Current:** `${ApiConstants.apiPrefix}/client/orders` (for all orders)
- **New:** No change required
- **File:** lib/services/api_service.dart
- **Line:** ~233
- **Action:** Verify the endpoint is correct

For specific order:
- **Current:** `${ApiConstants.apiPrefix}${ApiConstants.getOrderDetailsEndpoint}$orderId`
- **New:** `${ApiConstants.apiPrefix}/client/orders/$orderId`
- **File:** lib/services/api_service.dart
- **Line:** ~257
- **Action:** Update the `endpoint` constant in the `getOrderDetails` method

Update the `ApiConstants` class:
- **File:** lib/constants/api_constants.dart
- **Action:** Update `static const String getOrderDetailsEndpoint = '/client/orders/';`

### 3. Order Tracking Endpoint
- **Current:** `${ApiConstants.apiPrefix}${ApiConstants.startOrderTrackingEndpoint}$orderId/track`
- **New:** `${ApiConstants.apiPrefix}/orders/$orderId/track`
- **File:** lib/services/api_service.dart
- **Line:** ~409
- **Action:** Update the `endpoint` constant in the `startOrderTracking` method

Update the `ApiConstants` class:
- **File:** lib/constants/api_constants.dart
- **Action:** Update `static const String startOrderTrackingEndpoint = '/orders/';`

### 4. Order Cancellation Endpoint
- **Current:** `${ApiConstants.apiPrefix}${ApiConstants.cancelOrderEndpoint}$orderId/cancel`
- **New:** `${ApiConstants.apiPrefix}/orders/$orderId/cancel`
- **File:** lib/services/api_service.dart
- **Line:** ~318
- **Action:** Update the `endpoint` constant in the `cancelOrder` method

Update the `ApiConstants` class:
- **File:** lib/constants/api_constants.dart
- **Action:** Update `static const String cancelOrderEndpoint = '/orders/';`

### 5. Driver Location Retrieval Endpoint
- **Current:** `${ApiConstants.apiPrefix}${ApiConstants.getDriverLocationEndpoint}$orderId/location`
- **New:** `${ApiConstants.apiPrefix}/orders/$orderId/location`
- **File:** lib/services/api_service.dart
- **Line:** ~488
- **Action:** Update the `endpoint` constant in the `getCurrentDriverLocationForOrder` method

Update the `ApiConstants` class:
- **File:** lib/constants/api_constants.dart
- **Action:** Update `static const String getDriverLocationEndpoint = '/orders/';`

## Implementation Notes
- Ensure that all API calls use the new endpoints.
- Update any error handling or response parsing to match the new API structure.
- Test thoroughly after making these changes to ensure all order-related functionality works as expected.

## Next Steps
1. Review this summary with the development team.
2. Implement the changes in the respective files.
3. Update unit tests to reflect the new endpoints.
4. Perform integration testing to ensure all order-related features work correctly with the new endpoints.
