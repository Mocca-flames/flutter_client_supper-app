Flutter Client Application Development Guide
Phase 1: Project Foundation & Authentication Setup
1.1 Project Structure
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── order_model.dart
│   └── location_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── order_provider.dart
│   └── websocket_provider.dart
├── services/
│   ├── firebase_auth_service.dart
│   ├── api_service.dart
│   └── websocket_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── home_screen.dart
└── widgets/
    ├── custom_button.dart
    ├── custom_text_field.dart
    └── loading_widget.dart
1.2 Core Models
UserModel Class:

Properties: uid, email, displayName, phoneNumber
Methods: fromJson(), toJson(), copyWith()

LocationModel Class:

Properties: latitude, longitude, address
Methods: fromJson(), toJson(), distanceTo()

1.3 Firebase Authentication Service
FirebaseAuthService Class:

Methods:

signInWithEmailAndPassword(email, password)
createUserWithEmailAndPassword(email, password)
signInWithGoogle()
signOut()
getCurrentUser()
getIdToken()



1.4 Authentication Provider
AuthProvider Class (extends ChangeNotifier):

Properties: currentUser, isLoading, isAuthenticated
Methods:

signIn(email, password)
signUp(email, password)
signOut()
checkAuthState()
refreshToken()



1.5 Authentication Screens
LoginScreen:

Widgets: Email field, password field, login button, register link
Methods: _handleLogin(), _validateForm()

RegisterScreen:

Widgets: Email field, password field, confirm password field, register button
Methods: _handleRegister(), _validateForm()

SplashScreen:

Methods: _checkAuthState(), _navigateToNextScreen()


Phase 2: API Integration & HTTP Service
2.1 API Service Foundation
ApiService Class:

Properties: baseUrl, httpClient
Methods:

_getHeaders() - Returns headers with Firebase token
_handleResponse(response) - Processes API responses
_handleError(error) - Manages API errors



HTTP Methods:

get(endpoint)
post(endpoint, data)
put(endpoint, data)
delete(endpoint)

2.2 Client Registration & Profile Management
**Important Note:** After successful Firebase authentication (Phase 1), the client application must register with the backend API using the Firebase Auth UID. This registration step is crucial and must be completed before attempting to fetch or update the user's profile from the backend.

Extended ApiService Methods:

  `registerClient(firebaseUid)` - POST /api/auth/register (Registers the Firebase user with the backend)
  `getUserProfile()` - GET /api/auth/me (Fetches user profile *after* successful registration or if already registered)
  `updateUserProfile(userData)` - PUT /api/auth/profile

Enhanced AuthProvider:

  (AuthProvider properties like `currentUser` (Firebase User), `isLoading`, `isAuthenticated` are defined in Phase 1.)
  Properties:
    `userProfile` (Nullable UserModel for backend profile data)

  Methods:
    (Core authentication methods `signIn`, `signUp`, `signOut`, `checkAuthState`, `refreshToken` are from Phase 1. Their implementation will now incorporate the registration step.)

    `_registerClientWithBackendIfNeeded()`:
      - Retrieves `currentUser.uid` from Firebase Auth.
      - Calls `ApiService.registerClient(currentUser.uid)`.
      - Handles success/failure of registration. This might involve setting a flag or state indicating backend registration status (e.g., a boolean `isBackendRegistered`).
      - This method should be invoked internally by `signIn`, `signUp`, and `checkAuthState` upon confirming a Firebase authenticated user.

    `loadUserProfile()`:
      - This method should be called *after* `_registerClientWithBackendIfNeeded()` has successfully completed or confirmed prior registration.
      - Calls `ApiService.getUserProfile()` to fetch the backend profile.
      - Updates `userProfile` and notifies listeners.

    `updateProfile(userData)`:
      - Calls `ApiService.updateUserProfile(userData)`.
      - Updates `userProfile` and notifies listeners.

