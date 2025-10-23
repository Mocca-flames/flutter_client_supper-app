# Flutter Client Application Development Guide (Hybrid Map Implementation)

## Overview
This guide outlines the development of an Uber-like Flutter application using Provider for state management, Google Maps for map rendering, and Mapbox Search for location services. This hybrid approach leverages the strengths of both platforms for optimal performance and cost-effectiveness.

## Recommended Setup
Use:
- Google Maps for map rendering and camera/marker control
- Mapbox Search (via `mapbox_search: ^4.3.1`) for place search + geocoding

### Why This Combo Works (Especially for MVPs)
**✅ Google Maps Pros (for rendering):**
- Smooth rendering and performance (better than Mapbox Flutter SDK currently)
- Easier integration with Flutter via `google_maps_flutter`
- Robust mobile support and easy camera/movement control

**✅ Mapbox Search Pros:**
- Free generous quota (100K requests/month on Geocoding + Search)
- No billing surprises (unlike Google if you go over free tier)
- You only use search/geocoding, not map tiles (so it won’t break anything)
- Easier to customize search behavior

**❌ Why Avoid Mapbox for Map Display (for now):**
- Flutter SDK can be unstable or overly complex
- SDK 2.0+ is native-heavy (Android/iOS), leading to runtime crashes
- Your previous project broke with Mapbox — trust that instinct

**🧩 Component Breakdown:**
| Feature              | Service Used       | Rationale |
|----------------------|--------------------|-----------|
| Map rendering        | Google Maps        | Stable, mature Flutter support |
| Location search      | Mapbox Search API  | Free, flexible, usage-based billing |
| Reverse geocoding    | Mapbox             | Free for 100K/month |
| Directions/routing   | Mapbox             | Prefer unless needing Google ETA accuracy |
| Place details        | Google (optional)  | If needed, but costs apply quickly |

## Phase 1: Project Foundation & Authentication Setup

### 1.1 Project Structure
```
```

### 1.2 Map Configuration Setup

#### MapConfig Class
**Properties:**
- `googleMapsApiKey` (String) - For Google Maps SDK initialization (fetched from Firestore)
- `mapboxPublicToken` (String) - For Mapbox Search API requests (fetched from Firestore)
- `mapboxSecretToken` (String) - For Mapbox SDK downloads (build-time only, if needed for search SDK)
- `mapboxGeocodingApiUrl` (String) - Mapbox Geocoding API URL
- `mapboxDirectionsApiUrl` (String) - Mapbox Directions API URL

**Methods:**
- `validateGoogleMapsApiKey()` - Ensures Google Maps API key is present
- `validateMapboxTokens()` - Ensures Mapbox tokens are present and valid format
- `getGoogleMapsApiKey()` - Returns Google Maps API key for runtime usage
- `getMapboxPublicToken()` - Returns Mapbox public token for runtime usage
- `initializeGoogleMaps()` - Initializes Google Maps SDK

#### Android Configuration Requirements

**android/app/build.gradle modifications:**
```gradle
android {
    defaultConfig {
        // No longer needed as Google Maps API Key is fetched from Firestore
        // buildConfigField "String", "GOOGLE_MAPS_API_KEY", "\"${project.findProperty('GOOGLE_MAPS_API_KEY') ?: ''}\""
        // Add Mapbox public token as build config (if needed for Mapbox Search SDK)
        buildConfigField "String", "MAPBOX_PUBLIC_TOKEN", "\"${project.findProperty('MAPBOX_PUBLIC_TOKEN') ?: ''}\""
    }
}
```

**gradle.properties additions:**
```
# No longer needed as Google Maps API Key is fetched from Firestore
# GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Mapbox Tokens (for search/geocoding)
MAPBOX_PUBLIC_TOKEN=pk.your_mapbox_public_token_here
MAPBOX_SECRET_TOKEN=sk.your_mapbox_secret_token_here
```

