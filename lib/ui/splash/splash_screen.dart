// ============================================================================
//  BookMe — Event Booking App
//  Splash Screen built 100% with Flutter CustomPainter (no assets, no packages)
//
//  Theme    : White background, black foreground (monochrome)
//  Concept  : An event TICKET is "drawn" stroke-by-stroke, gets stamped with a
//             check mark (booking confirmed), confetti bursts, pulse rings
//             radiate, then the brand name slides in — and we move to Home.
//
//  Everything is adjustable through [SplashConfig].
//
//  HOW TO RUN:
//    1. flutter create bookme
//    2. Replace lib/main.dart with this file
//    3. flutter run
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_screen.dart';
import '../navigation/custom_navigation_bar.dart';



// ============================================================================
//  SPLASH CONFIG  —  every knob you may want to turn
// ============================================================================
class SplashConfig {
  // ---- timing -------------------------------------------------------------
  final Duration totalDuration; // full splash animation length
  final Duration holdAfterFinish; // pause before navigating to Home
  final Duration pageTransition; // splash -> home transition length

  // ---- colors -------------------------------------------------------------
  final Color background;
  final Color foreground; // ticket / text / particles
  final Color accent; // check stamp fill

  // ---- ticket -------------------------------------------------------------
  final double ticketWidthFactor; // ticket width as % of screen width
  final double ticketAspect; // height = width * aspect
  final double ticketStrokeWidth;
  final double ticketCornerRadius;
  final double notchRadius; // side semi-circle notches
  final int perforationDots; // dots on the tear line

  // ---- check stamp ----------------------------------------------------------
  final double stampRadiusFactor; // % of ticket height
  final double stampStrokeWidth;

  // ---- confetti -------------------------------------------------------------
  final int confettiCount;
  final double confettiMaxSize;
  final double confettiSpreadFactor; // how far particles fly (x ticket width)

  // ---- pulse rings ----------------------------------------------------------
  final int pulseRings;
  final double pulseMaxRadiusFactor; // % of screen shortest side

  // ---- branding -------------------------------------------------------------
  final String appName;
  final String tagline;
  final double titleSize;
  final double taglineSize;

  const SplashConfig({
    this.totalDuration = const Duration(milliseconds: 3400),
    this.holdAfterFinish = const Duration(milliseconds: 500),
    this.pageTransition = const Duration(milliseconds: 650),
    this.background = Colors.white,
    this.foreground = Colors.black,
    this.accent = Colors.black,
    this.ticketWidthFactor = 0.62,
    this.ticketAspect = 0.46,
    this.ticketStrokeWidth = 3.0,
    this.ticketCornerRadius = 18.0,
    this.notchRadius = 11.0,
    this.perforationDots = 7,
    this.stampRadiusFactor = 0.30,
    this.stampStrokeWidth = 3.0,
    this.confettiCount = 26,
    this.confettiMaxSize = 7.0,
    this.confettiSpreadFactor = 1.15,
    this.pulseRings = 3,
    this.pulseMaxRadiusFactor = 0.46,
    this.appName = 'BookMe',
    this.tagline = 'Every event. One tap away.',
    this.titleSize = 40,
    this.taglineSize = 14,
  });
}

// ============================================================================
//  SPLASH SCREEN
// ============================================================================
class SplashScreen extends StatefulWidget {
  final SplashConfig config;

  const SplashScreen({super.key, this.config = const SplashConfig()});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // -- staged sub-animations (all driven by one controller) ------------------
  late final Animation<double> ticketDraw; // 0.00 - 0.38 : outline traced
  late final Animation<double> perforation; // 0.30 - 0.46 : tear-line dots
  late final Animation<double> stampPop; // 0.44 - 0.60 : circle pops in
  late final Animation<double> checkDraw; // 0.56 - 0.70 : tick traced
  late final Animation<double> confetti; // 0.62 - 1.00 : burst & fall
  late final Animation<double> pulse; // 0.62 - 1.00 : radiating rings
  late final Animation<double> textReveal; // 0.70 - 0.92 : brand slides up
  late final Animation<double> ticketLift; // 0.66 - 0.86 : ticket floats up

