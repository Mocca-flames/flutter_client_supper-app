# Unimplemented Features and Dummy Data Analysis

This document outlines the features and components that are either unimplemented, use dummy data, or require further development, based on the `flutter_provider_plan.md` and the current codebase.

## Unimplemented Features (from `flutter_provider_plan.md` not found in code)

1.  **Order Item Model:**
    *   **Plan Reference:** Phase 3.1, "OrderItem Class".
    *   **Current Status:** The `OrderItem` class is not found as a separate model. The `OrderModel` currently includes `price` and `distanceKm` but lacks a direct `items` list as suggested by the plan.
    *   **Impact:** Full representation of order items and their pricing might be missing or simplified.

2.  **Create Order Screen:**
    *   **Plan Reference:** Phase 3.4, "CreateOrderScreen".
    *   **Current Status:** This screen is not found in the project.
    *   **Impact:** Users cannot initiate new orders through a dedicated screen.

3.  **Order Status Card Widget:**
    *   **Plan Reference:** Phase 6.2, "OrderStatusCard Widget".
    *   **Current Status:** This widget is not found.
    *   **Impact:** A reusable component for displaying order status in a card format is missing.

4.  **Live Tracking Map Widget:**
    *   **Plan Reference:** Phase 6.2, "LiveTrackingMap Widget".
    *   **Current Status:** This widget is not found. Map functionality is currently embedded directly within `OrderTrackingScreen`.
    *   **Impact:** Reusable map component for live tracking is missing.

5.  **Validation Service Class:**
    *   **Plan Reference:** Phase 8.1, "ValidationService Class".
    *   **Current Status:** This class is not implemented. Basic validation logic is currently embedded directly within screen widgets (e.g., `LoginScreen`, `RegisterScreen`).
    *   **Impact:** Centralized input validation logic is missing, leading to potential code duplication and inconsistency.

6.  **Form Validator Class:**
    *   **Plan Reference:** Phase 8.1, "FormValidator Class".
    *   **Current Status:** This class is not implemented.
    *   **Impact:** Centralized form validation logic is missing.

7.  **Security Service Class:**
    *   **Plan Reference:** Phase 8.2, "SecurityService Class".
    *   **Current Status:** This class is not implemented.
    *   **Impact:** Centralized security-related operations (e.g., encryption, API response validation, input sanitization) are missing.

8.  **Token Manager Class:**
    *   **Plan Reference:** Phase 8.3, "TokenManager Class".
    *   **Current Status:** This class is not implemented. Token management is currently handled within `FirebaseAuthService` and `ApiService`.
    *   **Impact:** A dedicated layer for token management (refreshing, storing, clearing) is missing.

9.  **App Wrapper:**
    *   **Plan Reference:** Phase 9.3, "AppWrapper".
    *   **Current Status:** An explicit `AppWrapper` class is not found. The `MainScreen` currently serves as the primary wrapper for the bottom navigation.
    *   **Impact:** A top-level wrapper for handling deep links, initial service initialization, and overall app flow might be less centralized.

## Dummy Data/Placeholder Implementations

1.  **API Service Location Methods (`lib/services/api_service.dart`):**
    *   `searchAddresses`: Currently returns hardcoded dummy addresses based on query.
    *   `reverseGeocode`: Returns a generic dummy address for any given coordinates.
    *   `searchNearbyPlaces`: Returns a fixed list of dummy nearby places.
    *   **Impact:** Real-world location search and geocoding functionality is not integrated.

2.  **Map Provider (`lib/providers/map_provider.dart`):**
    *   `fetchAndSetDummyDriverLocation` and `setDummyOrderLocations`: These methods are used to populate map data with dummy values for demonstration purposes.
    *   **Impact:** Map display relies on simulated data rather than live data.

3.  **Order Tracking Screen (`lib/screens/order_tracking_screen.dart`):**
    *   The screen heavily relies on `dummyOrder`, `dummyDriverLocation`, `dummyPickupLocation`, and `dummyDropoffLocation` for its functionality.
    *   The `_startDriverLocationUpdates` method simulates driver movement with hardcoded logic.
    *   **Impact:** Live order tracking with real driver data is not yet implemented.

4.  **Order History Screen (`lib/screens/order_history_screen.dart`):**
    *   This screen is currently a basic placeholder displaying only "Order History Screen".
    *   **Impact:** The actual UI and logic for displaying past orders are missing.

5.  **Settings Screen (`lib/screens/profile/settings_screen.dart`):**
    *   Actions for "Edit Profile", "Change Password", "Theme", "About Patonient", "Privacy Policy", and "Terms of Service" currently only show a `SnackBar` message when tapped.
    *   Notification switches (`Push Notifications`, `Email Notifications`) are present but do not have functional `onChanged` callbacks.
    *   **Impact:** Most settings options are non-functional placeholders.

6.  **Connectivity Provider (`lib/providers/connectivity_provider.dart`):**
    *   The `retryFailedRequests` method is commented out.
    *   **Impact:** Automatic retry logic for failed network requests when connectivity is restored is not implemented.

## Minor Discrepancies/Improvements

1.  **`OrderModel` vs. Plan (Phase 3.1):**
    *   The plan mentions `items` and `totalAmount` properties for `OrderModel`. The current `OrderModel` includes `price` and `distanceKm`, but a detailed `items` list is not part of the model.
    *   **Recommendation:** Clarify if `items` and `totalAmount` are still required or if `price` is sufficient for the current scope. If `items` are needed, an `OrderItem` model and its integration into `OrderModel` would be necessary.

2.  **`RegisterScreen` Navigation (Phase 1.5):**
    *   The `RegisterScreen` contains `TODO` comments regarding navigation to `LoginScreen` and `HomeScreen`. While the current implementation uses `Navigator.of(context).pushReplacementNamed('/home')` and `'/login'`, it should be updated to use the `AppRouter.navigateToHome(context)` and `AppRouter.navigateToLogin(context)` static methods for consistency with the defined routing pattern.

3.  **`WebSocketService.subscribe` and `unsubscribe` (Phase 4.1):**
    *   The `subscribe` and `unsubscribe` methods in `WebSocketService` are noted as conceptual/placeholders for generic topics. While specific driver location and order updates are handled, a more robust implementation might be needed if generic topic subscriptions are a core requirement.
    *   **Recommendation:** Review if the current WebSocket subscription model is sufficient or if a more generalized topic-based subscription mechanism is required.

4.  **`HomeScreen` Content (Phase 9.3):**
    *   The plan mentions "recent orders" as part of the `HomeScreen` content. While quick actions are present, a dedicated section for displaying recent orders on the `HomeScreen` itself is not explicitly implemented (this functionality is primarily in `OrderManagementScreen`).
    *   **Recommendation:** Decide if a summary of recent orders should be displayed directly on the `HomeScreen` for quick access.
