import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // only for Colors.blue[700]
import 'package:http/http.dart' as http;

// Your existing screens:
import 'app_info.dart';
import 'term_condition.dart';
import 'invite_friend.dart';
import 'about.dart';
import 'get_in_touch.dart';
import 'emp_help.dart';

class setting extends StatefulWidget {
  const setting({super.key});

  @override
  State<setting> createState() => _SettingsCupertinoScreenState();
}

class _SettingsCupertinoScreenState extends State<setting> {
  bool _isLoading = false;
  String _updateStatus = ''; // 'success' or 'error' or ''
  String _currentLanguage = 'English';
  final String _appVersion = '1.1.1';

  Color get _primaryBlue => Colors.blue.shade700;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('https://customprint.deodap.com/check_update.php'),
        body: {'version': _appVersion},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _updateStatus = data['status'] == 'success' ? 'success' : 'error';
        });
      } else {
        setState(() => _updateStatus = 'error');
      }
    } catch (_) {
      setState(() => _updateStatus = 'error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showLanguageSheet() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(primaryColor: _primaryBlue),
        child: CupertinoActionSheet(
          title: const Text(
            'Select your Language',
            style: TextStyle(decoration: TextDecoration.none),
          ),
          message: const Text(
            'More languages coming soon.',
            style: TextStyle(decoration: TextDecoration.none),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _currentLanguage = 'English');
                Navigator.pop(ctx);
              },
              isDefaultAction: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(CupertinoIcons.globe, size: 18),
                  SizedBox(width: 8),
                  Text('English', style: TextStyle(decoration: TextDecoration.none)),
                  SizedBox(width: 6),
                  Icon(CupertinoIcons.check_mark_circled_solid, size: 18),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            isDestructiveAction: false,
            child: const Text('Cancel', style: TextStyle(decoration: TextDecoration.none)),
          ),
        ),
      ),
    );
  }

  void _openPopupMenu() async {
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoTheme(
        data: CupertinoTheme.of(context).copyWith(primaryColor: _primaryBlue),
        child: CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, CupertinoPageRoute(builder: (_) => ContactHelpScreen()));
              },
              child: const Text('Help', style: TextStyle(decoration: TextDecoration.none)),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, CupertinoPageRoute(builder: (_) => AboutScreen()));
              },
              child: const Text('About', style: TextStyle(decoration: TextDecoration.none)),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context, CupertinoPageRoute(builder: (_) => ContactCupertinoView()));
              },
              child: const Text('Contact', style: TextStyle(decoration: TextDecoration.none)),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(decoration: TextDecoration.none)),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.4,
          color: CupertinoColors.systemGrey,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none, // ensure no underline
        ),
      ),
    );
  }

  Widget _cell({
    required Widget leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(12) : Radius.zero,
      bottom: isLast ? const Radius.circular(12) : Radius.zero,
    );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        color: CupertinoColors.systemBackground,
        child: CupertinoButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          pressedOpacity: 0.6,
          child: Container(
            // Remove the "underline" look under groups:
            // Only show a thin divider BETWEEN rows, not after the last one.
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : const BorderSide(color: CupertinoColors.separator, width: 0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 28, child: Center(child: IconTheme(data: IconThemeData(color: _primaryBlue), child: leading))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.label,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemGrey,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing ??
                    const Icon(
                      CupertinoIcons.chevron_forward,
                      size: 18,
                      color: CupertinoColors.systemGrey2,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _group(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoTheme(
      data: theme.copyWith(primaryColor: _primaryBlue), // blue[700] across this screen
      child: CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          // remove any hairline/underline on the nav bar
          border: null,
          middle: const Text('Settings', style: TextStyle(decoration: TextDecoration.none)),
          previousPageTitle: 'Back',
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _openPopupMenu,
            child: Icon(CupertinoIcons.ellipsis_circle, size: 24, color: _primaryBlue),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).maybePop(),
            child: Icon(CupertinoIcons.chevron_back, size: 22, color: _primaryBlue),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _checkForUpdate,
                builder: (context, mode, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
                  // keep default indicator, but ensure no unexpected color accents
                  return const Center(child: CupertinoActivityIndicator());
                },
              ),

              // COMMON
              SliverToBoxAdapter(child: _sectionHeader('Common')),
              SliverToBoxAdapter(
                child: _group([
                  _cell(
                    isFirst: true,
                    leading: const Icon(CupertinoIcons.globe),
                    title: 'Language',
                    subtitle: _currentLanguage,
                    onTap: _showLanguageSheet,
                  ),
                  _cell(
                    isLast: true,
                    leading: const Icon(CupertinoIcons.square_stack_3d_up),
                    title: 'Storage and Data',
                    subtitle: 'Network usage, Permissions',
                    onTap: () {
                      // Placeholder for future screen
                    },
                  ),
                ]),
              ),

              // MISC
              SliverToBoxAdapter(child: _sectionHeader('Misc')),
              SliverToBoxAdapter(
                child: _group([
                  _cell(
                    isFirst: true,
                    leading: const Icon(CupertinoIcons.arrow_down_square),
                    title: 'App Updates',
                    subtitle: _isLoading
                        ? 'Checking…'
                        : _updateStatus == 'success'
                        ? 'Update available'
                        : 'You’re up to date',
                    trailing: _isLoading
                        ? const CupertinoActivityIndicator()
                        : (_updateStatus == 'success'
                        ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _primaryBlue, // badge in blue[700]
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(color: CupertinoColors.white, fontSize: 12, decoration: TextDecoration.none),
                      ),
                    )
                        : const Icon(CupertinoIcons.check_mark_circled, color: CupertinoColors.activeGreen)),
                    onTap: _updateStatus == 'success'
                        ? () {
                      // TODO: Push "Update Available" screen
                      // Navigator.push(context, CupertinoPageRoute(builder: (_) => UpdateAvailablescreenView()));
                    }
                        : _checkForUpdate,
                  ),
                  _cell(
                    leading: const Icon(CupertinoIcons.person_2_fill),
                    title: 'Invite a Friend',
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(builder: (_) => InviteFriendscreenEmpView()));
                    },
                  ),
                  _cell(
                    leading: const Icon(CupertinoIcons.doc_text),
                    title: 'Terms of Service',
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(builder: (_) => TermsConditionscreenView()));
                    },
                  ),
                  _cell(
                    isLast: true,
                    leading: const Icon(CupertinoIcons.info_circle),
                    title: 'App Info',
                    subtitle: 'Version $_appVersion',
                    onTap: () {
                      Navigator.push(context, CupertinoPageRoute(builder: (_) => AppInfoScreenView()));
                    },
                  ),
                ]),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
