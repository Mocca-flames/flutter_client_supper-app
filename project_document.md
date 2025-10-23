# Molo Mobile Client - Project Technical Documentation

## Overview

Molo is an Android-first Flutter application for on-demand delivery services, providing users with location-based search, order placement, payment processing, and real-time tracking from pickup to drop-off. The app integrates Firebase for authentication and configuration, Google Maps for rendering and geocoding, WebSocket for realtime updates, and a REST API for backend communication.

**Key Technologies:**
- Flutter (Dart) with Provider for state management
- Firebase Auth for user authentication
- Firestore for dynamic configuration
- Dio for HTTP client with interceptors
- Google Maps Flutter for map rendering
- Google Places/Geocoding/Directions for location services
- WebSocket for realtime tracking
- Payment integration via webview

## User Journey

### 1. App Launch and Authentication
**WHAT:** User opens the app, which initializes Firebase and checks authentication state.
**HOW:** App starts in `main.dart`, initializes Firebase Core, then routes to splash screen. If not authenticated, user is directed to login/register screens.
**WHY:** Ensures secure access and loads user-specific data.

### 2. Sign Up / Registration
**WHAT:** New users create account using email/password or Google Sign In.
**HOW:**
- Email/Password: Calls `FirebaseAuthService.createUserWithEmailAndPassword()`
- Google Sign In: Uses `GoogleSignIn` to authenticate, then links to Firebase Auth via `signInWithCredential()`
- After Firebase auth, calls backend API `POST /api/auth/register` with `firebase_uid` and `user_type: 'client'`
**WHY:** Firebase provides secure, scalable authentication. Google Sign In simplifies onboarding.
**Example:**
```dart
// Google Sign In flow
final googleUser = await _googleSignIn.authenticate();
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
final userCredential = await _firebaseAuth.signInWithCredential(credential);
```

### 3. Home Screen and Service Discovery
**WHAT:** Authenticated users see available delivery services and can search locations.
**HOW:** Loads services from backend via `GET /api/client/delivery-services`. Location search uses Google Places Autocomplete API.
**WHY:** Provides intuitive service selection and location input.

### 4. Order Creation
**WHAT:** User selects pickup/dropoff locations, chooses service, and creates order.
**HOW:**
- Location selection: Google Places search via `ApiService.searchAddresses()`
- Order creation: `POST /api/client/orders` with `NewOrderPayload` containing pickup/dropoff coordinates, service ID, items
- Validates locations and estimates cost via `POST /api/delivery/estimate`
**WHY:** Structured payload ensures accurate routing and pricing.
**Example API Call:**
```dart
final order = await apiService.createOrder(NewOrderPayload(
  pickupLocation: LocationModel(...),
  dropoffLocation: LocationModel(...),
  serviceId: 'express_delivery',
  items: [OrderItem(...)],
));
```

### 5. Payment Processing
**WHAT:** User completes payment for the order.
**HOW:** Redirects to payment gateway via webview. Polls payment status via `GET /api/orders/{orderId}/verify-payment`.
**WHY:** Secure payment handling without storing card data in app.
**Payment States:** pending → processing → success/failed/cancelled

### 6. Order Tracking
**WHAT:** Real-time tracking of driver location and order status.
**HOW:**
- Starts tracking: `POST /api/orders/{orderId}/track` returns WebSocket session
- WebSocket connection: `wss://baseUrl/ws/track/{sessionId}` streams driver locations and status updates
- Map updates: Google Maps renders driver position and route polylines
**WHY:** Provides live visibility into delivery progress.
**Example WebSocket Message:**
```json
{
  "type": "driver_location",
  "data": {
    "latitude": -26.2041,
    "longitude": 28.0473,
    "timestamp": "2025-09-22T08:00:00Z"
  }
}
```

### 7. Order Completion
**WHAT:** Order delivered, user receives confirmation.
**HOW:** WebSocket sends `order_status: 'delivered'`, app shows completion screen with receipt.
**WHY:** Clear terminal state provides closure and enables rating/feedback.

## Authentication System

