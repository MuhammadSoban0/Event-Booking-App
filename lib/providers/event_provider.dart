import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/evnt_model.dart';

// Repository class to handle Firestore operations
class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all events from Firestore
  Future<List<Event>> fetchAllEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('Events')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Fetch featured events only
  Future<List<Event>> fetchFeaturedEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('Events')
          .where('featured', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured events: $e');
    }
  }

  // Fetch events by category
  Future<List<Event>> fetchEventsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('Events')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Event.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch events by category: $e');
    }
  }

  // Fetch single event by ID
  Future<Event?> fetchEventById(String eventId) async {
    try {
      final docSnapshot = await _firestore
          .collection('Events')
          .doc(eventId)
          .get();

      if (docSnapshot.exists) {
        return Event.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  // Add new event to Firestore
  Future<String> addEvent(Event event) async {
    try {
      final docRef = await _firestore
          .collection('Events')
          .add(event.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add event: $e');
    }
  }

  // Update existing event
  Future<void> updateEvent(String eventId, Event event) async {
    try {
      await _firestore
          .collection('Events')
          .doc(eventId)
          .update(event.toFirestore());
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore
          .collection('Events')
          .doc(eventId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Get real-time stream of events
  Stream<List<Event>> getEventsStream() {
    return _firestore
        .collection('Events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }

  // Get real-time stream of featured events
  Stream<List<Event>> getFeaturedEventsStream() {
    return _firestore
        .collection('Events')
        .where('featured', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList());
  }
}

// Provider for EventRepository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

// FutureProvider to fetch all events
final allEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.fetchAllEvents();
});

// FutureProvider to fetch limited featured events (3 events)
final featuredEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  final events = await repository.fetchFeaturedEvents();
  return events.take(3).toList(); // Limit to 3 events only
});

// Pagination providers
final eventPageSizeProvider = StateProvider<int>((ref) => 5);
final currentEventPageProvider = StateProvider<int>((ref) => 0);

// Provider for paginated events (cumulative loading)
final paginatedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  final pageSize = ref.watch(eventPageSizeProvider);
  final currentPage = ref.watch(currentEventPageProvider);
  
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Events')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(pageSize * (currentPage + 1)) // Get all items up to current page
        .get();

    return querySnapshot.docs
        .map((doc) => Event.fromFirestore(doc))
        .toList();
  } catch (e) {
    throw Exception('Failed to fetch paginated events: $e');
  }
});

// Provider to check if more events are available
final hasMoreEventsProvider = FutureProvider<bool>((ref) async {
  final pageSize = ref.watch(eventPageSizeProvider);
  final currentPage = ref.watch(currentEventPageProvider);
  
  try {
    // Check if there are more events beyond current page
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Events')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(pageSize * (currentPage + 2)) // Check one page ahead
        .get();

    return querySnapshot.docs.length > pageSize * (currentPage + 1);
  } catch (e) {
    return false;
  }
});

// State notifier for managing loading state
class LoadingState extends StateNotifier<bool> {
  LoadingState() : super(false);
  
  void setLoading(bool loading) {
    state = loading;
  }
}

final loadingStateProvider = StateNotifierProvider<LoadingState, bool>((ref) {
  return LoadingState();
});

// StreamProvider for real-time events
final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventsStream();
});

// StreamProvider for real-time featured events
final featuredEventsStreamProvider = StreamProvider<List<Event>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.getFeaturedEventsStream();
});

// Family provider to fetch events by category
final eventsByCategoryProvider = FutureProvider.family<List<Event>, String>((ref, category) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.fetchEventsByCategory(category);
});

// Family provider to fetch single event by ID
final eventByIdProvider = FutureProvider.family<Event?, String>((ref, eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  return await repository.fetchEventById(eventId);
});

// StateProvider for selected category filter
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// StateProvider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to get filtered events based on search and category
final filteredEventsProvider = Provider<AsyncValue<List<Event>>>((ref) {
  final eventsAsync = ref.watch(allEventsProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

  return eventsAsync.when(
    data: (events) {
      List<Event> filteredEvents = events;

      // Filter by category
      if (selectedCategory != null && selectedCategory.isNotEmpty) {
        filteredEvents = filteredEvents
            .where((event) => event.category.toLowerCase() == selectedCategory.toLowerCase())
            .toList();
      }

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        filteredEvents = filteredEvents.where((event) =>
            event.title.toLowerCase().contains(searchQuery) ||
            event.description.toLowerCase().contains(searchQuery) ||
            event.venueName.toLowerCase().contains(searchQuery) ||
            event.city.toLowerCase().contains(searchQuery)
        ).toList();
      }

      return AsyncValue.data(filteredEvents);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

// Provider for event statistics
final eventStatsProvider = Provider<Map<String, int>>((ref) {
  final eventsAsync = ref.watch(allEventsProvider);
  
  return eventsAsync.when(
    data: (events) {
      final stats = <String, int>{
        'total': events.length,
        'active': events.where((e) => e.status == 'active').length,
        'featured': events.where((e) => e.featured).length,
        'categories': events.map((e) => e.category).toSet().length,
      };
      return stats;
    },
    loading: () => <String, int>{},
    error: (_, __) => <String, int>{},
  );
});