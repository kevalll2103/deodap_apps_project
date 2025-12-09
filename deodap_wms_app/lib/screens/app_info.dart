import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoScreenView extends StatefulWidget {
  const AppInfoScreenView({super.key});

  @override
  State<AppInfoScreenView> createState() => _AppInfoScreenViewState();
}

class _AppInfoScreenViewState extends State<AppInfoScreenView> {
  String _currentVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _currentVersion = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF007E9B); // Blue[700]
    const backgroundColor = Color(0xFFF2F2F7); // iOS background
    const cardColor = CupertinoColors.white;
    const textColor = CupertinoColors.black;
    const secondaryTextColor = CupertinoColors.systemGrey;

    return CupertinoPageScaffold(
      backgroundColor: backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: cardColor,
        middle: const Text(
          'App Information',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            decoration: TextDecoration.none,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: primaryBlue),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App title card
                _IOSCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Deodap  Warehouse Management field System",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: primaryBlue,
                        letterSpacing: -0.6,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Logo
                _IOSCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      'assets/splash_bg.png',
                      height: 80,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.app_badge,
                                color: primaryBlue,
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Logo not found',
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 10,
                                  letterSpacing: -0.2,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Version + vendor block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.info_circle,
                              color: primaryBlue, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Version: $_currentVersion",
                            style: const TextStyle(
                              fontSize: 13,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "powered by vacalvers.com",
                        style: TextStyle(
                          fontSize: 11,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Deodap International Pvt Ltd",
                        style: TextStyle(
                          fontSize: 10,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Quick facts
                _IOSCard(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: CupertinoIcons.app_badge,
                          label: 'App',
                          value: 'DeoDap WMS Field Management System',
                        ),
                        const _Divider(),
                        _InfoTile(
                          icon: CupertinoIcons.calendar,
                          label: 'Since',
                          value: '2025',
                        ),
                        const _Divider(),
                        _InfoTile(
                          icon: CupertinoIcons.checkmark_seal,
                          label: 'License',
                          value: 'Open source app',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // View Licenses button
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'View Licenses',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'DeoDap CLO Management System',
                        applicationVersion: _currentVersion,
                        applicationLegalese: '© 2025 vacalvers.com Inc.',
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Copyright
                const Text(
                  "© 2025 vacalvers.com Inc.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---- iOS UI Components ----

class _IOSCard extends StatelessWidget {
  final Widget child;

  const _IOSCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF007E9B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF007E9B);
    const textColor = CupertinoColors.black;
    const secondaryTextColor = CupertinoColors.systemGrey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: primaryBlue, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: const Color(0xFF007E9B).withOpacity(0.1),
    );
  }
}
