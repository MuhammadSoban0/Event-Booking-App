import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_theme.dart';
import '../../model/booking_model.dart';
import '../../model/evnt_model.dart';
import '../ticket/ticket_detail_screen.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  final Event event;
  final int ticketQuantity;
  final double totalAmount;
  final String? bookingId;

  const PaymentConfirmationScreen({
    super.key,
    required this.event,
    required this.ticketQuantity,
    required this.totalAmount,
    this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: Text(
          'Payment Confirmation',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success Animation/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            // Success Message
            Text(
              'Payment Successful!',
              style: GoogleFonts.lexend(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Your ticket has been booked successfully',
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

            const SizedBox(height: 32),

            // Booking Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (bookingId != null) ...[
                    _buildDetailRow('Booking ID', bookingId!),
                    const SizedBox(height: 12),
                  ],

                  _buildDetailRow('Event', event.title),
                  const SizedBox(height: 12),
                  _buildDetailRow('Date & Time', '${event.date} • ${event.startTime}'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Venue', event.venueName),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tickets', '$ticketQuantity x ${event.currency} ${event.totalExpence.toStringAsFixed(0)}'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Total Amount',
                    '${event.currency} ${totalAmount.toStringAsFixed(0)}',
                    isTotal: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 32),

            // Important Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Information',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A confirmation email has been sent to your registered email address. Please show this booking confirmation at the venue entrance.',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

            const SizedBox(height: 40),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to ticket detail screen
                      if (bookingId != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TicketDetailScreen(
                              event: event,
                              bookingId: bookingId!,
                              ticketQuantity: ticketQuantity,
                              totalAmount: totalAmount,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking ID not available'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: Text(
                      'View Ticket',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate back to home or event list
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.home_outlined),
                    label: Text(
                      'Back to Home',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? Colors.green : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}