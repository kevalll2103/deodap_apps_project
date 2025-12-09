// lib/qr_scanner.dart
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class ClubOrderScanScreen extends StatefulWidget {
  final int warehouseId;
  final String warehouseLabel;

  const ClubOrderScanScreen({
    super.key,
    required this.warehouseId,
    required this.warehouseLabel,
  });

  @override
  State<ClubOrderScanScreen> createState() => _ClubOrderScanScreenState();
}

class _ClubOrderScanScreenState extends State<ClubOrderScanScreen>
    with SingleTickerProviderStateMixin {
  // ===== API config =====
  static const String baseUrl = 'https://api.vacalvers.com/api-wms-app';
  static const String appId = '1';
  static const String apiKey = 'd80fc360-f2ed-4cbd-a65d-761d14660ea4';

  // ===== iOS tones =====
  final Color _iosBlue = const Color(0xFF6B52A3);
  final Color _iosGreen = const Color(0xFF34C759);
  final Color _iosRed = const Color(0xFFFF3B30);

  // ===== scanner & audio =====
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    torchEnabled: false,
  );
  final AudioPlayer _player = AudioPlayer();

  bool _isBusy = false;
  bool _torchOn = false;
  bool _usingFrontCam = false;

  // Mobikwik-style square window
  static const double _windowSize = 280.0;
  static final BorderRadius _windowRadius = BorderRadius.circular(18);

  // animated scan line
  late final AnimationController _scanLineCtrl;
  late final Animation<double> _scanLineAnim;

  // cloudfront assets base
  String? _assetsBaseUrl; // e.g. https://d3np6213isvzh.cloudfront.net/

  String get _scanKey => 'scan_count_${widget.warehouseId}';

  @override
  void initState() {
    super.initState();
    _initAudio();
    _scanLineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _scanLineAnim = CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut);
    _ensureAssetsBaseUrl(); // fetch & cache once
  }

  Future<void> _initAudio() async {
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setVolume(0);
      await _player.play(AssetSource('audio/silence-50ms.mp3'));
      await _player.stop();
      await _player.setVolume(1);
    } catch (_) {}
  }

  Future<void> _ensureAssetsBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('assets_base_url');
    if (cached != null && cached.isNotEmpty) {
      setState(() => _assetsBaseUrl = _normalizeBase(cached));
      return;
    }
    try {
      final url = Uri.parse('$baseUrl/app_info').replace(queryParameters: {
        'app_id': appId,
        'api_key': apiKey,
      });
      final res = await http.get(url, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = (body['data'] ?? {}) as Map<String, dynamic>;
        final base = (data['assets_base_url'] ?? '').toString();
        if (base.isNotEmpty) {
          final norm = _normalizeBase(base);
          await prefs.setString('assets_base_url', norm);
          if (mounted) setState(() => _assetsBaseUrl = norm);
        }
      }
    } catch (_) {}
  }

  String _normalizeBase(String b) {
    // ensure trailing slash
    if (!b.endsWith('/')) return '$b/';
    return b;
  }

  String resolveImageUrl(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http')) return pathOrUrl;
    final base = _assetsBaseUrl ?? '';
    if (base.isNotEmpty) return '$base$pathOrUrl';
    // fallback to API host if base unknown
    return 'https://api.vacalvers.com/$pathOrUrl';
    // If your API returns paths already under cloudfront like "catalog/…",
    // cloudfront base will be used automatically once fetched.
  }

  @override
  void dispose() {
    _scanLineCtrl.dispose();
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  // ===== API calls =====
  Future<Map<String, dynamic>> _scanInward(String qr) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final url = Uri.parse('$baseUrl/catalog_products/inward_qr_scan').replace(queryParameters: {
      'app_id': appId,
      'api_key': apiKey,
      'token': token,
      'qr': qr,
    });
    final res = await http.get(url, headers: {'Accept': 'application/json'});
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'http': res.statusCode, 'body': body};
  }

  Future<Map<String, dynamic>> _updateProduct({
    required int productId,
    int? addStock,
    String? newSubLocation,
    int? newReserveThreshold,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final url = Uri.parse('$baseUrl/catalog_products/update');
    final payload = <String, dynamic>{
      'app_id': appId,
      'api_key': apiKey,
      'token': token,
      'product_id': productId,
      if (addStock != null) 'add_stock': addStock,
      if (newSubLocation != null) 'new_stock_physical_sub_location': newSubLocation,
      if (newReserveThreshold != null) 'new_stock_reserve_threshold': '$newReserveThreshold',
    };
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(payload),
    );
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {}
    return {'http': res.statusCode, 'body': body};
  }

  // ===== helpers =====
  Future<void> _playAsset(String asset, {Duration minPlay = const Duration(milliseconds: 300)}) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
      await Future.delayed(minPlay);
      await _player.stop();
    } catch (_) {}
  }

  Future<void> _showSuccessToast(String title, String message) async {
    HapticFeedback.lightImpact();
    unawaited(_playAsset('audio/success.mp3'));
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 90),
          child: _CupertinoToast(
            color: _iosGreen,
            icon: CupertinoIcons.check_mark_circled_solid,
            title: title,
            message: message,
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showErrorDialogAndHome(String title, String message) async {
    HapticFeedback.heavyImpact();
    unawaited(_playAsset('audio/alert.mp3', minPlay: const Duration(milliseconds: 800)));
    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.exclamationmark_triangle_fill, color: _iosRed, size: 20),
            const SizedBox(width: 8),
            Flexible(child: Text(title)),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _showPlainError(String title, String message) async {
    await showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(padding: const EdgeInsets.only(top: 8), child: Text(message)),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_scanKey) ?? 0;
    await prefs.setInt(_scanKey, current + 1);
  }

  // ===== scan handler =====
  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isBusy) return;
    final String? qr = capture.barcodes.firstOrNull?.rawValue;
    if (qr == null || qr.trim().isEmpty) return;

    setState(() => _isBusy = true);
    await _controller.stop();

    try {
      final scanRes = await _scanInward(qr);
      final code = scanRes['http'] as int;
      final body = (scanRes['body'] as Map<String, dynamic>?) ?? {};
      final flag = body['status_flag'];

      if (code == 200 && flag == 1) {
        await _incrementScanCount();
        final data = (body['data'] ?? {}) as Map<String, dynamic>;
        await _showInwardDialog(data);
      } else {
        final msg = _extractMsg(body, fallback: 'Invalid or unknown QR.');
        await _showErrorDialogAndHome('Scan Failed', msg);
      }
    } catch (e) {
      await _showErrorDialogAndHome('Scan Failed', 'Something went wrong: $e');
    }

    if (!mounted) return;
    setState(() => _isBusy = false);
    await _controller.start();
  }

  String _extractMsg(Map<String, dynamic> body, {String fallback = 'Error'}) {
    if (body['status_messages'] is List && (body['status_messages'] as List).isNotEmpty) {
      return body['status_messages'][0].toString();
    }
    if (body['message'] != null) return body['message'].toString();
    return fallback;
  }

  // ===== iOS pop-up (OK/Cancel) =====
  Future<void> _showInwardDialog(Map<String, dynamic> data) async {
    final int productId = (data['id'] as num).toInt();
    final String sku = (data['sku'] ?? '').toString();
    final String name = (data['name'] ?? '').toString();
    final int stock = (data['stock'] as num?)?.toInt() ?? 0;
    final String loc = (data['stock_physical_location'] ?? '').toString();
    final String subLoc = (data['stock_physical_sub_location'] ?? '').toString();
    final int inwardQty = int.tryParse((data['qr_inward_qty'] ?? '1').toString()) ?? 1;
    final String image = (data['image'] ?? '').toString();

    final qtyCtrl = TextEditingController(text: inwardQty.toString());
    final subLocCtrl = TextEditingController(text: subLoc.isNotEmpty ? subLoc : '');
    final reserveCtrl = TextEditingController();

    HapticFeedback.selectionClick();

    await showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocal) {
          final resolvedUrl = resolveImageUrl(image);
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resolvedUrl.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      resolvedUrl,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: CupertinoColors.systemGrey5,
                        child: const Center(child: Icon(CupertinoIcons.photo)),
                      ),
                    ),
                  ),
                ),
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('SKU: $sku', style: const TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
              Text('Stock: $stock', style: const TextStyle(fontSize: 13)),
              Text('Location: $loc • Sub: ${subLoc.isEmpty ? "-" : subLoc}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              _CupertinoInlineField(
                label: 'Add Stock (pcs)',
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                placeholder: 'e.g. $inwardQty',
              ),
              const SizedBox(height: 8),
              _CupertinoInlineField(
                label: 'New Sub-Location (A + 3 digits)',
                controller: subLocCtrl,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.characters,
                placeholder: 'e.g. A003',
              ),
              const SizedBox(height: 8),
              _CupertinoInlineField(
                label: 'New Reserve Threshold (optional)',
                controller: reserveCtrl,
                keyboardType: TextInputType.number,
                placeholder: 'e.g. 200',
              ),
            ],
          );

          return CupertinoAlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(CupertinoIcons.cube_box_fill, size: 20),
                SizedBox(width: 8),
                Flexible(child: Text('Update Product')),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SingleChildScrollView(child: info),
            ),
            actions: [
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(ctx, rootNavigator: true).pop();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text.trim());
                  final sub = subLocCtrl.text.trim().toUpperCase();
                  final thr = reserveCtrl.text.trim().isEmpty
                      ? null
                      : int.tryParse(reserveCtrl.text.trim());

                  if (qty == null || qty < 0) {
                    await _showPlainError('Invalid value', 'Please enter a valid non-negative Add Stock.');
                    return;
                  }
                  if (sub.isNotEmpty && !_isValidSubLoc(sub)) {
                    await _showPlainError('Invalid sub-location', 'Use format: A + 3 digits (e.g. A003).');
                    return;
                  }

                  Navigator.of(ctx, rootNavigator: true).pop();

                  setState(() => _isBusy = true);
                  final upd = await _updateProduct(
                    productId: productId,
                    addStock: qty,
                    newSubLocation: sub.isEmpty ? null : sub,
                    newReserveThreshold: thr,
                  );
                  setState(() => _isBusy = false);

                  final code = upd['http'] as int;
                  final body = (upd['body'] as Map<String, dynamic>?) ?? {};
                  if (code == 200 && body['status_flag'] == 1) {
                    final msg = _extractMsg(body, fallback: 'Product has been updated!');
                    await _showSuccessToast('Updated', msg);
                    if (mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  } else {
                    final msg = _extractMsg(body, fallback: 'Update failed.');
                    await _showErrorDialogAndHome('Update Failed', msg);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
      },
    );
  }

  bool _isValidSubLoc(String s) => RegExp(r'^[A-Z][0-9]{3}$').hasMatch(s);

  // ===== UI =====
  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  Future<void> _switchCamera() async {
    await _controller.switchCamera();
    setState(() => _usingFrontCam = !_usingFrontCam);
  }

  void _goHome() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final whNum = 'wh.${widget.warehouseId}';
    return WillPopScope(
      onWillPop: () async {
        _goHome(); // Android back → Home
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 72,
          backgroundColor: CupertinoColors.systemBackground,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: CupertinoButton(
            padding: const EdgeInsets.only(left: 8),
            onPressed: _goHome,
            child: const Icon(CupertinoIcons.back, color: Colors.black, size: 28),
          ),
          title: Text(
            'Inward QR – ${widget.warehouseLabel} ($whNum)',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 17),
          ),
          centerTitle: true,
          actions: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _toggleTorch,
              child: Icon(
                _torchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
                color: _torchOn ? Colors.amber : _iosBlue,
                size: 24,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: _switchCamera,
              child: Icon(CupertinoIcons.camera_rotate_fill, color: _iosBlue, size: 24),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final Rect windowRect = Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: _windowSize,
              height: _windowSize,
            );

            return Stack(
              children: [
                // camera feed
                Positioned.fill(
                  child: MobileScanner(controller: _controller, onDetect: _handleDetect),
                ),

                // translucent mask with square hole (Mobikwik style)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TransparentOverlayPainter(
                        holeRect: windowRect,
                        radius: _windowRadius,
                        overlayColor: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),

                // white frame & corners
                Positioned(
                  left: (size.width - _windowSize) / 2,
                  top: (size.height - _windowSize) / 2,
                  child: IgnorePointer(
                    child: Container(
                      width: _windowSize,
                      height: _windowSize,
                      decoration: BoxDecoration(
                        borderRadius: _windowRadius,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Stack(
                        children: [
                          ..._buildCornerIndicators(Colors.white),
                          // animated scan line (kept red for contrast)
                          AnimatedBuilder(
                            animation: _scanLineAnim,
                            builder: (context, child) {
                              const double topPadding = 16, bottomPadding = 16;
                              final usableHeight = _windowSize - topPadding - bottomPadding;
                              final y = topPadding + usableHeight * _scanLineAnim.value;
                              return Positioned(
                                top: y,
                                left: 12,
                                right: 12,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: _iosRed,
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _iosRed.withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // hint
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Align QR code within the frame',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                if (_isBusy)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CupertinoActivityIndicator(radius: 16)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCornerIndicators(Color color) {
    const double cornerSize = 26.0;
    const double cornerThickness = 4.0;
    return [
      Positioned(
        top: 12,
        left: 12,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: cornerThickness),
              left: BorderSide(color: color, width: cornerThickness),
            ),
          ),
        ),
      ),
      Positioned(
        top: 12,
        right: 12,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: cornerThickness),
              right: BorderSide(color: color, width: cornerThickness),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 12,
        left: 12,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: cornerThickness),
              left: BorderSide(color: color, width: cornerThickness),
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 12,
        right: 12,
        child: Container(
          width: cornerSize,
          height: cornerSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: color, width: cornerThickness),
              right: BorderSide(color: color, width: cornerThickness),
            ),
          ),
        ),
      ),
    ];
  }
}

// ===== painters & widgets =====
class _TransparentOverlayPainter extends CustomPainter {
  _TransparentOverlayPainter({
    required this.holeRect,
    required this.radius,
    required this.overlayColor,
  });

  final Rect holeRect;
  final BorderRadius radius;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Path outerPath = Path()..addRect(Offset.zero & size);
    final RRect scanWindow = RRect.fromRectAndCorners(
      holeRect,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );
    final Path holePath = Path()..addRRect(scanWindow);
    final Path finalPath = Path.combine(PathOperation.difference, outerPath, holePath);
    final Paint paint = Paint()..color = overlayColor..style = PaintingStyle.fill;
    canvas.drawPath(finalPath, paint);
  }

  @override
  bool shouldRepaint(covariant _TransparentOverlayPainter old) {
    return old.holeRect != holeRect || old.radius != radius || old.overlayColor != overlayColor;
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : this[0];
}

class _CupertinoToast extends StatelessWidget {
  const _CupertinoToast({
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CupertinoInlineField extends StatelessWidget {
  const _CupertinoInlineField({
    required this.label,
    required this.controller,
    this.placeholder,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: CupertinoColors.systemGrey)),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ],
    );
  }
}
