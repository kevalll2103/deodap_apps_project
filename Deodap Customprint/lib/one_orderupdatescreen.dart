import 'package:Deodap_Customprint/secondfullimage_screen.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart'as http;
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;


class OrderUpdatescreenView extends StatefulWidget {
  final String? productName;
  final String Id; // Add this
  final String productUniqueId;
  final String productImage;
  final String createdAt;

  const OrderUpdatescreenView({
    Key? key,
    required this.productUniqueId,
    required this.productImage,
    required this.Id, // Add this

    required this.createdAt,
    this. productName,

  }): super(key: key);

  @override
  State<OrderUpdatescreenView> createState() => _OrderUpdatescreenViewState();
}

class _OrderUpdatescreenViewState extends State<OrderUpdatescreenView> {
late TextEditingController orderIdController;
bool _hasImage = false; // Track whether an image is displayed
Uint8List? _imageBytes;
String? _imageFileName;
String? _timestamp; // Use nullable type

final ImagePicker _picker = ImagePicker();
bool _isLoading = false; // Add this in your class

Future<void> _getImage(ImageSource source) async {
  final pickedFile = await _picker.pickImage(source: source);

  if (pickedFile != null) {
    final image = File(pickedFile.path);
    final bytes = await image.readAsBytes();

    setState(() {
      _imageBytes = bytes; // Update with new image bytes
      _imageFileName = path.basename(image.path); // Store the original file name
      _hasImage = true; // Set to true since an image is now selected
    });
  }
}
final FocusNode _focusNode = FocusNode(); // FocusNode to control focus

void ClearImage() {
  setState(() {
    FocusScope.of(context).unfocus(); // Dismiss the keyboard
    _focusNode.unfocus();  // Remove focus
    _hasImage = false; // Set to false when clearing the image
  });
}


void ClearID() {
  FocusScope.of(context).unfocus(); // Dismiss the keyboard
  _focusNode.unfocus();  // Remove focus
  orderIdController.clear();
}
@override
void initState() {
  super.initState();
  _imageBytes = null; // Initialize to null; will be set when image is selected
  orderIdController = TextEditingController(text: widget.productUniqueId);
}

@override
void dispose() {
  orderIdController.dispose();
  _focusNode.dispose(); // Clean up the focus node when the widget is disposed
  super.dispose();
}


Future<void> _addProduct() async {
  FocusScope.of(context).unfocus(); // Dismiss the keyboard
  _focusNode.unfocus();  // Remove focus
  FocusScope.of(context).unfocus();

  final String orderId = orderIdController.text.trim();
  final String productUniqueId = orderIdController.text.trim();

  // Validate input fields
  if (orderId.isEmpty || productUniqueId.isEmpty) {

    return;
  }

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

  // Show loading overlay
  Overlay.of(context)!.insert(overlayEntry);

  setState(() {
    _isLoading = true; // Start loading
  });

  try {
    var request = http.MultipartRequest(
      'POST',
      // Uri.parse('https://customprint.deodap.com/update_order.php?id=${widget.Id}'),
      Uri.parse('https://customprint.deodap.com/api_customprint/update_order.php?id=${widget.Id}'),
    );

    request.fields['product_unique_id'] = productUniqueId;
    request.fields['product_id'] = orderId;

    // Attach image if it exists
    if (_hasImage && _imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'product_image',
        _imageBytes!,
        filename: _imageFileName,
      ));
    }

    final response = await request.send();
    final responseString = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(responseString.body);
      print('Response data: $jsonResponse');

