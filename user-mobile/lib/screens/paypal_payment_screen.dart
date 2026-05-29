import 'package:flutter/foundation.dart';
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
  WebViewController? _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  static const _successUrl = 'https://transitflow.app/payment/success';
  static const _cancelUrl = 'https://transitflow.app/payment/cancel';

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
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
            _handleUrlChange(url);
          },
          onPageFinished: (String url) {
            if (_paymentCompleted) return;
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _handleUrlChange(url);
          },
          onWebResourceError: (WebResourceError error) {
            if (_paymentCompleted) return;
            if (kDebugMode) {
              debugPrint('WebView error: ${error.description}');
            }
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

    if (!mounted) return;
    setState(() {
      _controller = controller;
      _isLoading = false;
    });
  }

  void _handleUrlChange(String url) {
    if (_paymentCompleted) return;

    if (url.startsWith(_successUrl)) {
      _paymentCompleted = true;
      widget.onPaymentComplete(widget.orderId);
      if (mounted) {
        Navigator.of(context).pop(widget.orderId);
      }
      return;
    }

    if (url.startsWith(_cancelUrl)) {
      _paymentCompleted = true;
      widget.onPaymentCancel();
      if (mounted) {
        Navigator.of(context).pop(null);
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
      body: _controller == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                WebViewWidget(controller: _controller!),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}
