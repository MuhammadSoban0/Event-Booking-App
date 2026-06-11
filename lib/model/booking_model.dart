import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String? id; // Firestore document ID
  final String bookingId;
  final String eventId;
  final String eventTitle;
  final String eventDescription;
  final String eventImage;
  final String eventDate;
  final String uid;
  final String userEmail;
  final double totalAmount;
  final double ticketPrice;
  final String currency;
  final int ticketQuantity;
  final String paymentStatus; // pending, completed, failed, refunded
  final String bookingStatus; // confirmed, cancelled, attended
  final DateTime createdAt;

  Booking({
    this.id,
    required this.bookingId,
    required this.eventId,
    required this.eventTitle,
    required this.eventDescription,
    required this.eventImage,
    required this.eventDate,
    required this.uid,
    required this.userEmail,
    required this.totalAmount,
    required this.ticketPrice,
    required this.currency,
    required this.ticketQuantity,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.createdAt,
  });

  // Factory constructor from Firestore
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Booking(
      id: doc.id,
      bookingId: data['bookingId'] ?? '',
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      eventDescription: data['eventDescription'] ?? '',
      eventImage: data['eventImage'] ?? '',
      eventDate: data['eventDate'] ?? '',
      uid: data['uid'] ?? '',
      userEmail: data['userEmail'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      ticketPrice: (data['ticketPrice'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'PKR',
      ticketQuantity: data['ticketQuantity'] ?? 1,
      paymentStatus: data['paymentStatus'] ?? 'pending',
      bookingStatus: data['bookingStatus'] ?? 'confirmed',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore format
  Map<String, dynamic> toFirestore() {
    return {
      'bookingId': bookingId,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDescription': eventDescription,
      'eventImage': eventImage,
      'eventDate': eventDate,
      'uid': uid,
      'userEmail': userEmail,
      'totalAmount': totalAmount,
      'ticketPrice': ticketPrice,
      'currency': currency,
      'ticketQuantity': ticketQuantity,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Copy with method
  Booking copyWith({
    String? id,
    String? bookingId,
    String? eventId,
    String? eventTitle,
    String? eventDescription,
    String? eventImage,
    String? eventDate,
    String? uid,
    String? userEmail,
    double? totalAmount,
    double? ticketPrice,
    String? currency,
    int? ticketQuantity,
    String? paymentStatus,
    String? bookingStatus,
    DateTime? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDescription: eventDescription ?? this.eventDescription,
      eventImage: eventImage ?? this.eventImage,
      eventDate: eventDate ?? this.eventDate,
      uid: uid ?? this.uid,
      userEmail: userEmail ?? this.userEmail,
      totalAmount: totalAmount ?? this.totalAmount,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      currency: currency ?? this.currency,
      ticketQuantity: ticketQuantity ?? this.ticketQuantity,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Generate unique booking ID
  static String generateBookingId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'BK$timestamp';
  }

  @override
  String toString() {
    return 'Booking{id: $id, bookingId: $bookingId, eventId: $eventId, paymentStatus: $paymentStatus}';
  }
}

// Enums for better type safety
enum PaymentStatus {
  pending('pending'),
  completed('completed'),
  failed('failed'),
  refunded('refunded');

  const PaymentStatus(this.value);
  final String value;
}

enum BookingStatus {
  confirmed('confirmed'),
  cancelled('cancelled'),
  attended('attended');

  const BookingStatus(this.value);
  final String value;
}