  SplashConfig get cfg => widget.config;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: cfg.totalDuration);

    Animation<double> seg(double a, double b, [Curve c = Curves.easeInOut]) =>
        CurvedAnimation(
          parent: _controller,
          curve: Interval(a, b, curve: c),
        );

    ticketDraw = seg(0.00, 0.38, Curves.easeInOutCubic);
    perforation = seg(0.30, 0.46, Curves.easeOut);
    stampPop = seg(0.44, 0.60, Curves.elasticOut);
    checkDraw = seg(0.56, 0.70, Curves.easeOutCubic);
    confetti = seg(0.62, 1.00, Curves.easeOutQuart);
    pulse = seg(0.62, 1.00, Curves.easeOut);
    textReveal = seg(0.70, 0.92, Curves.easeOutCubic);
    ticketLift = seg(0.66, 0.86, Curves.easeInOutCubic);

    _controller.forward();
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future.delayed(cfg.holdAfterFinish);
        if (mounted) _goHome();
      }
    });
  }

  void _goHome() {
    // Check if user is authenticated
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    Widget destination;
    if (currentUser != null) {
      // User is logged in, go to custom navigation
      destination = const CustomNavigationScreen();
    } else {
      // User is not logged in, go to auth screen
      destination = const AuthScreen();
    }
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: cfg.pageTransition,
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, anim, __, child) {
          final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cfg.background,
      body: GestureDetector(
        // tap anywhere to skip
        onTap: () {
          _controller.stop();
          _goHome();
        },
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: BookMeSplashPainter(
                  config: cfg,
                  ticketDraw: ticketDraw.value,
                  perforation: perforation.value,
                  stampPop: stampPop.value,
                  checkDraw: checkDraw.value,
                  confetti: confetti.value,
                  pulse: pulse.value,
                  textReveal: textReveal.value,
                  ticketLift: ticketLift.value,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
//  THE CUSTOM PAINTER  —  all visuals drawn here, zero images
// ============================================================================
class BookMeSplashPainter extends CustomPainter {
  final SplashConfig config;
  final double ticketDraw, perforation, stampPop, checkDraw;
  final double confetti, pulse, textReveal, ticketLift;

  BookMeSplashPainter({
    required this.config,
    required this.ticketDraw,
    required this.perforation,
    required this.stampPop,
    required this.checkDraw,
    required this.confetti,
    required this.pulse,
    required this.textReveal,
    required this.ticketLift,
  });

  // deterministic "random" so confetti doesn't jitter every frame
  static final List<_ConfettiSeed> _seeds = _buildSeeds(64);

  static List<_ConfettiSeed> _buildSeeds(int n) {
    final rng = math.Random(42);
    return List.generate(n, (i) {
      return _ConfettiSeed(
        angle: rng.nextDouble() * math.pi * 2,
        speed: 0.55 + rng.nextDouble() * 0.45,
        size: 0.35 + rng.nextDouble() * 0.65,
        spin: (rng.nextDouble() - 0.5) * 6,
        shape: i % 3,
        // 0 rect, 1 circle, 2 triangle
        drift: (rng.nextDouble() - 0.5) * 0.4,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ticket floats slightly up at the end to make room for the title
    final lift = ticketLift * size.height * 0.075;
    final ticketCenter = center.translate(0, -size.height * 0.02 - lift);

    final ticketW = size.width * config.ticketWidthFactor;
    final ticketH = ticketW * config.ticketAspect;
    final ticketRect = Rect.fromCenter(
      center: ticketCenter,
      width: ticketW,
      height: ticketH,
    );

    _paintPulseRings(canvas, size, ticketCenter);
    _paintConfetti(canvas, ticketCenter, ticketW);
    _paintTicket(canvas, ticketRect);
    _paintPerforation(canvas, ticketRect);
    _paintStamp(canvas, ticketRect);
    _paintBrand(canvas, size, ticketRect);
  }

  // --------------------------------------------------------------- ticket --
  Path _ticketPath(Rect r) {
    final rr = config.ticketCornerRadius;
    final notch = config.notchRadius;
    final cyL = Offset(r.left, r.center.dy);
    final cyR = Offset(r.right, r.center.dy);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(rr)));

    // punch the two side notches out using even-odd
    final notches = Path()
      ..addOval(Rect.fromCircle(center: cyL, radius: notch))
      ..addOval(Rect.fromCircle(center: cyR, radius: notch));

    return Path.combine(PathOperation.difference, path, notches);
  }

  void _paintTicket(Canvas canvas, Rect r) {
    if (ticketDraw <= 0) return;

    final paint = Paint()
      ..color = config.foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.ticketStrokeWidth
      ..strokeCap = StrokeCap.round;

    // trace the outline progressively using PathMetrics
    final full = _ticketPath(r);
    for (final metric in full.computeMetrics()) {
      final extract = metric.extractPath(0, metric.length * ticketDraw);
      canvas.drawPath(extract, paint);
    }
  }

  // ---------------------------------------------------------- perforation --
  void _paintPerforation(Canvas canvas, Rect r) {
    if (perforation <= 0) return;

    // vertical tear line at 68% of the ticket width
    final x = r.left + r.width * 0.68;
    final dots = config.perforationDots;
    final usableH = r.height - config.notchRadius * 2 - 16;
    final gap = usableH / (dots - 1);
    final startY = r.top + config.notchRadius + 8;

    final paint = Paint()..color = config.foreground;

    for (int i = 0; i < dots; i++) {
      // dots appear one-by-one
      final t = ((perforation * dots) - i).clamp(0.0, 1.0);
      if (t <= 0) continue;
      canvas.drawCircle(Offset(x, startY + gap * i), 2.2 * t, paint);
    }

    // tiny "barcode" lines in the stub area, fading in with perforation
    final stubPaint = Paint()
      ..color = config.foreground.withOpacity(0.85 * perforation)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final stubLeft = x + (r.right - x) * 0.30;
    final stubRight = r.right - (r.right - x) * 0.30;
    final lineCount = 4;
    final lh = r.height * 0.34;
    final ly0 = r.center.dy - lh / 2;
    for (int i = 0; i < lineCount; i++) {
      final lx = stubLeft + (stubRight - stubLeft) * i / (lineCount - 1);
      canvas.drawLine(Offset(lx, ly0), Offset(lx, ly0 + lh), stubPaint);
    }
  }

  // ---------------------------------------------------------------- stamp --
  void _paintStamp(Canvas canvas, Rect r) {
    if (stampPop <= 0) return;

    // stamp sits in the main (left) section of the ticket
    final cx = r.left + r.width * 0.34;
    final cy = r.center.dy;
    final radius = r.height * config.stampRadiusFactor * stampPop;

    final circle = Paint()
      ..color = config.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.stampStrokeWidth;

    canvas.drawCircle(Offset(cx, cy), radius, circle);

    // check mark traced inside
    if (checkDraw > 0) {
      final rBase = r.height * config.stampRadiusFactor;
      final check = Path()
        ..moveTo(cx - rBase * 0.45, cy + rBase * 0.02)
        ..lineTo(cx - rBase * 0.10, cy + rBase * 0.38)
        ..lineTo(cx + rBase * 0.50, cy - rBase * 0.32);

      final paint = Paint()
        ..color = config.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.stampStrokeWidth + 0.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (final m in check.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * checkDraw), paint);
      }
    }
  }

  // ------------------------------------------------------------- confetti --
  void _paintConfetti(Canvas canvas, Offset origin, double ticketW) {
    if (confetti <= 0) return;

    final spread = ticketW * config.confettiSpreadFactor;
    final fade = (1 - confetti).clamp(0.0, 1.0);

    for (int i = 0; i < config.confettiCount && i < _seeds.length; i++) {
      final s = _seeds[i];
      final dist = spread * s.speed * Curves.easeOutCubic.transform(confetti);
      final gravity = 60 * confetti * confetti; // gentle fall
      final pos =
          origin +
          Offset(
            math.cos(s.angle) * dist + s.drift * dist,
            math.sin(s.angle) * dist + gravity,
          );

      final sizePx = config.confettiMaxSize * s.size * (0.6 + 0.4 * fade);
      final paint = Paint()..color = config.foreground.withOpacity(0.9 * fade);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(s.spin * confetti * math.pi);

      switch (s.shape) {
        case 0: // rectangle
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: sizePx,
              height: sizePx * 0.55,
            ),
            paint,
          );
          break;
        case 1: // circle
          canvas.drawCircle(Offset.zero, sizePx * 0.42, paint);
          break;
        default: // triangle
          final h = sizePx * 0.9;
          final tri = Path()
            ..moveTo(0, -h / 2)
            ..lineTo(h / 2, h / 2)
            ..lineTo(-h / 2, h / 2)
            ..close();
          canvas.drawPath(tri, paint);
      }
      canvas.restore();
    }
  }

  // ---------------------------------------------------------- pulse rings --
  void _paintPulseRings(Canvas canvas, Size size, Offset center) {
    if (pulse <= 0) return;

    final maxR = size.shortestSide * config.pulseMaxRadiusFactor;
    for (int i = 0; i < config.pulseRings; i++) {
      final offsetT = (pulse - i * 0.18).clamp(0.0, 1.0);
      if (offsetT <= 0) continue;
      final t = Curves.easeOut.transform(offsetT);
      final paint = Paint()
        ..color = config.foreground.withOpacity(0.18 * (1 - t))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(center, maxR * t, paint);
    }
  }

  // ---------------------------------------------------------------- brand --
  void _paintBrand(Canvas canvas, Size size, Rect ticketRect) {
    if (textReveal <= 0) return;

    final opacity = textReveal.clamp(0.0, 1.0);
    final slide = (1 - textReveal) * 18;

    final title = TextPainter(
      text: TextSpan(
        text: config.appName,
        style: TextStyle(
          color: config.foreground.withOpacity(opacity),
          fontSize: config.titleSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tagline = TextPainter(
      text: TextSpan(
        text: config.tagline.toUpperCase(),
        style: TextStyle(
          color: config.foreground.withOpacity(opacity * 0.65),
          fontSize: config.taglineSize,
          fontWeight: FontWeight.w500,
          letterSpacing: 3.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final ty = ticketRect.bottom + 44 + slide;
    title.paint(canvas, Offset(size.width / 2 - title.width / 2, ty));
    tagline.paint(
      canvas,
      Offset(size.width / 2 - tagline.width / 2, ty + title.height + 10),
    );
  }

  @override
  bool shouldRepaint(covariant BookMeSplashPainter old) =>
      old.ticketDraw != ticketDraw ||
      old.perforation != perforation ||
      old.stampPop != stampPop ||
      old.checkDraw != checkDraw ||
      old.confetti != confetti ||
      old.pulse != pulse ||
      old.textReveal != textReveal ||
      old.ticketLift != ticketLift;
}

class _ConfettiSeed {
  final double angle, speed, size, spin, drift;
  final int shape;

  const _ConfettiSeed({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.shape,
    required this.drift,
  });
}

class _Event {
  final String title, dateTime, venue;

  const _Event(this.title, this.dateTime, this.venue);
}

class _EventCard extends StatelessWidget {
  final _Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.dateTime,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.65),
                  ),
                ),
                Text(
                  event.venue,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black),
        ],
      ),
    );
  }
}
