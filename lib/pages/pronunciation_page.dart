import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_routes.dart';

class PronunciationPage extends StatefulWidget {
  const PronunciationPage({super.key});

  @override
  State<PronunciationPage> createState() => _PronunciationPageState();
}

class _PronunciationPageState extends State<PronunciationPage> {
  // Define colors similar to FlutterFlow theme
  final Color primaryColor = const Color(0xFF4B39EF);
  final Color secondaryColor = const Color(0xFF39D2C0);
  final Color tertiaryColor = const Color(0xFFEE8B60);
  final Color accentColor = const Color(0xFFFF5963);
  
  final Color primaryBackground = const Color(0xFFF1F4F8);
  final Color secondaryBackground = const Color(0xFFFFFFFF);
  final Color primaryText = const Color(0xFF14181B);
  final Color secondaryText = const Color(0xFF57636C);
  final Color alternate = const Color(0xFFE0E3E7);

  bool _isRecording = false;
  bool _audioContextEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBackground,
      appBar: AppBar(
        backgroundColor: primaryBackground,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'TalkWise',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: primaryText,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: primaryText),
            onPressed: () {
              print('Search button pressed');
            },
          ),
        ],
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lesson header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Conversations',
                      style: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unit 3 • Level A2',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress indicator
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exercise 1 of 3',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: primaryText,
                            ),
                          ),
                          Text(
                            '60% Complete',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: 0.6,
                        backgroundColor: alternate,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              const Divider(height: 1, color: Color(0xFFE0E3E7)),
              const SizedBox(height: 24),

              // New Vocabulary section
              Text(
                'New Vocabulary',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Listen to the word and its meaning, then repeat it.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // Word card
              Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Restaurant',
                          style: GoogleFonts.interTight(
                            fontWeight: FontWeight.w600,
                            fontSize: 28,
                            color: primaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '/ˈrestərənt/',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'A place where people pay to sit and eat meals that are cooked and served on the premises.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: primaryText,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Audio context toggle
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.headset_rounded,
                            color: primaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Audio Context',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sound of cutlery and dining atmosphere',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Switch(
                            value: _audioContextEnabled,
                            onChanged: (value) {
                              setState(() {
                                _audioContextEnabled = value;
                              });
                            },
                            activeColor: primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _audioContextEnabled ? 'Enabled' : 'Disabled',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    print('Play Audio button pressed');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Play Audio',
                        style: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isRecording = !_isRecording;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? accentColor : primaryText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecording ? 'Stop Recording' : 'Tap to Record Your Response',
                        style: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Bottom navigation
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: secondaryBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_rounded, 'Home', secondaryText, AppRoutes.home),
                    _buildNavItem(Icons.menu_book_rounded, 'Lessons', secondaryText, AppRoutes.lessons),
                    _buildNavItem(Icons.volume_up_rounded, 'Practice', primaryColor, AppRoutes.pronunciation),
                    _buildNavItem(Icons.bar_chart_rounded, 'Progress', secondaryText, AppRoutes.progress),
                    _buildNavItem(Icons.settings_rounded, 'Settings', secondaryText, AppRoutes.settings),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, Color color, String route) {
    return GestureDetector(
      onTap: () {
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
