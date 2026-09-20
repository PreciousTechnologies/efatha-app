import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/supabase_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/api_config.dart';
import '../../core/services/storage_service.dart';
import '../../core/services/pesapal_service.dart';
import '../../core/services/supabase_auth_service.dart';
import '../../core/services/supabase_database_service.dart';
import 'pesapal_payment_screen.dart';

/// Multi-step donation flow screen
class DonationFlowScreen extends StatefulWidget {
  final String category;

  const DonationFlowScreen({super.key, required this.category});

  @override
  State<DonationFlowScreen> createState() => _DonationFlowScreenState();
}

class _DonationFlowScreenState extends State<DonationFlowScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();

  // Form data
  String _selectedAmount = '';
  String _selectedCurrency = 'TZS'; // Default to Tanzanian Shillings
  String _paymentMethod = 'Mobile Money';
  bool _isAnonymous = false;
  bool _isRecurring = false;
  String _recurringFrequency = 'Monthly';

  final List<String> _quickAmounts = ['10', '25', '50', '100', '500', '1000'];
  final List<Map<String, String>> _currencies = [
    {
      'code': 'TZS',
      'symbol': 'TSh',
      'name': 'Tanzanian Shilling',
    }, // Default for Tanzania - M-Pesa/Airtel/Tigo
    {'code': 'KES', 'symbol': 'KSh', 'name': 'Kenyan Shilling'}, // M-Pesa Kenya
    {
      'code': 'UGX',
      'symbol': 'USh',
      'name': 'Ugandan Shilling',
    }, // MTN/Airtel Uganda
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  ];
  final List<String> _paymentMethods = [
    'Mobile Money',
    'Credit Card',
    'Bank Transfer',
    'Cash',
  ];
  final List<String> _frequencies = [
    'Weekly',
    'Monthly',
    'Quarterly',
    'Yearly',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else {
      _submitDonation();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_amountController.text.isEmpty && _selectedAmount.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter or select an amount'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      case 1:
        if (!_isAnonymous) {
          if (_nameController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter your name'),
                backgroundColor: Colors.red,
              ),
            );
            return false;
          }
        }
        return true;
      case 2:
        if (_emailController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter your email'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _submitDonation() async {
    // Get user details from form
    final userName = _nameController.text.isEmpty
        ? 'Church Member'
        : _nameController.text;
    final userEmail = _emailController.text.isEmpty
        ? 'donor@efatha.church'
        : _emailController.text;

    // Get donation amount
    final amount = double.tryParse(
      _amountController.text.isEmpty ? _selectedAmount : _amountController.text,
    );

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid donation amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      // Initialize Pesapal service
      final pesapalService = PesapalService();
      await pesapalService.initialize();

      // Submit order to Pesapal
      final orderResult = await pesapalService.submitOrder(
        amount: amount,
        currency: _selectedCurrency,
        description:
            'Efatha Church - ${widget.category}${_noteController.text.isNotEmpty ? ": ${_noteController.text}" : ""}',
        userEmail: userEmail,
        userPhone: _phoneController.text,
        userName: _isAnonymous ? 'Anonymous Donor' : userName,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (orderResult == null || orderResult['error'] != null) {
        _showErrorDialog(
          orderResult?['error']?.toString() ?? 'Failed to initiate payment',
        );
        return;
      }

      // Extract order details with proper type conversion
      final redirectUrl = orderResult['redirect_url']?.toString();
      final merchantRef = orderResult['merchant_reference']?.toString();
      final orderTrackingId = orderResult['order_tracking_id']?.toString();

      if (redirectUrl == null ||
          merchantRef == null ||
          orderTrackingId == null) {
        _showErrorDialog('Invalid payment response from Pesapal');
        return;
      }

      // Navigate to payment webview
      final paymentResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PesapalPaymentScreen(
            paymentUrl: redirectUrl,
            merchantReference: merchantRef,
            orderTrackingId: orderTrackingId,
          ),
        ),
      );

      if (!mounted) return;

      // Handle payment result
      if (paymentResult != null && paymentResult['status'] == 'completed') {
        // Verify payment status with Pesapal
        final orderTrackingId =
            paymentResult['order_tracking_id']?.toString() ?? '';
        final merchantRef =
            paymentResult['merchant_reference']?.toString() ?? '';

        if (orderTrackingId.isNotEmpty) {
          final statusResult = await pesapalService.getTransactionStatus(
            orderTrackingId,
          );

          if (statusResult != null && statusResult['status_code'] == 1) {
            // Payment successful - save to backend
            await _saveDonationToBackend(
              amount: amount,
              currency: _selectedCurrency,
              paymentMethod:
                  statusResult['payment_method']?.toString() ?? _paymentMethod,
              transactionId:
                  statusResult['confirmation_code']?.toString() ?? '',
              merchantReference: merchantRef,
            );

            _showSuccessDialog();
          } else {
            _showErrorDialog(
              'Payment verification failed. Please contact support.',
            );
          }
        } else {
          _showErrorDialog('Invalid payment tracking information');
        }
      } else if (paymentResult != null &&
          paymentResult['status'] == 'cancelled') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        _showErrorDialog('Payment failed or was not completed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading if still open
      _showErrorDialog('Error: ${e.toString()}');
    }
  }

  Future<void> _saveDonationToBackend({
    required double amount,
    required String currency,
    required String paymentMethod,
    required String transactionId,
    required String merchantReference,
  }) async {
    // Supabase-first (Django fallback while migrating).
    if (SupabaseConfig.isConfigured) {
      await _saveDonationToSupabase(
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        merchantReference: merchantReference,
      );
      return;
    }

    try {
      final storageService = StorageService();
      final token = await storageService.getAccessToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/church/giving/verify_payment/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'merchant_reference': merchantReference,
          'transaction_id': transactionId,
          'confirmation_code': transactionId,
          'payment_method': paymentMethod,
          'payment_status': 'completed',
          'amount': amount,
          'currency': currency,
          'gateway': 'pesapal',
        }),
      );

      if (response.statusCode == 200) {
        print('Donation saved successfully');
      } else {
        print('Failed to save donation: ${response.body}');
      }
    } catch (e) {
      print('Error saving donation: $e');
    }
  }

  /// Save completed Pesapal payment as Supabase giving + transaction rows.
  Future<void> _saveDonationToSupabase({
    required double amount,
    required String currency,
    required String paymentMethod,
    required String transactionId,
    required String merchantReference,
  }) async {
    try {
      final db = SupabaseDatabaseService();
      final user = SupabaseAuthService().currentUser;

      final giving = await db.createGiving({
        if (user != null) 'user_id': user.id,
        'donor_name': _isAnonymous
            ? 'Anonymous'
            : (_nameController.text.trim().isEmpty
                  ? 'Church Member'
                  : _nameController.text.trim()),
        'donor_email': _emailController.text.trim(),
        'donor_phone': _phoneController.text.trim(),
        'amount': amount,
        'currency': currency,
        'giving_type': SupabaseDatabaseService.givingTypeForUiCategory(
          widget.category,
        ),
        'payment_method': _toDbPaymentMethod(paymentMethod),
        'transaction_ref': transactionId,
        'merchant_reference': merchantReference,
        'confirmation_code': transactionId,
        'payment_status': 'completed',
        'notes': _noteController.text.trim(),
        'is_anonymous': _isAnonymous,
        'is_recurring': _isRecurring,
        'recurring_frequency': _isRecurring
            ? _recurringFrequency.toLowerCase()
            : '',
        'completed_at': DateTime.now().toIso8601String(),
      });

      await db.createPaymentTransaction({
        'giving_id': giving['id'],
        'transaction_id':
            '${merchantReference}_${DateTime.now().millisecondsSinceEpoch}',
        'merchant_reference': merchantReference,
        'gateway': 'pesapal',
        'status': 'completed',
        'amount': amount,
        'currency': currency,
        'payment_method': _toDbPaymentMethod(paymentMethod),
        'confirmation_code': transactionId,
        'payment_status_description': 'Completed via Pesapal',
        'completed_at': DateTime.now().toIso8601String(),
      });

      print('Donation saved successfully (Supabase)');
    } catch (e) {
      print('Error saving donation: $e');
    }
  }

  String _toDbPaymentMethod(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('mobile') || lower.contains('m-pesa') ||
        lower.contains('mpesa')) {
      return 'mpesa';
    }
    if (lower.contains('credit')) return 'credit_card';
    if (lower.contains('debit')) return 'debit_card';
    if (lower.contains('bank')) return 'bank_transfer';
    if (lower.contains('cash')) return 'cash';
    return 'mpesa';
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Donation Successful!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for your generous contribution to ${widget.category}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to donations screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurpleDeep,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () =>
              _currentStep > 0 ? _previousStep() : Navigator.pop(context),
        ),
        title: Text(
          widget.category,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),

          // Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(key: _formKey, child: _buildStepContent()),
            ),
          ),

          // Next Button (Fixed at bottom)
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primaryPurpleDeep,
                                    AppColors.primaryPurpleVibrant,
                                  ],
                                )
                              : null,
                          color: isActive ? null : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getStepTitle(index),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isActive
                              ? AppColors.primaryPurpleDeep
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [
                                  AppColors.primaryPurpleDeep,
                                  AppColors.primaryPurpleVibrant,
                                ],
                              )
                            : null,
                        color: isCompleted ? null : Colors.grey[300],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'Amount';
      case 1:
        return 'Details';
      case 2:
        return 'Contact';
      case 3:
        return 'Review';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildAmountStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildContactStep();
      case 3:
        return _buildReviewStep();
      default:
        return Container();
    }
  }

  Widget _buildAmountStep() {
    final currentCurrency = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How much would you like to give?',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a quick amount or enter your own',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),

        // Currency Selection
        const Text(
          'Currency',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrency,
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down,
                color: AppColors.primaryPurpleDeep,
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCurrency = newValue;
                  });
                }
              },
              items: _currencies.map<DropdownMenuItem<String>>((
                Map<String, String> currency,
              ) {
                return DropdownMenuItem<String>(
                  value: currency['code'],
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryPurpleDeep,
                              AppColors.primaryPurpleVibrant,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            currency['symbol']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currency['code']!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            currency['name']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Quick Amount Buttons
        const Text(
          'Quick Amounts',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _quickAmounts.map((amount) {
            final isSelected = _selectedAmount == amount;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedAmount = amount;
                  _amountController.text = amount;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryPurpleDeep,
                            AppColors.primaryPurpleVibrant,
                          ],
                        )
                      : null,
                  color: isSelected ? null : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  '${currentCurrency['symbol']}$amount',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        // Custom Amount
        const Text(
          'Or Enter Custom Amount',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, top: 14),
              child: Text(
                currentCurrency['symbol']!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            hintText: '0',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryPurpleDeep,
                width: 2,
              ),
            ),
          ),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          onChanged: (value) {
            setState(() {
              _selectedAmount = value;
            });
          },
        ),

        const SizedBox(height: 32),

        // Recurring Option
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    color: _isRecurring
                        ? AppColors.primaryPurpleDeep
                        : Colors.grey[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Make this recurring',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Automate your giving',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value;
                      });
                    },
                    activeThumbColor: AppColors.primaryPurpleDeep,
                  ),
                ],
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: _frequencies.map((freq) {
                    final isSelected = _recurringFrequency == freq;
                    return ChoiceChip(
                      label: Text(freq),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _recurringFrequency = freq;
                        });
                      },
                      selectedColor: AppColors.primaryPurpleLight.withValues(
                        alpha: 0.3,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primaryPurpleDeep
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll use this information for your donation receipt',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),

        // Anonymous Option
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: _isAnonymous
                    ? AppColors.primaryPurpleDeep
                    : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Give Anonymously',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your name won\'t be shown',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
                activeThumbColor: AppColors.primaryPurpleDeep,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (!_isAnonymous) ...[
          const Text(
            'Full Name',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryPurpleDeep,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        const Text(
          'Add a Note (Optional)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 4,
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Share why you\'re giving or a prayer request...',
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryPurpleDeep,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send your receipt and confirmation here',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),

        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'your.email@example.com',
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryPurpleDeep,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Phone Number (Required for Mobile Money)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: _selectedCurrency == 'TZS'
                ? '0712345678 or +255712345678'
                : _selectedCurrency == 'KES'
                ? '0712345678 or +254712345678'
                : _selectedCurrency == 'UGX'
                ? '0712345678 or +256712345678'
                : '+1 (555) 123-4567',
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: const Icon(Icons.phone_outlined),
            helperText: _selectedCurrency == 'TZS'
                ? 'Required for M-Pesa/Airtel Money/Tigo Pesa'
                : _selectedCurrency == 'KES'
                ? 'Required for M-Pesa Kenya'
                : _selectedCurrency == 'UGX'
                ? 'Required for MTN/Airtel Money'
                : null,
            helperStyle: TextStyle(color: AppColors.primaryPurpleDeep),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryPurpleDeep,
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_paymentMethods.length, (index) {
          final method = _paymentMethods[index];
          final isSelected = _paymentMethod == method;
          final icons = [
            Icons.phone_android,
            Icons.credit_card,
            Icons.account_balance,
            Icons.payments,
          ];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _paymentMethod = method;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPurpleLight.withValues(alpha: 0.1)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPurpleDeep
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryPurpleDeep
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icons[index],
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        method,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primaryPurpleDeep
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primaryPurpleDeep,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewStep() {
    final amount = _amountController.text.isNotEmpty
        ? _amountController.text
        : _selectedAmount;
    final currentCurrency = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Donation',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please review the details before submitting',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 32),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryPurpleDeep,
                AppColors.primaryPurpleVibrant,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurpleLight.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.category,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  if (_isRecurring)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.repeat,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _recurringFrequency,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentCurrency['symbol']!,
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 56,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currentCurrency['name']!,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Details List
        _buildDetailRow(
          'Donor Name',
          _isAnonymous
              ? 'Anonymous'
              : _nameController.text.isNotEmpty
              ? _nameController.text
              : 'Not provided',
          Icons.person_outline,
        ),
        _buildDetailRow(
          'Email',
          _emailController.text.isNotEmpty
              ? _emailController.text
              : 'Not provided',
          Icons.email_outlined,
        ),
        _buildDetailRow(
          'Phone',
          _phoneController.text.isNotEmpty
              ? _phoneController.text
              : 'Not provided',
          Icons.phone_outlined,
        ),
        _buildDetailRow('Payment Method', _paymentMethod, Icons.payment),
        if (_noteController.text.isNotEmpty)
          _buildDetailRow('Note', _noteController.text, Icons.note_outlined),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurpleDeep,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.primaryPurpleLight.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentStep < 3 ? 'Next' : 'Submit Donation',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _currentStep < 3 ? Icons.arrow_forward : Icons.check,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