      if (jsonResponse['error'] != null) {
        overlayEntry.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order ID already exist..!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade900, // Change background color
            duration: Duration(seconds: 1), // Duration before it disappears

          ),
        );
      } else {
        Navigator.pop(context);

        overlayEntry.remove(); // Remove loading overlay
        setState(() {
          _timestamp = jsonResponse['product']['created_at']; // Update timestamp
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order Update Successfully',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF0B90A1),
            duration: Duration(seconds: 2), // Duration before it disappears


          ),
        );
      }
    } else {
      overlayEntry.remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Server error plz try again.!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade900, // Change background color
          duration: Duration(seconds: 1), // Duration before it disappears

        ),
      );
    }
  } on SocketException {
    overlayEntry.remove();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ' No Internet try again...!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade900, // Change background color
        duration: Duration(seconds: 1), // Duration before it disappears

      ),
    );

  }

  catch (e) {
    print('Error updating product: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('An unexpected error occurred.'),
      backgroundColor: Colors.red,
    ));
  } finally {
    overlayEntry.remove(); // Always remove the overlay at the end
    setState(() {
      _isLoading = false; // Stop loading
    });
  }
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      centerTitle: true,
      backgroundColor: Color(0xFF0B90A1),
      title: Text("Update Order", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),

    ),
    body: GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus(); // Remove focus from any input fields

      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, left: 25, right: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Date And Time: ${_timestamp ?? widget.createdAt}', // Display widget.createdAt if _timestamp is null
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ), SizedBox(height: 15,),
              GestureDetector(
                onTap: (){
                  FocusScope.of(context).unfocus(); // Remove focus from any input fields
                },
                child: Container(
                  child: InkWell(
                    onTap: () {
                      FocusScope.of(context).unfocus(); // Dismiss the keyboard
                      _focusNode.unfocus();  // Remove focus
                      if (_hasImage && _imageBytes != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShowFullimageScreenView(
                              imageBytes: _imageBytes!, imageUrl: '', // Pass the bytes of the selected image
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShowFullimageScreenView(
                              imageUrl: widget.productImage, // Pass the default image URL
                            ),
                          ),
                        );
                      }

                    },
                    child: Align(
                      alignment: Alignment.center,
                      child: DottedBorder(
                        borderType: BorderType.RRect,
                        radius: Radius.circular(12),
                        padding: EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          child: Container(
                            color: Colors.grey.shade300,
                            height: 300,
                            width: double.infinity,
                            child: _hasImage && _imageBytes != null
                                ? Image.memory(_imageBytes!) // Display the new image
                                : Image.network(widget.productImage), // Show the default image if no new image is selected

                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: (){
                  FocusScope.of(context).unfocus();
                  _getImage(ImageSource.camera);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  backgroundColor: Colors.red.shade800,
                  minimumSize: Size(35, 40),
                ),
                child: Text(
                  'Change Image',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              SizedBox(height: 20),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Order ID :-",style: TextStyle(color: Color(0xFF25253c),fontWeight: FontWeight.bold,fontSize: 16),)),
              SizedBox(height: 5,),
              TextFormField(
                controller: orderIdController,
                focusNode: _focusNode, // Attach the focus node
                decoration: InputDecoration(
                  filled: true,
                  hintText: 'Order ID',  // Keep hintText as the default placeholder
                  suffixIcon: IconButton(
                    icon: Icon(Icons.document_scanner_outlined, color: Colors.black),
                    onPressed: () async {
                      // Navigate to the QR scanner screen and await the result
                      // _focusNode.unfocus();  // Remove focus
                      // FocusScope.of(context).unfocus(); // Dismiss the keyboard
                      // _focusNodeOrderName.unfocus(); // Remove focus from the second field
                      //
                      // final scannedOrderId = await Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => OrderUpdateOrCode()),
                      // );
                      //
                      // // If a valid order ID was returned, update the TextFormField
                      // if (scannedOrderId != null && scannedOrderId != 'No order ID available') {
                      //   // Only update if a valid order ID is scanned
                      //   orderIdController.text = scannedOrderId;
                      // } else {
                      //   // Don't change anything if no valid order ID was found
                      //   // Hint text remains in place if no valid input
                      // }
                    },
                  ),
                  fillColor: Colors.grey[300],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                ),
                cursorColor: Colors.blue.shade900,
                style: TextStyle(color: Colors.black),
              ),


              SizedBox(height: 40,),

              ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _addProduct();
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  backgroundColor: Color(0xFF0B90A1),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  'Update',
                  style: TextStyle(color: Colors.white, fontSize: 18),
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
