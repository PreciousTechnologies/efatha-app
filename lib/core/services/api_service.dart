import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Main API Service for communicating with Django backend
class ApiService {
  final StorageService _storage = StorageService();

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Handle API errors
  Map<String, dynamic> _handleError(http.Response response) {
    try {
      // Try to parse as JSON first
      if (response.body.isNotEmpty) {
        final body = json.decode(response.body);
        return {
          'success': false,
          'message':
              body['detail'] ??
              body['message'] ??
              body['error'] ??
              'An error occurred',
          'errors': body,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message':
              'Server returned empty response (Status: ${response.statusCode})',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      // If JSON parsing fails, return the raw body
      return {
        'success': false,
        'message': response.body.isNotEmpty
            ? 'Server error: ${response.body}'
            : 'Server error (Status: ${response.statusCode})',
        'statusCode': response.statusCode,
        'rawBody': response.body,
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: await _getHeaders(),
            body: json.encode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Registration successful',
          'data': responseData,
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Login with password (traditional)
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.loginPassword),
            headers: await _getHeaders(),
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Save tokens
        await _storage.setAccessToken(responseData['access']);
        await _storage.setRefreshToken(responseData['refresh']);

        // Save user data
        if (responseData['user'] != null) {
          await _storage.saveUserData(responseData['user']);
          await _storage.setUserId(responseData['user']['id']);
          await _storage.setUserRole(responseData['user']['role']);
        }

        return {
          'success': true,
          'message': 'Login successful',
          'data': responseData,
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Send verification code to email
  Future<Map<String, dynamic>> sendVerificationCode({
    required String email,
    String purpose = 'login',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.sendVerificationCode),
            headers: await _getHeaders(),
            body: json.encode({'email': email, 'purpose': purpose}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Verification code sent',
          'data': responseData,
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Verify code and login
  Future<Map<String, dynamic>> verifyCodeAndLogin({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.verifyCode),
            headers: await _getHeaders(),
            body: json.encode({'email': email, 'code': code}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Save tokens
        await _storage.setAccessToken(responseData['access']);
        await _storage.setRefreshToken(responseData['refresh']);

        // Save user data
        if (responseData['user'] != null) {
          await _storage.saveUserData(responseData['user']);
          await _storage.setUserId(responseData['user']['id']);
          await _storage.setUserRole(responseData['user']['role']);
        }

        return {
          'success': true,
          'message': 'Login successful',
          'data': responseData,
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.currentUser),
            headers: await _getHeaders(includeAuth: true),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get constants (countries, regions, church positions)
  Future<Map<String, dynamic>> getConstants() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.constants), headers: await _getHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Get regions by country
  Future<Map<String, dynamic>> getRegionsByCountry(String country) async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.regionsByCountry}?country=$country'),
            headers: await _getHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData['regions']};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Refresh access token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        return {'success': false, 'message': 'No refresh token available'};
      }

      final response = await http
          .post(
            Uri.parse(ApiConfig.refresh),
            headers: await _getHeaders(),
            body: json.encode({'refresh': refreshToken}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        await _storage.setAccessToken(responseData['access']);

        return {
          'success': true,
          'message': 'Token refreshed',
          'data': responseData,
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Verify if current token is valid
  Future<bool> verifyToken() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return false;

      final response = await http
          .post(
            Uri.parse(ApiConfig.verifyToken),
            headers: await _getHeaders(),
            body: json.encode({'token': token}),
          )
          .timeout(ApiConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Check authentication status and refresh token if needed
  Future<bool> isAuthenticated() async {
    try {
      // Check if user has tokens stored
      final accessToken = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();
      final isLoggedIn = await _storage.isLoggedIn();

      if (!isLoggedIn || accessToken == null) {
        return false;
      }

      // Try to verify the current access token
      final isValid = await verifyToken();

      if (isValid) {
        return true;
      }

      // If access token is invalid, try to refresh it
      if (refreshToken != null) {
        final refreshResult = await this.refreshToken();
        if (refreshResult['success'] == true) {
          return true;
        }
      }

      // If refresh failed, user needs to login again
      await logout();
      return false;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();
  }

  // Generic GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(endpoint),
            headers: await _getHeaders(includeAuth: requiresAuth),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: await _getHeaders(includeAuth: requiresAuth),
            body: json.encode(data),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: ${e.toString()}'};
    }
  }

  // Upload profile picture
  Future<Map<String, dynamic>> uploadProfilePicture(String imagePath) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        print('❌ Upload failed: Not authenticated');
        return {'success': false, 'message': 'Not authenticated'};
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/auth/users/upload_profile_picture/',
      );
      print('📤 Uploading profile picture to: $uri');
      print('🖼️ Image path: $imagePath');

      final request = http.MultipartRequest('POST', uri);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', imagePath),
      );

      final streamedResponse = await request.send().timeout(
        ApiConfig.connectionTimeout,
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload response status: ${response.statusCode}');
      print('📥 Upload response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Profile picture uploaded successfully');
        return {'success': true, 'data': responseData};
      } else {
        print('❌ Upload failed with status ${response.statusCode}');
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Upload exception: ${e.toString()}');
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  // Delete profile picture
  Future<Map<String, dynamic>> deleteProfilePicture() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http
          .delete(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/auth/users/delete_profile_picture/',
            ),
            headers: await _getHeaders(includeAuth: true),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Delete failed: ${e.toString()}'};
    }
  }

  // Update user bio
  Future<Map<String, dynamic>> updateBio(String bio) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/users/update_bio/'),
            headers: await _getHeaders(includeAuth: true),
            body: json.encode({'bio': bio}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      return {'success': false, 'message': 'Update failed: ${e.toString()}'};
    }
  }

  // Update user profile information
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('📤 Updating profile with data: $profileData');

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/users/update_profile/'),
            headers: await _getHeaders(includeAuth: true),
            body: json.encode(profileData),
          )
          .timeout(ApiConfig.connectionTimeout);

      print('📥 Update response status: ${response.statusCode}');
      print('📥 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Update local storage with new data
        if (responseData != null) {
          await _storage.saveUserData(responseData);
        }

        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Update exception: ${e.toString()}');
      return {'success': false, 'message': 'Update failed: ${e.toString()}'};
    }
  }

  // ==================== SERMON MANAGEMENT ====================

  /// Get all sermons with optional filtering and search
  Future<Map<String, dynamic>> getSermons({
    String? category,
    String? pastor,
    String? topics,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Build query parameters
      Map<String, String> queryParams = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (category != null && category != 'all') {
        queryParams['category'] = category;
      }
      if (pastor != null && pastor.isNotEmpty) {
        queryParams['pastor'] = pastor;
      }
      if (topics != null && topics.isNotEmpty) {
        queryParams['topics'] = topics;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse(
        ApiConfig.sermons,
      ).replace(queryParameters: queryParams);

      print('📤 Fetching sermons from: $uri');

      final response = await http
          .get(uri, headers: await _getHeaders(includeAuth: true))
          .timeout(ApiConfig.connectionTimeout);

      print('📥 Sermons response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Get sermons exception: ${e.toString()}');
      return {'success': false, 'message': 'Failed to fetch sermons: $e'};
    }
  }

  /// Upload new sermon (multipart with files)
  Future<Map<String, dynamic>> uploadSermon(
    Map<String, dynamic> sermonData, {
    File? audioFile,
    File? videoFile,
    File? thumbnailFile,
  }) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('📤 Uploading sermon...');

      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.sermons));

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      sermonData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add audio file
      if (audioFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('audio_file', audioFile.path),
        );
      }