**android/app/src/main/AndroidManifest.xml:**
```xml
<application>
    <!-- Google Maps API Key (fetched from Firestore) -->
    <!-- No longer needed as Google Maps API Key is fetched from Firestore -->
    <!-- <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="${GOOGLE_MAPS_API_KEY}" /> -->
    <!-- Mapbox public token (if needed for Mapbox Search SDK) -->
    <meta-data
        android:name="com.mapbox.token"
        android:value="${MAPBOX_PUBLIC_TOKEN}" />
</application>
```

### 1.3 Core Models

#### UserModel Class
- **Properties**: `uid`, `email`, `displayName`, `phoneNumber`
- **Methods**: `fromJson()`, `toJson()`, `copyWith()`

#### LocationModel Class
- **Properties**: `latitude`, `longitude`, `address`, `placeId` (for Mapbox), `name` (for Google Places)
- **Methods**: `fromJson()`, `toJson()`, `distanceTo()`, `toMapboxQuery()`, `fromMapboxResponse(data)`, `toLatLng()`, `fromLatLng(latLng)`

### 1.4 Firebase Authentication Service

#### FirebaseAuthService Class
**Methods:**
- `signInWithEmailAndPassword(email, password)`
- `createUserWithEmailAndPassword(email, password)`
- `signInWithGoogle()`
- `signOut()`
- `getCurrentUser()`
- `getIdToken()`

### 1.5 Authentication Provider

#### AuthProvider Class (extends ChangeNotifier)
**Properties:** 
- `currentUser`
- `isLoading`
- `isAuthenticated`

**Methods:**
- `signIn(email, password)`
- `signUp(email, password)`
- `signOut()`
- `checkAuthState()`
- `refreshToken()`

### 1.6 Authentication Screens

#### LoginScreen
- **Widgets**: Email field, password field, login button, register link
- **Methods**: `_handleLogin()`, `_validateForm()`

#### RegisterScreen
- **Widgets**: Email field, password field, confirm password field, register button
- **Methods**: `_handleRegister()`, `_validateForm()`

#### SplashScreen
- **Methods**: `_checkAuthState()`, `_navigateToNextScreen()`, `_initializeMapServices()`

## Phase 2: API Integration & HTTP Service

### 2.1 API Service Foundation

#### ApiService Class
**Properties:** 
- `baseUrl`
- `httpClient`

**Methods:**
- `_getHeaders()` - Returns headers with Firebase token
- `_handleResponse(response)` - Processes API responses
- `_handleError(error)` - Manages API errors

**HTTP Methods:**
- `get(endpoint)`
- `post(endpoint, data)`
- `put(endpoint, data)`
- `delete(endpoint)`

### 2.2 Client Registration & Profile Management

**Important Note:** After successful Firebase authentication (Phase 1), the client application must register with the backend API using the Firebase Auth UID. This registration step is crucial and must be completed before attempting to fetch or update the user's profile from the backend.

#### Extended ApiService Methods
- `registerClient(firebaseUid)` - POST /api/auth/register
- `getUserProfile()` - GET /api/auth/me
- `updateUserProfile(userData)` - PUT /api/auth/profile

#### Enhanced AuthProvider
**Additional Properties:**
- `userProfile` (Nullable UserModel for backend profile data)

**Additional Methods:**
- `_registerClientWithBackendIfNeeded()`:
  - Retrieves `currentUser.uid` from Firebase Auth
  - Calls `ApiService.registerClient(currentUser.uid)`
  - Handles success/failure of registration
  - Sets backend registration status flag

- `loadUserProfile()`:
  - Called after successful backend registration
  - Calls `ApiService.getUserProfile()`
  - Updates `userProfile` and notifies listeners

- `updateProfile(userData)`:
  - Calls `ApiService.updateUserProfile(userData)`
  - Updates `userProfile` and notifies listeners

**Workflow Update:**
- `signIn(email, password)`: Firebase sign-in → `_registerClientWithBackendIfNeeded()` → `loadUserProfile()`
- `signUp(email, password)`: Firebase sign-up → `_registerClientWithBackendIfNeeded()` → `loadUserProfile()`
- `checkAuthState()`: If Firebase user found → `_registerClientWithBackendIfNeeded()` → `loadUserProfile()`

