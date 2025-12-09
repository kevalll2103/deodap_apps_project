import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:photo_view/photo_view.dart';
class ShowFullimageScreenView extends StatelessWidget {
  final String imageUrl;
  final Uint8List? imageBytes;
  const ShowFullimageScreenView({Key? key, this.imageBytes, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "View Image",
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),


      ),
      backgroundColor: Colors.black,
      body: PhotoView(
        imageProvider: imageBytes != null
            ? MemoryImage(imageBytes!) // Use MemoryImage for bytes
            : NetworkImage(imageUrl!), // Use NetworkImage for URL
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2, // Zoom level
        heroAttributes: const PhotoViewHeroAttributes(tag: 'imageHero'),
      ),
    );
  }
}
