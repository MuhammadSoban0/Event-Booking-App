import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/booking_model.dart';
import '../model/evnt_model.dart';

class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a booking
  static Future<String?> createBooking({
    required Event event,
    required int ticketQuantity,
  }) async {
    try {
      log('Starting booking creation process...');
      
      final user = _auth.currentUser;
      if (user == null) {
        log('ERROR: User not authenticated');
        throw Exception('User not authenticated. Please log in again.');
      }
      
      log('User authenticated: ${user.uid}');
      log('Event ID: ${event.eventId}');
      log('Event title: ${event.title}');
      log('Ticket quantity: $ticketQuantity');

      // Generate unique booking ID
      final bookingId = Booking.generateBookingId();
      log('Generated booking ID: $bookingId');

      // Create booking object
      final booking = Booking(
        bookingId: bookingId,
        eventId: event.eventId,
        eventTitle: event.title,
        eventDescription: event.description,
        eventImage: event.imageUrl,
        eventDate: event.date, // Use the date field directly as it's already a string
        uid: user.uid,
        userEmail: user.email ?? '',
        totalAmount: event.totalExpence * ticketQuantity,
        ticketPrice: event.totalExpence,
        currency: event.currency,
        ticketQuantity: ticketQuantity,
        paymentStatus: 'pending',
        bookingStatus: 'confirmed',
        createdAt: DateTime.now(),
      );

      log('Booking object created, saving to Firestore...');

      // Save booking to Firestore
      final docRef = await _firestore
          .collection('Bookings')
          .add(booking.toFirestore());

      log('Booking created successfully with document ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      log('ERROR creating booking: $e');
      log('Stack trace: $stackTrace');
      return null;
    }
  }

  // Update booking payment status
  static Future<bool> updateBookingPaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) async {
    try {
      await _firestore.collection('Bookings').doc(bookingId).update({
        'paymentStatus': paymentStatus,
      });

      log('Booking payment status updated: $bookingId -> $paymentStatus');
      return true;
    } catch (e) {
      log('Error updating booking payment status: $e');
      return false;
    }
  }

  // Update event available seats after successful booking
  static Future<bool> updateEventSeats({
    required String eventId,
    required int ticketQuantity,
  }) async {
    try {
      // Use transaction to ensure data consistency
      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(
          _firestore.collection('events').doc(eventId)
        );

        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final currentSeats = eventDoc.data()?['availableSeats'] ?? 0;
        final newAvailableSeats = currentSeats - ticketQuantity;

        if (newAvailableSeats < 0) {
          throw Exception('Not enough seats available');
        }

        transaction.update(eventDoc.reference, {
          'availableSeats': newAvailableSeats,
        });
      });

      log('Event seats updated successfully: $eventId');
      return true;
    } catch (e) {
      log('Error updating event seats: $e');
      return false;
    }
  }

  // Get user bookings
  static Future<List<Booking>> getUserBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('Bookings')
          .where('uid', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      log('Error fetching user bookings: $e');
      return [];
    }
  }

  // Get specific booking
  static Future<Booking?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore
          .collection('Bookings')
          .doc(bookingId)
          .get();

      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      log('Error fetching booking: $e');
      return null;
    }
  }

  // Cancel booking
  static Future<bool> cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('Bookings').doc(bookingId).update({
        'bookingStatus': 'cancelled',
      });

      log('Booking cancelled: $bookingId');
      return true;
    } catch (e) {
      log('Error cancelling booking: $e');
      return false;
    }
  }

  // Complete booking process (after successful payment)
  static Future<bool> completeBooking({
    required String bookingId,
    required String eventId,
    required int ticketQuantity,
  }) async {
    try {
      log('Starting booking completion process...');
      log('Booking ID: $bookingId');
      log('Event ID: $eventId');
      log('Ticket quantity: $ticketQuantity');

      // Update booking payment status
      log('Updating booking payment status...');
      final paymentUpdated = await updateBookingPaymentStatus(
        bookingId: bookingId,
        paymentStatus: 'completed',
      );

      if (!paymentUpdated) {
        log('ERROR: Failed to update booking payment status');
        throw Exception('Failed to update booking payment status');
      }
      log('Booking payment status updated successfully');

      // Update event seats
      log('Updating event seats...');
      final seatsUpdated = await updateEventSeats(
        eventId: eventId,
        ticketQuantity: ticketQuantity,
      );

      if (!seatsUpdated) {
        log('ERROR: Failed to update event seats, rolling back payment status');
        // Rollback payment status update
        await updateBookingPaymentStatus(
          bookingId: bookingId,
          paymentStatus: 'failed',
        );
        throw Exception('Failed to update event seats');
      }
      log('Event seats updated successfully');

      log('Booking completed successfully: $bookingId');
      return true;
    } catch (e, stackTrace) {
      log('ERROR completing booking: $e');
      log('Stack trace: $stackTrace');
      return false;
    }
  }
}