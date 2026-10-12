import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slide_model.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';
import '../widgets/floating_bottom_bar.dart';
import '../theme/app_theme.dart';

class ExportScreen extends StatefulWidget {
  final List<SlideModel> slides;
  final String templateId;

  const ExportScreen({
    super.key,
    required this.slides,
    required this.templateId,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isLoading = false;
  String _loadingMessage = "";

  void _downloadPPTX() async {
    setState(() {
      _isLoading = true;
      _loadingMessage = "Compiling PPTX slides...";
    });

    try {
      // 1. Fetch compiled binary buffer from backend API
      final bytes = await ApiService.generatePPTX(
        slides: widget.slides,
        templateId: widget.templateId,
      );

      setState(() {
        _loadingMessage = "Writing presentation to storage...";
      });

      // Define default name using timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = "presentation_$timestamp.pptx";

      // 2. Save binary bytes locally on device
      final savedPath = await FileService.saveFileToDownloads(bytes, filename);

      if (mounted) {
        // Show success green notification snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF43A047), // Success green
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFFFFFFFF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Saved to Downloads!\nPath: $savedPath",
                    style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE53935), // Error red
            content: Text("Download failed: ${e.toString().replaceAll("Exception: ", "")}"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Export Deck",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary),
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
          // Main Body Export controls
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header success card icon
                const Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.success,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  "Presentation Ready!",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Your presentation deck has been successfully formatted. Choose your preferred export file type below.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Button 1: Download PPTX
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.surfaceBorder,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _isLoading ? null : _downloadPPTX,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.slideshow_rounded, color: AppColors.primary, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Download PPTX",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Save editable PowerPoint presentation",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.download_rounded, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Dialog Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessage,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 2),
    );
  }
}
