import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:photo_view/photo_view.dart';
class ShowfullscreenimageScreen extends StatelessWidget {
  final Uint8List imageBytes;

  const ShowfullscreenimageScreen({super.key,required this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          "View Image",
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // This will navigate back to the previous screen
          },
        ),


      ),

      backgroundColor: Colors.black,
      body: PhotoView(
        imageProvider: MemoryImage(imageBytes),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2, // Zoom level
        heroAttributes: const PhotoViewHeroAttributes(tag: 'imageHero'),
      ),
    );
  }
}
