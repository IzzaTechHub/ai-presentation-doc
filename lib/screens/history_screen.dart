import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/slide_model.dart';
import '../models/template_model.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/interactive_bounce.dart';
import '../widgets/app_snackbar.dart';
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
    try {
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
    } catch (_) {
      showAppSnackBar(
        context,
        message: "Unable to load presentation. Saved format might be corrupted.",
        isError: true,
      );
    }
  }

  void _deleteHistoryItem(String id) async {
    setState(() {
      AppState.history.removeWhere((item) => item['id'] == id);
    });
    await AppState.saveHistoryToStorage();
    if (mounted) {
      showAppSnackBar(
        context,
        message: "Presentation removed from history.",
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
        actions: [
          if (AppState.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary, size: 22),
                tooltip: "Clear All History",
                onPressed: _clearAllHistory,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : AppState.history.isEmpty
                ? _buildEmptyState()
                : _buildHistoryList(),
      ),
      bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 0),
    );
  }

  void _clearAllHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              "Clear History?",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete all saved presentations from your vault? This cannot be undone.",
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                AppState.history.clear();
              });
              await AppState.saveHistoryToStorage();
              if (mounted) {
                showAppSnackBar(
                  context,
                  message: "All presentations removed from history.",
                );
              }
            },
            child: Text(
              "Clear All",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "Delete Deck",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$topic" from your presentation history?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteHistoryItem(id);
            },
            child: Text(
              "Delete",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseHex(String? hexColor, {Color fallback = const Color(0xFF1E293B)}) {
    if (hexColor == null || hexColor.isEmpty) return fallback;
    try {
      String formatted = hexColor.replaceAll('#', '').trim();
      if (formatted.length == 6) {
        formatted = 'FF$formatted';
      } else if (formatted.length == 8) {
        // Already 8 characters
      } else if (formatted.length == 3) {
        formatted = 'FF${formatted[0]}${formatted[0]}${formatted[1]}${formatted[1]}${formatted[2]}${formatted[2]}';
      } else {
        return fallback;
      }
      return Color(int.parse(formatted, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  String _formatDate(String? timestampStr) {
    if (timestampStr == null) return "Recently";
    try {
      final date = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return "Just now";
      } else if (diff.inHours < 1) {
        return "${diff.inMinutes}m ago";
      } else if (diff.inDays < 1) {
        return "${diff.inHours}h ago";
      } else if (diff.inDays < 7) {
        return "${diff.inDays}d ago";
      } else {
        final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return "${months[date.month - 1]} ${date.day}, ${date.year}";
      }
    } catch (_) {
      return "Recently";
    }
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
    return CustomScrollView(
      slivers: [
        // Top summary header bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.view_carousel_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Saved Decks (${AppState.history.length})",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "Tap any slide card to open or edit",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 2-Column Visual Grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.69,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = AppState.history[index];
                return _buildHistoryCard(item, index);
              },
              childCount: AppState.history.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, int index) {
    final id = item['id'] as String;
    final topic = item['topic'] as String? ?? "Untitled";
    final slideCount = item['slideCount'] as int? ?? 0;
    final templateName = item['templateName'] as String? ?? "Default";
    final templateId = (item['templateId'] as String? ?? '').toLowerCase();
    final templateLower = templateName.toLowerCase();

    // Extract template colors
    final templateJson = item['templateJson'] as Map<String, dynamic>?;
    final colorsJson = templateJson?['colors'] as Map<String, dynamic>?;

    String? bgHex = colorsJson?['background'];
    String? bgStartHex = colorsJson?['backgroundStart'];
    String? bgEndHex = colorsJson?['backgroundEnd'];
    String? titleHex = colorsJson?['title'];
    String? bodyHex = colorsJson?['body'];
    String? accentHex = colorsJson?['accent'];

    // Authentic template fallbacks & violet recognition
    if (bgHex == null && bgStartHex == null) {
      if (templateId.contains('violet') || templateLower.contains('violet') || templateLower.contains('purple')) {
        bgStartHex = '#2E1065';
        bgEndHex = '#1E1B4B';
        accentHex = '#A855F7';
        titleHex = '#FAF5FF';
        bodyHex = '#E9D5FF';
      } else if (templateId.contains('tech') || templateLower.contains('tech')) {
        bgHex = '#0B0F19';
        accentHex = '#06B6D4';
        titleHex = '#F8FAFC';
        bodyHex = '#94A3B8';
      } else if (templateId.contains('organic') || templateLower.contains('organic')) {
        bgHex = '#064E3B';
        accentHex = '#10B981';
        titleHex = '#F0FDF4';
        bodyHex = '#A7F3D0';
      } else if (templateId.contains('editorial') || templateLower.contains('editorial')) {
        bgHex = '#18181B';
        accentHex = '#F59E0B';
        titleHex = '#FEF3C7';
        bodyHex = '#D4D4D8';
      } else {
        bgStartHex = '#1E293B';
        bgEndHex = '#0F172A';
        accentHex = '#FF5722';
        titleHex = '#FFFFFF';
        bodyHex = '#CBD5E1';
      }
    }

    final bg = _parseHex(bgHex, fallback: const Color(0xFF1E293B));
    final bgStart = bgStartHex != null ? _parseHex(bgStartHex) : null;
    final bgEnd = bgEndHex != null ? _parseHex(bgEndHex) : null;
    final titleColor = _parseHex(titleHex, fallback: Colors.white);
    final bodyColor = _parseHex(bodyHex, fallback: const Color(0xFFCBD5E1));
    final accentColor = _parseHex(accentHex, fallback: AppColors.primary);

    // Extract first slide
    final slidesRaw = item['slides'] as List<dynamic>? ?? [];
    Map<String, dynamic>? firstSlide;
    if (slidesRaw.isNotEmpty && slidesRaw.first is Map<String, dynamic>) {
      firstSlide = slidesRaw.first as Map<String, dynamic>;
    }

    final formattedDate = _formatDate(item['timestamp'] as String?);

    return InteractiveBounce(
      scaleFactor: 0.97,
      onTap: () => _loadPresentation(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surfaceBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 16:9 Presentation Slide Preview on Top
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildMiniSlidePreview(
                bg: bg,
                bgStart: bgStart,
                bgEnd: bgEnd,
                titleColor: titleColor,
                bodyColor: bodyColor,
                accentColor: accentColor,
                topic: topic,
                firstSlide: firstSlide,
              ),
            ),

            // Card Bottom Metadata & Actions
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Deck Title & Metadata Chips
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          topic,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _buildMiniBadge(
                              label: "$slideCount slides",
                              icon: Icons.layers_outlined,
                              color: AppColors.primary,
                              bgColor: AppColors.primaryContainer,
                            ),
                            _buildMiniBadge(
                              label: templateName,
                              icon: null,
                              color: accentColor,
                              bgColor: accentColor.withValues(alpha: 0.12),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Timestamp & Delete Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InteractiveBounce(
                          scaleFactor: 0.88,
                          onTap: () => _confirmDelete(context, id, topic),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: AppColors.errorContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppColors.error,
                              size: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: (index * 45).ms,
      duration: 320.ms,
    ).scale(
      begin: const Offset(0.96, 0.96),
      end: const Offset(1, 1),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildMiniSlidePreview({
    required Color bg,
    Color? bgStart,
    Color? bgEnd,
    required Color titleColor,
    required Color bodyColor,
    required Color accentColor,
    required String topic,
    Map<String, dynamic>? firstSlide,
  }) {
    final slideTitle = (firstSlide?['title'] as String? ?? '').trim().isNotEmpty
        ? (firstSlide!['title'] as String)
        : topic;
    final bullets = (firstSlide?['bullets'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final hasImage = (firstSlide?['imageUrl'] as String? ?? '').isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: bgStart != null && bgEnd != null
            ? LinearGradient(
                colors: [bgStart, bgEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: bgStart == null ? bg : null,
      ),
      child: Stack(
        children: [

          // Slide Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top header row: "AI DECK" pill & "16:9" ratio badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "DECK",
                            style: GoogleFonts.inter(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        "16:9",
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Slide Title
                Text(
                  slideTitle,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                // Accent Underline Bar
                Container(
                  width: 18,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                const SizedBox(height: 5),

                // Miniature Bullets preview or layout representation
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: hasImage ? 3 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (bullets.isNotEmpty) ...[
                              _buildMiniBulletItem(bullets[0], bodyColor, accentColor),
                              if (bullets.length > 1) ...[
                                const SizedBox(height: 3),
                                _buildMiniBulletItem(bullets[1], bodyColor, accentColor),
                              ],
                            ] else ...[
                              // Skeleton preview bars
                              Container(
                                height: 3.5,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: bodyColor.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Container(
                                height: 3.5,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: bodyColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (hasImage) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.image_outlined,
                            size: 13,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom subtle border divider separating slide preview from card body
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBulletItem(String text, Color bodyColor, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 7.5,
              color: bodyColor.withValues(alpha: 0.85),
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge({
    required String label,
    IconData? icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
