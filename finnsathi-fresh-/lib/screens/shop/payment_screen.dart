import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../models/shop_models.dart';
import '../../services/shop_api_service.dart';
import '../../services/auth_state_service.dart';
import 'order_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int total;
  final List<CartItem> cart;
  final String shopId;
  final String deliveryAddress;
  final String? deliveryPhone;

  const PaymentScreen({
    super.key,
    required this.total,
    required this.cart,
    required this.shopId,
    required this.deliveryAddress,
    this.deliveryPhone,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  String _paymentMethod = 'upi';
  bool _isPlacingOrder = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  PaymentMethod _mapPaymentMethod() {
    switch (_paymentMethod) {
      case 'card':
        return PaymentMethod.card;
      case 'wallet':
        return PaymentMethod.wallet;
      case 'cashOnDelivery':
        return PaymentMethod.cashOnDelivery;
      case 'upi':
      default:
        return PaymentMethod.upi;
    }
  }

  Future<void> _startOnlinePayment() async {
    const razorpayKey = 'rzp_live_RTWtDf8dwDjtms';

    final options = {
      'key': razorpayKey,
      'amount': widget.total * 100, // Razorpay works with paise
      'name': 'FinSathi',
      'description': 'Order payment',
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _error = 'Failed to start payment: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_error!)));
      }
    }
  }

  Future<void> _placeOrder({String? razorpayPaymentId}) async {
    if (_isPlacingOrder) return;

    setState(() {
      _isPlacingOrder = true;
      _error = null;
    });

    try {
      final token = await AuthStateService.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('You must be logged in to place an order');
      }

      final profile = await AuthStateService.getUserProfile();
      Map<String, dynamic>? customer;
      if (profile != null) {
        final overridePhone = widget.deliveryPhone;
        customer = {
          'id': profile['id']?.toString(),
          'name': profile['name']?.toString(),
          'email': profile['email']?.toString(),
          'phone':
              (overridePhone != null && overridePhone.isNotEmpty)
                  ? overridePhone
                  : profile['phone']?.toString(),
          'avatarUrl': profile['avatarUrl']?.toString(),
        };
      }

      final items =
          widget.cart.map((cartItem) {
            return {
              'menuItemId': cartItem.item.id,
              'name': cartItem.item.name,
              'price': cartItem.item.price,
              'quantity': cartItem.quantity,
              'customizations': cartItem.selectedCustomizations,
              'specialInstructions': cartItem.specialInstructions,
              'totalPrice': cartItem.totalPrice,
            };
          }).toList();

      final result = await ShopApiService.createOrder(
        shopId: widget.shopId,
        items: items,
        deliveryAddress: widget.deliveryAddress,
        paymentMethod: _paymentMethod,
        authToken: token,
        notes:
            razorpayPaymentId != null
                ? 'Order from FinSathi app (Razorpay paymentId: $razorpayPaymentId)'
                : 'Order from FinSathi app',
        customer: customer,
      );

      final orderId = (result['orderId'] ?? result['_id'] ?? '').toString();

      final order = Order(
        id: orderId,
        items: widget.cart,
        totalAmount: widget.total,
        deliveryAddress: widget.deliveryAddress,
        orderTime: DateTime.now(),
        paymentMethod: _mapPaymentMethod(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to place order: $e';
      });
      if (mounted && _error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_error!)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _placeOrder(razorpayPaymentId: response.paymentId);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _error = 'Payment failed: ${response.message}';
    });
    if (mounted && _error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error!)));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(
              Icons.credit_card,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Cards',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Debit / Credit card',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: Radio<String>(
              value: 'card',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value ?? 'card');
              },
            ),
            onTap: () => setState(() => _paymentMethod = 'card'),
          ),
          ListTile(
            leading: Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'UPI',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Pay with UPI',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: Radio<String>(
              value: 'upi',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value ?? 'upi');
              },
            ),
            onTap: () => setState(() => _paymentMethod = 'upi'),
          ),
          ListTile(
            leading: Icon(
              Icons.wallet,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Wallets',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Paytm wallet, PhonePe wallet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: Radio<String>(
              value: 'wallet',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value ?? 'wallet');
              },
            ),
            onTap: () => setState(() => _paymentMethod = 'wallet'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.delivery_dining,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Pay on delivery',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Cash on delivery',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: Radio<String>(
              value: 'cashOnDelivery',
              groupValue: _paymentMethod,
              onChanged: (value) {
                setState(() => _paymentMethod = value ?? 'cashOnDelivery');
              },
            ),
            onTap: () => setState(() => _paymentMethod = 'cashOnDelivery'),
          ),
          const SizedBox(height: 24),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed:
                _isPlacingOrder
                    ? null
                    : () async {
                      if (_paymentMethod == 'cashOnDelivery') {
                        await _placeOrder();
                      } else {
                        await _startOnlinePayment();
                      }
                    },
            child:
                _isPlacingOrder
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Place Order'),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '₹${widget.total}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
}