**Workflow Update for AuthProvider (integrating with Phase 1 methods):**
  - `signIn(email, password)`: After successful Firebase sign-in -> get Firebase user -> call `_registerClientWithBackendIfNeeded()` -> then call `loadUserProfile()`.
  - `signUp(email, password)`: After successful Firebase sign-up -> get Firebase user -> call `_registerClientWithBackendIfNeeded()` -> then call `loadUserProfile()`.
  - `checkAuthState()`: If a Firebase user is found -> call `_registerClientWithBackendIfNeeded()` -> then call `loadUserProfile()`.




Phase 3: Order Management System
3.1 Order Models & Data Structure
OrderModel Class:

Properties: orderId, clientId, status, pickupLocation, dropoffLocation, items, totalAmount, createdAt, estimatedDeliveryTime
Methods: fromJson(), toJson(), getStatusText(), isActive()

OrderItem Class:

Properties: name, quantity, price
Methods: fromJson(), toJson(), getTotalPrice()

3.2 Order Provider
OrderProvider Class (extends ChangeNotifier):

Properties: orders, currentOrder, isLoading
Methods:

createOrder(orderData)
getOrderHistory()
getOrderById(orderId)
refreshOrders()



3.3 Order API Service Extension
Extended ApiService Methods:

createOrder(orderData) - POST /api/client/orders/
getOrders() - GET /api/client/orders/
getOrderDetails(orderId) - GET /api/client/orders/{orderId}

3.4 Order Management Screens
CreateOrderScreen:

Widgets: Location pickers, item list, payment method selector
Methods: _handleLocationSelection(), _addItem(), _calculateTotal(), _submitOrder()

OrderHistoryScreen:

Widgets: Order list, filter options, search bar
Methods: _loadOrders(), _refreshOrders(), _filterOrders()

OrderDetailsScreen:

Widgets: Order info display, status timeline, action buttons
Methods: _loadOrderDetails(), _cancelOrder()


Phase 4: Real-time WebSocket Integration
4.1 WebSocket Service Foundation
WebSocketService Class:

Properties: channel, isConnected, subscriptions
Methods:

connect(firebaseToken)
disconnect()
subscribe(topic)
unsubscribe(topic)
sendMessage(message)
_handleMessage(message)



4.2 WebSocket Provider
WebSocketProvider Class (extends ChangeNotifier):

Properties: connectionState, activeSubscriptions
Methods:

initializeConnection()
subscribeToOrderUpdates(orderId)
subscribeToDriverLocation(orderId)
_processOrderUpdate(data)
_processLocationUpdate(data)



4.3 Integration with Order Provider
Enhanced OrderProvider:

Methods:

startRealTimeTracking(orderId)
stopRealTimeTracking()
_updateOrderStatus(orderData)




Phase 5: Driver Tracking & Map Integration
5.1 Location Models Extension
DriverLocationModel Class:

Properties: orderId, driverId, latitude, longitude, timestamp, heading
Methods: fromJson(), isRecent(), distanceFrom(location)

5.2 Map Integration Provider
MapProvider Class (extends ChangeNotifier):

Properties: driverLocation, pickupLocation, dropoffLocation, routePolyline
Methods:

updateDriverLocation(locationData)
setOrderLocations(pickup, dropoff)
calculateRoute()
getEstimatedArrival()



5.3 Tracking Screen
OrderTrackingScreen:

Widgets: Map view, driver info card, ETA display, order status
Methods:

_initializeMap()
_updateDriverMarker()
_centerMapOnDriver()
_showRouteToDestination()



5.4 WebSocket Integration for Tracking
Enhanced WebSocketService:

Methods:

_handleDriverLocationUpdate(data)
_broadcastLocationToMap(locationData)




Phase 6: Enhanced UI/UX & State Management
6.1 Advanced State Management
AppStateProvider Class (extends ChangeNotifier):

Properties: currentScreen, isOffline, notifications
Methods:

