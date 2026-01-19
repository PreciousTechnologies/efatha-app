import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// AuthManager - Centralized authentication state management
/// Handles token refresh, session persistence, and auto-login
class AuthManager extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isAuthenticated = false;
  bool _isInitialized = false;
  Timer? _tokenRefreshTimer;

  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  /// Initialize auth manager - Call this on app startup
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check if user has valid session
      _isAuthenticated = await _apiService.isAuthenticated();
      _isInitialized = true;

      // If authenticated, start auto-refresh timer
      if (_isAuthenticated) {
        _startTokenRefreshTimer();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _isAuthenticated = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Login user and start session
  Future<bool> login(String username, String password) async {
    try {
      final response = await _apiService.login(
        username: username,
        password: password,
      );

      if (response['success'] == true) {
        _isAuthenticated = true;
        _startTokenRefreshTimer();
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  /// Logout user and clear session
  Future<void> logout() async {
    try {
      await _apiService.logout();
      _isAuthenticated = false;
      _stopTokenRefreshTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Start automatic token refresh timer
  /// Refreshes token every 30 minutes (adjust based on your token expiry)
  void _startTokenRefreshTimer() {
    _stopTokenRefreshTimer(); // Clear any existing timer

    // Refresh token every 30 minutes
    _tokenRefreshTimer = Timer.periodic(const Duration(minutes: 30), (
      timer,
    ) async {
      try {
        final result = await _apiService.refreshToken();

        if (result['success'] != true) {
          // If refresh fails, logout user
          await logout();
        }
      } catch (e) {
        debugPrint('Token refresh error: $e');
        await logout();
      }
    });
  }

  /// Stop token refresh timer
  void _stopTokenRefreshTimer() {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
  }

  /// Manually refresh token
  Future<bool> refreshToken() async {
    try {
      final result = await _apiService.refreshToken();
      return result['success'] == true;
    } catch (e) {
      debugPrint('Manual token refresh error: $e');
      return false;
    }
  }

  /// Check if current session is still valid
  Future<bool> validateSession() async {
    try {
      final isValid = await _apiService.isAuthenticated();

      if (!isValid && _isAuthenticated) {
        // Session expired, logout
        await logout();
      }

      _isAuthenticated = isValid;
      notifyListeners();
      return isValid;
    } catch (e) {
      debugPrint('Session validation error: $e');
      return false;
    }
  }

  /// Get user data from storage
  Future<Map<String, String?>> getUserData() async {
    return await _storageService.getUserData();
  }

  @override
  void dispose() {
    _stopTokenRefreshTimer();
    super.dispose();
  }
}
