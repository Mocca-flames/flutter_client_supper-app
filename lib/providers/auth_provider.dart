import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:molo/models/user_model.dart';
import 'package:molo/services/firebase_auth_service.dart';
import 'package:molo/services/api_service.dart'; // Added ApiService import
import 'dart:async';
import 'dart:convert'; // For jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

const String _userProfileCacheKeyPrefix = 'userProfile_'; // Cache key prefix

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final ApiService _apiService; // Added ApiService dependency
  final SharedPreferences _prefs; // Added SharedPreferences dependency
  var logger = Logger();

  UserModel? _currentUser;
  UserModel? _userProfile; // Added userProfile property
  bool _isLoading = false;
  bool _isAuthenticated = false;
  StreamSubscription<UserModel?>? _authStateSubscription;

  // Updated constructor to accept ApiService and SharedPreferences
  AuthProvider(this._authService, this._apiService, this._prefs) {
    // Initialize and listen to auth state changes
    checkAuthState();
  }

  UserModel? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile; // Added getter for userProfile
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // This method is now async to handle backend registration and profile loading.
  Future<void> _setUser(UserModel? user) async {
    final previousUid = _currentUser?.uid;
    _currentUser = user;
    _isAuthenticated = user != null;

    if (user == null) {
      // User signed out
      _userProfile = null;
      if (previousUid != null) {
        await _clearUserProfileFromCache(previousUid);
      }
    } else if (user.uid != null && user.uid!.isNotEmpty) {
      // User signed in or registered
      if (previousUid != null && previousUid != user.uid) {
        // Different user signed in, clear old cache
        await _clearUserProfileFromCache(previousUid);
      }
      try {
        await _registerClientWithBackendIfNeeded(user.uid!);
        await loadUserProfile(); // This will now try cache first
      } catch (e) {
        logger.d(
          'AuthProvider: Error during post-authentication steps (registration/profile load) - $e',
        );
      }
    } else {
      // User object exists but UID is missing (should ideally not happen with Firebase)
      _userProfile = null;
      if (previousUid != null) {
        await _clearUserProfileFromCache(previousUid);
      }
    }
    // Notify listeners after all async operations related to setting the user are complete.
    // This ensures the UI reacts to the final state (e.g., profile loaded or error occurred).
    // Note: _setLoading(true/false) should wrap these async operations if they are lengthy.
    // For simplicity here, _setLoading is handled by the calling methods like signIn, signUp, checkAuthState.
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      _setUser(user);
    } catch (e) {
      _setUser(null); // Ensure user is null on error
      logger.d('AuthProvider: SignIn failed - $e');
      rethrow; // Allow UI to handle the error
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      final user = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      // Check if user and user.uid are not null and uid is not empty
      if (user != null && user.uid != null && user.uid!.isNotEmpty) {
        // _setUser will now handle backend registration and profile loading.
        // The try-catch for backend registration is now within _setUser or _registerClientWithBackendIfNeeded.
        // If _setUser encounters a critical failure during registration/profile load
        // that requires user sign-out, it should handle it or rethrow an exception
        // that this top-level catch block can manage.
        await _setUser(user);
        // If _setUser itself throws an exception (e.g., critical registration failure that it decides to rethrow),
        // it will be caught by the outer catch (e).
      } else {
        // This case implies Firebase user creation failed or returned a user without a UID.
        await _setUser(null); // Ensure state is cleared
        throw Exception('Firebase user creation failed or UID is missing.');
      }
    } catch (e) {
      // This will catch errors from _authService.createUserWithEmailAndPassword
      // or critical errors rethrown from _setUser.
      await _setUser(
        null,
      ); // Ensure local state is cleared on any signUp failure.
      logger.d('AuthProvider: SignUp failed - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final user = await _authService.signInWithGoogle();
      _setUser(user);
    } catch (e) {
      _setUser(null);
      logger.d('AuthProvider: Google SignIn failed - $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _setUser(null); // This will also clear _userProfile
    } catch (e) {
      logger.d('AuthProvider: SignOut failed - $e');
      // Decide if rethrow is needed or if UI should just react to _currentUser being null
    } finally {
      _setLoading(false);
    }
  }

  void checkAuthState() {
    _setLoading(true); // Indicate that we are checking the auth state.
    _authStateSubscription
        ?.cancel(); // Cancel any existing subscription to prevent multiple listeners.
    _authStateSubscription = _authService.authStateChanges.listen(
      (UserModel? user) async {
        // _setUser is async, so await it.
        await _setUser(user);
        // Only set loading to false after the first auth state is processed.
        // This ensures UI doesn't flicker or show content prematurely.
        if (_isLoading) _setLoading(false);
      },
      onError: (error) {
        logger.d('AuthProvider: Error in authStateChanges stream - $error');
        // Ensure user state is cleared on stream error. _setUser(null) is async.
        _setUser(null).then((_) {
          if (_isLoading) _setLoading(false); // Stop loading on error as well.
        });
      },
    );
    // Note: _isLoading remains true until the first event from authStateChanges is processed.
    // This is generally the desired behavior for an initial auth check.
  }

  Future<String?> refreshToken() async {
    _setLoading(true);
    try {
      final token = await _authService.getIdToken();
      // Token refresh is handled by getIdToken(true) in FirebaseAuthService.
      // This method here is more of a getter for the refreshed token.
      // No specific state change in AuthProvider needed unless token itself is stored here.
      return token;
    } catch (e) {
      logger.d('AuthProvider: RefreshToken failed - $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // Method to register client with backend if needed
  Future<void> _registerClientWithBackendIfNeeded(String firebaseUid) async {
    if (firebaseUid.isEmpty) {
      logger.d(
        'AuthProvider: Firebase UID is empty, skipping backend registration.',
      );
      return;
    }
    try {
      logger.d(
        'AuthProvider: Attempting to register client with backend, UID: $firebaseUid',
      );
      // The registerClient method in ApiService should ideally handle cases
      // where the user is already registered (e.g., by the backend returning a 200 or 201
      // on first registration, and maybe a 200 or a specific "already registered" status code
      // like 409 Conflict, which ApiService or this method should interpret correctly).
      await _apiService.registerClient(firebaseUid);
      logger.d(
        'AuthProvider: Client registration call completed for UID: $firebaseUid',
      );
    } catch (e) {
      // Check if the error is due to the user already being registered.
      // This depends on how ApiService and the backend communicate this.
      // For example, if ApiService throws a specific exception for "already registered"
      // or if the error 'e' contains a specific status code (e.g., 409).
      // If ApiService.registerClient throws an exception, it means it was not a
      // "user already registered" (409) scenario that it handles gracefully.
      // Therefore, any exception caught here is considered a critical failure in registration.
      logger.d(
        'AuthProvider: CRITICAL - Failed to register client with backend for UID: $firebaseUid - $e',
      );
      // Rethrow the error to be caught by the calling method (e.g., _setUser).
      // This will prevent loadUserProfile from being called if registration failed.
      rethrow;
    }
  }

  // New methods for Phase 2.2
  Future<void> _saveUserProfileToCache(UserModel userProfile) async {
    if (userProfile.uid == null || userProfile.uid!.isEmpty) return;
    try {
      final String profileJson = jsonEncode(userProfile.toJson());
      await _prefs.setString(
        _userProfileCacheKeyPrefix + userProfile.uid!,
        profileJson,
      );
      logger.d(
        'AuthProvider: User profile saved to cache for UID ${userProfile.uid}',
      );
    } catch (e) {
    logger.d('AuthProvider: Failed to save user profile to cache - $e');
    }
  }

  Future<UserModel?> _loadUserProfileFromCache(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final String? profileJson = _prefs.getString(
        _userProfileCacheKeyPrefix + uid,
      );
      if (profileJson != null) {
        final Map<String, dynamic> profileData = jsonDecode(profileJson);
        logger.d('AuthProvider: User profile loaded from cache for UID $uid');
        return UserModel.fromJson(profileData);
      }
    } catch (e) {
      logger.d(
        'AuthProvider: Failed to load user profile from cache or parse it - $e',
      );
      // If cache is corrupted, clear it for this user
      await _clearUserProfileFromCache(uid);
    }
    return null;
  }

  Future<void> _clearUserProfileFromCache(String uid) async {
    if (uid.isEmpty) return;
    try {
      await _prefs.remove(_userProfileCacheKeyPrefix + uid);
      logger.d('AuthProvider: User profile cleared from cache for UID $uid');
    } catch (e) {
      logger.d('AuthProvider: Failed to clear user profile from cache - $e');
    }
  }

  Future<void> loadUserProfile({bool forceRefresh = false}) async {
    if (_currentUser == null ||
        _currentUser!.uid == null ||
        _currentUser!.uid!.isEmpty) {
      logger.d(
        'AuthProvider: No current user or UID is empty/null, cannot load profile.',
      );
      _userProfile = null; // Ensure profile is cleared if no user
      notifyListeners();
      return;
    }

    final String currentUid = _currentUser!.uid!;
    _setLoading(true);

    try {
      if (!forceRefresh) {
        final cachedProfile = await _loadUserProfileFromCache(currentUid);
        if (cachedProfile != null) {
          if (kDebugMode) {
            print('[AuthProvider.loadUserProfile] Loaded profile from cache: $cachedProfile');
          }
          _userProfile = cachedProfile;
          notifyListeners(); // Notify after loading from cache
          // If profile is from cache, we might not need to set loading to false yet,
          // depending on whether a background refresh is desired.
          // For now, assume cache load is sufficient if not force refreshing.
          _setLoading(false);
          return; // Profile loaded from cache
        }
      }

      // If not in cache, or if forceRefresh is true, fetch from API
      logger.d(
        'AuthProvider: Fetching user profile from API for UID $currentUid.',
      );
      final UserModel profileData = await _apiService.getUserProfile();

      // If _apiService.getUserProfile() succeeds, it returns a UserModel.
      // If it fails, it throws an exception caught below.
      _userProfile = profileData;

      // Ensure the fetched profile has the current user's UID if it's missing from the API response.
      if (_userProfile!.uid == null || _userProfile!.uid!.isEmpty) {
        _userProfile = _userProfile!.copyWith(uid: currentUid);
      }

      if (kDebugMode) {
        print('[AuthProvider.loadUserProfile] Fetched profile from API: $_userProfile');
      }

      await _saveUserProfileToCache(_userProfile!);
    } catch (e) {
      logger.d(
        'AuthProvider: Failed to load user profile (API or cache interaction) - $e',
      );
      _userProfile = null;
      // Also clear cache on error to prevent serving stale/corrupted data next time
      await _clearUserProfileFromCache(currentUid);
    } finally {
      _setLoading(false);
      notifyListeners(); // Ensure listeners are notified in all cases after attempting to load
    }
  }

  Future<void> updateProfile(Map<String, dynamic> userData) async {
    if (_currentUser == null) return;
    _setLoading(true);
    try {
      await _apiService.updateUserProfile(
        fullName: userData['full_name'],
        phoneNumber: userData['phone_number'],
      );
      // After updating, reload the profile to get the latest data, forcing a refresh from API
      await loadUserProfile(forceRefresh: true);
    } catch (e) {
      logger.d('AuthProvider: Failed to update user profile - $e');
      rethrow; // Allow UI to handle the error
    } finally {
      _setLoading(false);
    }
  }

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }
}