## Phase 3: Order Management System

### 3.1 Order Models & Data Structure

#### OrderModel Class
**Properties:** 
- `id`, `clientId`, `driverId`, `orderType`, `status`, `pickupAddress`, `pickupLatitude`, `pickupLongitude`, `dropoffAddress`, `dropoffLatitude`, `dropoffLongitude`, `price`, `distanceKm`, `specialInstructions`, `createdAt`

**Methods:** 
- `fromJson()`, `toJson()`, `getStatusText()`, `isActive()`

#### OrderCreateModel Class
**Properties:**
- `orderType`, `pickupAddress`, `pickupLatitude`, `pickupLongitude`, `dropoffAddress`, `dropoffLatitude`, `dropoffLongitude`, `specialInstructions`

**Methods:** 
- `fromJson()`, `toJson()`

#### TrackingSessionModel Class
**Properties:**
- `sessionId`, `orderId`, `trackingUrl`

**Methods:** 
- `fromJson()`, `toJson()`

#### DriverLocationModel Class
**Properties:**
- `driverId`, `latitude`, `longitude`, `timestamp`

**Methods:** 
- `fromJson()`, `toJson()`

### 3.2 Order Provider

#### OrderProvider Class (extends ChangeNotifier)
**Properties:** 
- `orders`, `currentOrder`, `isLoading`

**Methods:**
- `createOrder(OrderCreateModel orderData)`
- `getOrderHistory()`
- `getOrderById(String orderId)`
- `getOrderRoute(String orderId)`
- `recalculateOrderRoute(String orderId)`
- `startOrderTracking(String orderId)`
- `cancelOrder(String orderId)`
- `getDriverLocation(String orderId)`
- `refreshOrders()`

### 3.3 Order API Service Extension

#### Extended ApiService Methods

**Authentication Required**: All endpoints require Authorization header with Firebase token
- `Authorization: Bearer <firebase_token>`

#### Client Order Endpoints:

1. **Get All Orders**
   - `getOrders()` - GET `/orders`
   - Returns: `List<OrderModel>`

2. **Create Order**
   - `createOrder(OrderCreateModel orderData)` - POST `/orders`
   - Request Body: `OrderCreateModel`
   - Returns: `OrderModel`

3. **Get Order Route**
   - `getOrderRoute(String orderId)` - GET `/orders/{orderId}/route`
   - Returns: `OrderModel`

4. **Recalculate Route**
   - `recalculateOrderRoute(String orderId)` - POST `/orders/{orderId}/recalculate-route`
   - Returns: `OrderModel`

5. **Start Tracking**
   - `startOrderTracking(String orderId)` - POST `/orders/{orderId}/track`
   - Returns: `TrackingSessionModel`

6. **Cancel Order**
   - `cancelOrder(String orderId)` - PATCH `/orders/{orderId}/cancel`
   - Returns: `OrderModel`

7. **Get Driver Location**
   - `getDriverLocation(String orderId)` - GET `/orders/{orderId}/location`
   - Returns: `DriverLocationModel`

### 3.4 Order Management Screens

#### CreateOrderScreen
- **Widgets**: Location pickers, order type selector, special instructions field
- **Methods**: `_handleLocationSelection()`, `_selectOrderType()`, `_calculateRoute()`, `_submitOrder()`

#### OrderHistoryScreen
- **Widgets**: Order list, filter options, search bar
- **Methods**: `_loadOrders()`, `_refreshOrders()`, `_filterOrders()`

#### OrderDetailsScreen
- **Widgets**: Order info display, status timeline, action buttons
- **Methods**: `_loadOrderDetails()`, `_cancelOrder()`, `_startTracking()`, `_getDriverLocation()`

#### OrderTrackingScreen
- **Widgets**: Map view, driver location marker, ETA display, route visualization
- **Methods**: `_initializeTracking()`, `_updateDriverLocation()`, `_recalculateRoute()`

