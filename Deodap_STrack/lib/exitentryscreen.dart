import 'dart:convert';
import 'package:Deodap_STrack/fullimagescreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:Deodap_STrack/homescreen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:http_parser/http_parser.dart'; // Add this for MediaType

class Exitentryscreen extends StatefulWidget {
  final String id;
  final String receivedFrom;
  final String receivedDatetime;
  final String isPending;

  const Exitentryscreen({
    super.key,
    required this.id,
    required this.receivedFrom,
    required this.receivedDatetime,
    required this.isPending,
  });

  @override
  State<Exitentryscreen> createState() => _ExitentryscreenState();
}

class _ExitentryscreenState extends State<Exitentryscreen> with TickerProviderStateMixin {
  late bool isPending;
  late TabController _tabController;
  late Future<Map<String, dynamic>> inwardDataFuture;
  final PageController _pageController = PageController();
  Map<String, dynamic>? inwardData;
  final List<File> _images = []; // Store images
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  FocusNode _nameFocusNode = FocusNode();
  String nameError = '';

  Future<File> _convertToJpgOrPng(File imageFile, {bool toPng = false}) async {
    final imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      print("❌ Image decoding failed!");
      return imageFile;
    }

    List<int> convertedBytes;
    String newExtension = toPng ? 'png' : 'jpg';
    if (toPng) {
      convertedBytes = img.encodePng(image);
    } else {
      convertedBytes = img.encodeJpg(image, quality: 85);
    }

    String newPath = '${imageFile.parent.path}/${DateTime.now().millisecondsSinceEpoch}.$newExtension';
    File newFile = File(newPath);
    await newFile.writeAsBytes(convertedBytes);