      // Add video file
      if (videoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('video_file', videoFile.path),
        );
      }

      // Add thumbnail
      if (thumbnailFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('thumbnail', thumbnailFile.path),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5), // Longer timeout for file uploads
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload response status: ${response.statusCode}');
      print('📥 Upload response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Sermon uploaded successfully',
          'data': responseData,
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Upload sermon exception: ${e.toString()}');
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }

  /// Update existing sermon
  Future<Map<String, dynamic>> updateSermon(
    int sermonId,
    Map<String, dynamic> sermonData, {
    File? audioFile,
    File? videoFile,
    File? thumbnailFile,
  }) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('📤 Updating sermon $sermonId...');

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiConfig.sermons}$sermonId/'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      sermonData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Add audio file if provided
      if (audioFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('audio_file', audioFile.path),
        );
      }

      // Add video file if provided
      if (videoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('video_file', videoFile.path),
        );
      }

      // Add thumbnail if provided
      if (thumbnailFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('thumbnail', thumbnailFile.path),
        );
      }

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Update response status: ${response.statusCode}');
      print('📥 Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': 'Sermon updated successfully',
          'data': responseData,
        };
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Update sermon exception: ${e.toString()}');
      return {'success': false, 'message': 'Update failed: $e'};
    }
  }

  /// Delete sermon
  Future<Map<String, dynamic>> deleteSermon(int sermonId) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print('📤 Deleting sermon $sermonId...');

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.sermons}$sermonId/'),
            headers: await _getHeaders(includeAuth: true),
          )
          .timeout(ApiConfig.connectionTimeout);

      print('📥 Delete response status: ${response.statusCode}');

      if (response.statusCode == 204) {
        return {'success': true, 'message': 'Sermon deleted successfully'};
      } else {
        return _handleError(response);
      }
    } catch (e) {
      print('❌ Delete sermon exception: ${e.toString()}');
      return {'success': false, 'message': 'Delete failed: $e'};
    }
  }
}