## Phase 4: Real-time WebSocket Integration

### 4.1 WebSocket Service Foundation

#### WebSocketService Class
**Properties:** 
- `channel`, `isConnected`, `subscriptions`

**Methods:**
- `connect(firebaseToken)`
- `disconnect()`
- `subscribe(topic)`
- `unsubscribe(topic)`
- `sendMessage(message)`
- `_handleMessage(message)`

## Phase 4: Real-time WebSocket Integration

### 4.1 WebSocket Service Foundation

#### WebSocketService Class
**Properties:** 
- `channel`, `isConnected`, `subscriptions`

**Methods:**
- `connect(firebaseToken)`
- `disconnect()`
- `subscribe(topic)`
- `unsubscribe(topic)`
- `sendMessage(message)`
- `_handleMessage(message)`

### 4.2 WebSocket Provider

#### WebSocketProvider Class (extends ChangeNotifier)
**Properties:** 
- `connectionState`, `activeSubscriptions`

**Methods:**
- `initializeConnection()`
- `subscribeToOrderUpdates(orderId)`
- `subscribeToDriverLocation(orderId)`
- `_processOrderUpdate(data)`
- `_processLocationUpdate(data)`

### 4.3 Integration with Order Provider

#### Enhanced OrderProvider
**Additional Methods:**
- `startRealTimeTracking(orderId)`
- `stopRealTimeTracking()`
- `_updateOrderStatus(orderData)`

## Phase 5: Map Services Integration & Driver Tracking

### 5.1 Map Service Foundation

#### GoogleMapService Class
**Properties:**
- `googleMapController` (GoogleMapController instance)
- `isInitialized` (bool)

**Methods:**
- `initializeGoogleMaps()` - Initializes Google Maps SDK
- `createGoogleMap()` - Creates and returns GoogleMap widget
- `getCurrentLocation()` - Gets device location
- `addMarker(location, markerId)` - Adds custom markers
- `removeMarker(markerId)` - Removes specific marker
- `updateCamera(location, zoom)` - Updates map camera position
- `fitBounds(locations)` - Fits map to show all locations
- `addPolyline(coordinates, routeId)` - Draws route on map
- `clearPolylines()` - Removes all route polylines

#### MapboxGeocodingService Class
**Properties:**
- `publicToken` (String)
- `geocodingBaseUrl` (String)
- `directionsBaseUrl` (String)

**Methods:**
- `geocodeAddress(address)` - Forward geocoding using Mapbox Geocoding API
- `reverseGeocode(latitude, longitude)` - Reverse geocoding
- `getDirections(start, end, profile)` - Get route using Directions API
- `getDistanceMatrix(origins, destinations)` - Calculate distances/durations
- `searchPlaces(query, proximity)` - Search nearby places
- `_buildGeocodingUrl(query, options)` - Constructs API URLs
- `_parseGeocodingResponse(response)` - Processes API responses

**Supported Profiles:**
- `driving-traffic` - Real-time traffic
- `driving` - Standard driving
- `walking` - Walking directions
- `cycling` - Cycling routes

### 5.2 Location Models Extension

#### Enhanced LocationModel Class
**Additional Properties:**
- `placeId` (String) - Mapbox place identifier
- `placeName` (String) - Formatted place name
- `context` (List) - Place context (city, region, etc.)

**Additional Methods:**
- `toMapboxQuery()` - Formats for Mapbox geocoding
- `fromMapboxResponse(data)` - Creates LocationModel from Mapbox response
- `toLatLng()` - Converts to Google Maps LatLng format
- `fromLatLng(latLng)` - Creates LocationModel from Google Maps LatLng

#### DriverLocationModel Class
**Properties:** 
- `orderId`, `driverId`, `latitude`, `longitude`, `timestamp`, `heading`, `speed`

**Methods:** 
- `fromJson()`, `isRecent()`, `distanceFrom(location)`, `toGoogleMapsMarker()`

#### RouteModel Class
**Properties:**
- `routeId`, `coordinates`, `distance`, `duration`, `instructions`

