import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for authentication tokens and user data
class StorageService {
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyUsername = 'username';
  static const String _keyEmail = 'email';
  static const String _keyChurchPosition = 'church_position';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyCountry = 'country';
  static const String _keyRegion = 'region';
  static const String _keyServiceRegion = 'service_region';
  static const String _keyCity = 'city';
  static const String _keyRegistrationNumber = 'registration_number';
  static const String _keyMembershipNumber = 'membership_number';
  static const String _keyBio = 'bio';
  static const String _keyAddress = 'address';

  // Get SharedPreferences instance
  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // Access Token
  Future<void> setAccessToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAccessToken, token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAccessToken);
  }

  // Refresh Token
  Future<void> setRefreshToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyRefreshToken, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyRefreshToken);
  }

  // User ID
  Future<void> setUserId(int id) async {
    final prefs = await _prefs;
    await prefs.setInt(_keyUserId, id);
  }

  Future<int?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getInt(_keyUserId);
  }

  // User Role
  Future<void> setUserRole(String role) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUserRole, role);
  }

  Future<String?> getUserRole() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserRole);
  }

  // Username
  Future<void> setUsername(String username) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUsername, username);
  }

  Future<String?> getUsername() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUsername);
  }

  // Email
  Future<void> setEmail(String email) async {
    final prefs = await _prefs;
    await prefs.setString(_keyEmail, email);
  }

  Future<String?> getEmail() async {
    final prefs = await _prefs;
    return prefs.getString(_keyEmail);
  }

  // Church Position
  Future<void> setChurchPosition(String position) async {
    final prefs = await _prefs;
    await prefs.setString(_keyChurchPosition, position);
  }

  Future<String?> getChurchPosition() async {
    final prefs = await _prefs;
    return prefs.getString(_keyChurchPosition);
  }

  // Login Status
  Future<void> setLoggedIn(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_keyIsLoggedIn, value);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }

  // First Name
  Future<void> setFirstName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_keyFirstName, name);
  }

  Future<String?> getFirstName() async {
    final prefs = await _prefs;
    return prefs.getString(_keyFirstName);
  }

  // Last Name
  Future<void> setLastName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLastName, name);
  }

  Future<String?> getLastName() async {
    final prefs = await _prefs;
    return prefs.getString(_keyLastName);
  }

  // Phone Number
  Future<void> setPhoneNumber(String phone) async {
    final prefs = await _prefs;
    await prefs.setString(_keyPhoneNumber, phone);
  }

  Future<String?> getPhoneNumber() async {
    final prefs = await _prefs;
    return prefs.getString(_keyPhoneNumber);
  }

  // Country
  Future<void> setCountry(String country) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCountry, country);
  }

  Future<String?> getCountry() async {
    final prefs = await _prefs;
    return prefs.getString(_keyCountry);
  }

  // Region
  Future<void> setRegion(String region) async {
    final prefs = await _prefs;
    await prefs.setString(_keyRegion, region);
  }

  Future<String?> getRegion() async {
    final prefs = await _prefs;
    return prefs.getString(_keyRegion);
  }

  // Service Region
  Future<void> setServiceRegion(String serviceRegion) async {
    final prefs = await _prefs;
    await prefs.setString(_keyServiceRegion, serviceRegion);
  }

  Future<String?> getServiceRegion() async {
    final prefs = await _prefs;
    return prefs.getString(_keyServiceRegion);
  }

  // City
  Future<void> setCity(String city) async {
    final prefs = await _prefs;
    await prefs.setString(_keyCity, city);
  }

  Future<String?> getCity() async {
    final prefs = await _prefs;
    return prefs.getString(_keyCity);
  }

  // Registration Number
  Future<void> setRegistrationNumber(String regNumber) async {
    final prefs = await _prefs;
    await prefs.setString(_keyRegistrationNumber, regNumber);
  }

  Future<String?> getRegistrationNumber() async {
    final prefs = await _prefs;
    return prefs.getString(_keyRegistrationNumber);
  }

  // Membership Number
  Future<void> setMembershipNumber(String membershipNumber) async {
    final prefs = await _prefs;
    await prefs.setString(_keyMembershipNumber, membershipNumber);
  }

  Future<String?> getMembershipNumber() async {
    final prefs = await _prefs;
    return prefs.getString(_keyMembershipNumber);
  }

  // Bio
  Future<void> setBio(String bio) async {
    final prefs = await _prefs;
    await prefs.setString(_keyBio, bio);
  }

  Future<String?> getBio() async {
    final prefs = await _prefs;
    return prefs.getString(_keyBio);
  }

  // Address
  Future<void> setAddress(String address) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAddress, address);
  }

  Future<String?> getAddress() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAddress);
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    if (userData['id'] != null) await setUserId(userData['id']);
    if (userData['username'] != null) await setUsername(userData['username']);
    if (userData['email'] != null) await setEmail(userData['email']);
    if (userData['role'] != null) await setUserRole(userData['role']);
    if (userData['church_position'] != null) {
      await setChurchPosition(userData['church_position']);
    }
    if (userData['first_name'] != null) {
      await setFirstName(userData['first_name']);
    }
    if (userData['last_name'] != null) await setLastName(userData['last_name']);
    if (userData['phone_number'] != null) {
      await setPhoneNumber(userData['phone_number']);
    }
    if (userData['country'] != null) await setCountry(userData['country']);
    if (userData['region'] != null) await setRegion(userData['region']);
    if (userData['service_region'] != null) {
      await setServiceRegion(userData['service_region']);
    }
    if (userData['city'] != null) await setCity(userData['city']);
    if (userData['registration_number'] != null) {
      await setRegistrationNumber(userData['registration_number']);
    }
    if (userData['membership_number'] != null) {
      await setMembershipNumber(userData['membership_number']);
    }
    if (userData['bio'] != null) await setBio(userData['bio']);
    if (userData['address'] != null) await setAddress(userData['address']);
    await setLoggedIn(true);
  }

  // Get all user data
  Future<Map<String, String?>> getUserData() async {
    return {
      'id': (await getUserId())?.toString(),
      'username': await getUsername(),
      'email': await getEmail(),
      'role': await getUserRole(),
      'church_position': await getChurchPosition(),
      'first_name': await getFirstName(),
      'last_name': await getLastName(),
      'phone_number': await getPhoneNumber(),
      'country': await getCountry(),
      'region': await getRegion(),
      'service_region': await getServiceRegion(),
      'city': await getCity(),
      'registration_number': await getRegistrationNumber(),
      'membership_number': await getMembershipNumber(),
      'bio': await getBio(),
      'address': await getAddress(),
    };
  }
}
