import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/slide_model.dart';
import '../models/template_model.dart';
import '../widgets/floating_bottom_bar.dart';
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
          // Background ambient leaks in brand orange
          Positioned(
            top: -150,
            left: -100,
            width: 400,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryContainer, Colors.transparent],
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1FFF5722), Colors.transparent],
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
            const Icon(
              Icons.history_toggle_off_rounded,
              color: Color(0xFFCBC3D7),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "No history yet",
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your generated presentations will automatically be saved to history.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFFCBC3D7).withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
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
              child: Text(
                "Create Presentation",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: AppState.history.length,
      itemBuilder: (context, index) {
        final item = AppState.history[index];
        final id = item['id'] as String;
        final topic = item['topic'] as String? ?? "Untitled";
        final slideCount = item['slideCount'] as int? ?? 0;
        final templateName = item['templateName'] as String? ?? "Default";
        
        // Parse time dynamically using custom formatter to avoid package dependencies
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

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: 1.0,
            ),
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
                color: Colors.white,
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
                    color: const Color(0xFFCBC3D7).withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBC3D7).withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFFB4AB), size: 20),
              onPressed: () => _deleteHistoryItem(id),
            ),
            onTap: () => _loadPresentation(item),
          ),
        );
      },
    );
  }
}
