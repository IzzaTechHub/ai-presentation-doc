import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slide_model.dart';
import '../models/template_model.dart';
import '../services/app_state.dart';
import '../widgets/floating_bottom_bar.dart';
import '../theme/app_theme.dart';
import 'export_screen.dart';
import 'template_screen.dart';
import 'home_screen.dart';

class EditorScreen extends StatefulWidget {
  final List<SlideModel>? initialSlides;
  final TemplateModel? selectedTemplate;

  const EditorScreen({
    super.key,
    this.initialSlides,
    this.selectedTemplate,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late List<SlideModel> _slides;
  int _selectedSlideIndex = 0;

  /// null | 'title' | 'bullet_N'
  String? _editingTarget;
  TextEditingController? _editController;
  FocusNode? _editFocusNode;
  int? _selectedBulletIndex;

  @override
  void initState() {
    super.initState();
    final slidesToUse = widget.initialSlides ?? AppState.activeSlides;
    if (slidesToUse != null) {
      _slides = slidesToUse.map((s) => s.copy()).toList();
    } else {
      _slides = [];
    }
  }

  @override
  void dispose() {
    _editFocusNode?.removeListener(_onEditFocusChange);
    _editController?.dispose();
    _editFocusNode?.dispose();
    super.dispose();
  }

  // Helper to parse CSS Hex Colors
  Color _parseHex(String hexColor) {
    String formatted = hexColor.replaceAll('#', '');
    if (formatted.length == 6) {
      formatted = 'FF$formatted';
    }
    return Color(int.parse(formatted, radix: 16));
  }

  List<String> get _availableLayouts =>
      widget.selectedTemplate?.layouts ??
      AppState.selectedTemplate?.layouts ??
      const [
        'title_only',
        'title_bullets',
        'title_image_right',
        'two_column',
        'image_full',
      ];

  void _applyEditToModel() {
    if (_editingTarget == null || _editController == null || _slides.isEmpty) {
      return;
    }
    final slide = _slides[_selectedSlideIndex];
    if (_editingTarget == 'title') {
      slide.title = _editController!.text;
    } else if (_editingTarget!.startsWith('bullet_')) {
      final idx = int.tryParse(_editingTarget!.substring(7));
      if (idx != null && idx >= 0 && idx < slide.bullets.length) {
        slide.bullets[idx] = _editController!.text.trim();
      }
    }
    AppState.activeSlides = _slides;
  }

  void _disposeEditResources() {
    _editFocusNode?.removeListener(_onEditFocusChange);
    _editController?.dispose();
    _editFocusNode?.dispose();
    _editController = null;
    _editFocusNode = null;
    _editingTarget = null;
  }

  void _commitEdit({bool rebuild = true}) {
    if (_editingTarget == null) return;
    _applyEditToModel();
    _disposeEditResources();
    if (rebuild && mounted) setState(() {});
  }

  void _onEditFocusChange() {
    if (_editFocusNode == null || _editFocusNode!.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_editFocusNode != null && !_editFocusNode!.hasFocus) {
        _commitEdit();
      }
    });
  }

  void _beginEdit(String target, String initialText) {
    if (_editingTarget == target) return;
    _commitEdit(rebuild: false);
    _editController = TextEditingController(text: initialText);
    _editFocusNode = FocusNode();
    _editFocusNode!.addListener(_onEditFocusChange);
    setState(() {
      _editingTarget = target;
      if (target.startsWith('bullet_')) {
        _selectedBulletIndex = int.tryParse(target.substring(7));
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _editFocusNode?.requestFocus();
    });
  }

  void _startEditTitle() {
    if (_slides.isEmpty) return;
    _beginEdit('title', _slides[_selectedSlideIndex].title);
  }

  void _startEditBullet(int index) {
    if (_slides.isEmpty) return;
    final bullets = _slides[_selectedSlideIndex].bullets;
    if (index < 0 || index >= bullets.length) return;
    _beginEdit('bullet_$index', bullets[index]);
  }

  void _selectSlide(int index) {
    if (index == _selectedSlideIndex) return;
    _commitEdit(rebuild: false);
    setState(() {
      _selectedSlideIndex = index;
      _selectedBulletIndex = null;
    });
  }

  void _changeLayout(String layout) {
    _commitEdit(rebuild: false);
    setState(() {
      _slides[_selectedSlideIndex].layout = layout;
      AppState.activeSlides = _slides;
    });
  }

  void _addBullet() {
    _commitEdit(rebuild: false);
    setState(() {
      final slide = _slides[_selectedSlideIndex];
      slide.bullets = [...slide.bullets, 'New bullet point'];
      _selectedBulletIndex = slide.bullets.length - 1;
      AppState.activeSlides = _slides;
    });
    _startEditBullet(_selectedBulletIndex!);
  }

  void _removeSelectedBullet() {
    final slide = _slides[_selectedSlideIndex];
    final idx = _selectedBulletIndex;
    if (idx == null || idx < 0 || idx >= slide.bullets.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap a bullet first, then remove it.')),
      );
      return;
    }
    _commitEdit(rebuild: false);
    setState(() {
      slide.bullets = List<String>.from(slide.bullets)..removeAt(idx);
      _selectedBulletIndex = null;
      AppState.activeSlides = _slides;
    });
  }