**Methods:**
- `fromMapboxDirections(response)`, `toPolylineCoordinates()`, `getEstimatedArrival()`

### 5.3 Map Integration Provider

#### MapProvider Class (extends ChangeNotifier)
**Properties:**
- `googleMapController` (GoogleMapController)
- `currentLocation` (LocationModel)
- `driverLocation` (DriverLocationModel)
- `pickupLocation` (LocationModel)
- `dropoffLocation` (LocationModel)
- `currentRoute` (RouteModel)
- `activeMarkers` (Map<String, Marker>)
- `isMapReady` (bool)
- `followUserLocation` (bool)

**Methods:**
- `initializeMap()` - Sets up Google Maps map
- `onMapCreated(GoogleMapController controller)` - Map initialization callback
- `updateDriverLocation(locationData)` - Updates driver position and marker
- `setOrderLocations(pickup, dropoff)` - Sets pickup/dropoff markers
- `calculateRoute(start, end, profile)` - Gets route using Mapbox Directions
- `drawRoute(routeCoordinates)` - Draws polyline on map
- `clearRoute()` - Removes current route
- `centerOnLocation(location, zoom)` - Centers map on specific location
- `fitToRoute()` - Adjusts camera to fit entire route
- `toggleLocationTracking()` - Enables/disables location following
- `searchNearbyPlaces(query)` - Search places using Mapbox Geocoding
- `addCustomMarker(location, icon, id)` - Adds custom marker
- `removeMarker(markerId)` - Removes specific marker
- `onMarkerTapped(markerId)` - Handles marker tap events

### 5.4 Tracking Screen with Google Maps

#### OrderTrackingScreen
**Widgets:**
- `GoogleMap` widget (main map display)
- Custom floating action buttons for location controls
- Route information panel
- ETA display with real-time updates
- Driver information card

**Methods:**
- `_initializeGoogleMap()` - Sets up Google Map widget
- `_onMapCreated(GoogleMapController controller)` - Map ready callback
- `_updateDriverMarker(driverLocation)` - Updates driver position
- `_centerMapOnDriver()` - Follows driver location
- `_showRouteToDestination()` - Displays route polyline
- `_handleMapTap(LatLng point)` - Handles map tap for address selection
- `_toggleLocationTracking()` - Enables/disables location following
- `_refreshRoute()` - Recalculates route with traffic data
- `_showETAUpdate()` - Updates estimated arrival time

**Google Maps-specific Features:**
- Real-time traffic integration
- Custom marker clustering
- Smooth camera animations
- Gesture handling (zoom, pan, rotate)
- Map type switching (normal, satellite, terrain, hybrid)

### 5.5 Address Search & Selection with Mapbox

#### AddressSearchWidget
**Properties:** 
- `onAddressSelected` (Function)
- `searchController` (TextEditingController)
- `currentLocation` (LocationModel) - For proximity bias
- `searchResults` (List<LocationModel>)

**Methods:**
- `_searchAddressesMapbox(query)` - Search using Mapbox Geocoding API
- `_showSearchResults()` - Displays search results in dropdown
- `_selectAddress(address)` - Handles address selection
- `_getCurrentLocation()` - Gets device location for proximity
- `_clearSearchResults()` - Clears current search results
- `_buildSearchResultItem(location)` - Builds individual result widget

**Mapbox Geocoding Features:**
- Proximity-based results (closer results first)
- Place categories (restaurant, gas station, etc.)
- Structured address components
- International address support
- Real-time search suggestions

### 5.6 WebSocket Integration for Tracking

#### Enhanced WebSocketService
**Additional Methods:**
- `_handleDriverLocationUpdate(data)` - Processes driver location updates
- `_broadcastLocationToMap(locationData)` - Sends location to MapProvider
- `subscribeToRouteUpdates(orderId)` - Subscribe to route changes
- `_handleRouteUpdate(data)` - Processes route updates (traffic, ETA changes)

## Phase 6: Enhanced UI/UX & State Management

### 6.1 Advanced State Management

