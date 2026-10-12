import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../models/template_model.dart';
import '../services/api_service.dart';
import '../services/app_state.dart';
import '../widgets/floating_bottom_bar.dart';
import '../widgets/interactive_bounce.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

class TemplateScreen extends StatefulWidget {
  final String topic;
  final int slideCount;

  const TemplateScreen({
    super.key,
    required this.topic,
    required this.slideCount,
  });

  @override
  State<TemplateScreen> createState() => _TemplateScreenState();
}

class _TemplateScreenState extends State<TemplateScreen> {
  late Future<List<TemplateModel>> _templatesFuture;
  TemplateModel? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _templatesFuture = ApiService.fetchTemplates();
  }

  // Parse CSS hex string (e.g. #0B192C) to Flutter Color
  Color _parseHex(String hexColor) {
    String formatted = hexColor.replaceAll('#', '');
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    return Color(int.parse(formatted, radix: 16));
  }

  void _generateSlides() async {
    if (_selectedTemplate == null) return;

    // Show elite multi-phase futuristic loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _GenerationProgressDialog();
      },
    );

    try {
      // Call endpoint to generate slide content structure
      final slides = await ApiService.generateSlides(
        topic: widget.topic,
        slideCount: widget.slideCount,
      );

      // Save presentation to global AppState
      AppState.activeSlides = slides;
      AppState.selectedTemplate = _selectedTemplate!;

      // Add presentation to local history storage
      await AppState.addPresentationToHistory(
        topic: widget.topic,
        slides: slides,
        template: _selectedTemplate!,
      );

      // Dismiss dialog
      if (mounted) Navigator.pop(context);

      // Navigate to EditorScreen, clearing navigation history so it acts as root
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => EditorScreen(
              initialSlides: slides,
              selectedTemplate: _selectedTemplate!,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Dismiss dialog
      if (mounted) Navigator.pop(context);

      // Show alert error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              "Generation Failed",
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            content: Text(
              e.toString().replaceAll("Exception: ", ""),
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Choose Template",
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
          ),
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
          ),
          // Main layout content
          Column(
            children: [
              // Header descriptive prompt
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select a design style for \"${widget.topic}\"",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "The layout rules, background tones, typography settings, and accents of your chosen template will apply to all slides.",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              // Main picker Grid
              Expanded(
                child: FutureBuilder<List<TemplateModel>>(
                  future: _templatesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildShimmerGrid();
                    } else if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "No design templates available.",
                          style: GoogleFonts.inter(color: const Color(0xFFCBC3D7)),
                        ),
                      );
                    }

                    final templates = snapshot.data!;
                    
                    // Automatically select first template if none is selected
                    _selectedTemplate ??= templates.first;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        final isSelected = _selectedTemplate?.id == template.id;

                        return TemplateListItem(
                          template: template,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedTemplate = template;
                            });
                          },
                          parseHex: _parseHex,
                          topic: widget.topic,
                        ).animate().fadeIn(
                          delay: (index * 70).ms,
                          duration: 400.ms,
                        ).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
                      },
                    );
                  },
                ),
              ),

              // Bottom Action Button with premium gradient background & InteractiveBounce
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: InteractiveBounce(
                  scaleFactor: 0.97,
                  onTap: _selectedTemplate != null ? _generateSlides : null,
                  child: Opacity(
                    opacity: _selectedTemplate != null ? 1.0 : 0.6,
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
                        boxShadow: _selectedTemplate != null
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "USE THIS TEMPLATE",
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
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 1),
    );
  }

  // Shimmer Loader List for fetching templates state
  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0),
      highlightColor: const Color(0xFFF8FAFC),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  // Error fetching state UI
  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              "Unable to load templates",
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceAll("Exception: ", ""),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 44),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _templatesFuture = ApiService.fetchTemplates();
                });
              },
              child: Text(
                "Retry Connection",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TemplateListItem extends StatelessWidget {
  final TemplateModel template;
  final bool isSelected;
  final VoidCallback onTap;
  final Color Function(String) parseHex;
  final String topic;

  const TemplateListItem({
    super.key,
    required this.template,
    required this.isSelected,
    required this.onTap,
    required this.parseHex,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    final bg = parseHex(template.colors.background);
    final titleColor = parseHex(template.colors.title);
    final bodyColor = parseHex(template.colors.body);
    final accentColor = parseHex(template.colors.accent);

    final titleFont = template.fonts.title.name ?? "Segoe UI";
    final bodyFont = template.fonts.body.name ?? "Arial";

    // Dynamic style subtitle
    String styleSubtitle = "";
    switch (template.style) {
      case 'tech':
        styleSubtitle = "Tech Style • Neon Accent & Sharp Borders";
        break;
      case 'minimal':
        styleSubtitle = "Minimalist Style • Clean & Spacious Layout";
        break;
      case 'organic':
        styleSubtitle = "Organic Style • Quote Left Bar & Soft Cards";
        break;
      case 'editorial':
        styleSubtitle = "Classic Editorial Style • Gold Accent & Centered";
        break;
      case 'vibrant':
        styleSubtitle = "Vibrant Style • Playful Pill & Rounded Panels";
        break;
      default:
        styleSubtitle = "${template.name} Styled Presentation";
    }

    final isEditorial = template.style == 'editorial';

    // Accent line or underlines
    Widget accentLine;
    if (template.style == 'minimal') {
      accentLine = const SizedBox(height: 4);
    } else if (template.style == 'organic') {
      accentLine = const SizedBox(height: 6);
    } else if (template.style == 'tech') {
      accentLine = Container(
        margin: const EdgeInsets.only(top: 4, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 2, color: accentColor),
            const SizedBox(height: 1),
            Container(width: 20, height: 1, color: const Color(0xFF5DE6FF)),
          ],
        ),
      );
    } else if (template.style == 'editorial') {
      accentLine = Container(
        margin: const EdgeInsets.only(top: 4, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 40, height: 1, color: accentColor),
            const SizedBox(height: 2),
            Container(width: 25, height: 1, color: accentColor),
          ],
        ),
      );
    } else {
      // vibrant / default
      accentLine = Container(
        width: 40,
        height: 3,
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(1.5),
        ),
        margin: const EdgeInsets.only(top: 4, bottom: 6),
      );
    }

    // Title row with possible left quote bar (organic)
    Widget titleWidget = Row(
      mainAxisAlignment: isEditorial ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (template.style == 'organic') ...[
          Container(
            width: 2,
            height: 12,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(0.5),
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            "Designing Future AI",
            style: _getSafeGoogleFont(
              titleFont,
              textStyle: TextStyle(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: isEditorial ? TextAlign.center : TextAlign.left,
          ),
        ),
      ],
    );

    // Bullets list builder
    Widget bulletsList = Column(
      children: [
        _buildMockBullet(bodyFont, bodyColor, accentColor, "Context-specific Unsplash photos", template.style),
        const SizedBox(height: 4),
        _buildMockBullet(bodyFont, bodyColor, accentColor, "Professional slide structure layouts", template.style),
      ],
    );

    if (template.style == 'tech') {
      bulletsList = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 0.8),
        ),
        child: bulletsList,
      );
    } else if (template.style == 'vibrant') {
      bulletsList = Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withValues(alpha: 0.12), width: 0.6),
        ),
        child: bulletsList,
      );
    }

    // Right Side Photo Mockup (representing title_image_right layout)
    double imageRadius = 6.0;
    if (template.style == 'vibrant') {
      imageRadius = 10.0;
    } else if (template.style == 'organic') {
      imageRadius = 8.0;
    } else if (template.style == 'tech') {
      imageRadius = 0.0; // sharp corners
    }

    final cleanTopic = topic
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .take(3)
        .join(',');

    final imageUrl = cleanTopic.isNotEmpty
        ? 'https://loremflickr.com/300/200/$cleanTopic?lock=${topic.hashCode.abs()}'
        : 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=300&q=80';

    Widget imageWidget = Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(imageRadius),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: template.style == 'tech' ? 1.5 : 1,
          style: BorderStyle.solid,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(imageRadius > 0 ? imageRadius - 1 : 0),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
              Icons.image_outlined,
              color: accentColor.withValues(alpha: 0.8),
              size: 24,
            ),
          ),
        ),
      ),
    );

    return InteractiveBounce(
      scaleFactor: 0.98,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          styleSubtitle,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Dynamic 16:9 Presentation Slide Preview Container
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: template.colors.backgroundStart != null && template.colors.backgroundEnd != null
                        ? LinearGradient(
                            colors: [
                              parseHex(template.colors.backgroundStart!),
                              parseHex(template.colors.backgroundEnd!),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: template.colors.backgroundStart == null ? bg : null,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative background textures matching PowerPoint
                      if (template.style == 'editorial') ...[
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          bottom: 6,
                          right: 8,
                          width: 2,
                          child: Container(
                            color: accentColor.withValues(alpha: 0.2),
                          ),
                        ),
                      ] else if (template.style == 'vibrant') ...[
                        Positioned(
                          top: -20,
                          left: -20,
                          width: 60,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withValues(alpha: 0.09),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -20,
                          right: -20,
                          width: 60,
                          height: 60,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor.withValues(alpha: 0.07),
                            ),
                          ),
                        ),
                      ] else if (template.style == 'tech') ...[
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: titleColor.withValues(alpha: 0.25),
                                width: 0.6,
                              ),
                            ),
                          ),
                        ),
                        // Corner brackets
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(width: 10, height: 1.5, color: titleColor),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(width: 1.5, height: 10, color: titleColor),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(width: 10, height: 1.5, color: titleColor),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(width: 1.5, height: 10, color: titleColor),
                        ),
                      ],

                      // Inner Layout elements
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Text Content
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: isEditorial ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                children: [
                                  titleWidget,
                                  accentLine,
                                  const SizedBox(height: 6),
                                  bulletsList,
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Right Side Photo Mockup (representing title_image_right layout)
                            Expanded(
                              flex: 3,
                              child: imageWidget,
                            ),
                          ],
                        ),
                      ),
                      // "Preview" watermark tag
                      Positioned(
                        bottom: 6,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "MOCK SLIDE",
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bottom details row containing Color Swatches & Layout Capabilities
              Row(
                children: [
                  Text(
                    "Palette: ",
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Color Swatches
                  _buildSwatch(bg, "Background"),
                  _buildSwatch(titleColor, "Title"),
                  _buildSwatch(bodyColor, "Body"),
                  _buildSwatch(accentColor, "Accent"),
                  const Spacer(),
                  // Layout capabilities chips/icons
                  Row(
                    children: [
                      _buildCapabilityIcon(Icons.slideshow, "Title"),
                      _buildCapabilityIcon(Icons.format_list_bulleted, "Bullets"),
                      _buildCapabilityIcon(Icons.view_column_outlined, "Columns"),
                      _buildCapabilityIcon(Icons.image_outlined, "Photos"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockBullet(String font, Color color, Color accent, String text, String archetype) {
    IconData icon = Icons.check_circle;
    double iconSize = 8.0;
    if (archetype == 'tech') {
      icon = Icons.check_box_outline_blank_rounded;
      iconSize = 8.0;
    } else if (archetype == 'editorial') {
      icon = Icons.stop_rounded;
      iconSize = 8.0;
    } else if (archetype == 'organic') {
      icon = Icons.arrow_right_alt_rounded;
      iconSize = 10.0;
    } else if (archetype == 'minimal') {
      icon = Icons.fiber_manual_record_rounded;
      iconSize = 5.0;
    }
    return Row(
      children: [
        Icon(
          icon,
          color: accent,
          size: iconSize,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: _getSafeGoogleFont(
              font,
              textStyle: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 8.5,
              ),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSwatch(Color color, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildCapabilityIcon(IconData icon, String tooltip) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Icon(
        icon,
        color: AppColors.textMuted,
        size: 14,
      ),
    );
  }

  TextStyle _getSafeGoogleFont(String fontName, {required TextStyle textStyle}) {
    try {
      return GoogleFonts.getFont(fontName, textStyle: textStyle);
    } catch (_) {
      return textStyle;
    }
  }
}

class _GenerationProgressDialog extends StatefulWidget {
  const _GenerationProgressDialog();

  @override
  State<_GenerationProgressDialog> createState() => _GenerationProgressDialogState();
}

class _GenerationProgressDialogState extends State<_GenerationProgressDialog> {
  int _currentPhase = 0;
  Timer? _timer;

  final List<(String, String)> _phases = const [
    ("Analyzing Outline", "Extracting core themes and structural hierarchy..."),
    ("Synthesizing Layouts", "Formulating multi-column cards, bullet lists, and metrics..."),
    ("Harmonizing Aesthetics", "Applying typography, brand tokens, and color contrast..."),
    ("Generating Deck", "Compiling slides and speaker notes..."),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (mounted) {
        setState(() {
          _currentPhase = (_currentPhase + 1) % _phases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = _phases[_currentPhase];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(28.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Pulsing Spinner Container
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
                border: Border.all(
                  color: AppColors.primaryBorder,
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scaleXY(begin: 0.98, end: 1.05, duration: 1200.ms, curve: Curves.easeInOut),
            const SizedBox(height: 24),

            // Animated Header Title
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                title,
                key: ValueKey<int>(_currentPhase),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),

            // Animated Subtitle Description
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                subtitle,
                key: ValueKey<String>(subtitle),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Progress Step Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_phases.length, (index) {
                final isPassed = index <= _currentPhase;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentPhase ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isPassed ? AppColors.primary : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).scale(
      begin: const Offset(0.94, 0.94),
      end: const Offset(1, 1),
      curve: Curves.easeOutBack,
    );
  }
}