  void _addSlide() {
    _commitEdit(rebuild: false);
    setState(() {
      final newSlideNumber = _slides.length + 1;
      _slides.add(
        SlideModel(
          slideNumber: newSlideNumber,
          layout: 'title_bullets',
          title: 'New Slide Title',
          bullets: ['Key point description one', 'Key point description two'],
          speakerNote: 'Add notes here',
        ),
      );
      _selectedSlideIndex = _slides.length - 1;
      _selectedBulletIndex = null;
      AppState.activeSlides = _slides;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("New slide added at the end")),
    );
  }

  void _deleteSlide() {
    if (_slides.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot delete the only remaining slide.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF171F33),
        title: Text(
          "Delete Slide",
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete Slide ${_selectedSlideIndex + 1}?",
          style: GoogleFonts.inter(color: const Color(0xFFCBC3D7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: const Color(0xFFCBC3D7)),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFB4AB)),
            onPressed: () {
              Navigator.pop(context);
              _commitEdit(rebuild: false);
              setState(() {
                _slides.removeAt(_selectedSlideIndex);
                for (int i = 0; i < _slides.length; i++) {
                  _slides[i].slideNumber = i + 1;
                }
                if (_selectedSlideIndex >= _slides.length) {
                  _selectedSlideIndex = _slides.length - 1;
                }
                _selectedBulletIndex = null;
                AppState.activeSlides = _slides;
              });
            },
            child: Text(
              "Delete",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideToolbar(SlideModel currentSlide) {
    final layouts = _availableLayouts;
    final layoutValue =
        layouts.contains(currentSlide.layout) ? currentSlide.layout : layouts.first;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171F33).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tap text on the slide to edit',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFFCBC3D7).withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: layoutValue,
                    dropdownColor: const Color(0xFF171F33),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF5DE6FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    items: layouts
                        .map(
                          (layout) => DropdownMenuItem<String>(
                            value: layout,
                            child: Text(
                              layout.replaceAll('_', ' ').toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _changeLayout(val);
                    },
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add bullet',
                onPressed: _addBullet,
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
              ),
              IconButton(
                tooltip: 'Remove selected bullet',
                onPressed: _removeSelectedBullet,
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Slide Editor",
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.slideshow_rounded,
                      color: AppColors.textMuted,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No Active Presentation",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Create a new presentation from the Dashboard tab to begin editing.",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
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
                        "Start Generating",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 2),
      );
    }

    final currentSlide = _slides[_selectedSlideIndex];
    final template = widget.selectedTemplate ?? AppState.selectedTemplate!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon/app_logo.png',
                width: 28,
                height: 28,
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
        backgroundColor: AppColors.background.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // Toolbar Actions
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: AppColors.primaryLight),
            tooltip: "Change Style",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TemplateScreen(
                    topic: AppState.currentTopic,
                    slideCount: AppState.currentSlideCount,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.primary),
            tooltip: "Add Slide",
            onPressed: _addSlide,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: "Delete Slide",
            onPressed: _deleteSlide,
          ),
          const SizedBox(width: 4),
          // Export Button styled with border outline
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.primaryBorder),
                ),
              ),
              onPressed: () {
                _commitEdit(rebuild: false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExportScreen(
                      slides: _slides,
                      templateId: template.id,
                    ),
                  ),
                );
              },
              child: Text(
                "Export",
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
        shape: const Border(
          bottom: BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient leaks in orange
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
          // Workspace row: side rail + stage canvas
          Row(
            children: [
              // LEFT PANEL: Slide Thumbnails Rail (Secondary Rail)
              Container(
                width: 96,
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.65),
                  border: const Border(
                    right: BorderSide(color: AppColors.surfaceBorder, width: 1),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _slides.length + 1, // list + add ghost button
                  itemBuilder: (context, index) {
                    // Add Slide Ghost Button at the end
                    if (index == _slides.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        child: GestureDetector(
                          onTap: _addSlide,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.add, color: AppColors.textSecondary, size: 20),
                          ),
                        ),
                      );
                    }

                    final isSelected = index == _selectedSlideIndex;
                    final slide = _slides[index];
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      child: GestureDetector(
                        onTap: () => _selectSlide(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: template.colors.backgroundStart != null && template.colors.backgroundEnd != null
                                ? LinearGradient(
                                    colors: [
                                      _parseHex(template.colors.backgroundStart!),
                                      _parseHex(template.colors.backgroundEnd!),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: template.colors.backgroundStart == null ? _parseHex(template.colors.background) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                              width: isSelected ? 2.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                // Mini slide preview
                                Positioned.fill(
                                  child: _buildSlideContent(slide, template),
                                ),
                                // Slide number badge (bottom-left)
                                Positioned(
                                  bottom: 3,
                                  left: 3,
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "${slide.slideNumber}",
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // STAGE: Presentation canvas + under-slide toolbar
              Expanded(
                child: Container(
                  color: const Color(0xFF060E20).withValues(alpha: 0.3),
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: constraints.maxHeight),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: template.colors.backgroundStart != null &&
                                            template.colors.backgroundEnd != null
                                        ? LinearGradient(
                                            colors: [
                                              _parseHex(template.colors.backgroundStart!),
                                              _parseHex(template.colors.backgroundEnd!),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: template.colors.backgroundStart == null
                                        ? _parseHex(template.colors.background)
                                        : null,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: _buildSlideContent(
                                          currentSlide,
                                          template,
                                          editable: true,
                                        ),
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: IgnorePointer(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.4),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withValues(alpha: 0.12),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              "AI Enhanced",
                                              style: GoogleFonts.inter(
                                                color: const Color(0xFFCBC3D7),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildSlideToolbar(currentSlide),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 2),
    );
  }

  // Renders mock presentation details matched with layouts
  Widget _buildSlideContent(
    SlideModel slide,
    TemplateModel template, {
    bool editable = false,
  }) {
    final style = template.style;
    final accentColor = _parseHex(template.colors.accent);
    final titleColor = _parseHex(template.colors.title);

    List<Widget> backgroundDecorations = [];
    if (style == 'editorial') {
      // Elegant nested card border
      backgroundDecorations.add(
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 3.0,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
      // Soft accent block on the right
      backgroundDecorations.add(
        Positioned(
          top: 24,
          bottom: 24,
          right: 32,
          width: 8,
          child: Container(
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
      );
    } else if (style == 'vibrant') {
      // Dark Theme: Ambient gradient glowing blobs in corners
      backgroundDecorations.addAll([
        Positioned(
          top: -100,
          left: -100,
          width: 300,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.09),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          width: 300,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.07),
            ),
          ),
        ),
      ]);
    } else if (style == 'tech') {
      // Tech Theme: Outer grid cyan boundary & corners
      backgroundDecorations.addAll([
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: titleColor.withValues(alpha: 0.25),
                width: 2.0,
              ),
            ),
          ),
        ),
        // Corner bracket simulations
        Positioned(
          top: 24,
          left: 24,
          child: Container(
            width: 40,
            height: 6,
            color: titleColor,
          ),
        ),
        Positioned(
          top: 24,
          left: 24,
          child: Container(
            width: 6,
            height: 40,
            color: titleColor,
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: Container(
            width: 40,
            height: 6,
            color: titleColor,
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: Container(
            width: 6,
            height: 40,
            color: titleColor,
          ),
        ),
      ]);
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: 960,
        height: 540,
        decoration: BoxDecoration(
          gradient: template.colors.backgroundStart != null && template.colors.backgroundEnd != null
              ? LinearGradient(
                  colors: [
                    _parseHex(template.colors.backgroundStart!),
                    _parseHex(template.colors.backgroundEnd!),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: template.colors.backgroundStart == null ? _parseHex(template.colors.background) : null,
        ),
        child: Stack(
          children: [
            ...backgroundDecorations,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: _buildScaledSlideContent(slide, template, editable: editable),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineTextField({
    required TextStyle style,
    required TextAlign textAlign,
    int maxLines = 2,
  }) {
    return TextField(
      controller: _editController,
      focusNode: _editFocusNode,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      onSubmitted: (_) => _commitEdit(),
      onEditingComplete: _commitEdit,
    );
  }

  Widget _buildEditableTitleText(
    String title,
    TextStyle style, {
    required bool editable,
    TextAlign textAlign = TextAlign.left,
    int maxLines = 2,
  }) {
    if (editable && _editingTarget == 'title') {
      return _buildInlineTextField(
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    final textWidget = Text(
      title,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
    );

    if (!editable) return textWidget;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _startEditTitle,
      child: textWidget,
    );
  }

  Widget _buildScaledSlideContent(
    SlideModel slide,
    TemplateModel template, {
    bool editable = false,
  }) {
    final titleColor = _parseHex(template.colors.title);
    final bodyColor = _parseHex(template.colors.body);
    final accentColor = _parseHex(template.colors.accent);
    final style = template.style;

    final titleStyle = GoogleFonts.outfit(
      color: titleColor,
      fontSize: 42,
      fontWeight: FontWeight.bold,
    );

    final bodyStyle = GoogleFonts.inter(
      color: bodyColor,
      fontSize: 22,
      height: 1.4,
    );

    switch (slide.layout) {
      case 'title_only':
        if (style == 'organic') {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 180,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildEditableTitleText(
                  slide.title,
                  titleStyle.copyWith(fontSize: 44),
                  editable: editable,
                  textAlign: TextAlign.left,
                  maxLines: 3,
                ),
              ),
            ],
          );
        } else if (style == 'editorial') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEditableTitleText(
                  slide.title,
                  titleStyle.copyWith(fontSize: 48),
                  editable: editable,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Container(width: 180, height: 3, color: accentColor),
                const SizedBox(height: 6),
                Container(width: 120, height: 3, color: accentColor),
              ],
            ),
          );
        } else if (style == 'vibrant') {
          return Container(
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Center(
              child: _buildEditableTitleText(
                slide.title,
                titleStyle.copyWith(fontSize: 46),
                editable: editable,
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ),
          );
        } else if (style == 'tech') {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: accentColor, width: 3.0),
              color: _parseHex(template.colors.background),
            ),
            padding: const EdgeInsets.all(40),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(width: 30, height: 8, color: accentColor),
                ),
                Center(
                  child: _buildEditableTitleText(
                    slide.title,
                    titleStyle.copyWith(fontSize: 48),
                    editable: editable,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: _buildEditableTitleText(
              slide.title,
              titleStyle.copyWith(fontSize: 50),
              editable: editable,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          );
        }

      case 'image_full':
        DecorationImage? bgImage;
        if (slide.imageUrl.isNotEmpty) {
          bgImage = DecorationImage(
            image: NetworkImage(slide.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
              BlendMode.srcOver,
            ),
          );
        }

        Widget child = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEditableTitleText(
              slide.title,
              titleStyle.copyWith(color: const Color(0xFFFFFFFF), fontSize: 44),
              editable: editable,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Container(width: 80, height: 4, color: Colors.white.withValues(alpha: 0.8)),
          ],
        );

        if (style == 'vibrant') {
          child = Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
            ),
            child: child,
          );
        } else if (style == 'tech') {
          child = Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: accentColor, width: 3.0),
            ),
            child: child,
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(16),
            image: bgImage,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(32),
          child: child,
        );

      case 'title_image_right':
        return Row(
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleHeader(
                    slide.title,
                    titleStyle,
                    accentColor,
                    style,
                    editable: editable,
                  ),
                  _buildGradientLine(style, accentColor),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildBulletsList(
                      slide.bullets,
                      bodyStyle,
                      accentColor,
                      style,
                      editable: editable,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accentColor,
                    width: style == 'editorial' ? 1.5 : 3.0,
                  ),
                  borderRadius: BorderRadius.circular(style == 'vibrant' ? 24 : 16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(style == 'vibrant' ? 21 : 13),
                  child: slide.imageUrl.isNotEmpty
                      ? Image.network(
                          slide.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(Icons.image_outlined, color: accentColor, size: 64),
                          ),
                        )
                      : Center(
                          child: Icon(Icons.image_outlined, color: accentColor, size: 64),
                        ),
                ),
              ),
            ),
          ],
        );

      case 'two_column':
        final midpoint = (slide.bullets.length / 2).ceil();
        final col1 = slide.bullets.take(midpoint).toList();
        final col2 = slide.bullets.skip(midpoint).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleHeader(
              slide.title,
              titleStyle,
              accentColor,
              style,
              editable: editable,
            ),
            _buildGradientLine(style, accentColor),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildBulletsList(
                      col1,
                      bodyStyle,
                      accentColor,
                      style,
                      editable: editable,
                      indexOffset: 0,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildBulletsList(
                      col2,
                      bodyStyle,
                      accentColor,
                      style,
                      editable: editable,
                      indexOffset: midpoint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'title_bullets':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleHeader(
              slide.title,
              titleStyle,
              accentColor,
              style,
              editable: editable,
            ),
            _buildGradientLine(style, accentColor),
            const SizedBox(height: 16),
            Expanded(
              child: _buildBulletsList(
                slide.bullets,
                bodyStyle,
                accentColor,
                style,
                editable: editable,
              ),
            ),
          ],
        );
    }
  }

  // Header Title widget supporting Organic left bar and Editorial centering
  Widget _buildTitleHeader(
    String title,
    TextStyle style,
    Color accentColor,
    String archetype, {
    bool editable = false,
  }) {
    return Row(
      children: [
        if (archetype == 'organic') ...[
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: _buildEditableTitleText(
            title,
            style,
            editable: editable,
            textAlign: archetype == 'editorial' ? TextAlign.center : TextAlign.left,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  // Underlines for different archetypes
  Widget _buildGradientLine(String style, Color accentColor) {
    if (style == 'minimal') {
      return const SizedBox(height: 8); // No underline
    }
    if (style == 'organic') {
      // Small vertical bar handles it
      return const SizedBox(height: 12);
    }
    
    // Tech: Neon double lines
    if (style == 'tech') {
      return Container(
        margin: const EdgeInsets.only(top: 14, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 6, color: accentColor),
            const SizedBox(height: 4),
            Container(width: 60, height: 3, color: const Color(0xFF5DE6FF)),
          ],
        ),
      );
    }

    // Editorial: Double lines
    if (style == 'editorial') {
      return Container(
        margin: const EdgeInsets.only(top: 14, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 120, height: 2, color: accentColor),
            const SizedBox(height: 4),
            Container(width: 80, height: 2, color: accentColor),
          ],
        ),
      );
    }

    // Vibrant/Default: rounded pill
    return Container(
      width: 120,
      height: 8,
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(4),
      ),
      margin: const EdgeInsets.only(top: 14, bottom: 20),
    );
  }

  // Bullets list builder
  Widget _buildBulletsList(
    List<String> bullets,
    TextStyle style,
    Color iconColor,
    String archetype, {
    bool editable = false,
    int indexOffset = 0,
  }) {
    Widget list = ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(bullets.length, (i) {
        final globalIndex = indexOffset + i;
        return _buildBulletRow(
          bullets[i],
          style,
          iconColor,
          archetype,
          editable: editable,
          bulletIndex: globalIndex,
        );
      }),
    );

    if (archetype == 'tech') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: list,
      );
    }

    if (archetype == 'vibrant') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.12), width: 1),
        ),
        child: list,
      );
    }

    return list;
  }

  // Premium bullet points with custom check shapes
  Widget _buildBulletRow(
    String text,
    TextStyle style,
    Color iconColor,
    String archetype, {
    bool editable = false,
    int bulletIndex = 0,
  }) {
    IconData icon = Icons.check_circle;
    if (archetype == 'tech') {
      icon = Icons.check_box_outline_blank_rounded;
    } else if (archetype == 'editorial') {
      icon = Icons.stop_rounded;
    } else if (archetype == 'organic') {
      icon = Icons.arrow_right_alt_rounded;
    } else if (archetype == 'minimal') {
      icon = Icons.fiber_manual_record_rounded;
    }

    final isEditing = editable && _editingTarget == 'bullet_$bulletIndex';
    final isSelected = editable && _selectedBulletIndex == bulletIndex;

    Widget textChild;
    if (isEditing) {
      textChild = _buildInlineTextField(
        style: style,
        textAlign: TextAlign.left,
        maxLines: 3,
      );
    } else {
      textChild = Text(
        text,
        style: style,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
      if (editable) {
        textChild = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() => _selectedBulletIndex = bulletIndex);
            _startEditBullet(bulletIndex);
          },
          child: textChild,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: isSelected && !isEditing
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: archetype == 'minimal' ? 14 : 24,
            ),
            const SizedBox(width: 14),
            Expanded(child: textChild),
          ],
        ),
      ),
    );
  }
}
