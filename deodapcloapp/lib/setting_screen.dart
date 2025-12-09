import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_info.dart';
import 'term_condition.dart';
import 'invite_friend.dart';
import 'about.dart';
import 'get_in_touch.dart';
import 'emp_help.dart';


class setting extends StatefulWidget {
  const setting({super.key});

  @override
  State<setting> createState() => _SettingscreenDropshipperViewState();
}

class _SettingscreenDropshipperViewState extends State<setting> {
  bool isDarkMode = false;
  bool finger = false;
  bool _isLoading = false;
  String status = '';
  String value = '';

  void _showLanguageSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            right: 20,
            left: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Select your Language',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1565C0),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListTile(
                  onTap: () => Navigator.pop(context),
                  title: Text('English', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                  trailing: Icon(Icons.check_circle_rounded, color: Colors.green),
                  leading: Icon(Icons.language, color: const Color(0xFF1565C0)),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'No more language available..!',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isLoading = true;
    });
    String version = '1.1.1';

    try {
      var response = await http.post(
        Uri.parse('https://customprint.deodap.com/check_update.php'),
        body: {
          'version': version,
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          status = data['status'] == 'success' ? 'success' : 'error';
        });
      } else {
        setState(() {
          status = 'error';
        });
      }
    } catch (e) {
      setState(() {
        status = 'error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, {VoidCallback? onTap, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: const Color(0xFF1565C0)),
        title: Text(title, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: TextStyle(color: Colors.grey[600])) : null,
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0), // Dark blue
        elevation: 0,
        centerTitle: true,
        title: Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            color: Colors.white,
            onSelected: (String value) {
              switch (value) {
                case 'help':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => emphelp()));
                  break;
                case 'about':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AboutScreen()));
                  break;
                case 'contact':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ContactScreenView()));
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Help', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('About', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'contact',
                child: Row(
                  children: [
                    Icon(Icons.contact_support, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Contact', style: TextStyle(color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Common", style: TextStyle(color: const Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 16),
                  _buildSettingsTile('Language', 'English', Icons.language, onTap: _showLanguageSelectionBottomSheet),
                  _buildSettingsTile('Storage and Data', 'Network usage, Permission', Icons.data_usage),

                  SizedBox(height: 24),
                  Divider(color: Colors.grey[300]),
                  SizedBox(height: 16),

                  Text("Misc", style: TextStyle(color: const Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 16),
                  // _buildSettingsTile(
                  //   'App updates',
                  //   '',
                  //   Icons.system_update,
                  //   onTap: status == 'success'
                  //       ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => UpdateAvailablescreenView()))
                  //       : null,
                  //   trailing: status == 'success'
                  //       ? Container(
                  //     height: 20,
                  //     width: 20,
                  //     decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(10)),
                  //     child: Center(child: Text('1', style: TextStyle(color: Colors.white, fontSize: 12))),
                  //   )
                  //       : Icon(Icons.check_circle, color: Colors.green),
                  // ),
                  _buildSettingsTile('Invite a friend', '', Icons.group_add, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => InviteFriendscreenEmpView()));
                  }),
                  _buildSettingsTile('Terms of Service', '', Icons.description, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TermsConditionscreenView()));
                  }),
                  _buildSettingsTile('App info', '', Icons.info_outline, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AppInfoScreenView()));
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
