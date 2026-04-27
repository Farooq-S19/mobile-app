import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/constants.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  _AboutAppScreenState createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: AppBar(
          title: Text(
            "About",
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, "About the App"),
              const SizedBox(height: 8),
              _aboutPoint(context, "Real-time tomato leaf disease detection using EfficientNet-B0 optimized for smartphones."),
              _aboutPoint(context, "Provides instant diagnosis with high accuracy, helping farmers take faster actions."),
              _aboutPoint(context, "Reduces dependency on expert visits and minimizes crop loss."),
              _aboutPoint(context, "Supports offline prediction mode."),
              _aboutPoint(context, "Built with modern, mobile-first UI for rural users."),
              _aboutPoint(context, "Analytics dashboard with confidence score and scan history."),
              
              const SizedBox(height: 20),
              _sectionTitle(context, "How to Use"),
              const SizedBox(height: 4),
              _aboutStep(context, "Open scanner and point camera at tomato leaf."),
              _aboutStep(context, "Ensure leaf fits in frame for best accuracy."),
              _aboutStep(context, "Tap scan button and wait for processing."),
              _aboutStep(context, "View disease name, confidence, and remedies."),
              _aboutStep(context, "Save result to history or rescan another leaf."),
              
              const SizedBox(height: 20),
              _sectionTitle(context, "Developer"),
              const SizedBox(height: 8),

              // Single Developer - Krishna Vamsi (Both App & ML)
              _devCard(
                context,
                "Krishna Vamsi",
                "Full Stack Developer",
                "Designed and developed the complete mobile application interface for capturing and uploading leaf images. Integrated the disease detection system and organized disease information. Also developed and trained the deep learning model for detecting tomato leaf diseases, optimized for accurate classification and seamless mobile integration.",
                LucideIcons.user,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Text(
      t,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _aboutPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.chevronRight, color: AppColors.emerald, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.lightTextSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutStep(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(LucideIcons.dot, color: AppColors.emerald, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.lightTextTertiary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _devCard(BuildContext context, String name, String role, String desc, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.15)
              : const Color(0x1A000000),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.25)
                : const Color(0x1A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.emerald, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w600
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.lightTextSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}