#### AppStateProvider Class (extends ChangeNotifier)
**Properties:** 
- `currentScreen`, `isOffline`, `notifications`, `mapTheme`

**Methods:**
- `navigateToScreen(screen)`
- `showNotification(message)`
- `setOfflineMode(status)`
- `changeMapTheme(theme)` - Switch between map styles

### 6.2 Custom Widgets Library

#### OrderStatusCard Widget
**Properties:** 
- `order`, `onTap`

**Methods:** 
- `_getStatusColor()`, `_getStatusIcon()`

#### LocationPicker Widget (Google Maps & Mapbox Search Implementation)
**Properties:** 
- `onLocationSelected` (Function)
- `initialLocation` (LocationModel)
- `showSearchBar` (bool)
- `enableCurrentLocation` (bool)

**Methods:**
- `_showGoogleMapsLocationDialog()` - Shows full-screen map picker
- `_getCurrentLocationGoogleMaps()` - Gets location using Google Maps
- `_searchWithMapboxGeocoding(query)` - Search addresses using Mapbox
- `_handleMapTapForLocation(LatLng point)` - Handle location selection from map
- `_reverseGeocodeLocation(LatLng point)` - Convert coordinates to address

#### LiveTrackingMap Widget (Google Maps Implementation)
**Properties:**
- `orderId` (String)
- `showDriverInfo` (bool)
- `enableGestures` (bool)
- `mapType` (MapType) - Google Maps map type

**Features:**
- Real-time driver tracking with smooth animations
- Custom marker designs for different entity types
- Route polyline with traffic color coding
- Interactive map controls (zoom, compass, location)
- Map type switching (normal, satellite, terrain, hybrid)

**Methods:**
- `_updateMapCamera()` - Smooth camera transitions
- `_drawTrafficAwareRoute()` - Route with traffic data
- `_animateMarkerMovement()` - Smooth marker transitions
- `_switchMapType(mapType)` - Change map appearance
- `_handleMapTypeLoaded()` - Map type load callback

### 6.3 Navigation & Routing

#### AppRouter Class
**Methods:**
- `generateRoute(settings)`
- `_buildRoute(widget)`

**Navigation Methods:**
- `navigateToLogin()`
- `navigateToHome()`
- `navigateToOrderTracking(orderId)`
- `navigateToOrderDetails(orderId)`
- `navigateToGoogleMapsLocationPicker()`

## Phase 7: Error Handling & Offline Support

### 7.1 Error Management System

#### ErrorHandler Class
**Methods:**
- `handleApiError(error)`
- `handleWebSocketError(error)`
- `handleAuthError(error)`
- `handleGoogleMapsError(error)` - Handles Google Maps SDK and API errors
- `handleMapboxSearchError(error)` - Handles Mapbox Search API errors
- `handleGeocodingError(error)` - Handles geocoding failures
- `handleDirectionsError(error)` - Handles routing failures
- `handleTokenError(error)` - Handles invalid/expired token issues
- `showErrorDialog(context, error)`

**Map-specific Error Handling:**
- Google Maps API key validation errors
- Mapbox token validation errors
- Network connectivity issues
- API rate limit exceeded
- Invalid coordinates or addresses
- Map loading failures

#### ErrorProvider Class (extends ChangeNotifier)
**Properties:** 
- `currentError`, `errorHistory`, `mapErrors`

**Methods:**
- `setError(error)`
- `clearError()`
- `retryLastAction()`
- `handleMapTokenError()` - Specific token error handling

### 7.2 Local Storage & Caching

#### LocalStorageService Class
**Methods:**
- `saveUserData(userData)`
- `getUserData()`
- `saveOrderHistory(orders)`
- `getOrderHistory()`
- `clearStorage()`

#### CacheProvider Class (extends ChangeNotifier)
**Properties:** 
- `cachedOrders`, `cachedUserProfile`, `cachedMapData`

