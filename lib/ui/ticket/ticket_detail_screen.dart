import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_theme.dart';
import '../../model/evnt_model.dart';
import '../../model/booking_model.dart';

class TicketDetailScreen extends StatelessWidget {
  final Event event;
  final String bookingId;
  final int ticketQuantity;
  final double totalAmount;

  const TicketDetailScreen({
    super.key,
    required this.event,
    required this.bookingId,
    required this.ticketQuantity,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
        ),
        title: Text(
          'Your Ticket',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _shareTicket(context);
            },
            icon: const Icon(Icons.share_outlined, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ticket Card
            Container(
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Header with Event Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ADMIT ${ticketQuantity.toString().toUpperCase()}',
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'CONFIRMED',
                                  style: GoogleFonts.lexend(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            event.title,
                            style: GoogleFonts.lexend(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                color: Colors.white.withOpacity(0.9),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.venueName,
                                  style: GoogleFonts.lexend(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Dotted Divider
                    Container(
                      height: 1,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: DottedLinePainter(),
                      ),
                    ),

                    // Ticket Details
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Date and Time Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTicketInfo(
                                  'Date',
                                  event.date,
                                  Icons.calendar_today_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTicketInfo(
                                  'Time',
                                  event.startTime,
                                  Icons.access_time_outlined,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Venue and Booking ID Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildTicketInfo(
                                  'Venue',
                                  event.venueName,
                                  Icons.location_on_outlined,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTicketInfo(
                                  'Booking ID',
                                  '#${bookingId.substring(0, 8).toUpperCase()}',
                                  Icons.confirmation_number_outlined,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // QR Code Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE9ECEF),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Show this QR code at the entrance',
                                  style: GoogleFonts.lexend(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: 'TICKET:$bookingId:${event.eventId}:$ticketQuantity',
                                    version: QrVersions.auto,
                                    size: 150,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  bookingId.toUpperCase(),
                                  style: GoogleFonts.lexend(
                                    fontSize: 10,
                                    color: AppTheme.textSecondaryColor,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // Additional Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Notes',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNoteItem('Please arrive 30 minutes before the event starts'),
                  _buildNoteItem('Bring a valid ID for verification'),
                  _buildNoteItem('This ticket is non-transferable and non-refundable'),
                  _buildNoteItem('Follow the venue\'s safety guidelines'),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadTicket(context),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      'Download',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareTicket(context),
                    icon: const Icon(Icons.share_outlined),
                    label: Text(
                      'Share',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildNoteItem(String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              note,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareTicket(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing ticket...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _downloadTicket(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading ticket...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..strokeWidth = 1;

    double dashWidth = 6;
    double dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}