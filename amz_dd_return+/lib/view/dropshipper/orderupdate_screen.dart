import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PendingOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  PendingOrderScreen({required this.order});

  @override
  _PendingOrderScreenState createState() => _PendingOrderScreenState();
}

class _PendingOrderScreenState extends State<PendingOrderScreen> {

  late String orderId;

  String sellerName = '';
  String userid = '';
  void initState() {
    super.initState();
    _loadUserDetails(); // SharedPreferences se data retrieve karna
    _nameController.text = widget.order['amazon_order_id'].toString();
    _empcodeController.text = widget.order['return_tracking_id'].toString();
    _passwordController.text = widget.order['otp'].toString();
    orderId = widget.order['id'].toString(); // Initialize orderId


  }
  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      sellerName = prefs.getString('seller_name') ?? 'N/A';
      userid = prefs.getString('userId') ?? 'N/A';
    });
  }

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _empcodeController = TextEditingController();
  void _clearName() {
    _nameController.clear();
  }
  void _clearEmpcode() {
    _empcodeController.clear();
  }
  void _clearEmpcodss() {
    _passwordController.clear();
  }
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _Addorder() async {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    // Check if any field is empty
    if (_passwordController.text.isEmpty || _nameController.text.isEmpty || _empcodeController.text.isEmpty) {
      return;
    }

    // Validate the form using the existing form key
    if (_formKey.currentState!.validate()) {
      // Check if terms and conditions checkbox is not checked

      // Show loading indicator
      OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Stack(
          children: [
            Container(
              color: Colors.black12.withOpacity(0.8),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      Overlay.of(context)!.insert(overlayEntry);
      https://customprint.deodap.com/amz_dd_return/get_return_orders_by_seller.php?seller_id=$sellerId
      try {
        // API call
        final response = await http.post(
          Uri.parse('https://customprint.deodap.com/api_amzDD_return/update_order.php?tracking_id=$orderId'),
          body: {
            'amazon_order_ids': _nameController.text,
            'return_tracking_ids': _empcodeController.text,
            'otp': _passwordController.text,

          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("API Response: $data");

          if (data['message'] == 'Tracking details updated successfully') {
            setState(() {

            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Order Update successfully',
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.white,
                duration: Duration(seconds: 1),

              ),
            );

            overlayEntry.remove();
          }
          else if (data['message'] == 'Duplicate Tracking ID not allowed') {

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Duplicate Tracking ID Not allowed',
                  style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.red.shade900,
                duration: Duration(seconds: 1),
              ),
            );
            overlayEntry.remove();

          } else {
            setState(() {
              overlayEntry.remove();

            });

            overlayEntry.remove();
          }
        } else {
          overlayEntry.remove();
          // Handle unexpected server errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Server error, please try again later...!',
                style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.red.shade900,
              duration: Duration(seconds: 1),

            ),
          );
        }
      } catch (e) {
        print("Exception: $e");

        overlayEntry.remove();
        // Handle exceptions (like no internet)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No Internet Connection...!',
              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red.shade900,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);  // ✅ Back karne pe `true` return hoga
        return false; // ❌ Default pop nahi karega, hamne manually pop kiya
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1565C0),
          elevation: 0,
          title: Text(
            "Update Return Order",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                _buildCleanInputField(
                  controller: _nameController,
                  hintText: "AMZ Order ID",
                  icon: Icons.local_shipping_outlined,
                  onClear: _clearName,
                ),
                const SizedBox(height: 16),
                _buildCleanInputField(
                  controller: _empcodeController,
                  hintText: "Tracking ID",
                  icon: Icons.location_disabled_outlined,
                  onClear: _clearEmpcode,
                ),
                const SizedBox(height: 16),
                _buildCleanInputField(
                  controller: _passwordController,
                  hintText: "OTP",
                  icon: Icons.verified_user_outlined,
                  onClear: _clearEmpcodss,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (value) {
                    if (value.length == 6) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
                const SizedBox(height: 40),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _Addorder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Update Order",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required VoidCallback onClear,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[600]),
            onPressed: onClear,
          ),
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }
}