### Firebase Auth Integration
**WHAT:** Handles user sign-in, registration, and session management.
**HOW:**
- Service: `FirebaseAuthService` wraps Firebase Auth methods
- Provider: `AuthProvider` manages auth state and API calls
- Token: Gets ID token for API authentication via `getIdToken()`
**WHY:** Secure, serverless auth with Google integration.
**Key Methods:**
- `signInWithEmailAndPassword()`
- `createUserWithEmailAndPassword()`
- `signInWithGoogle()`
- `signOut()`

### Google Sign In
**WHAT:** OAuth-based authentication using Google accounts.
**HOW:** Uses `google_sign_in` package to authenticate, then links to Firebase Auth.
**WHY:** Reduces friction for users with Google accounts.
**Example:**
```dart
final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
final GoogleSignInAuthentication googleAuth = googleUser.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
```

### Backend Registration
**WHAT:** After Firebase auth, registers user with backend.
**HOW:** `POST /api/auth/register?firebase_uid={uid}&user_type=client`
**WHY:** Links Firebase UID to backend user record.

## Configuration Management

### Dynamic Backend URL
**WHAT:** Fetches base URL from Firestore instead of hardcoding.
**HOW:**
- On app start: `ConfigService.initialize()` fetches from Firestore collection `config/doc/app_settings`
- Document contains: `{baseUrl: "https://api.molo.com", googleMapsApiKey: "..."}`
- Falls back to defaults if Firestore unavailable
**WHY:** Enables environment switching without app rebuilds.
**Example Firestore Document:**
```json
{
  "baseUrl": "https://api-prod.molo.com",
  "googleMapsApiKey": "AIzaSy..."
}
```

### Google Maps API Key
**WHAT:** Securely provides API key for Google services.
**HOW:** Retrieved from same Firestore config document.
**WHY:** Avoids committing secrets to repository.

## API Integration

### HTTP Client (Dio)
**WHAT:** Handles all REST API communication with interceptors.
**HOW:**
- Base URL from ConfigService
- Auth headers: `Authorization: Bearer {firebase_token}`
- Interceptors for logging, error handling, redaction
- Timeouts: 30s connect, 30s send, 30s receive
**WHY:** Centralized, robust HTTP handling with security.

### Key API Endpoints

#### Authentication
- `POST /api/auth/register?firebase_uid={uid}&user_type=client` - Register user

#### Orders
- `POST /api/client/orders` - Create order
- `GET /api/client/orders` - List user orders
- `GET /api/client/orders/{id}` - Get order details
- `PATCH /api/orders/{id}/cancel` - Cancel order
- `POST /api/orders/{id}/track` - Start tracking session

#### Location Services
- `GET https://maps.googleapis.com/maps/api/place/autocomplete/json` - Address search
- `GET https://maps.googleapis.com/maps/api/place/details/json` - Place details
- `GET https://maps.googleapis.com/maps/api/geocode/json` - Reverse geocoding
- `GET https://maps.googleapis.com/maps/api/directions/json` - Route directions

#### Payments
- `GET /api/orders/{id}/verify-payment` - Check payment status

#### User Profile
- `GET /api/user/profile` - Get profile
- `PUT /api/user/profile` - Update profile

**Example API Call:**
```dart
final headers = await _getHeaders(); // Gets Bearer token
final response = await _dio.post(
  '$_baseUrl/api/client/orders',
  data: orderPayload.toJson(),
  options: Options(headers: headers),
);
```

## Realtime Features (WebSocket)

### Connection Management
**WHAT:** Maintains WebSocket connection for live tracking.
**HOW:**
- Service: `WebSocketService` handles connection lifecycle
- URL: `wss://{baseUrl}/ws/track/{sessionId}`
- Messages: JSON with types like `driver_location`, `order_status`
**WHY:** Enables real-time updates without polling.

### Message Types
- `driver_location`: `{latitude, longitude, timestamp}`
- `order_status`: `{status: 'in_transit', timestamp}`
- `route_update`: Polyline coordinates for map

### State Management
**WHAT:** `WebSocketProvider` bridges WebSocket to UI state.
**HOW:** Listens to WebSocket stream, updates `DriverLocationModel` and `OrderStatusModel`.
**WHY:** Reactive UI updates without tight coupling.

## Maps and Geocoding