navigateToScreen(screen)
showNotification(message)
setOfflineMode(status)



6.2 Custom Widgets Library
OrderStatusCard Widget:

Properties: order, onTap
Methods: _getStatusColor(), _getStatusIcon()

LocationPicker Widget:

Properties: onLocationSelected, initialLocation
Methods: _showLocationDialog(), _getCurrentLocation()

LiveTrackingMap Widget:

Properties: driverLocation, destinationLocation
Methods: _updateMapCamera(), _drawRoute()

6.3 Navigation & Routing
AppRouter Class:

Methods:

generateRoute(settings)
_buildRoute(widget)



Navigation Methods:

navigateToLogin()
navigateToHome()
navigateToOrderTracking(orderId)
navigateToOrderDetails(orderId)


Phase 7: Error Handling & Offline Support
7.1 Error Management System
ErrorHandler Class:

Methods:

handleApiError(error)
handleWebSocketError(error)
handleAuthError(error)
showErrorDialog(context, error)



ErrorProvider Class (extends ChangeNotifier):

Properties: currentError, errorHistory
Methods:

setError(error)
clearError()
retryLastAction()



7.2 Local Storage & Caching
LocalStorageService Class:

Methods:

saveUserData(userData)
getUserData()
saveOrderHistory(orders)
getOrderHistory()
clearStorage()



CacheProvider Class (extends ChangeNotifier):

Properties: cachedOrders, cachedUserProfile
Methods:

cacheOrderData(orders)
getCachedData(key)
invalidateCache(key)



7.3 Connectivity Management
ConnectivityProvider Class (extends ChangeNotifier):

Properties: isOnline, connectionType
Methods:

checkConnectivity()
handleConnectivityChange()
retryFailedRequests()




Phase 8: Security & Data Validation
8.1 Input Validation
ValidationService Class:

Methods:

validateEmail(email)
validatePassword(password)
validatePhoneNumber(phone)
validateAddress(address)



FormValidator Class:

Methods:

validateLoginForm(email, password)
validateOrderForm(orderData)
getValidationErrors()



8.2 Security Service
SecurityService Class:

Methods:

encryptSensitiveData(data)
validateApiResponse(response)
sanitizeUserInput(input)
checkTokenExpiry()



8.3 Token Management
TokenManager Class:

Properties: currentToken, tokenExpiry
Methods:

getValidToken()
refreshTokenIfNeeded()
clearTokens()




Phase 9: Final Integration & Testing Preparation
9.1 Main App Integration
MyApp Class (StatelessWidget):

Widgets: MaterialApp with MultiProvider wrapper
Providers: AuthProvider, OrderProvider, WebSocketProvider, MapProvider

Main Function:

Initialize Firebase
Setup providers
Run app

9.2 Provider Dependencies & Initialization
Provider Setup Order:

AuthProvider (independent)
ApiService (depends on AuthProvider)
WebSocketProvider (depends on AuthProvider)
OrderProvider (depends on ApiService, WebSocketProvider)
MapProvider (depends on OrderProvider)

9.3 Screen Flow Management
HomeScreen:

Widgets: Order quick actions, recent orders, profile access
Methods: _checkActiveOrders(), _showQuickActions()

AppWrapper:

Methods: _handleDeepLinks(), _checkAuthState(), _initializeServices()


Provider Integration Strategy
Dependencies Flow:
AuthProvider
    ↓
ApiService ← WebSocketService
    ↓           ↓
OrderProvider ←┘
    ↓
MapProvider
State Management Hierarchy:

AuthProvider - Manages user authentication state
OrderProvider - Manages order data and operations
WebSocketProvider - Handles real-time communications
MapProvider - Manages location and tracking data
ErrorProvider - Handles application-wide errors
ConnectivityProvider - Manages network state

This phased approach ensures each component builds upon the previous phase, creating a robust and maintainable Flutter application architecture using Provider for state management.
