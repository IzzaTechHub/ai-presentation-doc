import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/slide_model.dart';
import '../services/api_service.dart';
import '../services/file_service.dart';
import '../widgets/floating_bottom_bar.dart';

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

  void _downloadPDF() {
    // Show premium descriptive dialog explaining PDF offline compilation options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF5C6BC0)),
            SizedBox(width: 10),
            Text("PDF Export"),
          ],
        ),
        content: const Text(
          "PDF conversion requires LibreOffice server-side compilation which is currently in setup for the production Render cluster. \n\nPlease use the 'Download PPTX' option to export your editable slides directly.",
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Export Deck",
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0B1326).withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background ambient leaks
          Positioned(
            top: -150,
            left: -100,
            width: 400,
            height: 400,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x268B5CF6), Colors.transparent],
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
                  colors: [Color(0x1F8B5CF6), Colors.transparent],
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
                  color: Color(0xFF43A047),
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
                    color: const Color(0xFFCBC3D7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Button 1: Download PPTX
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF171F33).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                  child: InkWell(
                    onTap: _isLoading ? null : _downloadPPTX,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          const Icon(Icons.slideshow_rounded, color: Color(0xFF8B5CF6), size: 36),
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
                                    color: const Color(0xFFCBC3D7).withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.download_rounded, color: Color(0xFFCBC3D7)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Button 2: Download PDF
                // Container(
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF171F33).withValues(alpha: 0.8),
                //     borderRadius: BorderRadius.circular(16),
                //     border: Border.all(
                //       color: Colors.white.withValues(alpha: 0.08),
                //       width: 1.0,
                //     ),
                //   ),
                //   child: InkWell(
                //     onTap: _isLoading ? null : _downloadPDF,
                //     borderRadius: BorderRadius.circular(16),
                //     child: Padding(
                //       padding: const EdgeInsets.all(20.0),
                //       child: Row(
                //         children: [
                //           const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF5DE6FF), size: 36),
                //           const SizedBox(width: 16),
                //           Expanded(
                //             child: Column(
                //               crossAxisAlignment: CrossAxisAlignment.start,
                //               children: [
                //                 Text(
                //                   "Download PDF",
                //                   style: GoogleFonts.inter(
                //                     fontSize: 16,
                //                     fontWeight: FontWeight.bold,
                //                     color: Colors.white,
                //                   ),
                //                 ),
                //                 const SizedBox(height: 4),
                //                 Text(
                //                   "Save read-only PDF file structure",
                //                   style: GoogleFonts.inter(
                //                     fontSize: 12,
                //                     color: const Color(0xFFCBC3D7).withValues(alpha: 0.7),
                //                   ),
                //                 ),
                //               ],
                //             ),
                //           ),
                //           const Icon(Icons.download_rounded, color: Color(0xFFCBC3D7)),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          // Loading Dialog Overlay
          if (_isLoading)
            Container(
              color: const Color(0xFF000000).withValues(alpha: 0.6),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF171F33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
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
