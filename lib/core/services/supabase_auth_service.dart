import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client_service.dart';
import '../config/supabase_config.dart';

/// Supabase Auth — replaces Django JWT + email-code flow.
///
/// Django mapping:
/// - POST auth/register/            -> signUp() (+ creates public.profiles row)
/// - POST auth/login-password/      -> signInWithPassword()
/// - POST auth/send-code|verify-code -> signInWithOtp() + verifyOTP()
///   (Supabase sends the email itself; no custom SMTP needed)
/// - GET auth/users/me/             -> getCurrentProfile()
/// - POST auth/refresh|verify       -> handled automatically by supabase_flutter
class SupabaseAuthService {
  SupabaseClient get _client => SupabaseClientService.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentSession != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Human-friendly text for common Supabase Auth errors
  /// (rate limits, duplicates, weak passwords, unconfirmed emails).
  static String friendlyError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('rate limit') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('too many')) {
      return 'Too many emails sent. Supabase limits auth emails per hour. '
          'Please wait about an hour and try again (avoid repeated resends).';
    }
    if (lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('user already')) {
      return 'This email is already registered. Please sign in instead.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Wrong email or password. Please try again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email first — check your inbox.';
    }
    if (lower.contains('password')) {
      return 'Password too weak. Use at least 6 characters.';
    }
    if (lower.contains('signups not allowed') ||
        lower.contains('user not found')) {
      return 'No account found for this email. Please register first.';
    }
    return message;
  }

  /// Key for a profile that could not be written at sign-up time
  /// (no session when email confirmation is ON -> RLS forbids anon writes).
  static const String _pendingProfileKey = 'pending_profile';

  Map<String, dynamic> _profileRow(
    String userId,
    String email,
    Map<String, dynamic> profile,
  ) {
    return {
      'id': userId,
      'email': email,
      'username': profile['username'] ?? email.split('@').first,
      'first_name': profile['first_name'] ?? '',
      'last_name': profile['last_name'] ?? '',
      'middle_name': profile['middle_name'],
      'phone_number': profile['phone_number'],
      'country': profile['country'],
      'region': profile['region'],
      'service_region': profile['service_region'],
      'city': profile['city'],
      'church_position': profile['church_position'] ?? 'muumini',
      'role': 'member',
    };
  }

  /// Register with email + password. Creates auth user and profile row.
  ///
  /// When email confirmation is ON there is no session yet, so the profile
  /// write would violate RLS — instead it is stashed locally and applied by
  /// [completePendingProfile] after the first sign-in.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic> profile = const {},
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': profile['username'] ?? email.split('@').first,
        'first_name': profile['first_name'] ?? '',
        'last_name': profile['last_name'] ?? '',
      },
    );

    final user = response.user;
    if (user != null) {
      if (response.session != null) {
        // Authenticated -> RLS (auth.uid() = id) allows the write.
        // (The handle_new_user trigger may already have created the row;
        // upsert covers both cases.)
        await _client
            .from(SupabaseConfig.profilesTable)
            .upsert(_profileRow(user.id, email, profile));
      } else {
        // No session (confirmation pending) — stash for post-sign-in.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _pendingProfileKey,
          jsonEncode(_profileRow(user.id, email, profile)),
        );
      }
    }
    return response;
  }

  /// Apply a profile stashed by [signUp] once the user is signed in.
  /// Safe to call after any successful sign-in; no-op when nothing pending
  /// or when the signed-in user differs from the stashed one.
  Future<void> completePendingProfile() async {
    final user = currentUser;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingProfileKey);
    if (raw == null) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      // Only apply to the account it was created for.
      if (data['id']?.toString() != user.id) return;
      await _client.from(SupabaseConfig.profilesTable).upsert(data);
      await prefs.remove(_pendingProfileKey);
    } catch (_) {
      // Leave it stashed; a later sign-in will retry.
    }
  }

  /// Traditional login (replaces login-password/).
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Passwordless email OTP (replaces send-code/verify-code/).
  /// Set [shouldCreateUser] false for returning-user login so unknown
  /// emails don't silently create accounts.
  Future<void> sendOtp({
    required String email,
    bool shouldCreateUser = true,
  }) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: shouldCreateUser,
    );
  }

  /// Send password-reset email (replaces Django forgot-password).
  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Verify an email OTP code.
  /// Supabase issues two flavors: sign-in codes (`email`, from signInWithOtp)
  /// and signup-confirmation codes (`signup`, from the Confirm-signup
  /// template when it contains `{{ .Token }}`). Defaults to `email`.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
    OtpType type = OtpType.email,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: type,
    );
  }

  /// Current user's profile row (replaces GET users/me/).
  /// Adds legacy aliases (`profile_picture`, `role_display`) so existing
  /// Home/More UI code works unchanged.
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final row = await _client
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    final map = Map<String, dynamic>.from(row);
    map['profile_picture'] ??= map['profile_picture_url'];
    map['role_display'] ??= _roleDisplayName(map['role']?.toString());
    map['email'] ??= user.email;
    return map;
  }

  String _roleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'chief_apostle':
        return 'Chief Apostle';
      case 'katibu_kiongozi':
        return 'Katibu Kiongozi';
      case 'apostle':
        return 'Apostle';
      case 'senior_pastor':
        return 'Senior Pastor';
      case 'bishop':
        return 'Bishop';
      case 'editor':
        return 'Editor';
      case 'data_entry':
        return 'Data Entry';
      default:
        return 'Member';
    }
  }

  /// Update profile fields (replaces PATCH update_profile/update_bio/).
  Future<Map<String, dynamic>?> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');
    final row = await _client
        .from(SupabaseConfig.profilesTable)
        .update(data)
        .eq('id', user.id)
        .select()
        .single();
    return row;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
