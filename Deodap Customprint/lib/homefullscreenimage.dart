import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeFullScreenImage extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;

  const HomeFullScreenImage({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  State<HomeFullScreenImage> createState() => _HomeFullScreenImageState();
}

class _HomeFullScreenImageState extends State<HomeFullScreenImage> {
  late PhotoViewController _photoViewController;
  double _scale = 1.0;
  bool _isLoading = true;
  bool _hasError = false;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _photoViewController = PhotoViewController()
      ..outputStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _scale = state.scale ?? 1.0;
            // Hide app bar when zoomed in
            if (_scale > 1.0 && _showAppBar) {
              _showAppBar = false;
            } else if (_scale <= 1.0 && !_showAppBar) {
              _showAppBar = true;
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showAppBar ? AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          "View Image",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && !_hasError)
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadImage,
              tooltip: 'Download Image',
            ),
        ],
      ) : null,
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          // Toggle app bar visibility on single tap
          setState(() => _showAppBar = !_showAppBar);
        },
        onDoubleTap: () {
          // Reset zoom on double tap
          _photoViewController.reset();
        },
        child: Stack(
          children: [
            if (_hasError)
              _buildErrorWidget()
            else
              PhotoView(
                imageProvider: CachedNetworkImageProvider(widget.imageUrl),
                loadingBuilder: (context, event) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _isLoading = true);
                  });
                  return _buildLoadingIndicator();
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                  });
                  return _buildErrorWidget();
                },
                controller: _photoViewController,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                heroAttributes: widget.heroTag != null
                    ? PhotoViewHeroAttributes(tag: widget.heroTag!)
                    : null,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
            if (_isLoading && !_hasError)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Failed to load image',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadImage() async {
    // TODO: Implement image download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Download functionality will be implemented'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}