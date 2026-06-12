import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../model/evnt_model.dart';
import '../../services/stripe_service.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';
import '../payment/payment_confirmation_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;
  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isBookmarked = false;
  bool _isProcessingPayment = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Handle ticket booking with Stripe payment
  // Future<void> _handleTicketBooking() async {
  //   if (_isProcessingPayment || widget.event.availableSeats <= 0) return;
  //
  //   setState(() {
  //     _isProcessingPayment = true;
  //   });
  //
  //   try {
  //     print('=== BOOKING DEBUG START ===');
  //     print('Event ID: ${widget.event.eventId}');
  //     print('Event Title: ${widget.event.title}');
  //     print('Ticket Quantity: $_ticketQuantity');
  //     print('User authenticated: ${FirebaseAuth.instance.currentUser != null}');
  //     print('User ID: ${FirebaseAuth.instance.currentUser?.uid}');
  //
  //     // Calculate total amount
  //     final totalAmount = widget.event.totalExpence * _ticketQuantity;
  //     print('Total Amount: $totalAmount ${widget.event.currency}');
  //
  //     // Create booking first
  //     print('Creating booking...');
  //     final bookingId = await BookingService.createBooking(
  //       event: widget.event,
  //       paymentIntentId: '', // Will be updated after payment
  //       ticketQuantity: _ticketQuantity,
  //       paymentMetadata: {
  //         'event_title': widget.event.title,
  //         'ticket_quantity': _ticketQuantity,
  //         'event_date': widget.event.date,
  //       },
  //     );
  //
  //     if (bookingId == null) {
  //       throw Exception('Failed to create booking - please check your login status');
  //     }
  //     print('Booking created with ID: $bookingId');
  //
  //     // Process Stripe payment
  //     print('Processing Stripe payment...');
  //     final paymentSuccess = await StripeService.processPayment(
  //       context: context,
  //       amount: totalAmount,
  //       currency: widget.event.currency.toLowerCase(),
  //       description: 'Ticket for ${widget.event.title} - ${widget.event.date}',
  //       metadata: {
  //         'booking_id': bookingId,
  //         'event_id': widget.event.eventId,
  //         'ticket_quantity': _ticketQuantity,
  //       },
  //     );
  //
  //     print('Payment success: $paymentSuccess');
  //
  //     if (paymentSuccess) {
  //       print('Completing booking...');
  //       // Complete the booking process
  //       final bookingCompleted = await BookingService.completeBooking(
  //         bookingId: bookingId,
  //         eventId: widget.event.id ?? widget.event.eventId,
  //         ticketQuantity: _ticketQuantity,
  //       );
  //
  //       print('Booking completed: $bookingCompleted');
  //
  //       if (paymentSuccess) {
  //         await BookingService.updateBookingPaymentStatus(
  //           bookingId: bookingId,
  //           paymentStatus: 'completed',
  //         );
  //
  //         if (mounted) {
  //           Navigator.of(context).pushReplacement(
  //             MaterialPageRoute(
  //               builder: (context) => PaymentConfirmationScreen(
  //                 event: widget.event,
  //                 ticketQuantity: _ticketQuantity,
  //                 totalAmount: totalAmount,
  //                 bookingId: bookingId,
  //               ),
  //             ),
  //           );
  //         }
  //       }else {
  //         throw Exception('Failed to complete booking - seat update failed');
  //       }
  //     } else {
  //       // Payment failed, update booking status
  //       print('Payment failed, updating booking status...');
  //       await BookingService.updateBookingPaymentStatus(
  //         bookingId: bookingId,
  //         paymentStatus: 'failed',
  //       );
  //
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Payment failed or was canceled. Please try again.'),
  //             backgroundColor: Colors.orange,
  //             duration: Duration(seconds: 3),
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e, stackTrace) {
  //     print('=== BOOKING ERROR ===');
  //     print('Error: $e');
  //     print('Stack trace: $stackTrace');
  //
  //     if (mounted) {
  //       String errorMessage = 'Booking failed';
  //
  //       // Provide specific error messages
  //       if (e.toString().contains('not authenticated')) {
  //         errorMessage = 'Please log in to book tickets';
  //       } else if (e.toString().contains('Stripe')) {
  //         errorMessage = 'Payment system error. Please try again.';
  //       } else if (e.toString().contains('seat')) {
  //         errorMessage = 'Not enough seats available';
  //       } else {
  //         errorMessage = 'Booking failed: ${e.toString()}';
  //       }
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(errorMessage),
  //           backgroundColor: Colors.red,
  //           duration: const Duration(seconds: 5),
  //           action: SnackBarAction(
  //             label: 'Retry',
  //             textColor: Colors.white,
  //             onPressed: () => _handleTicketBooking(),
  //           ),
  //         ),
  //       );
  //     }
  //   } finally {
  //     print('=== BOOKING DEBUG END ===');
  //     if (mounted) {
  //       setState(() {
  //         _isProcessingPayment = false;
  //       });
  //     }
  //   }
  // }
  Future<void> _handleEventBooking() async {
    if (_isProcessingPayment) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final totalAmount = widget.event.totalExpence;

      // Process payment first - directly show Stripe payment sheet
      final paymentSuccess = await StripeService.processPayment(
        context: context,
        amount: totalAmount,
        currency: widget.event.currency.toLowerCase(),
        description: 'Booking for ${widget.event.title} - ${widget.event.date}',
        metadata: {
          'event_id': widget.event.eventId,
          'ticket_quantity': 1,
        },
      );

      if (!paymentSuccess) {
        throw Exception('Payment failed');
      }

      // Create booking after successful payment
      final bookingRef = FirebaseFirestore.instance.collection('Bookings').doc();

      await bookingRef.set({
        'bookingId': bookingRef.id,
        'uid': user.uid,
        'userEmail': user.email,

        // Event Information
        'eventId': widget.event.eventId,
        'eventTitle': widget.event.title,
        'eventDescription': widget.event.description,
        'eventDate': widget.event.date,
        'eventImage': widget.event.imageUrl,

        // Ticket Information
        'ticketQuantity': 1,
        'ticketPrice': widget.event.totalExpence,
        'totalAmount': totalAmount,
        'currency': widget.event.currency,

        // Payment Information
        'paymentStatus': 'completed',

        // Booking Status
        'bookingStatus': 'confirmed',

        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔔 Send booking confirmation notification
      await NotificationService.showBookingConfirmationNotification(
        eventTitle: widget.event.title,
        eventDate: widget.event.date,
        ticketQuantity: 1,
        bookingId: bookingRef.id,
      );

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationScreen(
              event: widget.event,
              ticketQuantity: 1,
              totalAmount: totalAmount,
              bookingId: bookingRef.id,
            ),
          ),
        );
      }
    } catch (e) {
      // 🔔 Send payment failed notification
      await NotificationService.showPaymentFailedNotification(
        eventTitle: widget.event.title,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Booking failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final List<String> displayImages = event.images.isNotEmpty ? event.images : [event.imageUrl];
    final screenWidth = MediaQuery.of(context).size.width;
    final double sliderHeight = 320.0;

    // Calculate occupancy for progress bar
    final double bookedSeats = (event.totalSeats - event.availableSeats).toDouble();
    final double occupancyProgress = event.totalSeats > 0 ? (bookedSeats / event.totalSeats).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // 1. Scrollable Event Details Content
          Positioned.fill(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  // Background Image Slider
                  SizedBox(
                    height: sliderHeight + 20,
                    width: screenWidth,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: displayImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return CachedNetworkImage(
                              imageUrl: displayImages[index],
                              width: screenWidth,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: Container()
                                    .animate(onPlay: (controller) => controller.repeat())
                                    .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                ),
                              ),
                            );
                          },
                        ),
                        // Dark overlay gradient to ensure text/icons readability on image
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.4),
                                  Colors.black.withValues(alpha: 0.0),
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (displayImages.length > 1)
                          Positioned(
                            bottom: 45,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                displayImages.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                  height: 6,
                                  width: _currentImageIndex == index ? 16 : 6,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Event details main container (overlapping card)
                  Padding(
                    padding: EdgeInsets.only(top: sliderHeight - 30),
                    child: Container(
                      width: screenWidth,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 100.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category & Featured Tag Row
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  event.category.toUpperCase(),
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              if (event.featured) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        'FEATURED',
                                        style: GoogleFonts.lexend(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 16),

                          // Event Title
                          Text(
                            event.title,
                            style: GoogleFonts.lexend(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                              height: 1.3,
                            ),
                          ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 24),

                          // Date and Time Row
                          _buildDetailRow(
                            icon: Icons.calendar_month_rounded,
                            iconColor: AppTheme.primaryColor,
                            title: event.date,
                            subtitle: '${event.startTime} - ${event.endTime}',
                          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

                          const SizedBox(height: 20),

                          // Venue and Location Row
                          _buildDetailRow(
                            icon: Icons.location_on_rounded,
                            iconColor: Colors.redAccent,
                            title: event.venueName,
                            subtitle: '${event.address}, ${event.city}, ${event.country}',
                            trailing: TextButton(
                              onPressed: () {
                                // Simple visual interaction
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    content: Text('Opening map for ${event.venueName}...'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Text(
                                'View Map',
                                style: GoogleFonts.lexend(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                          const SizedBox(height: 24),

                          // Divider
                          const Divider(height: 32, color: Color(0xFFF3F4F6)),

                          // Available Seats / Progress Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tickets Available',
                                    style: GoogleFonts.lexend(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  Text(
                                    '${event.availableSeats} / ${event.totalSeats} seats left',
                                    style: GoogleFonts.lexend(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: event.availableSeats > 0 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: occupancyProgress,
                                  minHeight: 10,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    event.availableSeats > 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(occupancyProgress * 100).toStringAsFixed(0)}% tickets booked',
                                style: GoogleFonts.lexend(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                          const Divider(height: 32, color: Color(0xFFF3F4F6)),

                          // About Event Section
                          Text(
                            'About this Event',
                            style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
                          const SizedBox(height: 12),
                          Text(
                            event.description,
                            style: GoogleFonts.lexend(
                              fontSize: 15,
                              color: AppTheme.textSecondaryColor,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

                          const Divider(height: 32, color: Color(0xFFF3F4F6)),

                          // Organizer Card
                          Text(
                            'Organizer',
                            style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFECEFF1)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppTheme.primaryColor,
                                  child: Text(
                                    event.organizerName.isNotEmpty ? event.organizerName[0].toUpperCase() : 'O',
                                    style: GoogleFonts.lexend(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.organizerName.isNotEmpty ? event.organizerName : 'Event Organizer',
                                        style: GoogleFonts.lexend(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Event Coordinator',
                                        style: GoogleFonts.lexend(
                                          fontSize: 12,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildContactButton(
                                      icon: Icons.mail_outline_rounded,
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Contact email: ${event.contactEmail}'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildContactButton(
                                      icon: Icons.phone_android_rounded,
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            behavior: SnackBarBehavior.floating,
                                            content: Text('Call phone: ${event.contactPhone}'),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
                        ],
                      ),
                    ),
                  ),
                  )],
              ),
            ),
          ),

          // 3. Top Action Controls (Back & Action Buttons)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
                

                // Share & Favorite Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBookmarked = !_isBookmarked;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              _isBookmarked ? 'Event added to favorites' : 'Event removed from favorites',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isBookmarked ? Colors.red : Colors.black,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Sticky Bottom Booking Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Price',
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.event.currency} ${widget.event.totalExpence.toStringAsFixed(0)}',
                        style: GoogleFonts.lexend(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (widget.event.availableSeats > 0 && !_isProcessingPayment)
                            ? _handleEventBooking
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isProcessingPayment
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.event.availableSeats > 0 ? 'Book Event' : 'Sold Out',
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFECEFF1)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
    );
  }
}
