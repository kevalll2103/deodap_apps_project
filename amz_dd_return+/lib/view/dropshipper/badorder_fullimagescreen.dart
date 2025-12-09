import 'package:flutter/material.dart';

class BadOrderImagesScreen extends StatelessWidget {
  final List<String> imageUrls;

  const BadOrderImagesScreen({super.key, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Bad Order Images",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios), // Yahan back icon change kiya gaya hai
          onPressed: () {
            Navigator.pop(context); // Back action ke liye
          },
        ),
      ),

      body: Center(
        child: PageView.builder(
          itemCount: imageUrls.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              panEnabled: true, // Drag allowed
              boundaryMargin: EdgeInsets.zero, // No margin shift
              minScale: 1.0, // Minimum zoom level
              maxScale: 5.0, // Maximum zoom level
              child: Center( // Image ko center me fix rakhne ke liye
                child: FittedBox(
                  fit: BoxFit.contain, // Image ko frame ke andar adjust karega
                  child: Image.network(imageUrls[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
