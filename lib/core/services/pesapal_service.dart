import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../config/api_config.dart';

/// Pesapal Payment Service
/// Handles integration with Pesapal payment gateway
class PesapalService {
  // HTTP client with SSL certificate handling
  static http.Client? _httpClient;

  /// Get HTTP client with proper SSL handling
  static http.Client _getHttpClient() {
    if (_httpClient == null) {
      final ioClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) {
              // Accept certificates from Pesapal domains
              return host.contains('pesapal.com');
            };
      _httpClient = IOClient(ioClient);
    }
    return _httpClient!;
  }

  // Environment: 'sandbox' for testing, 'live' for production
  // IMPORTANT: Only use 'live' when ready for real payments
  // Current live credentials are configured for Tanzania [TZ]
  static const String _environment =
      'live'; // Changed to 'live' for Tanzania M-Pesa production

  // Pesapal API URLs (dynamic based on environment)
  static const String _pesapalApiUrl = _environment == 'sandbox'
      ? 'https://cybqa.pesapal.com/pesapalv3'
      : 'https://pay.pesapal.com/v3';
  static const String _authUrl = '$_pesapalApiUrl/api/Auth/RequestToken';
  static const String _registerIpnUrl =
      '$_pesapalApiUrl/api/URLSetup/RegisterIPN';
  static const String _submitOrderUrl =
      '$_pesapalApiUrl/api/Transactions/SubmitOrderRequest';
  static const String _transactionStatusUrl =
      '$_pesapalApiUrl/api/Transactions/GetTransactionStatus';

  // Pesapal credentials (dynamic based on environment)
  // LIVE CREDENTIALS (Production)
  static const String _consumerKeyLive = '84tMkwKOsyp8MQBLLltdolXcvoF2T9h+';
  static const String _consumerSecretLive = 'I7RVFHfvANb4/559uM2UUNdXpd4=';

  // SANDBOX CREDENTIALS (Testing - has all payment methods including M-Pesa)
  static const String _consumerKeySandbox = 'qkio1BGGYAXTu2JOfm7XSXNruoZsrqEW';
  static const String _consumerSecretSandbox = 'osGQ364R49cXKeOYSpaOnT++rHs=';

  // Active credentials based on environment
  final String _consumerKey = _environment == 'sandbox'
      ? _consumerKeySandbox
      : _consumerKeyLive;
  final String _consumerSecret = _environment == 'sandbox'
      ? _consumerSecretSandbox
      : _consumerSecretLive;
  String? _accessToken;
  DateTime? _tokenExpiry;
  String? _ipnId; // Store registered IPN ID

  /// Initialize with credentials from backend/env
  Future<void> initialize() async {
    // In production, fetch these from your secure backend
    // For now, we'll use the hardcoded values
    await _getAccessToken();

    // Register IPN if not already registered
    if (_ipnId == null) {
      final callbackUrl = '${ApiConfig.apiUrl}/payments/pesapal/callback';
      _ipnId = await registerIPN(callbackUrl);
      if (_ipnId != null) {
        print('IPN registered successfully: $_ipnId');
      } else {
        print('Failed to register IPN, will proceed without notification_id');
      }
    }
  }

  /// Get Pesapal access token
  Future<String?> _getAccessToken() async {
    // Check if token is still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final client = _getHttpClient();
      final response = await client.post(
        Uri.parse(_authUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'consumer_key': _consumerKey,
          'consumer_secret': _consumerSecret,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['token'];
        // Tokens typically expire in 5 minutes
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 4));
        return _accessToken;
      } else {
        print(
          'Error getting Pesapal access token: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error getting Pesapal access token: $e');
    }
    return null;
  }

  /// Submit payment order to Pesapal
  Future<Map<String, dynamic>?> submitOrder({
    required double amount,
    required String currency,
    required String description,
    required String userEmail,
    required String userPhone,
    required String userName,
    String? reference,
  }) async {
    final token = await _getAccessToken();
    if (token == null) {
      return {'error': 'Failed to authenticate with Pesapal'};
    }

    // Generate unique merchant reference
    final merchantReference =
        reference ?? 'EFA-${DateTime.now().millisecondsSinceEpoch}';

    // Determine country code based on currency
    String countryCode = 'TZ'; // Default Tanzania (primary market)
    if (currency == 'KES') {
      countryCode = 'KE'; // Kenya
    } else if (currency == 'UGX') {
      countryCode = 'UG'; // Uganda
    } else if (currency == 'RWF') {
      countryCode = 'RW'; // Rwanda
    }

    // Format phone number (ensure it starts with country code)
    String formattedPhone = userPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formattedPhone.startsWith('+')) {
      // Add country code if missing
      if (countryCode == 'TZ' && !formattedPhone.startsWith('255')) {
        formattedPhone = '255${formattedPhone.replaceFirst(RegExp(r'^0'), '')}';
      } else if (countryCode == 'KE' && !formattedPhone.startsWith('254')) {
        formattedPhone = '254${formattedPhone.replaceFirst(RegExp(r'^0'), '')}';
      } else if (countryCode == 'UG' && !formattedPhone.startsWith('256')) {
        formattedPhone = '256${formattedPhone.replaceFirst(RegExp(r'^0'), '')}';
      } else if (countryCode == 'RW' && !formattedPhone.startsWith('250')) {
        formattedPhone = '250${formattedPhone.replaceFirst(RegExp(r'^0'), '')}';
      }
    }

    // Callback URLs
    const String callbackUrl = '${ApiConfig.apiUrl}/payments/pesapal/callback';

    // Build order data - only include notification_id if we have a valid one
    final orderData = <String, dynamic>{
      'id': merchantReference,
      'currency': currency,
      'amount': amount,
      'description': description,
      'callback_url': callbackUrl,
      'billing_address': {
        'email_address': userEmail,
        'phone_number': formattedPhone,
        'country_code': countryCode,
        'first_name': userName.split(' ').first,
        'last_name': userName.split(' ').length > 1
            ? userName.split(' ').last
            : userName.split(' ').first,
        'line_1': '', // Optional
        'line_2': '', // Optional
        'city': '', // Optional
        'state': '', // Optional
        'postal_code': '', // Optional
        'zip_code': '', // Optional
      },
    };

    // Add notification_id only if we have a valid one
    if (_ipnId != null && _ipnId!.isNotEmpty) {
      orderData['notification_id'] = _ipnId;
    }

    try {
      final client = _getHttpClient();
      final response = await client.post(
        Uri.parse(_submitOrderUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'order_tracking_id': data['order_tracking_id'],
          'merchant_reference': data['merchant_reference'],
          'redirect_url': data['redirect_url'],
          'error': data['error'],
          'status': data['status'],
        };
      } else {
        return {'error': 'Payment initiation failed: ${response.body}'};
      }
    } catch (e) {
      return {'error': 'Error submitting payment: $e'};
    }
  }

  /// Check payment status
  Future<Map<String, dynamic>?> getTransactionStatus(
    String orderTrackingId,
  ) async {
    final token = await _getAccessToken();
    if (token == null) {
      return {'error': 'Failed to authenticate with Pesapal'};
    }

    try {
      final client = _getHttpClient();
      final response = await client.get(
        Uri.parse('$_transactionStatusUrl?orderTrackingId=$orderTrackingId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'payment_method': data['payment_method'],
          'amount': data['amount'],
          'created_date': data['created_date'],
          'confirmation_code': data['confirmation_code'],
          'payment_status_description': data['payment_status_description'],
          'description': data['description'],
          'message': data['message'],
          'payment_account': data['payment_account'],
          'call_back_url': data['call_back_url'],
          'status_code': data['status_code'],
          'merchant_reference': data['merchant_reference'],
          'currency': data['currency'],
          'error': data['error'],
          'status': data['status'],
        };
      }
    } catch (e) {
      return {'error': 'Error checking transaction status: $e'};
    }
    return null;
  }

  /// Register IPN (Instant Payment Notification) URL
  /// Call this once during app setup
  Future<String?> registerIPN(String ipnUrl) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final client = _getHttpClient();
      final response = await client.post(
        Uri.parse(_registerIpnUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'url': ipnUrl, 'ipn_notification_type': 'GET'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['ipn_id'];
      }
    } catch (e) {
      print('Error registering IPN: $e');
    }
    return null;
  }

  /// Clean up resources
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
  }
}
