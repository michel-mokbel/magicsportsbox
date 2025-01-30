import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // 🔥 Function to create a settings item
  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
      onTap: onTap,
    );
  }

  // 🔥 Function to create a divider
  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.white24, thickness: 0.5),
    );
  }

  // ✅ Share App Function (Uses existing implementation)
  void shareApp(BuildContext context) {
    const String appUrl = 'https://apps.apple.com/app/id';
    Share.share(appUrl);
  }

  // ✅ Show Privacy Policy (Uses existing implementation)
  void showPrivacyPolicy(BuildContext context) async {
    String htmlData = await rootBundle.loadString('lib/assets/html/privacy_policy_en.html');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Html(data: htmlData),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Profile Icon
          const Padding(
            padding: EdgeInsets.only(top: 20, bottom: 30),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 60, color: Colors.black),
            ),
          ),

          // Settings List
          _buildSettingsOption(
            icon: Icons.language,
            title: "Languages",
            onTap: () {
              // Add language selection functionality
            },
          ),
          _buildDivider(),

          _buildSettingsOption(
            icon: Icons.share,
            title: "Share App",
            onTap: () {
              shareApp(context);
            },
          ),
          _buildDivider(),

          _buildSettingsOption(
            icon: Icons.privacy_tip,
            title: "Privacy Policy",
            onTap: () {
              showPrivacyPolicy(context);
            },
          ),
        ],
      ),
    );
  }
}
