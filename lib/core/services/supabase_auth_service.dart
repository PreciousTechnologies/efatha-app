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

  /// Register with email + password. Creates auth user and profile row.
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
      // Upsert profile (trigger in schema.sql also does this; upsert is safe).
      await _client.from(SupabaseConfig.profilesTable).upsert({
        'id': user.id,
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
      });
    }
    return response;
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
  Future<void> sendOtp({required String email}) async {
    await _client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Current user's profile row (replaces GET users/me/).
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final row = await _client
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', user.id)
        .maybeSingle();
    return row;
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
