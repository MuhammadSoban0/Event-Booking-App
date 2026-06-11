import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_theme.dart';
import '../../setting/setting_screen.dart';
import '../booking/booking_screen.dart';
import '../home/home_screen.dart';


class CustomNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const CustomNavigationScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<CustomNavigationScreen> createState() => _CustomNavigationScreenState();
}

class _CustomNavigationScreenState extends State<CustomNavigationScreen> {
  ValueNotifier<int> currentIndex = ValueNotifier(0);
  ValueNotifier<Color> sliderColor = ValueNotifier<Color>(Colors.black); // Black for selected slider

  // Using colors from AppTheme
  final Color txtColor = AppTheme.textPrimaryColor;
  final Color primaryColor = AppTheme.primaryColor;
  final Color bgColor = AppTheme.backgroundColor;
  final Color secondaryColor = Colors.black.withOpacity(0.34); // Black with 34% opacity for unselected

  final List<Map<String, dynamic>> _tabs = [
    {'key': 'navHome', 'icon': 'assets/images/home1.svg', 'activeIcon': 'assets/images/home.svg'},
    {'key': 'navExplore', 'icon': 'assets/images/map.svg', 'activeIcon': 'assets/images/map2.svg'},
    {'key': 'navSettings', 'icon': 'assets/images/settings.svg', 'activeIcon': 'assets/images/settings2.svg'},
  ];

  final List<Widget> _pages = [
    HomeScreen(),
    BookingScreen(),
    SettingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex.value = widget.initialIndex;
  }

  @override
  void dispose() {
    currentIndex.dispose();
    sliderColor.dispose();
    super.dispose();
  }

  void _handleTabTap(int index) {
    sliderColor.value = Colors.black; // Black slider for selected tab
    currentIndex.value = index;
  }

  String _getTabLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Booking';
      case 2:
        return 'Settings';
      default:
        return 'Tab';
    }
  }

  Widget _buildCustomBottomNavBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(
        left: screenWidth * 0.03,
        right: screenWidth * 0.03,
        bottom: 20,
      ),
      height: screenHeight * 0.07,
      constraints: const BoxConstraints(minHeight: 54, maxHeight: 70),
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 6),
      decoration: ShapeDecoration(
        color: AppTheme.backgroundColor, // White background from theme
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: const Color(0xFFE5E5E5), // Light gray border
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        shadows: [
          BoxShadow(
            color: Color(0x1A000000), // Subtle black shadow
            blurRadius: 8.90,
            offset: Offset(0, 2),
            spreadRadius: 0,
          )
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / _tabs.length;

          return ValueListenableBuilder<int>(
            valueListenable: currentIndex,
            builder: (context, activeIndex, child) {
              return Stack(
                children: [
                  // Slider background
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: tabWidth * activeIndex,
                    top: 0,
                    bottom: 0,
                    child: ValueListenableBuilder<Color>(
                      valueListenable: sliderColor,
                      builder: (context, color, _) {
                        return Container(
                          width: tabWidth,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                  ),

                  // Row of tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_tabs.length, (index) {
                      final isActive = currentIndex.value == index;
                      final tab = _tabs[index];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _handleTabTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            height: constraints.maxHeight,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  isActive ? tab['activeIcon'] : tab['icon'],
                                  color: isActive ? Colors.white : secondaryColor, // White for active, black 34% for inactive
                                  height: 20,
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    _getTabLabel(index),
                                    style: GoogleFonts.lexend(
                                      color: Colors.white, // White text for selected tab
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool showNav = MediaQuery.of(context).viewInsets.bottom == 0.0;

    return PopScope(
      canPop: false, // We handle all pop logic manually
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        if (currentIndex.value != 0) {
          _handleTabTap(0); // Go back to Home tab
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: ValueListenableBuilder<int>(
          valueListenable: currentIndex,
          builder: (context, index, child) {
            return IndexedStack(
              index: index,
              children: _pages,
            );
          },
        ),
        bottomNavigationBar: showNav ? _buildCustomBottomNavBar() : null,
      ),
    );
  }
}