**Methods:**
- `cacheOrderData(orders)`
- `getCachedData(key)`
- `invalidateCache(key)`
- `cacheGeocodingResults(query, results)`
- `getCachedGeocodingResults(query)`
- `cacheDirectionsResponse(start, end, response)`
- `getCachedDirections(start, end)`
- `clearMapCache()`
- `manageCacheSize()` - Limits cache size to prevent storage issues

### 7.3 Connectivity Management

#### ConnectivityProvider Class (extends ChangeNotifier)
**Properties:** 
- `isOnline`, `connectionType`, `mapOfflineMode`

**Methods:**
- `checkConnectivity()`
- `handleConnectivityChange()`
- `retryFailedRequests()`
- `enableMapOfflineMode()` - Handle offline map scenarios (if supported by Google Maps)
- `downloadOfflineRegion(bounds)` - Pre-download map areas (if supported by Google Maps)

## Phase 8: Security & Data Validation

### 8.1 Input Validation

#### ValidationService Class
**Methods:**
- `validateEmail(email)`
- `validatePassword(password)`
- `validatePhoneNumber(phone)`
- `validateAddress(address)`
- `validateCoordinates(lat, lng)` - Validates coordinate ranges
- `validateGoogleMapsApiKey(key)` - Validates Google Maps API key format
- `validateMapboxToken(token)` - Validates Mapbox token format

#### FormValidator Class
**Methods:**
- `validateLoginForm(email, password)`
- `validateOrderForm(orderData)`
- `validateLocationData(locationModel)`
- `getValidationErrors()`

### 8.2 Security Service

#### SecurityService Class
**Methods:**
- `encryptSensitiveData(data)`
- `validateApiResponse(response)`
- `sanitizeUserInput(input)`
- `checkTokenExpiry()`
- `validateGoogleMapsResponse(response)` - Validates Google Maps API responses
- `validateMapboxSearchResponse(response)` - Validates Mapbox Search API responses
- `sanitizeLocationData(locationData)` - Ensures location data integrity

### 8.3 Token Management & Rate Limiting

#### TokenManager Class
**Properties:** 
- `firebaseToken`, `tokenExpiry`, `googleMapsApiKey`, `mapboxPublicToken`

**Methods:**
- `getValidFirebaseToken()`
- `refreshTokenIfNeeded()`
- `clearTokens()`
- `getGoogleMapsApiKey()` - Returns Google Maps API key
- `getMapboxPublicToken()` - Returns Mapbox public token
- `validateGoogleMapsApiKey()` - Validates Google Maps API key
- `validateMapboxToken()` - Validates Mapbox token

#### RateLimitManager Class
**Properties:** 
- `googleMapsRequestCount`, `mapboxGeocodingRequestCount`, `mapboxDirectionsRequestCount`, `dailyLimits`

**Methods:**
- `checkGoogleMapsLimit()` - Monitor Google Maps API usage
- `checkMapboxGeocodingLimit()` - Monitor Mapbox Geocoding API usage
- `checkMapboxDirectionsLimit()` - Monitor Mapbox Directions API usage
- `logApiRequest(service, endpoint)` - Track API usage
- `resetDailyCounters()` - Reset counters at midnight
- `getUsageReport()` - Generate usage statistics

**API Limits (Free Tier):**
- Google Maps: Check Google Cloud pricing for details (often 200 USD free credit/month)
- Mapbox Geocoding: 100,000 requests/month
- Mapbox Directions: 100,000 requests/month
- Map loads: 50,000 loads/month (for Mapbox, not applicable for Google Maps rendering)

## Phase 9: Final Integration & Testing Preparation

### 9.1 Main App Integration

#### MyApp Class (StatelessWidget)
**Widgets:** MaterialApp with MultiProvider wrapper

**Providers:** AuthProvider, OrderProvider, WebSocketProvider, MapProvider, ErrorProvider

#### Main Function
- Initialize Firebase
- Initialize Google Maps SDK
- Setup providers
- Run app

