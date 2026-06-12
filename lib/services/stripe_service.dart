import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  static String get _publishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get _secretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';
  static const String _baseUrl = 'https://api.stripe.com/v1';

  // Initialize Stripe
  static Future<void> init() async {
    if (_publishableKey.isEmpty) {
      throw Exception('Stripe publishable key not found in .env file');
    }
    
    Stripe.publishableKey = _publishableKey;
    await Stripe.instance.applySettings();
  }

  // Create payment intent
  static Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Convert amount to cents (Stripe uses smallest currency unit)
      final amountInCents = (amount * 100).round();
      
      Map<String, dynamic> body = {
        'amount': amountInCents.toString(),
        'currency': currency.toLowerCase(),
        'description': description,
        'payment_method_types[]': 'card',
      };

      // Add metadata if provided
      if (metadata != null) {
        metadata.forEach((key, value) {
          body['metadata[$key]'] = value.toString();
        });
      }

      var response = await http.post(
        Uri.parse('$_baseUrl/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log('Error creating payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      log('Exception creating payment intent: $e');
      return null;
    }
  }

  // Process payment
  static Future<bool> processPayment({
    required BuildContext context,
    required double amount,
    required String currency,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      log('Starting payment process...');
      log('Amount: $amount $currency');
      log('Description: $description');
      
      // Validate Stripe keys
      if (_publishableKey.isEmpty || _secretKey.isEmpty) {
        throw Exception('Stripe API keys not configured properly');
      }
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing Payment...'),
                ],
              ),
            ),
          ),
        ),
      );

      log('Creating payment intent...');
      // Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        description: description,
        metadata: metadata,
      );

      if (paymentIntent == null) {
        Navigator.of(context).pop(); // Close loading dialog
        throw Exception('Failed to create payment intent - check your Stripe configuration');
      }
      
      log('Payment intent created successfully: ${paymentIntent['id']}');

      log('Initializing payment sheet...');
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'Event Booking App',
          style: ThemeMode.system,
          billingDetails: const BillingDetails(
            name: 'Event Ticket Purchase',
          ),
        ),
      );

      Navigator.of(context).pop(); // Close loading dialog
      log('Payment sheet initialized, presenting to user...');

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      log('Payment completed successfully');
      return true;
    } catch (e, stackTrace) {
      // Ensure loading dialog is closed
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      log('Payment error: $e');
      log('Stack trace: $stackTrace');
      
      // Show error message
      if (context.mounted) {
        String errorMessage = 'Payment failed';
        
        // Provide more specific error messages
        if (e.toString().contains('canceled')) {
          errorMessage = 'Payment was canceled';
        } else if (e.toString().contains('api_key')) {
          errorMessage = 'Payment configuration error';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error, please check your internet connection';
        } else {
          errorMessage = 'Payment failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      return false;
    }
  }

  // Validate card details
  static bool validateCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) {
    // Basic validation
    if (cardNumber.replaceAll(' ', '').length < 13) return false;
    if (expiryDate.length != 5 || !expiryDate.contains('/')) return false;
    if (cvv.length < 3) return false;
    
    // Validate expiry date
    try {
      final parts = expiryDate.split('/');
      final month = int.parse(parts[0]);
      final year = int.parse('20${parts[1]}');
      
      if (month < 1 || month > 12) return false;
      
      final now = DateTime.now();
      final expiry = DateTime(year, month);
      
      if (expiry.isBefore(DateTime(now.year, now.month))) {
        return false;
      }
    } catch (e) {
      return false;
    }
    
    return true;
  }

  // Format card number for display
  static String formatCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');
    String formatted = '';
    
    for (int i = 0; i < cardNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += cardNumber[i];
    }
    
    return formatted;
  }

  // Get card type from number
  static String getCardType(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');
    
    if (cardNumber.startsWith('4')) {
      return 'Visa';
    } else if (cardNumber.startsWith('5') || 
               cardNumber.startsWith('2')) {
      return 'Mastercard';
    } else if (cardNumber.startsWith('3')) {
      return 'American Express';
    } else {
      return 'Unknown';
    }
  }
}