import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_theme.dart';
import '../../model/evnt_model.dart';
import '../../providers/event_provider.dart';
import '../event_details/event_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  List<Event> _allEvents = [];
  bool _hasMoreEvents = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialEvents() async {
    setState(() {
      _allEvents = []; // Clear events to show shimmer
    });
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Events')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _allEvents = querySnapshot.docs
              .map((doc) => Event.fromFirestore(doc))
              .toList();
          _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;
          _hasMoreEvents = querySnapshot.docs.length == 5;
        });
      }
    } catch (e) {
      print('Error loading initial events: $e');
      if (mounted) {
        setState(() {
          _allEvents = []; // Keep empty to show error state
        });
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 100) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreEvents || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Events')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!) // Start after last loaded document
          .limit(5)
          .get();

      if (mounted) {
        final newEvents = querySnapshot.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList();

        setState(() {
          _allEvents.addAll(newEvents); // Add to existing list, don't replace
          _lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : _lastDocument;
          _hasMoreEvents = newEvents.length == 5;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error loading more events: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuredEventsAsync = ref.watch(featuredEventsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header and Search Section
              _buildHeaderSection(),
              
              // Featured Events Carousel Slider (Limited to 3)
              _buildFeaturedEventsCarousel(featuredEventsAsync),
              
              // All Events Section (Local State Management)
              _buildAllEventsSection(),
              
              // Loading indicator for pagination
              if (_isLoadingMore)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildEventShimmerCard(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHeaderSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting and Profile
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Events',
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildFeaturedEventsCarousel(AsyncValue<List<Event>> featuredEventsAsync) {
    return Column(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 190, // Reduced from 200 to 160
          child: featuredEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return _buildEmptyFeaturedEvents();
              }
              return CarouselSlider.builder(
                itemCount: events.length,
                itemBuilder: (context, index, realIndex) {
                  return _buildFeaturedEventCard(events[index]);
                },
                options: CarouselOptions(
                  height: 160, // Reduced from 200 to 160
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: false, // Disable enlarging to make all cards same size
                  viewportFraction: 1.0, // Full width cards
                  scrollDirection: Axis.horizontal,
                ),
              );
            },
            loading: () => _buildCarouselShimmer(),
            error: (error, stack) => Center(
              child: Text(
                'Error loading featured events',
                style: GoogleFonts.lexend(color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselShimmer() {
    return CarouselSlider.builder(
      itemCount: 3, // Show 3 shimmer cards
      itemBuilder: (context, index, realIndex) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4), // Reduced margin to match main carousel
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.8))
            .then(delay: 400.ms)
            .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.6)),
        );
      },
      options: CarouselOptions(
        height: 160, // Updated to match new carousel height
        enlargeCenterPage: false, // Disable enlarging to match main carousel
        viewportFraction: 1.0, // Full width to match main carousel
        scrollDirection: Axis.horizontal,
      ),
    );
  }
  Widget _buildEmptyFeaturedEvents() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 48,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          Text(
            'No Featured Events Yet',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for exciting events',
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildFeaturedEventCard(Event event) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal:20), // Reduced margin for wider cards
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Container()
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.8))
                    .then(delay: 400.ms)
                    .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.6)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.grey[600],
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            
            // Dark Overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Event Title Only
                  Text(
                    event.title,
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Discount Banner - Top Right Corner
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Text(
                  '30% OFF',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildAllEventsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explore Events',
                style: GoogleFonts.lexend(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Events List (Full-Width Cards) - Using local state
          if (_allEvents.isEmpty && !_isLoadingMore)
            _buildEventsShimmer() // Show shimmer for initial load
          else if (_allEvents.isEmpty)
            _buildEmptyEventsState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allEvents.length,
              itemBuilder: (context, index) {
                return _buildFullWidthEventCard(_allEvents[index], index);
              },
            ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEventsShimmer() {
    return Column(
      children: List.generate(3, (index) => _buildEventShimmerCard()),
    );
  }

  Widget _buildEventShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x21000000),
            blurRadius: 17,
            offset: Offset(0, 6),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          
          // Shimmer Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badges shimmer
                Row(
                  children: [
                    Container(
                      height: 24,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Title shimmer
                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Description shimmer
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(height: 4),
                
                Container(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info row shimmer
                Row(
                  children: [
                    Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Container(
                      height: 16,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Price and button row shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 20,
                          width: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 40,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Seats shimmer
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.8))
      .then(delay: 400.ms)
      .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.6));
  }

  Widget _buildFullWidthEventCard(Event event, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsScreen(event: event),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: [
            BoxShadow(
              color: Color(0x21000000),
              blurRadius: 17,
              offset: Offset(0, 6),
              spreadRadius: 0,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: event.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Container()
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.8))
                    .then(delay: 400.ms)
                    .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.6)),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[100],
                  child: Center(
                    child: Icon(
                      Icons.event,
                      size: 48,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            
            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Featured Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category,
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      if (event.featured) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ).animate(delay: Duration(milliseconds: 100 + (index * 50)))
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                  
                  const SizedBox(height: 12),
                  
                  // Event Title
                  Text(
                    event.title,
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).animate(delay: Duration(milliseconds: 150 + (index * 50)))
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  
                  const SizedBox(height: 8),
                  
                  // Event Description
                  Text(
                    event.description,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ).animate(delay: Duration(milliseconds: 200 + (index * 50)))
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  
                  const SizedBox(height: 16),
                  
                  // Event Info Row
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.date,
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${event.venueName}, ${event.city}',
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ).animate(delay: Duration(milliseconds: 250 + (index * 50)))
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideX(begin: -0.3, end: 0, curve: Curves.easeOut),
                  
                  const SizedBox(height: 16),
                  
                  // Price and Action Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting from',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          Text(
                            '${event.currency} ${event.totalExpence.toStringAsFixed(0)}',
                            style: GoogleFonts.lexend(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ).animate(delay: Duration(milliseconds: 300 + (index * 50)))
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailsScreen(event: event),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        ),
                        child: Text(
                          'Book Now',
                          style: GoogleFonts.lexend(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate(delay: Duration(milliseconds: 350 + (index * 50)))
                        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                        .scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0), curve: Curves.elasticOut),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Seats Available
                  Text(
                    '${event.availableSeats} seats available',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: event.availableSeats > 0 
                          ? Colors.green 
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate(delay: Duration(milliseconds: 400 + (index * 50)))
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack)
        .scale(begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0), curve: Curves.easeOut),
    );
  }
  Widget _buildEmptyEventsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: GoogleFonts.lexend(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new events',
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}