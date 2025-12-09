// lib/warehouse_listscreen.dart
import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, RefreshIndicator, Icons;
import 'package:flutter/services.dart'; // Clipboard
import 'package:http/http.dart' as http;

// Reverse geocoding & deep links
import 'package:geocoding/geocoding.dart' as geo;
import 'package:url_launcher/url_launcher.dart';

import 'pending_order.dart';

// ---------- iOS brand color ----------
const Color kIOSBlue = Color(0xFF007E9B);
const String kDash = '—';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  static const String _url =
      'https://api.vacalvers.com/api-wms-field-app/app_info/warehouse_list';
  static const String _apiKey = 'd5e61e52-fd9d-4ac9-a953-fde5fe5f6e5e';
  static const int _appId = 1;

  List<dynamic> _warehouses = [];
  bool _loading = true;
  String _search = '';
  String? _error;

  // Cache for reverse geocoded addresses by warehouse id
  final Map<int, String> _addressCache = {};
  final Map<int, bool> _addressFailed = {};

  @override
  void initState() {
    super.initState();
    _fetchWarehouses();
  }

  Future<void> _fetchWarehouses() async {
    setState(() {
      _loading = true;
      _error = null;
      _addressCache.clear();
      _addressFailed.clear();
    });

    try {
      // ---- Attempt 1: GET with JSON body
      final client = http.Client();
      try {
        final req = http.Request('GET', Uri.parse(_url))
          ..headers[HttpHeaders.contentTypeHeader] = 'application/json'
          ..body = jsonEncode({'app_id': _appId, 'api_key': _apiKey});

        final streamed =
        await client.send(req).timeout(const Duration(seconds: 20));
        final resp = await http.Response.fromStream(streamed);

        if (resp.statusCode == 200) {
          _handleResponse(resp.body);
          return;
        }
      } finally {
        client.close();
      }

      // ---- Attempt 2: GET with query params
      final uriWithQuery = Uri.parse(_url).replace(queryParameters: {
        'app_id': '$_appId',
        'api_key': _apiKey,
      });

      final resp2 = await http
          .get(
        uriWithQuery,
        headers: {HttpHeaders.acceptHeader: 'application/json'},
      )
          .timeout(const Duration(seconds: 20));

      if (resp2.statusCode == 200) {
        _handleResponse(resp2.body);
        return;
      }

      setState(() {
        _loading = false;
        _error =
        'Server responded with ${resp2.statusCode}. Try again or check API rules.';
      });
    } on SocketException {
      setState(() {
        _loading = false;
        _error = 'No internet connection.';
      });
    } on TimeoutException {
      setState(() {
        _loading = false;
        _error = 'Request timed out.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Something went wrong: $e';
      });
    }
  }

  void _handleResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['status_flag'] == 1 && decoded['data'] is List) {
          setState(() {
            _warehouses = decoded['data'];
            _loading = false;
          });
        } else {
          final msg = (decoded['status_messages'] is List &&
              (decoded['status_messages'] as List).isNotEmpty)
              ? (decoded['status_messages'] as List).join('\n')
              : 'API returned an error.';
          setState(() {
            _loading = false;
            _error = msg;
          });
        }
      } else {
        setState(() {
          _loading = false;
          _error = 'Unexpected response format.';
        });
      }
    } catch (_) {
      setState(() {
        _loading = false;
        _error = 'Invalid JSON from server.';
      });
    }
  }

  List<dynamic> get _filtered {
    if (_search.trim().isEmpty) return _warehouses;
    final q = _search.toLowerCase();
    return _warehouses.where((w) {
      final label = (w['label'] ?? '').toString().toLowerCase();
      final manager = (w['manager'] ?? '').toString().toLowerCase();
      final city = (w['city']?['name'] ?? '').toString().toLowerCase();
      return label.contains(q) || manager.contains(q) || city.contains(q);
    }).toList();
  }

  // --- Reverse geocoding (cached) ---
  Future<String?> _getLiveAddress(int id, dynamic w) async {
    if (_addressCache.containsKey(id)) return _addressCache[id];
    if (_addressFailed[id] == true) return null;

    final lat = _toDouble(w['address_lat']);
    final lng = _toDouble(w['address_long']);
    if (lat == null || lng == null) {
      _addressFailed[id] = true;
      return null;
    }

    try {
      final placemarks =
      await geo.placemarkFromCoordinates(lat, lng, localeIdentifier: 'en');
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Build a neat, compact address line
        final parts = <String>[
          _joinNonEmpty([p.name, p.subLocality]),
          _joinNonEmpty([p.locality, p.administrativeArea]),
          _joinNonEmpty([p.postalCode, p.country]),
        ].where((s) => s.trim().isNotEmpty).toList();

        final result = parts.join(', ');
        _addressCache[id] = result;
        return result;
      }
    } catch (_) {
      _addressFailed[id] = true;
    }
    return null;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }

  String _mergeAddresses({required String? apiAddress, required String? live}) {
    final a = (apiAddress ?? '').trim();
    final l = (live ?? '').trim();
    if (a.isEmpty && l.isEmpty) return kDash;
    if (a.isEmpty) return l;
    if (l.isEmpty) return a;
    if (a.toLowerCase() == l.toLowerCase()) return a;
    return '$l\n$a';
  }

  // -------- OPEN MAPS on address tap --------
  Future<void> _openMaps({
    required String? label,
    required String? addressText,
    required double? lat,
    required double? lng,
  }) async {
    // If nothing to search, do nothing
    if ((addressText ?? '').trim().isEmpty && (label ?? '').trim().isEmpty) {
      return;
    }

    Uri? uri;

    // Prefer coordinates if we have them
    if (lat != null && lng != null) {
      if (Platform.isIOS) {
        // Apple Maps with coordinate + label
        final q = Uri.encodeComponent(
            (label?.trim().isNotEmpty ?? false) ? label! : (addressText ?? 'Location'));
        uri = Uri.parse('http://maps.apple.com/?ll=$lat,$lng&q=$q');
      } else {
        // Android geo: scheme (opens Google Maps)
        // geo:lat,lng?q=lat,lng(label)
        final lbl = Uri.encodeComponent(
            (label?.trim().isNotEmpty ?? false) ? label! : (addressText ?? ''));
        uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($lbl)');
      }
    } else {
      // Fallback to text query if no coords available
      final query = (addressText ?? label ?? '').trim();
      if (query.isNotEmpty) {
        if (Platform.isIOS) {
          uri = Uri.parse('http://maps.apple.com/?q=${Uri.encodeComponent(query)}');
        } else {
          uri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
        }
      }
    }

    // Last-chance web fallback
    uri ??= Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(addressText ?? label ?? 'Warehouse')}');

    // Best-effort external launch
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // --------- Dialer helpers (reliable across devices) ----------
  String _normalizePhone(String raw) {
    // Keep + for country code and digits only
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    return (hasPlus ? '+' : '') + digits;
  }

  bool _looksLikePhone(String? raw) {
    if (raw == null) return false;
    final n = _normalizePhone(raw);
    // Minimum 6 digits to look like a phone
    return n.replaceAll(RegExp(r'[^0-9]'), '').length >= 6;
  }

  Future<void> _launchDialer(String phoneRaw) async {
    final phone = _normalizePhone(phoneRaw);
    if (phone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);

    // Try launching externally (dialer). If fails, show alert with copy option.
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Unable to open dialer'),
          content: Text('Phone: $phone'),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phone));
                Navigator.of(context).pop();
              },
              child: const Text('Copy'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showDetails(dynamic w, {String? liveAddress}) {
    final apiAddress = w['address']?.toString();
    final merged = _mergeAddresses(apiAddress: apiAddress, live: liveAddress);
    final lat = _toDouble(w['address_lat']);
    final lng = _toDouble(w['address_long']);
    final label = w['label']?.toString();

    final phoneRaw = (w['phone'] ?? '').toString();
    final hasPhone = _looksLikePhone(phoneRaw);

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(label?.trim().isEmpty == true ? 'Warehouse' : label!),
        message: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail('Manager', w['manager']),
            _detail('Brand', w['brand_name']),
            // Address (tap-to-open only if present)
            _tappableAddress(
              title: 'Address',
              value: merged,
              onTap: (merged.trim().isEmpty || merged == kDash)
                  ? null
                  : () => _openMaps(
                label: label,
                addressText: merged,
                lat: lat,
                lng: lng,
              ),
            ),
            _detail('City', w['city']?['name']),
            _phoneRow(hasPhone ? phoneRaw : null),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String k, dynamic v) {
    final val = (v == null || v.toString().trim().isEmpty) ? kDash : v.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text('$k: $val', style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _tappableAddress({
    required String title,
    required String value,
    required VoidCallback? onTap,
  }) {
    final trimmed = value.trim();
    final show = trimmed.isEmpty ? kDash : trimmed;

    final canTap = onTap != null && show != kDash;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title:', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: canTap ? onTap : null,
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.map_pin_ellipse,
                  size: 16,
                  color: kIOSBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    show,
                    style: TextStyle(
                      fontSize: 14,
                      color: canTap ? kIOSBlue : CupertinoColors.secondaryLabel,
                      fontWeight: canTap ? FontWeight.w600 : FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneRow(String? phoneRaw) {
    final hasPhone = _looksLikePhone(phoneRaw);
    final phone = hasPhone ? _normalizePhone(phoneRaw!) : kDash;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Text('Phone: ', style: TextStyle(fontSize: 14)),
          if (hasPhone)
            GestureDetector(
              onTap: () => _launchDialer(phone),
              child: Text(
                phone,
                style: const TextStyle(
                  fontSize: 14,
                  color: kIOSBlue,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Text(
              kDash,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(
        primaryColor: kIOSBlue,
        barBackgroundColor: CupertinoColors.systemBackground,
      ),
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Warehouses'),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: CupertinoSearchTextField(
                  placeholder: 'Search warehouses…',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              if (_loading)
                const Expanded(
                  child: Center(child: CupertinoActivityIndicator(radius: 16)),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoButton.filled(
                          onPressed: _fetchWarehouses,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filtered.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No warehouses found',
                        style: TextStyle(
                            color: CupertinoColors.secondaryLabel, fontSize: 16),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      color: Colors.black,
                      onRefresh: _fetchWarehouses,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final w = _filtered[i];
                          final id = (w['id'] is int)
                              ? w['id'] as int
                              : int.tryParse('${w['id']}') ?? i;

                          return FutureBuilder<String?>(
                            future: _getLiveAddress(id, w),
                            builder: (ctx, snap) {
                              final live = snap.data;
                              final apiAddr = w['address']?.toString();
                              final mergedForTile =
                              _mergeAddresses(apiAddress: apiAddr, live: live);

                              final lat = _toDouble(w['address_lat']);
                              final lng = _toDouble(w['address_long']);
                              final label = w['label']?.toString();

                              final rawPhone = (w['phone'] ?? '').toString();
                              final hasPhone = _looksLikePhone(rawPhone);

                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBackground
                                      .resolveFrom(context),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (_) => PendingOrdersScreen(
                                          warehouseId: w['id'],
                                          warehouseLabel: w['label'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Leading icon tile
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: kIOSBlue.withOpacity(0.10),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            CupertinoIcons.building_2_fill,
                                            color: kIOSBlue,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              // Header: Label + phone + map button
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      (w['label']?.toString() ?? '')
                                                          .trim()
                                                          .isEmpty
                                                          ? kDash
                                                          : w['label'].toString(),
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.w600,
                                                        color: CupertinoColors.label,
                                                      ),
                                                    ),
                                                  ),
                                                  if (hasPhone)
                                                    CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      minSize: 28,
                                                      onPressed: () =>
                                                          _launchDialer(rawPhone),
                                                      child: const Icon(
                                                        CupertinoIcons.phone_fill,
                                                        size: 20,
                                                        color: kIOSBlue,
                                                      ),
                                                    ),
                                                  if (mergedForTile != kDash)
                                                    CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      minSize: 28,
                                                      onPressed: () => _openMaps(
                                                        label: label,
                                                        addressText: mergedForTile,
                                                        lat: lat,
                                                        lng: lng,
                                                      ),
                                                      child: const Icon(
                                                        CupertinoIcons.map_fill,
                                                        size: 20,
                                                        color: kIOSBlue,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                (w['manager']?.toString() ?? '')
                                                    .trim()
                                                    .isEmpty
                                                    ? kDash
                                                    : w['manager'].toString(),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                  CupertinoColors.secondaryLabel,
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              // Address — 2 lines, tappable only if available
                                              GestureDetector(
                                                onTap: (mergedForTile == kDash)
                                                    ? null
                                                    : () => _openMaps(
                                                  label: label,
                                                  addressText:
                                                  mergedForTile,
                                                  lat: lat,
                                                  lng: lng,
                                                ),
                                                behavior: HitTestBehavior.opaque,
                                                child: Row(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                      CupertinoIcons.location_solid,
                                                      size: 14,
                                                      color: CupertinoColors
                                                          .systemGrey,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        mergedForTile,
                                                        maxLines: 2,
                                                        overflow:
                                                        TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: (mergedForTile ==
                                                              kDash)
                                                              ? CupertinoColors
                                                              .secondaryLabel
                                                              : CupertinoColors
                                                              .systemGrey,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 6),

                                              // Phone row with dash if missing
                                              Row(
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons.phone,
                                                    size: 14,
                                                    color: CupertinoColors
                                                        .systemGrey,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  hasPhone
                                                      ? GestureDetector(
                                                    onTap: () =>
                                                        _launchDialer(
                                                            rawPhone),
                                                    child: Text(
                                                      _normalizePhone(
                                                          rawPhone),
                                                      style:
                                                      const TextStyle(
                                                        fontSize: 13,
                                                        color: kIOSBlue,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                  )
                                                      : const Text(
                                                    kDash,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: CupertinoColors
                                                          .secondaryLabel,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          children: [
                                            CupertinoButton(
                                              padding: EdgeInsets.zero,
                                              minSize: 28,
                                              onPressed: () => _showDetails(w,
                                                  liveAddress: live),
                                              child: const Icon(
                                                CupertinoIcons.info_circle,
                                                color: kIOSBlue,
                                                size: 22,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Icon(
                                              CupertinoIcons.chevron_right,
                                              color: CupertinoColors.systemGrey3,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------- small helpers ----------
String _joinNonEmpty(List<String?> parts) =>
    parts.where((s) => (s ?? '').trim().isNotEmpty).join(', ');
