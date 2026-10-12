import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/floating_bottom_bar.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF8B5CF6),
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: const Color(0xFF0B1326).withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1.0),
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
          // Scrollable Settings options
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Text(
                  "App Information",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.info_outline_rounded,
                        title: "App Version",
                        subtitle: "1.0.5",
                      ),
                      const Divider(color: Color(0x1AFFFFFF), height: 1),
                      // _buildSettingItem(
                      //   icon: Icons.shield_outlined,
                      //   title: "Privacy Policy & Licenses",
                      //   subtitle: "View our privacy policy",
                      //   onTap: () {
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => const PrivacyPolicyScreen(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      const Divider(color: Color(0x1AFFFFFF), height: 1),
                      _buildSettingItem(
                        icon: Icons.share_outlined,
                        title: "Share App",
                        subtitle: "Tell your friends about us",
                        onTap: () {
                          SharePlus.instance.share(
                            ShareParams(
                              text:
                                  'Check out AI Visualizer - Create amazing presentations with AI!\nhttps://play.google.com/store/apps/details?id=com.ai.visualizer.app',
                            ),
                          );
                        },
                      ),
                      const Divider(color: Color(0x1AFFFFFF), height: 1),
                      _buildSettingItem(
                        icon: Icons.star_rate_outlined,
                        title: "Rate Us",
                        subtitle: "Rate us on the Play Store",
                        onTap: () async {
                          final uri = Uri.parse(
                            'https://play.google.com/store/apps/details?id=com.ai.visualizer.app',
                          );
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const FloatingBottomBar(currentTabIndex: 3),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171F33).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),
      child: child,
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF8B5CF6)),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          color: const Color(0xFFCBC3D7).withValues(alpha: 0.7),
          fontSize: 12,
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8B5CF6),
                )
              : null),
      onTap: onTap,
    );
  }
}
