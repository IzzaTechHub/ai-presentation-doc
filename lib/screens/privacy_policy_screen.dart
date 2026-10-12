// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class PrivacyPolicyScreen extends StatefulWidget {
//   const PrivacyPolicyScreen({super.key});

//   @override
//   State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
// }

// class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
//   late final WebViewController _controller;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _controller = WebViewController()
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onPageStarted: (String url) {
//             setState(() {
//               _isLoading = true;
//             });
//           },
//           onPageFinished: (String url) {
//             setState(() {
//               _isLoading = false;
//             });
//             _hideGoogleUi();
//           },
//           onNavigationRequest: (NavigationRequest request) {
//             // Prevent leaving this document (e.g. Google's back button going to workspace)
//             const docId = '1SLMN4QYLfh4iYJdHME2DI_bYyGf5yDPXQGyF68DmZek';
//             if (request.url.contains(docId)) {
//               return NavigationDecision.navigate;
//             }
//             return NavigationDecision.prevent;
//           },
//           onWebResourceError: (WebResourceError error) {
//             setState(() {
//               _isLoading = false;
//             });
//           },
//         ),
//       )
//       ..loadRequest(
//         Uri.parse(
//           'https://docs.google.com/document/d/1SLMN4QYLfh4iYJdHME2DI_bYyGf5yDPXQGyF68DmZek/preview?usp=sharing',
//         ),
//       );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Privacy Policy",
//           style: GoogleFonts.outfit(
//             fontWeight: FontWeight.w700,
//             color: const Color(0xFF8B5CF6),
//             fontSize: 20,
//             letterSpacing: -0.5,
//           ),
//         ),
//         backgroundColor: const Color(0xFF0B1326).withValues(alpha: 0.8),
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         shape: const Border(
//           bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1.0),
//         ),
//         iconTheme: const IconThemeData(color: Color(0xFFDAE2FD)),
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: _controller),
//           if (_isLoading)
//             const Center(
//               child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
//             ),
//         ],
//       ),
//     );
//   }

//   void _hideGoogleUi() {
//     _controller.runJavaScript('''
//       (function() {
//         function hideChrome() {
//           const selectors = [
//             'header',
//             '.docs-titlebar',
//             '.docs-chrome',
//             '.drive-viewer-header',
//             '.drive-viewer-header-container',
//             '.ndfHFb-c4YZDc-Wrql6b',
//             'nav',
//             '#docs-header',
//             '.docs-gm',
//             '.appview',
//             '.drive-viewer-header-actions'
//           ];
//           selectors.forEach(function(sel) {
//             document.querySelectorAll(sel).forEach(function(el) {
//               if (el && el.style) el.style.display = 'none';
//             });
//           });
//           if (document.body) {
//             document.body.style.paddingTop = '0px';
//             document.body.style.marginTop = '0px';
//           }
//           const viewer = document.querySelector('.drive-viewer');
//           if (viewer) viewer.style.marginTop = '0';
//           const content = document.querySelector('.drive-viewer-content');
//           if (content) content.style.marginTop = '0';
//         }
//         hideChrome();
//         setTimeout(hideChrome, 500);
//         setTimeout(hideChrome, 1200);
//         setTimeout(hideChrome, 2500);
//       })();
//     ''');
//   }
// }
