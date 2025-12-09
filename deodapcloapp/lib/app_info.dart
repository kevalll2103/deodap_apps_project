import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    const primary = Color(0xFF1565C0);
    const primaryDark = Color(0xFF0D47A1);
    const surface = Color(0xFFF8FAFC);
    const border = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF2D3748);
    const textSecondary = Color(0xFF718096);

    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primary, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: canPop
            ? IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        )
            : null,
        title: Text(
          'App Information',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App title card
                _GlassCard(
                  border: border,
                  shadowOpacity: .05,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      "Deodap Club Order Warehouse Management System",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Logo (height increased)
                _GlassCard(
                  border: border,
                  shadowOpacity: .08,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/deodap_logo.png',
                      height: 120, // increased from 80 → 120
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Version + vendor block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Version: $_currentVersion",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "powered by vacalvers.com",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Deodap International Pvt Ltd",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick facts row
                _InfoRow(
                  border: border,
                  items: const [
                    _InfoItem(
                      icon: Icons.app_shortcut_rounded,
                      label: 'App',
                      value: 'DeoDap CLO Management System',
                    ),
                    _InfoItem(
                      icon: Icons.event_available_rounded,
                      label: 'Since',
                      value: '2025',
                    ),
                    _InfoItem(
                      icon: Icons.verified_user_rounded,
                      label: 'License',
                      value: 'Open source app',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // View Licenses button (shadow removed)
                    _PrimaryButton(
                      label: 'View Licenses',
                      icon: Icons.description_rounded,
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'DeoDap CLO Management System',
                          applicationVersion: _currentVersion,
                          applicationLegalese: '© 2025 vacalvers.com Inc.',
                        );
                      },
                    ),
                    // NOTE: Bottom Back button removed as requested
                  ],
                ),

                const SizedBox(height: 24),

                // Copyright
                Text(
                  "© 2025 vacalvers.com Inc.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
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

/// ---- UI Pieces ----

class _GlassCard extends StatelessWidget {
  final Widget child;
  final Color border;
  final double shadowOpacity;
  const _GlassCard({
    required this.child,
    required this.border,
    this.shadowOpacity = .06,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadowOpacity),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1565C0);
    // Shadow removed: using plain ElevatedButton with elevation 0
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0, // no shadow
        minimumSize: const Size(180, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlinedButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1565C0);
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: primary),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: primary,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: primary, width: 1.2),
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final List<_InfoItem> items;
  final Color border;
  const _InfoRow({required this.items, required this.border});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final isWide = c.maxWidth > 520;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: isWide
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
            items.map((e) => Expanded(child: _InfoTile(item: e))).toList(),
          )
              : Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _InfoTile(item: items[i]),
                if (i != items.length - 1)
                  Divider(height: 20, color: border),
              ]
            ],
          ),
        );
      },
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;
  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF1565C0);
    const textPrimary = Color(0xFF2D3748);
    const textSecondary = Color(0xFF718096);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(item.value,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: textPrimary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