### Map Rendering
**WHAT:** Google Maps Flutter displays interactive maps.
**HOW:** `GoogleMapService` manages markers, polylines, camera.
**WHY:** Native performance for map interactions.

### Location Search
**WHAT:** Google Places Autocomplete for address input.
**HOW:** `ApiService.searchAddresses()` calls Places API with query.
**WHY:** Rich, accurate location suggestions.
**Example:**
```dart
final addresses = await apiService.searchAddresses(
  query: 'Sandton',
  proximityLat: userLat,
  proximityLng: userLng,
);
```

### Reverse Geocoding
**WHAT:** Coordinates to human-readable address.
**HOW:** Google Geocoding API via `ApiService.reverseGeocode()`.
**WHY:** Converts GPS to address for display.

## Payment Integration

### Flow
**WHAT:** Secure payment via external gateway.
**HOW:**
- Initiate: Backend creates payment intent
- Redirect: Webview to payment gateway
- Status: Poll `verifyPayment()` for completion
**WHY:** PCI compliance, no card data in app.

### Status Tracking
**States:** pending → processing → success/failed/cancelled
**UI:** `PaymentStatusDisplay` widget shows current state with actions.

## State Management (Provider)

### Architecture
**WHAT:** Provider pattern for reactive state management.
**HOW:**
- App-level providers in `main.dart` MultiProvider
- Domain providers: `AuthProvider`, `OrderProvider`, `MapProvider`
- Services injected into providers
**WHY:** Simple, Flutter-native, good performance with selectors.

### Key Providers
- `AuthProvider`: User auth state, login/logout
- `OrderProvider`: Order CRUD, status updates
- `MapProvider`: Location search, route display
- `WebSocketProvider`: Realtime data
- `PaymentProvider`: Payment flow state

## Data Models

### Core Models
- `UserModel`: Firebase user data
- `OrderModel`: Order details, status, locations
- `LocationModel`: Coordinates with address
- `PaymentModel`: Payment status and amounts
- `DriverLocationModel`: Realtime driver position

### Serialization
**WHAT:** JSON conversion for API communication.
**HOW:** `fromJson()` and `toJson()` methods in all models.
**WHY:** Type-safe data exchange.

## UI and Theming

### Material Design
**WHAT:** Consistent Material UI with custom theme.
**HOW:** `AppTheme.lightTheme` in `main.dart`.
**WHY:** Professional, accessible interface.

### Key Screens
- `LoginScreen`: Email/password and Google auth
- `HomeScreen`: Service discovery
- `CreateOrderSheet`: Order input
- `OrderTrackingScreen`: Live map and status
- `PaymentScreen`: Payment flow

### Widgets
- `LiveTrackingMap`: Google Maps with driver overlay
- `LocationPicker`: Address search input
- `PaymentStatusDisplay`: Payment state UI

## Dependencies

From `pubspec.yaml`:
- `firebase_auth: ^6.0.0` - Authentication
- `cloud_firestore: ^6.0.0` - Configuration storage
- `dio: ^5.8.0+1` - HTTP client
- `google_maps_flutter: ^2.12.3` - Map rendering
- `web_socket_channel: ^3.0.3` - Realtime communication
- `provider: ^6.1.5` - State management
- `google_sign_in: ^7.1.1` - OAuth authentication

## Security Considerations

- **Secrets:** API keys and tokens not committed, loaded from Firestore
- **Auth:** Firebase ID tokens for API authentication
- **Logging:** Redact sensitive data (tokens, locations) in logs
- **HTTPS:** All API calls use TLS
- **Permissions:** Location access only when needed

## Performance Optimizations

- **Debouncing:** Search inputs (250-400ms delay)
- **Caching:** Recent locations and routes
- **Batching:** Map updates to reduce redraws
- **Lazy Loading:** Order history pagination

## Error Handling

- **Centralized:** `ErrorHandler` service for user-safe messages
- **Connectivity:** `ConnectivityProvider` for offline handling
- **Retry Logic:** Automatic retries for network failures
- **Fallbacks:** Default values when services unavailable

This documentation covers the complete technical implementation of the Molo mobile client, from user authentication through order fulfillment, with detailed explanations of HOW, WHY, and WHAT for each component.