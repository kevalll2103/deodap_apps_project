import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:photo_view/photo_view.dart';

class Fullimagescreen extends StatefulWidget {
  final List imageList;
  final int initialIndex;

  const Fullimagescreen({super.key,required this.imageList,
    required this.initialIndex,});

  @override
  State<Fullimagescreen> createState() => _FullimagescreenState();
}

class _FullimagescreenState extends State<Fullimagescreen> {

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "View Image",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context,true),
        ),
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            itemCount: widget.imageList.length,
            pageController: _pageController,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(widget.imageList[index]['path']),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2.5,
                heroAttributes: PhotoViewHeroAttributes(tag: widget.imageList[index]['path']),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(
              color: Colors.black,
            ),
          ),

        ],
      ),
    );
  }
}