#### Dependencies (Updated for Hybrid Map Implementation)
```yaml
dependencies:
  flutter:
    sdk: flutter
  google_maps_flutter: ^2.2.3 # For map rendering
  mapbox_search: ^4.3.1 # For search and geocoding
  http: ^1.1.0
  provider: ^6.0.5
  firebase_auth: ^4.15.3
  firebase_core: ^2.24.2
  web_socket_channel: ^2.4.0
  geolocator: ^10.1.0
  shared_preferences: ^2.2.2
  connectivity_plus: ^5.0.2
  permission_handler: ^11.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
```

### 9.2 Provider Dependencies & Initialization

#### Provider Setup Order
1. **AuthProvider** (independent)
2. **ApiService** (depends on AuthProvider)
3. **MapboxService** (independent - handles Mapbox SDK)
4. **WebSocketProvider** (depends on AuthProvider)
5. **OrderProvider** (depends on ApiService, WebSocketProvider)
6. **MapProvider** (depends on OrderProvider, MapboxService)
7. **ErrorProvider** (independent - handles all errors)

#### State Management Hierarchy
- **AuthProvider** - Manages user authentication state
- **OrderProvider** - Manages order data and operations
- **WebSocketProvider** - Handles real-time communications
- **MapProvider** - Manages Mapbox integration and location data
- **ErrorProvider** - Handles application-wide errors
- **ConnectivityProvider** - Manages network state

### 9.3 Screen Flow Management

#### HomeScreen
**Widgets:** Order quick actions, recent orders, profile access, map preview

**Methods:** `_checkActiveOrders()`, `_showQuickActions()`, `_initializeMapPreview()`

#### AppWrapper
**Methods:** `_handleDeepLinks()`, `_checkAuthState()`, `_initializeServices()`, `_setupMapServices()`

### 9.4 Map Token Security Best Practices

#### Token Management Strategy
1. **Google Maps API Key Storage:**
   - Store in Firestore collection (`config/app_settings`)
   - Fetched at runtime by `ConfigService`
   - Never hardcode in source code
   - Restrict API key to Android apps and specific APIs (Maps SDK for Android, Geocoding API, Directions API, Places API)

2. **Mapbox Public Token Storage:**
   - Store in Firestore collection (`config/app_settings`)
   - Fetched at runtime by `ConfigService`
   - Never hardcode in source code

4. **Token Rotation:**
   - Implement token rotation strategy for both Google Maps and Mapbox
   - Monitor token usage via respective dashboards
   - Set up alerts for usage thresholds

#### Security Checklist
- [ ] Google Maps API Key fetched from Firestore
- [ ] Mapbox public token fetched from Firestore
- [ ] No tokens hardcoded in source files
- [ ] Token validation in app initialization
- [ ] Usage monitoring and alerts set up
- [ ] Fallback handling for token errors

## Hybrid Map Implementation Benefits

### Technical Advantages
- **Google Maps:** Stable, mature Flutter support for map rendering, smooth performance, robust mobile support.
- **Mapbox Search:** Free generous quota, predictable pricing, flexible search behavior, comprehensive geocoding.
- **Real-time traffic data** for accurate ETAs (from Mapbox Directions or Google Directions).
- **Customizable map styles** for brand consistency (Google Maps).
- **High performance** native SDK integration (Google Maps).
- **Comprehensive geocoding** with international support (Mapbox).

### Business Advantages
- **Cost-effective:** Leverages free tiers and predictable pricing from both platforms.
- **Professional appearance:** Enhances user trust with high-quality mapping.
- **Feature-rich platform:** Supports growth and advanced features.
- **Strong developer ecosystem** and documentation for both Google Maps and Mapbox.

### Dependencies Flow
```
AuthProvider
    ↓
ApiService ← WebSocketService
    ↓           ↓
OrderProvider ←┘
    ↓
MapProvider (with GoogleMapService and MapboxGeocodingService)
    ↓
GoogleMapService
MapboxGeocodingService
```

This comprehensive guide provides a robust Flutter application architecture using Provider for state management, Google Maps for map rendering, and Mapbox Search for location services. The implementation includes proper token management, security best practices, and a scalable structure for Android deployment.
