import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io' show Platform;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../core/theme/app_colors.dart';

/// Pesapal Payment WebView Screen
/// Displays the Pesapal checkout page and handles payment completion
class PesapalPaymentScreen extends StatefulWidget {
  final String paymentUrl;
  final String merchantReference;
  final String orderTrackingId;

  const PesapalPaymentScreen({
    super.key,
    required this.paymentUrl,
    required this.merchantReference,
    required this.orderTrackingId,
  });

  @override
  State<PesapalPaymentScreen> createState() => _PesapalPaymentScreenState();
}

class _PesapalPaymentScreenState extends State<PesapalPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _pageTitle = 'Payment';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkForCompletion(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _controller.getTitle().then((title) {
              if (title != null) {
                setState(() => _pageTitle = title);
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            // Log SSL errors but don't show to user as Pesapal certificates may cause warnings
            if (error.errorType == WebResourceErrorType.unknown ||
                error.errorType == WebResourceErrorType.connect) {
              print('WebView error (likely SSL): ${error.description}');
              // Don't show snackbar for SSL errors, proceed with loading
              return;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error loading payment page: ${error.description}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
    
    // Configure Android-specific WebView settings for SSL handling
    if (Platform.isAndroid) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setOnShowFileSelector((params) async {
        return [];
      });
    }
  }

  void _checkForCompletion(String url) {
    // Check if the URL indicates payment completion
    if (url.contains('/callback') || url.contains('payment/complete')) {
      // Payment completed - return to previous screen with success
      Navigator.pop(context, {
        'status': 'completed',
        'merchant_reference': widget.merchantReference,
        'order_tracking_id': widget.orderTrackingId,
      });
    } else if (url.contains('cancel') || url.contains('failed')) {
      // Payment cancelled or failed
      Navigator.pop(context, {
        'status': 'failed',
        'merchant_reference': widget.merchantReference,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryPurpleDeep,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelDialog();
          },
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryPurpleDeep,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading payment page...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Payment?'),
          content: const Text('Are you sure you want to cancel this payment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, {
                  'status': 'cancelled',
                  'merchant_reference': widget.merchantReference,
                }); // Close payment screen
              },
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
