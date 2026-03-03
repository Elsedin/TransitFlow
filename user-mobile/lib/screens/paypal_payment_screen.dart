import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PayPalPaymentScreen extends StatefulWidget {
  final String approvalUrl;
  final String orderId;
  final Function(String orderId) onPaymentComplete;
  final Function() onPaymentCancel;

  const PayPalPaymentScreen({
    super.key,
    required this.approvalUrl,
    required this.orderId,
    required this.onPaymentComplete,
    required this.onPaymentCancel,
  });

  @override
  State<PayPalPaymentScreen> createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    final cookieManager = WebViewCookieManager();
    await cookieManager.clearCookies();
    
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (_paymentCompleted) return;
            
            setState(() {
              _isLoading = true;
            });
            _handleUrlChange(url);
          },
          onPageFinished: (String url) async {
            if (_paymentCompleted) return;
            
            setState(() {
              _isLoading = false;
            });
            _handleUrlChange(url);
            
            if (!_paymentCompleted) {
              try {
                final currentUrl = await _controller.currentUrl();
                if (currentUrl != null && !_paymentCompleted) {
                  _handleUrlChange(currentUrl);
                }
              } catch (e) {
                print('Error getting current URL: $e');
              }
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (_paymentCompleted) return;
            print('WebView error: ${error.description}');
          },
          onUrlChange: (UrlChange change) {
            if (_paymentCompleted) return;
            
            if (change.url != null) {
              _handleUrlChange(change.url!);
            }
          },
        ),
      );

    await controller.loadRequest(Uri.parse(widget.approvalUrl));
    
    setState(() {
      _controller = controller;
    });
  }

  void _handleUrlChange(String url) {
    if (_paymentCompleted) return;
    
    print('PayPal URL changed: $url');
    
    if (url.contains('transitflow.app/payment/success') || 
        (url.contains('token=') && (url.contains('PayerID=') || url.contains('payer_id=')))) {
      print('PayPal payment approved - closing WebView');
      _paymentCompleted = true;
      if (mounted) {
        Navigator.of(context).pop(widget.orderId);
      }
    } else if (url.contains('transitflow.app/payment/cancel') || 
               (url.contains('cancel') && url.contains('transitflow.app'))) {
      print('PayPal payment cancelled');
      _paymentCompleted = true;
      widget.onPaymentCancel();
      if (mounted) {
        Navigator.of(context).pop(null);
      }
    } else if ((url.contains('/checkoutnow/2') || 
               url.contains('payment/confirm') || 
               url.contains('checkout/confirm')) && url.contains('token=')) {
      print('PayPal payment confirmed - closing WebView');
      _paymentCompleted = true;
      if (mounted) {
        Navigator.of(context).pop(widget.orderId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Plaćanje'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
