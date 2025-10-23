# Update Plan: Mobile Client Implementation

## Overview
This document outlines the implementation plan to align the mobile client with the new API endpoints and payment flow specifications. Based on analysis of `new_endpoints.md` and `order_payment_flow.md`, several key features need to be implemented or enhanced.

## Current Status Analysis
- ✅ **Existing**: Basic order CRUD, Paystack payment integration, user authentication
- ❌ **Missing**: Order estimation, enhanced payment verification, client profile management
- ⚠️ **Partial**: Payment flow needs alignment with documented webhook/manual verification

## Implementation Plan

### 1. API Service Enhancements (`lib/services/api_service.dart`)

#### Add Missing Endpoints:
- `POST /client/orders/estimate` - Order cost estimation
- `PUT /client/profile` - Update client profile (home address)
- `GET /payment/paystack/verify/{reference}` - Enhanced payment verification (Client-initiated status query)

#### Update Existing Endpoints:
- Ensure `POST /client/orders` matches new payload structure
- Update `POST /payment/paystack/initialize` to match documented response format
- Add proper error handling for all payment endpoints

### 2. Model Updates

#### New Models Required:
- `CostEstimationResponse` - For order estimation API response
- `ClientProfile` - For client profile management
- `PaymentVerificationResponse` - For payment verification responses

#### Update Existing Models:
- `OrderModel` - Add missing fields like `total_paid`, `total_refunded`, `payment_status`
- `PaymentModel` - Ensure compatibility with new API response formats

### 3. Order Estimation Implementation

#### Files to Create/Update:
- `lib/models/cost_estimation_model.dart` - Model for estimation response
- `lib/services/order_estimation_service.dart` - Service for estimation logic
- `lib/providers/order_estimation_provider.dart` - Provider for state management

#### Integration Points:
- Add estimation step before order creation in order flow
- Update UI to show estimated costs to users
- Cache estimation results for better UX

### 4. Payment Flow Enhancements

#### Verification Flow (Server-Centric):
- **Primary Verification:** Backend handles Paystack webhooks (Server-to-Server).
- **Client Fallback:** Enhance `PaymentWebViewScreen` to redirect to a status screen after payment completion.
- **Status Query:** Implement client-initiated status query (`GET /payment/paystack/verify/{reference}`) as a fallback mechanism to confirm payment status if the order status is not immediately updated.
- Improve error handling for payment failures.

#### Payment Provider Updates:
- Add methods for querying payment status
- Implement payment history retrieval
- Add support for refunds and partial payments

### 5. Client Profile Management

#### Features to Implement:
- Home address management
- Profile verification status
- Profile update validation

#### UI Integration:
- Add profile settings screen
- Integrate with existing user management flow
- Add address autocomplete using Google Places

### 6. Error Handling & State Management

#### Enhancements Needed:
- Standardized error handling across all API calls
- Better loading states for long-running operations
- Offline support for critical operations
- Retry mechanisms for failed requests

#### Provider Updates:
- Enhance `PaymentProvider` with better error states
- Add `OrderProvider` methods for estimation
- Update `AuthProvider` for profile management

### 7. Testing & Validation

#### Test Cases Required:
- Order estimation flow
- Payment initialization and verification
- Profile updates
- Error scenarios (network failures, API errors)
- Edge cases (invalid data, timeouts)

#### Integration Testing:
- End-to-end payment flow testing
- API response validation
- UI state management testing

## Implementation Priority

### Phase 1: Core API Integration (High Priority)
1. Add missing API endpoints to `ApiService`
2. Create/update required models
3. Implement order estimation functionality

### Phase 2: Payment Flow Enhancement (High Priority)
1. Integrate client-side payment initiation and redirection.
2. Implement client-initiated payment status query as a fallback.
3. Update payment provider and models to reflect server-centric status updates.
4. Improve error handling in payment flow.

### Phase 3: Profile Management (Medium Priority)
1. Implement client profile updates
2. Add address management
3. Integrate with user settings

### Phase 4: Testing & Polish (Medium Priority)
1. Comprehensive testing
2. Error handling improvements
3. Performance optimizations

## Dependencies
- Ensure backend API endpoints are deployed and accessible
- Firebase configuration for authentication
- Paystack credentials configured
- Google Places API for address autocomplete

## Success Criteria
- All documented API endpoints implemented
- Payment flow matches specification
- Order estimation working end-to-end
- Client profile management functional
- Comprehensive error handling
- All tests passing

## Notes
- Driver ratings functionality excluded as per requirements
- Focus on client-side order and payment management
- Maintain backward compatibility with existing features