import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CleanInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;

  const CleanInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
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
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color(0xFF1565C0), size: 20),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () => controller.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
      ),
    );
  }
}

class DropshipperAddreturnOrderView extends StatefulWidget {
  const DropshipperAddreturnOrderView({super.key});

  @override
  State<DropshipperAddreturnOrderView> createState() => _DropshipperAddreturnOrderViewState();
}

class _DropshipperAddreturnOrderViewState extends State<DropshipperAddreturnOrderView> {
  String sellerId = '';
  bool _isLoading = false;

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _trackingIdController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  DateTime? selectedDeliveryDate;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _deliveryDateController.text = "${DateTime.now().toLocal()}".split(' ')[0];
  }

  Future<void> _loadUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      sellerId = prefs.getString('seller_id') ?? '';
    });
  }

  void _Addorder() async {
    FocusScope.of(context).unfocus();

    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final overlayEntry = OverlayEntry(
        builder: (context) => Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );

      Overlay.of(context).insert(overlayEntry);

      try {
        final response = await http.post(
          Uri.parse('https://customprint.deodap.com/api_amzDD_return/dropshipper_addorder.php'),
          body: {
            'seller_id': sellerId,
            'amazon_order_ids': _orderIdController.text,
            'return_tracking_ids': _trackingIdController.text,
            'otp': _otpController.text,
            'out_for_delivery_date': _deliveryDateController.text,
            'bad_good_return': 'bad',
          },
        );

        overlayEntry.remove();
        setState(() => _isLoading = false);

        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data['success'] == true) {
          _clearAllFields();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Order added successfully',
                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            duration: Duration(seconds: 2),
          ));
        } else {
          String msg = data['message'] ?? 'Unknown error';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.red.shade900,
            duration: Duration(seconds: 2),
          ));
        }
      } catch (e) {
        overlayEntry.remove();
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No Internet Connection..!'),
          backgroundColor: Colors.red.shade900,
        ));
      }
    }
  }

  void _clearAllFields() {
    _orderIdController.clear();
    _trackingIdController.clear();
    _otpController.clear();
    _deliveryDateController.text = "${DateTime.now().toLocal()}".split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              CleanInputField(
                controller: _orderIdController,
                hintText: 'AMZ Order ID(s) (comma separated)',
                icon: Icons.local_shipping_outlined,
                validator: (value) => value == null || value.isEmpty ? 'Please enter Order ID(s)' : null,
              ),
              CleanInputField(
                controller: _trackingIdController,
                hintText: 'Tracking ID(s) (comma separated)',
                icon: Icons.location_disabled_outlined,
                validator: (value) => value == null || value.isEmpty ? 'Please enter Tracking ID(s)' : null,
              ),
              CleanInputField(
                controller: _otpController,
                hintText: 'OTP',
                icon: Icons.verified_user_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (value) => value == null || value.isEmpty ? 'Please enter OTP' : null,
              ),
              CleanInputField(
                controller: _deliveryDateController,
                hintText: 'Out for Delivery Date',
                icon: Icons.calendar_today,
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2023),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFF1565C0),
                            onPrimary: Colors.white,
                            onSurface: Colors.black,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDeliveryDate = picked;
                      _deliveryDateController.text = "${picked.toLocal()}".split(' ')[0];
                    });
                  }
                },
                validator: (value) => value == null || value.isEmpty ? 'Please select a delivery date' : null,
              ),
              const SizedBox(height: 40),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildCleanButton(
          "Add Return Order", 
          Icons.add_task, 
          _Addorder,
          Color(0xFF1565C0),
        ),
        const SizedBox(height: 16),
        _buildCleanButton(
          "Clear All Fields", 
          Icons.clear_all, 
          _clearAllFields,
          Colors.grey[600]!,
        ),
      ],
    );
  }

  Widget _buildCleanButton(String label, IconData icon, VoidCallback onPressed, Color color) {
    return Container(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1565C0),
      elevation: 0,
      title: Text(
        "Add Return Order",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_return_rounded,
                  color: Color(0xFF1565C0),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Return Order Form',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fill in the details to add a return order',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
