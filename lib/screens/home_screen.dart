import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'template_screen.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/interactive_bounce.dart';
import '../widgets/app_snackbar.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _topicController = TextEditingController();
  int _slideCount = 10;
  final _formKey = GlobalKey<FormState>();
  bool _isPerfecting = false;
  String? _previousPrompt;

  @override
  void initState() {
    super.initState();
    _topicController.text = AppState.currentTopic;
    _slideCount = AppState.currentSlideCount;
    AppState.loadHistoryFromStorage();
  }

  void _perfectPrompt() async {
    final text = _topicController.text.trim();
    if (text.isEmpty) {
      showAppSnackBar(
        context,
        message: "Please enter a topic or prompt first to optimize it.",
        isError: true,
      );
      return;
    }

    setState(() {
      _isPerfecting = true;
      _previousPrompt = _topicController.text;
    });

    try {
      final perfected = await ApiService.perfectPrompt(prompt: text);
      
      if (mounted) {
        setState(() {
          _topicController.text = perfected;
          _isPerfecting = false;
        });
        
        showAppSnackBar(
          context,
          message: "Prompt optimized with AI!",
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPerfecting = false;
          _previousPrompt = null;
        });
        
        final appError = ErrorHandler.parse(e);
        showAppSnackBar(
          context,
          message: appError.message,
          isError: true,
        );
      }
    }
  }

  void _undoPerfectPrompt() {
    if (_previousPrompt != null) {
      setState(() {
        _topicController.text = _previousPrompt!;
        _previousPrompt = null;
      });
      showAppSnackBar(
        context,
        message: "Reverted to original prompt.",
      );
    }
  }

  final List<String> _suggestedTopics = [
    "Artificial Intelligence in 2026",
    "Clean Energy Transition",
    "Product Launch Pitch",
    "Deep Tech Investment Thesis",
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      AppState.currentTopic = _topicController.text.trim();
      AppState.currentSlideCount = _slideCount;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateScreen(
            topic: AppState.currentTopic,
            slideCount: AppState.currentSlideCount,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "SlideAI",
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0),
        centerTitle: false,
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
          InteractiveBounce(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Generate a presentation first to export!")),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.file_upload_outlined, color: AppColors.primaryLight, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "Export",
                      style: GoogleFonts.inter(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient leaks in brand orange with subtle pulsing animation
          Positioned(
            top: -150,
            left: -100,
            width: 450,
            height: 450,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryContainer.withValues(alpha: 0.8), Colors.transparent],
                  radius: 0.5,
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.0, end: 1.08, duration: 4000.ms, curve: Curves.easeInOut),
          Positioned(
            bottom: -150,
            right: -100,
            width: 400,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryContainer.withValues(alpha: 0.5), Colors.transparent],
                  radius: 0.5,
                ),
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scaleXY(begin: 1.08, end: 1.0, duration: 4500.ms, curve: Curves.easeInOut),

          // Scrollable main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Pill Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Next-Gen AI Deck Generator",
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 14),

                    // Heading Section
                    Text(
                      "Create stunning presentations in seconds.",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 450.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      "Enter your topic or outline. SlideAI creates slides with tailored layouts, typography, and imagery.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ).animate().fadeIn(delay: 150.ms, duration: 450.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 28),

                    // Glassmorphic interactive form area
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(22.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.surfaceBorder,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Topic Input Label
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Topic or Detailed Prompt",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    "Required",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // TextFormField styled as glass input
                              TextFormField(
                                controller: _topicController,
                                maxLines: 3,
                                minLines: 2,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Please enter a valid presentation topic or prompt.";
                                  }
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: "e.g. Future of Quantum Computing, or pitch deck for a SaaS startup...",
                                  alignLabelWithHint: true,
                                  fillColor: AppColors.inputFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Perfect Prompt & Undo actions
                              Row(
                                children: [
                                  InteractiveBounce(
                                    onTap: _isPerfecting ? null : _perfectPrompt,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isPerfecting
                                            ? AppColors.inputFill
                                            : AppColors.primaryContainer,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _isPerfecting
                                              ? AppColors.surfaceBorder
                                              : AppColors.primaryBorder,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isPerfecting) ...[
                                            const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ] else ...[
                                            const Icon(
                                              Icons.auto_fix_high_rounded,
                                              color: AppColors.primary,
                                              size: 15,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            _isPerfecting ? "Perfecting..." : "Perfect Prompt",
                                            style: GoogleFonts.inter(
                                              color: AppColors.primary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_previousPrompt != null) ...[
                                    const SizedBox(width: 8),
                                    InteractiveBounce(
                                      onTap: _undoPerfectPrompt,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceBorderSubtle,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.surfaceBorder,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.undo_rounded,
                                              color: AppColors.textSecondary,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Undo",
                                              style: GoogleFonts.inter(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Quick Inspiration Chips Label
                              Text(
                                "Quick Inspiration",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Suggestions Chips with stagger
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(_suggestedTopics.length, (index) {
                                  final topic = _suggestedTopics[index];
                                  return InteractiveBounce(
                                    scaleFactor: 0.94,
                                    onTap: () {
                                      setState(() {
                                        _topicController.text = topic;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryContainer.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.primaryBorder,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.lightbulb_outline_rounded,
                                            color: AppColors.primary,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            topic,
                                            style: GoogleFonts.inter(
                                              color: AppColors.primaryDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ).animate().fadeIn(
                                    delay: (200 + index * 50).ms,
                                    duration: 350.ms,
                                  ).slideX(begin: 0.1, end: 0);
                                }),
                              ),
                              const SizedBox(height: 28),

                              // Slide Count Label / Value Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.view_carousel_outlined,
                                        color: AppColors.textSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Slide Deck Length",
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      "$_slideCount slides",
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Quick Slide Count Preset Pills
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [5, 8, 10, 15, 20].map((preset) {
                                  final isCurrent = _slideCount == preset;
                                  return InteractiveBounce(
                                    scaleFactor: 0.9,
                                    onTap: () {
                                      setState(() {
                                        _slideCount = preset;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? AppColors.primary
                                            : AppColors.surfaceBorderSubtle,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isCurrent
                                              ? AppColors.primaryLight
                                              : AppColors.surfaceBorder,
                                        ),
                                      ),
                                      child: Text(
                                        "$preset",
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                          color: isCurrent ? Colors.white : AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),

                              // Slide Count Slider with customized styles
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6,
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.surfaceBorder,
                                  thumbColor: AppColors.primary,
                                  overlayColor: AppColors.primaryContainer,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                                ),
                                child: Slider(
                                  value: _slideCount.toDouble(),
                                  min: 4,
                                  max: 20,
                                  divisions: 16,
                                  onChanged: (double val) {
                                    setState(() {
                                      _slideCount = val.round();
                                    });
                                  },
                                ),
                              ),
                              
                              // Slider label indicators
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Concise (4)",
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      "In-Depth (20)",
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Glowing Action Button
                              InteractiveBounce(
                                scaleFactor: 0.97,
                                onTap: _submit,
                                child: Container(
                                  width: double.infinity,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryDark],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.45),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "CHOOSE DESIGN TEMPLATE",
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms).scale(
                      begin: const Offset(0.97, 0.97),
                      end: const Offset(1, 1),
                      curve: Curves.easeOutBack,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 1),
    );
  }
}
