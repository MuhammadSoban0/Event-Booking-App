import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String? id; // Document ID from Firestore
  final String eventId;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final List<String> images;
  final String venueName;
  final String address;
  final String city;
  final String country;
  final String date;
  final String startTime;
  final String endTime;
  final double totalExpence;
  final String currency;
  final int totalSeats;
  final int availableSeats;
  final String organizerId;
  final String organizerName;
  final String contactEmail;
  final String contactPhone;
  final String status;
  final bool featured;
  final DateTime? createdAt;

  Event({
    this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.images,
    required this.venueName,
    required this.address,
    required this.city,
    required this.country,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalExpence,
    required this.currency,
    required this.totalSeats,
    required this.availableSeats,
    required this.organizerId,
    required this.organizerName,
    required this.contactEmail,
    required this.contactPhone,
    required this.status,
    required this.featured,
    this.createdAt,
  });

  // Factory constructor to create Event from Firestore document
  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Event(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      venueName: data['venueName'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      totalExpence: (data['totalExpence'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'PKR',
      totalSeats: data['totalSeats'] ?? 0,
      availableSeats: data['availableSeats'] ?? 0,
      organizerId: data['organizerId'] ?? '',
      organizerName: data['organizerName'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      status: data['status'] ?? 'active',
      featured: data['featured'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Factory constructor to create Event from JSON (for API calls or local storage)
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      eventId: json['eventId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      venueName: json['venueName'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      totalExpence: (json['totalExpence'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'PKR',
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? '',
      contactEmail: json['contactEmail'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      status: json['status'] ?? 'active',
      featured: json['featured'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  // Convert Event to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'images': images,
      'venueName': venueName,
      'address': address,
      'city': city,
      'country': country,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'totalExpence': totalExpence,
      'currency': currency,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'status': status,
      'featured': featured,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Convert Event to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'images': images,
      'venueName': venueName,
      'address': address,
      'city': city,
      'country': country,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'totalExpence': totalExpence,
      'currency': currency,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'status': status,
      'featured': featured,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create a copy of Event with updated fields
  Event copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    List<String>? images,
    String? venueName,
    String? address,
    String? city,
    String? country,
    String? date,
    String? startTime,
    String? endTime,
    double? totalExpence,
    String? currency,
    int? totalSeats,
    int? availableSeats,
    String? organizerId,
    String? organizerName,
    String? contactEmail,
    String? contactPhone,
    String? status,
    bool? featured,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalExpence: totalExpence ?? this.totalExpence,
      currency: currency ?? this.currency,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      featured: featured ?? this.featured,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Utility methods
  bool get isActive => status == 'active';
  bool get hasAvailableSeats => availableSeats > 0;
  int get bookedSeats => totalSeats - availableSeats;
  double get occupancyPercentage => totalSeats > 0 ? (bookedSeats / totalSeats) * 100 : 0;
  
  // Get full address string
  String get fullAddress => '$address, $city, $country';
  
  // Get event duration (assuming same day)
  String get duration => '$startTime - $endTime';
  
  // Check if event is in the past (basic string comparison, you might want to use proper DateTime parsing)
  bool get isPastEvent {
    try {
      final eventDate = DateTime.parse(date.split('/').reversed.join('-'));
      return eventDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() {
    return 'Event{id: $id, eventId: $eventId, title: $title, date: $date, venue: $venueName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          eventId == other.eventId;

  @override
  int get hashCode => id.hashCode ^ eventId.hashCode;
}

// Enum for event categories (optional, for better type safety)
enum EventCategory {
  technology('Technology'),
  business('Business'),
  education('Education'),
  entertainment('Entertainment'),
  sports('Sports'),
  health('Health'),
  food('Food & Drink'),
  travel('Travel'),
  music('Music'),
  art('Art & Culture'),
  other('Other');

  const EventCategory(this.displayName);
  final String displayName;
}

// Enum for event status (optional, for better type safety)
enum EventStatus {
  active('active'),
  cancelled('cancelled'),
  completed('completed'),
  draft('draft');

  const EventStatus(this.value);
  final String value;
}