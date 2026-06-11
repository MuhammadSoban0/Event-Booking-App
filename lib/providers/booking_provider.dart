import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/booking_model.dart';

// Repository class to handle Firestore operations for bookings
class BookingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all bookings for current user from Firestore
  Future<List<Booking>> fetchUserBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
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
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  // Fetch bookings by status for current user
  Future<List<Booking>> fetchBookingsByStatus(String status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      final querySnapshot = await _firestore
          .collection('Bookings')
          .where('uid', isEqualTo: user.uid)
          .where('bookingStatus', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings by status: $e');
    }
  }

  // Fetch bookings by payment status for current user
  Future<List<Booking>> fetchBookingsByPaymentStatus(String paymentStatus) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please log in again.');
      }

      final querySnapshot = await _firestore
          .collection('Bookings')
          .where('uid', isEqualTo: user.uid)
          .where('paymentStatus', isEqualTo: paymentStatus)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings by payment status: $e');
    }
  }

  // Fetch single booking by ID
  Future<Booking?> fetchBookingById(String bookingId) async {
    try {
      final docSnapshot = await _firestore
          .collection('Bookings')
          .doc(bookingId)
          .get();

      if (docSnapshot.exists) {
        return Booking.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  // Get real-time stream of user bookings
  Stream<List<Booking>> getUserBookingsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('Bookings')
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  // Get real-time stream of bookings by status
  Stream<List<Booking>> getBookingsByStatusStream(String status) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('Bookings')
        .where('uid', isEqualTo: user.uid)
        .where('bookingStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore
          .collection('Bookings')
          .doc(bookingId)
          .update({'bookingStatus': status});
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _firestore
          .collection('Bookings')
          .doc(bookingId)
          .update({
        'bookingStatus': 'cancelled',
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
}

// Provider for BookingRepository
final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

// FutureProvider to fetch all user bookings
final userBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.fetchUserBookings();
});

// FutureProvider to fetch confirmed bookings
final confirmedBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.fetchBookingsByStatus('confirmed');
});

// FutureProvider to fetch cancelled bookings
final cancelledBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.fetchBookingsByStatus('cancelled');
});

// FutureProvider to fetch completed payment bookings
final completedPaymentBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.fetchBookingsByPaymentStatus('completed');
});

// StreamProvider for real-time user bookings
final userBookingsStreamProvider = StreamProvider<List<Booking>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getUserBookingsStream();
});

// StreamProvider for real-time confirmed bookings
final confirmedBookingsStreamProvider = StreamProvider<List<Booking>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return repository.getBookingsByStatusStream('confirmed');
});

// Family provider to fetch single booking by ID
final bookingByIdProvider = FutureProvider.family<Booking?, String>((ref, bookingId) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.fetchBookingById(bookingId);
});

// Family provider to fetch bookings by status
final bookingsByStatusProvider = FutureProvider.family<List<Booking>, String>((ref, status) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.fetchBookingsByStatus(status);
});

// Family provider to fetch bookings by payment status
final bookingsByPaymentStatusProvider = FutureProvider.family<List<Booking>, String>((ref, paymentStatus) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.fetchBookingsByPaymentStatus(paymentStatus);
});

// StateProvider for selected booking status filter
final selectedBookingStatusProvider = StateProvider<String?>((ref) => null);

// StateProvider for search query for bookings
final bookingSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider to get filtered bookings based on search and status
final filteredBookingsProvider = Provider<AsyncValue<List<Booking>>>((ref) {
  final bookingsAsync = ref.watch(userBookingsProvider);
  final selectedStatus = ref.watch(selectedBookingStatusProvider);
  final searchQuery = ref.watch(bookingSearchQueryProvider).toLowerCase();

  return bookingsAsync.when(
    data: (bookings) {
      List<Booking> filteredBookings = bookings;

      // Filter by status
      if (selectedStatus != null && selectedStatus.isNotEmpty) {
        filteredBookings = filteredBookings
            .where((booking) => booking.bookingStatus.toLowerCase() == selectedStatus.toLowerCase())
            .toList();
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        filteredBookings = filteredBookings.where((booking) =>
            booking.eventTitle.toLowerCase().contains(searchQuery) ||
            booking.eventDescription.toLowerCase().contains(searchQuery) ||
            booking.bookingId.toLowerCase().contains(searchQuery) ||
            booking.eventId.toLowerCase().contains(searchQuery)
        ).toList();
      }

      return AsyncValue.data(filteredBookings);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Provider for booking statistics
final bookingStatsProvider = Provider<Map<String, int>>((ref) {
  final bookingsAsync = ref.watch(userBookingsProvider);
  
  return bookingsAsync.when(
    data: (bookings) {
      final stats = <String, int>{
        'total': bookings.length,
        'confirmed': bookings.where((b) => b.bookingStatus == 'confirmed').length,
        'cancelled': bookings.where((b) => b.bookingStatus == 'cancelled').length,
        'attended': bookings.where((b) => b.bookingStatus == 'attended').length,
        'completed_payments': bookings.where((b) => b.paymentStatus == 'completed').length,
        'pending_payments': bookings.where((b) => b.paymentStatus == 'pending').length,
      };
      return stats;
    },
    loading: () => <String, int>{},
    error: (_, __) => <String, int>{},
  );
});

// Provider for total amount spent by user
final totalAmountSpentProvider = Provider<double>((ref) {
  final bookingsAsync = ref.watch(userBookingsProvider);
  
  return bookingsAsync.when(
    data: (bookings) {
      return bookings
          .where((b) => b.paymentStatus == 'completed')
          .fold<double>(0.0, (sum, booking) => sum + booking.totalAmount);
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

// State notifier for managing booking operations
class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  BookingNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadBookings();
  }

  final BookingRepository _repository;

  Future<void> _loadBookings() async {
    try {
      final bookings = await _repository.fetchUserBookings();
      state = AsyncValue.data(bookings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshBookings() async {
    state = const AsyncValue.loading();
    await _loadBookings();
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await _repository.cancelBooking(bookingId);
      await _loadBookings(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _repository.updateBookingStatus(bookingId, status);
      await _loadBookings(); // Refresh the list
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

// StateNotifierProvider for BookingNotifier
final bookingNotifierProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repository);
});