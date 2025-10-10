import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Use theme colors instead of hardcoded colors
    final primaryBackground = theme.scaffoldBackgroundColor;
    final secondaryBackground = theme.cardColor;
    final primaryText = theme.textTheme.bodyLarge!.color!;
    final secondaryText = theme.textTheme.bodyMedium!.color!;
    final alternate = isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE0E3E7);

    // Keep your accent colors for charts and progress indicators
    const primaryColor = Color(0xFF4B39EF);
    const secondaryColor = Color(0xFF39D2C0);
    const tertiaryColor = Color(0xFFEE8B60);
    const accentColor = Color(0xFFFF5963);
    const successColor = Color(0xFF249689);
    const warningColor = Color(0xFFFFC107);
    const infoColor = Color(0xFF17C1E8);

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
          'Progress Dashboard',
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: primaryText,
          ),
        ),
        actions: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
              child: IconButton(
                iconSize: 40,
                icon: Icon(
                  Icons.settings,
                  color: primaryText,
                  size: 24,
                ),
                onPressed: () {
                  print('Settings button pressed');
                },
              ),
            ),
          ),
        ],
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        top: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: alternate,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Level: A2',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '68% toward B1',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: primaryText,
                                ),
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
                                  width: MediaQuery.of(context).size.width * 0.68,
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Progress: 68 percent complete toward B1 level',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color: warningColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '12 day streak',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: primaryText,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: infoColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '45h total time',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                      color: primaryText,
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
                ),

                // Weekly Activity Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: alternate,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Activity',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDayActivity('Monday: 2 sessions, 25 min, 88% accuracy'),
                              const SizedBox(height: 12),
                              _buildDayActivity('Tuesday: 1 session, 15 min, 92% accuracy'),
                              const SizedBox(height: 12),
                              _buildDayActivity('Wednesday: 3 sessions, 35 min, 85% accuracy'),
                              const SizedBox(height: 12),
                              _buildDayActivity('Thursday: 2 sessions, 28 min, 90% accuracy'),
                              const SizedBox(height: 12),
                              _buildDayActivity('Friday: 1 session, 20 min, 87% accuracy'),
                              const SizedBox(height: 12),
                              _buildDayActivity('Saturday: 2 sessions, 30 min, 94% accuracy'),
                              const SizedBox(height: 12),
                              _buildDayActivity('Sunday: 1 session, 18 min, 89% accuracy'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Skills Breakdown Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: alternate,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skills Breakdown',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView(
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.7,
                            ),
                            primary: false,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            children: [
                              _buildSkillCard(
                                Icons.headset,
                                'Listening',
                                'Current: A2',
                                'Next: B1 - Understand main points',
                                0.72,
                                primaryColor,
                              ),
                              _buildSkillCard(
                                Icons.mic,
                                'Speaking',
                                'Current: A2',
                                'Next: B1 - Express opinions clearly',
                                0.65,
                                secondaryColor,
                              ),
                              _buildSkillCard(
                                Icons.record_voice_over,
                                'Pronunciation',
                                'Current: A2',
                                'Next: B1 - Clear pronunciation',
                                0.58,
                                tertiaryColor,
                              ),
                              _buildSkillCard(
                                Icons.library_books,
                                'Vocabulary',
                                'Current: A2',
                                'Next: B1 - 2000+ words mastered',
                                0.78,
                                accentColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Achievements Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: alternate,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievements',
                            style: GoogleFonts.interTight(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAchievementCard(
                                Icons.emoji_events,
                                'First Week Complete',
                                'Completed 7 consecutive days of learning',
                                'Earned: December 15, 2024',
                                warningColor,
                              ),
                              const SizedBox(height: 12),
                              _buildAchievementCard(
                                Icons.star,
                                'Vocabulary Master',
                                'Learned 500 new words',
                                'Earned: December 10, 2024',
                                primaryColor,
                              ),
                              const SizedBox(height: 12),
                              _buildAchievementCard(
                                Icons.trending_up,
                                'Perfect Score',
                                'Achieved 100% accuracy in a lesson',
                                'Earned: December 8, 2024',
                                secondaryColor,
                              ),
                              const SizedBox(height: 12),
                              _buildAchievementCard(
                                Icons.speed,
                                'Speed Learner',
                                'Completed 10 lessons in one day',
                                'Earned: December 5, 2024',
                                tertiaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayActivity(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: const Color(0xFF14181B),
                  ),
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: Color(0xFF249689),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillCard(IconData icon, String title, String currentLevel, 
                         String nextLevel, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E3E7),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.interTight(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: const Color(0xFF14181B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                currentLevel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF57636C),
                ),
              ),
              Text(
                nextLevel,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF57636C),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E3E7),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * progress,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Progress: ${(progress * 100).toInt()}% complete',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF57636C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(IconData icon, String title, String description, 
                              String earnedDate, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF249689),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.interTight(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: const Color(0xFF14181B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF57636C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      earnedDate,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: const Color(0xFF249689),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}