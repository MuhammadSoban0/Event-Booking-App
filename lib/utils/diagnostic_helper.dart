import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DiagnosticHelper {
  static Future<Map<String, bool>> runDiagnostics() async {
    Map<String, bool> results = {};
    
    try {
      // Test Firebase Auth
      log('Testing Firebase Auth...');
      final user = FirebaseAuth.instance.currentUser;
      results['firebase_auth'] = user != null;
      if (user != null) {
        log('✓ Firebase Auth: User logged in (${user.uid})');
      } else {
        log('✗ Firebase Auth: No user logged in');
      }
      
      // Test Firestore connection
      log('Testing Firestore connection...');
      try {
        await FirebaseFirestore.instance
            .collection('_diagnostic')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));
        results['firestore'] = true;
        log('✓ Firestore: Connection successful');
      } catch (e) {
        results['firestore'] = false;
        log('✗ Firestore: Connection failed - $e');
      }
      
      // Test Stripe keys
      log('Testing Stripe configuration...');
      final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
      final secretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
      results['stripe_keys'] = publishableKey.isNotEmpty && secretKey.isNotEmpty;
      if (results['stripe_keys']!) {
        log('✓ Stripe: API keys configured');
        log('  Publishable key: ${publishableKey.substring(0, 12)}...');
      } else {
        log('✗ Stripe: API keys missing or empty');
        log('  Publishable key empty: ${publishableKey.isEmpty}');
        log('  Secret key empty: ${secretKey.isEmpty}');
      }
      
      // Test event data structure (if we can access an event)
      if (results['firestore'] == true) {
        log('Testing events collection...');
        try {
          final eventsSnapshot = await FirebaseFirestore.instance
              .collection('events')
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 5));
          results['events_collection'] = eventsSnapshot.docs.isNotEmpty;
          if (eventsSnapshot.docs.isNotEmpty) {
            log('✓ Events: Collection accessible with ${eventsSnapshot.docs.length} documents');
            final eventData = eventsSnapshot.docs.first.data();
            log('  Sample event fields: ${eventData.keys.toList()}');
          } else {
            log('✗ Events: Collection empty or inaccessible');
          }
        } catch (e) {
          results['events_collection'] = false;
          log('✗ Events: Collection access failed - $e');
        }
      }
      
      // Test bookings collection permissions
      if (results['firebase_auth'] == true) {
        log('Testing bookings collection permissions...');
        try {
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('userId', isEqualTo: user!.uid)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 5));
          results['bookings_permissions'] = true;
          log('✓ Bookings: Write permissions available');
        } catch (e) {
          results['bookings_permissions'] = false;
          log('✗ Bookings: Permission denied or error - $e');
        }
      }
      
    } catch (e, stackTrace) {
      log('Error running diagnostics: $e');
      log('Stack trace: $stackTrace');
    }
    
    // Summary
    log('=== DIAGNOSTIC SUMMARY ===');
    results.forEach((key, value) {
      log('$key: ${value ? "✓ PASS" : "✗ FAIL"}');
    });
    
    return results;
  }
  
  static void logEventDetails(dynamic event) {
    log('=== EVENT DETAILS ===');
    if (event != null) {
      log('Event ID: ${event.eventId ?? 'null'}');
      log('Document ID: ${event.id ?? 'null'}');
      log('Title: ${event.title ?? 'null'}');
      log('Available Seats: ${event.availableSeats ?? 'null'}');
      log('Total Expense: ${event.totalExpence ?? 'null'}');
      log('Currency: ${event.currency ?? 'null'}');
    } else {
      log('Event is null');
    }
  }
}