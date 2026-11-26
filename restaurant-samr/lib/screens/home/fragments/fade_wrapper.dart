import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FadeWrapper extends StatefulWidget {
  final Widget child;
  const FadeWrapper({super.key, required this.child});

  @override
  State<FadeWrapper> createState() => _FadeWrapperState();
}

class _FadeWrapperState extends State<FadeWrapper> {
  double _opacity = 0.0;
  bool _expired = false;

  @override
  void initState() {
    super.initState();

    _expired = isExpired();

    if (_expired) {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _opacity = 1.0;
        });
      });
    }
  }

  // Open external URL for license extension
  void openExtensionUrl() async {
    final url = Uri.parse('https://your-license-extension-page.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // opens browser externally
      );
    } else {
      debugPrint('Could not launch URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_expired)
          AnimatedOpacity(
            opacity: _opacity,
            duration: const Duration(seconds: 2),
            child: Container(
              color: Colors.white.withOpacity(0.95),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Plan Expired",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: openExtensionUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Renew Plan"),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Visit the link to extend your Plan",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// Force expiry for testing
bool isExpired() => true;
