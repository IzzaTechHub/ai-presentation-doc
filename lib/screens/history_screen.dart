import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/slide_model.dart';
import '../models/template_model.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/interactive_bounce.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import 'editor_screen.dart';
import 'home_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  void _initHistory() async {
    await AppState.loadHistoryFromStorage();
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _loadPresentation(Map<String, dynamic> item) {
    // Parse slides
    final slidesJson = item['slides'] as List<dynamic>;
    final slides = slidesJson.map((s) => SlideModel.fromJson(s)).toList();

    // Parse template
    final templateJson = item['templateJson'] as Map<String, dynamic>;
    final template = TemplateModel.fromJson(templateJson);

    // Save globally
    AppState.activeSlides = slides;
    AppState.selectedTemplate = template;
    AppState.currentTopic = item['topic'] ?? '';
    AppState.currentSlideCount = slides.length;

    // Navigate to Editor (Tab 2)
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => EditorScreen(
          initialSlides: slides,
          selectedTemplate: template,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  void _deleteHistoryItem(String id) async {
    setState(() {
      AppState.history.removeWhere((item) => item['id'] == id);
    });
    await AppState.saveHistoryToStorage();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Presentation removed from history")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Presentation History",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: AppColors.surfaceBorder,
            width: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient leaks in soft brand orange
          Positioned(
            top: -150,
            left: -100,
            width: 400,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryContainer.withValues(alpha: 0.8), Colors.transparent],
                  radius: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            width: 350,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryContainer.withValues(alpha: 0.5), Colors.transparent],
                  radius: 0.5,
                ),
              ),
            ),
          ),
          // Main Body
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : AppState.history.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryList(),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 0),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBorder, width: 1.5),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                color: AppColors.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "No presentations yet",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your generated presentations will automatically be preserved in your vault.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            InteractiveBounce(
              scaleFactor: 0.95,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const HomeScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                  (route) => false,
                );
              },
              child: Container(
                width: 200,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Create Presentation",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      itemCount: AppState.history.length,
      itemBuilder: (context, index) {
        final item = AppState.history[index];
        final id = item['id'] as String;
        final topic = item['topic'] as String? ?? "Untitled";
        final slideCount = item['slideCount'] as int? ?? 0;
        final templateName = item['templateName'] as String? ?? "Default";
        
        final timestampStr = item['timestamp'] as String?;
        String formattedDate = "Recently";
        if (timestampStr != null) {
          try {
            final date = DateTime.parse(timestampStr);
            final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            final period = date.hour >= 12 ? "PM" : "AM";
            final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
            final minute = date.minute.toString().padLeft(2, '0');
            formattedDate = "${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute $period";
          } catch (_) {}
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: InteractiveBounce(
            scaleFactor: 0.98,
            onTap: () => _loadPresentation(item),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.slideshow_rounded, color: AppColors.primary, size: 24),
                ),
                title: Text(
                  topic,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "$slideCount slides  •  $templateName style",
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                  onPressed: () => _deleteHistoryItem(id),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(
          delay: (index * 60).ms,
          duration: 350.ms,
        ).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
      },
    );
  }
}