    print("✅ Converted Image Path: ${newFile.path}");
    return newFile;
  }

  Future<void> _pickImage() async {
    FocusScope.of(context).unfocus();
    if (_images.length >= 4) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // 🧐 Check image type
        String fileExtension = path.extension(imageFile.path).toLowerCase();
        print("🧐 Image Type: $fileExtension");

        setState(() {
          _images.add(imageFile);
        });

        print("✅ Image added to list: ${imageFile.path}");
      } else {
        print("❌ No image selected!");
      }
    } catch (e) {
      print("❌ Camera Error: $e");
    }
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    if (_nameController.text.isEmpty || _images.isEmpty) {
      print("❌ Empty field");
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

    Overlay.of(context)!.insert(overlayEntry);

    var uri = Uri.parse("https://tools.deodap.in/api/sample-product-api/product.php");
    var request = http.MultipartRequest("POST", uri);

    request.fields['action'] = 'outward';
    request.fields['id'] = widget.id;
    request.fields['outward_taken_name'] = _nameController.text;

    for (int i = 0; i < _images.length; i++) {
      File imageFile = _images[i];
      String filePath = imageFile.path;
      String fileExtension = path.extension(filePath).toLowerCase();

      print("📤 Uploading Image Path: $filePath");
      print("🔎 Image Exists: ${imageFile.existsSync()}");

      // ✅ Set correct MIME Type based on file extension
      MediaType contentType;
      if (fileExtension == '.png') {
        contentType = MediaType('image', 'png');
      } else if (fileExtension == '.jpeg' || fileExtension == '.jpg') {
        contentType = MediaType('image', 'jpeg');
      } else {
        contentType = MediaType('image', 'jpeg'); // Default to JPEG
      }

      print("🖼 MIME Type: ${contentType.type}/${contentType.subtype}");

      request.files.add(await http.MultipartFile.fromPath(
        'image${i + 1}',
        filePath,
        filename: path.basename(filePath),
        contentType: contentType,
      ));
    }

    print("📡 Sending API Request...");

    try {
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      print("📩 API Response: $jsonResponse");

      if (jsonResponse['status'] == 'success') {
        print("✅ Success: ${jsonResponse['data']}");
        _nameController.clear();
        setState(() {
          _images.clear();
        });
        Navigator.push(context,
          MaterialPageRoute(
              builder: (context) => Homescreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added Successfully!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFF0B90A1),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        print("❌ Error: ${jsonResponse['errors']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server Down, try again later!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red.shade900,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print("❌ API Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No Internet Connection!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red.shade900,
          duration: Duration(seconds: 1),
        ),
      );
    } finally {
      overlayEntry.remove();
    }
  }


  // Remove selected image
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // Clear all images
  void _clearAllImages() {
    setState(() {
      _images.clear();
    });
  }
  void _clearName() {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard
    FocusScope.of(context).unfocus();

    _nameController.clear();
  }

  @override
  void dispose() {

    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }
  // Show full-screen image with swipe functionality
  void _showFullImage(int index) {
    FocusScope.of(context).requestFocus(FocusNode()); // Dismiss the keyboard
    FocusScope.of(context).unfocus();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: index),
                itemCount: _images.length,
                itemBuilder: (context, pageIndex) {
                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0, // Zoom limit
                    child: Center(
                      child: Image.file(
                        _images[pageIndex],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  @override
  void initState() {
    super.initState();
    isPending = widget.isPending.toLowerCase() == "true";
    _tabController = TabController(length: 2, vsync: this);
    inwardDataFuture = fetchInwardData();
    inwardDataFuture.then((data) {
      setState(() {
        inwardData = data; // Store it for later use
      });
    });
  }



  Future<Map<String, dynamic>> fetchInwardData() async {
    var uri = Uri.parse('https://tools.deodap.in/api/sample-product-api/product.php');
    var response = await http.post(uri, body: {
      "action": "detail",
      "id": widget.id,
    });

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        return jsonData['data'];
      } else {
        throw Exception('Failed to load data');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Outward Entry",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 10,),
            Text(
              inwardData != null ? "${inwardData!['id']}" : "",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.orange,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),        backgroundColor: const Color(0xFF0B90A1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              isPending ? Icons.access_time : Icons.check_circle,
              color: isPending ? Colors.orange : Colors.white,
              size: 30,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          labelStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'Inward'),
            Tab(text: 'Outward'),
          ],
          indicator: const BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 3, color: Colors.orange),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildInwardTab(),
          isPending ? buildPendingOutwardTab() : buildDoneOutwardTab(),
        ],
      ),
    );
  }

  Widget buildInwardTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: inwardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            color: Color(0xFF0B90A1),
          ));
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Colors.black, size: 100),
                SizedBox(height: 20),
                Text(
                  "No Internet Connection..!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          );
        }

        var data = snapshot.data!;
        var imageList = List<Map<String, dynamic>>.from(data['inward_images']);
        return SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Entry Username: ${data['received_from']}", style: const TextStyle(fontSize: 15)),
                    Text("Entry Datetime: ${data['received_datetime']}", style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 500,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: imageList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Fullimagescreen(
                                      imageList: imageList,
                                      initialIndex: index,
                                    ),
                                  ),
                                );
                              },

                              child: Hero(
                                tag: imageList[index]['path'],
                                child: Image.network(
                                  imageList[index]['path'],
                                  fit: BoxFit.contain,
                                  height: 350,
                                  alignment: Alignment.center,
                                  width: double.infinity,
                                ),
                              ),
                            )

                          );
                        },

                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: imageList.length,
                        effect: const WormEffect(
                          dotHeight: 10,
                          dotWidth: 10,
                          activeDotColor: Colors.orange,
                          dotColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ),
        );
      },

    );
  }
  Widget buildPendingOutwardTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            SizedBox(height: 40),
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              cursorColor: Colors.black,
              decoration: InputDecoration(
                hintText: "Exit Sample name",
                hintStyle: TextStyle(color: Colors.grey),
                errorText: nameError.isEmpty ? null : nameError,
                suffixIcon: IconButton(
                  icon: Icon(Icons.cancel_outlined, color: Color(0xFF0d1627)),
                  onPressed: _clearName,
                ),
                prefixIcon: Icon(Icons.production_quantity_limits,
                    color: Colors.grey),
                labelStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: Color(0xFF0d1627), width: 1.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: Color(0xFF0d1627), width: 1.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            SizedBox(height: 40),
            Container(
              width: 300,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border:
                Border.all(color: Colors.black26, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _images.isEmpty
                  ? _buildUploadSection()
                  : _buildImageScrollView(),
            ),
            const SizedBox(height: 12),
            if (_images.length < 4 && _images.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add More Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B90A1),
                  foregroundColor: Colors.white,
                ),
              ),
            if (_images.length == 4)
              ElevatedButton.icon(
                onPressed: _clearAllImages,
                icon: const Icon(Icons.delete),
                label: const Text("Clear All Images"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                ),
              ),
            SizedBox(height: 30),
            OutlinedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0B90A1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                side: BorderSide(color: Colors.white),
                minimumSize: Size(double.infinity, 45),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Add",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDoneOutwardTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: inwardDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(
            color: Color(0xFF0B90A1),
          ));
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.signal_wifi_connected_no_internet_4_rounded, color: Colors.black, size: 100),
                SizedBox(height: 20),
                Text(
                  "No Internet Connection..!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          );
        }

        var data = snapshot.data!;
        var imageList = List<Map<String, dynamic>>.from(data['outward_images']);
        return SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Exit Username: ${data['exit_taken_by']}", style: const TextStyle(fontSize: 15)),
                    Text("Exit Datetime: ${data['exit_datetime']}", style: const TextStyle(fontSize: 15)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 500,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: imageList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Fullimagescreen(
                                        imageList: imageList,
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },

                                child: Hero(
                                  tag: imageList[index]['path'],
                                  child: Image.network(
                                    imageList[index]['path'],
                                    fit: BoxFit.contain,
                                    height: 350,
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                  ),
                                ),
                              )

                          );
                        },

                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: imageList.length,
                        effect: const WormEffect(
                          dotHeight: 10,
                          dotWidth: 10,
                          activeDotColor: Colors.orange,
                          dotColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              )
          ),
        );
      },

    );
  }
  // Upload Section (Initial View)
  Widget _buildUploadSection() {
    return InkWell(
      onTap: _pickImage,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.camera_alt, size: 60, color: Colors.black54),
          SizedBox(height: 8),
          Text("Upload Image", style: TextStyle(fontSize: 16, color: Colors.black54,fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Image Scroll View
  Widget _buildImageScrollView() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(_images.length, (index) {
          return Stack(
            children: [
              GestureDetector(
                onTap: () => _showFullImage(index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 134, // Adjust based on number of images
                    height: 145,
                    child: Image.file(
                      _images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 1,
                right: 1,
                child: GestureDetector(
                  onTap: () => _removeImage(index),
                  child: Container(
                    height: 18,
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade900,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

}
