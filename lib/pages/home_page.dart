import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // Define colors similar to FlutterFlow theme
    const primaryColor = Color(0xFF4B39EF);
    const secondaryColor = Color(0xFF39D2C0);
    const tertiaryColor = Color(0xFFEE8B60);
    const accentColor = Color(0xFFFF5963);
    const successColor = Color(0xFF249689);
    const warningColor = Color(0xFFFFC107);
    const infoColor = Color(0xFF17C1E8);
    
    const primaryBackground = Color(0xFFF1F4F8);
    const secondaryBackground = Color(0xFFFFFFFF);
    const primaryText = Color(0xFF14181B);
    const secondaryText = Color(0xFF57636C);
    const alternate = Color(0xFFE0E3E7);

    return Scaffold(
      backgroundColor: primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            'Good morning! 👋',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.volume_up,
                            color: secondaryText,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ready to continue your English journey?',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Progress Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(
                            Icons.track_changes,
                            color: primaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Progress',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Level A2',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            '24/50 lessons',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 8,
                        decoration: BoxDecoration(
                          color: alternate,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.48,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Text('🔥'),
                                  const SizedBox(width: 4),
                                  Text(
                                    '12',
                                    style: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Day Streak',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Text('🎯'),
                                  const SizedBox(width: 4),
                                  Text(
                                    '85%',
                                    style: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pronunciation',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  const Text('⏱️'),
                                  const SizedBox(width: 4),
                                  Text(
                                    '2h 30m',
                                    style: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Time Today',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions Section
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _buildActionCard(
                        Icons.play_arrow,
                        'Continue Lesson',
                        'Unit 3: Daily Conversations',
                        primaryColor,
                        onTap: () {
                          // Add navigation to lesson page if needed
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        Icons.mic,
                        'Pronunciation Practice',
                        'Work on your accent',
                        secondaryColor,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.pronunciation);
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        Icons.bar_chart,
                        'View Progress',
                        'See your achievements',
                        tertiaryColor,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.progress);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Today's Lessons Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(
                            Icons.book,
                            color: primaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Today\'s Lessons',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          _buildLessonItem(
                            'Greetings & Introductions',
                            '15 min',
                            'Complete',
                            secondaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildLessonItem(
                            'Asking for Directions',
                            '20 min',
                            'Start',
                            primaryText,
                          ),
                          const SizedBox(height: 12),
                          _buildLessonItem(
                            'Ordering Food',
                            '18 min',
                            'Start',
                            primaryText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Voice Commands Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          const Icon(
                            Icons.mic,
                            color: primaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Voice Commands',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Say "Continue lesson", "Practice pronunciation" or "Show progress" to navigate quickly.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Navigation Bar
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: secondaryBackground,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(Icons.home, 'Home', primaryColor, AppRoutes.home),
                      _buildNavItem(Icons.book, 'Lessons', secondaryText, AppRoutes.lessons),
                      _buildNavItem(Icons.volume_up, 'Practice', secondaryText, AppRoutes.pronunciation),
                      _buildNavItem(Icons.bar_chart, 'Progress', secondaryText, AppRoutes.progress),
                      _buildNavItem(Icons.settings, 'Settings', secondaryText, AppRoutes.settings),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF14181B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF57636C),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.volume_up,
                color: Color(0xFF57636C),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonItem(String title, String duration, String status, Color statusColor) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: const Color(0xFF14181B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF57636C),
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, Color color, String route) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushNamed(context, route);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}