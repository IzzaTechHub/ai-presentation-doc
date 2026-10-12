import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'template_screen.dart';
import '../widgets/floating_bottom_bar.dart';
import '../services/app_state.dart';
import '../services/api_service.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a topic or prompt to perfect!"),
          backgroundColor: Color(0xFFE53935),
        ),
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Prompt optimized with AI!"),
            backgroundColor: Color(0xFF43A047),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPerfecting = false;
          _previousPrompt = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to perfect prompt: ${e.toString().replaceAll("Exception: ", "")}"),
            backgroundColor: const Color(0xFFE53935),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reverted to original prompt."),
          backgroundColor: Color(0xFF757575),
        ),
      );
    }
  }


  // Premium feature: suggest sample topics that fill the text field on click
  final List<String> _suggestedTopics = [
    "Artificial Intelligence",
    "Climate Change",
    "Marketing Pitch",
    "History of Space",
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
        ),
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
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Generate a presentation first to export!")),
              );
            },
            child: Text(
              "Export",
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient leaks (Radial glow circles in orange)
          Positioned(
            top: -150,
            left: -100,
            width: 450,
            height: 450,
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
            width: 400,
            height: 400,
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
          // Scrollable main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading Section
                    Text(
                      "Create stunning presentations in seconds.",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Enter a topic and select the template style to automatically generate custom PowerPoint decks.",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFFCBC3D7),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Glassmorphic interactive form area
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.surfaceBorder,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Topic Input Label
                              Text(
                                "Topic or Detailed Prompt",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
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
                                  hintText: "e.g. Enter a topic, or type a custom prompt and click 'Perfect Prompt' below...",
                                  alignLabelWithHint: true,
                                  fillColor: AppColors.inputFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Perfect Prompt & Undo actions
                              Row(
                                children: [
                                  GestureDetector(
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
                                              ? Colors.white10
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
                                          ],
                                          Text(
                                            _isPerfecting ? "Perfecting..." : "Perfect Prompt",
                                            style: GoogleFonts.inter(
                                              color: AppColors.primaryLight,
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
                                    GestureDetector(
                                      onTap: _undoPerfectPrompt,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0x1F757575), // Soft translucent gray bg
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1.0,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.undo_rounded,
                                              color: Colors.white70,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "Undo",
                                              style: GoogleFonts.inter(
                                                color: Colors.white70,
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
                              const SizedBox(height: 16),

                              // Suggestions Chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _suggestedTopics.map((topic) {
                                  return ActionChip(
                                    label: Text(
                                      topic,
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF5DE6FF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    backgroundColor: const Color(0x1F5DE6FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: const BorderSide(color: Color(0x335DE6FF), width: 1),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    onPressed: () {
                                      setState(() {
                                        _topicController.text = topic;
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 32),

                              // Slide Count Label / Value Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Number of Slides",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    "$_slideCount",
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Slide Count Slider with customized styles
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6,
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
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
                                      "Brief (4)",
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      "Comprehensive (20)",
                                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 36),

                              // Gradient "Choose Design Template" Action Button
                              GestureDetector(
                                onTap: _submit,
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.primary, AppColors.primaryDark],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      )
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
