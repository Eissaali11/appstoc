import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../models/item_type.dart';
import '../scanner/barcode_candidate_selector.dart';
import '../scanner/barcode_rule_registry.dart';
import '../scanner/camera_lifecycle_manager.dart';
import '../scanner/duplicate_scanner_guard.dart';
import '../scanner/identifier_normalization_service.dart';
import '../scanner/scanner_context.dart';
import '../scanner/scanner_session_manager.dart';
import '../scanner/success_feedback_service.dart';
import 'rassco_app_bar.dart';

/// Enterprise Smart Scanner V2 — context-aware single-serial capture.
///
/// - Evaluates ALL barcodes in frame against current item-type rules
/// - Ignores GTIN / PN / product codes that do not match
/// - One success per session (IDLE→SCANNING→VALIDATING→ACCEPTED→CLOSED)
/// - Lock BEFORE any await after valid accept
/// - Success: local beep + haptic ~100ms + green frame + checkmark + fill + close
/// - Invalid: silent; Duplicate: one cooldown toast, camera stays open
/// - Native [scanWindow] ROI so codes outside the frame are filtered early
class BarcodeScannerWidget extends StatefulWidget {
  final Function(String)? onBarcodeDetected;
  final String title;
  final bool isMultiScan;
  final List<ItemType>? itemTypes;
  final String? selectedItemTypeId;
  final Function(String)? onItemTypeChanged;

  /// Serials already present in the calling form (duplicate detection).
  final List<String> existingValues;

  /// Category hint when no single type is selected: `devices` | `sim`.
  final String? categoryHint;

  /// When true (default) and [itemTypes] is non-empty without a selection,
  /// accept any serial matching rules from those types (union). When false,
  /// require an explicit selected type (fail closed until chosen).
  final bool allowUnionOfItemTypes;

  /// Non-serial barcode capture (e.g. Terminal ID). Bypasses item-type rules
  /// and accepts the first non-empty code after light normalize — still one
  /// success / session lock / single beep. Do NOT use for device serials.
  final bool rawBarcodeMode;

  const BarcodeScannerWidget({
    super.key,
    this.onBarcodeDetected,
    this.title = 'مسح الباركود بالكاميرا',
    this.isMultiScan = false,
    this.itemTypes,
    this.selectedItemTypeId,
    this.onItemTypeChanged,
    this.existingValues = const [],
    this.categoryHint,
    this.allowUnionOfItemTypes = true,
    this.rawBarcodeMode = false,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late final CameraLifecycleManager _camera;
  late final ScannerSessionManager _session;
  late final DuplicateScannerGuard _dupGuard;
  late final SuccessFeedbackService _feedback;
  late final BarcodeCandidateSelector _selector;
  late ScannerContext _context;

  bool _showGreenFrame = false;
  bool _showCheckmark = false;
  String? _guidance;
  String? _selectedItemTypeId;
  final List<String> _scannedCodes = [];

  static const _closeDelay = Duration(milliseconds: 280);
  static const _scanAreaHeight = 200.0;

  @override
  void initState() {
    super.initState();
    _selectedItemTypeId = widget.selectedItemTypeId;
    _camera = CameraLifecycleManager();
    _session = ScannerSessionManager();
    _dupGuard = DuplicateScannerGuard()..seedExisting(widget.existingValues);
    _feedback = SuccessFeedbackService();
    _selector = BarcodeCandidateSelector();
    if (widget.itemTypes != null) {
      BarcodeRuleRegistry.cacheFromItemTypes(widget.itemTypes!);
    }
    _rebuildContext();
    _session.markScanning();
  }

  @override
  void dispose() {
    _feedback.dispose();
    _camera.dispose();
    super.dispose();
  }

  ItemType? _selectedType() {
    if (widget.itemTypes == null || _selectedItemTypeId == null) return null;
    for (final t in widget.itemTypes!) {
      if (t.id == _selectedItemTypeId) return t;
    }
    return null;
  }

  void _rebuildContext() {
    final selected = _selectedType();
    final types = widget.itemTypes;
    // Union even when one type is pre-selected (SIM category defaults to STC
    // first — without union, Lebara/Zain 19-digit ICCIDs never match).
    final useUnion = widget.allowUnionOfItemTypes &&
        types != null &&
        types.isNotEmpty;

    _context = ScannerContext.create(
      sessionId: 'scan_${DateTime.now().microsecondsSinceEpoch}',
      itemType: selected,
      itemTypeId: _selectedItemTypeId,
      existingValues: {
        ...widget.existingValues,
        ..._scannedCodes,
        ..._dupGuard.accepted,
      },
      isMultiScan: widget.isMultiScan,
      allowedItemTypes: useUnion ? types : null,
      categoryHint: widget.categoryHint ?? selected?.category,
      // Fail closed unless we have a type, a union of types, or explicit category fallback.
      allowFallbackRegistry: selected == null &&
          !useUnion &&
          widget.categoryHint != null &&
          (types == null || types.isEmpty),
    );
    _selector.resetStability();
  }

  void _onDetect(BarcodeCapture capture) {
    // Session lock / closed → ignore every subsequent frame (no double beep).
    if (!_session.isOpen || _session.isLocked) return;

    _session.markScanning();

    if (widget.rawBarcodeMode) {
      _onDetectRaw(capture);
      return;
    }

    // Fail closed: no trusted rules for the selected item type.
    if (!_context.hasTrustedRules) {
      if (mounted && _guidance == null) {
        setState(() => _guidance = 'اختر نوع الصنف أولاً');
      }
      return;
    }

    final imgW = capture.width;
    final imgH = capture.height;

    final observations = <BarcodeObservation>[];
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      observations.add(
        BarcodeObservation(
          raw: raw,
          center: _barcodeCenter(barcode, imgW, imgH),
          confidence: 1.0, // mobile_scanner does not expose a stable score
        ),
      );
    }
    if (observations.isEmpty) return;

    // Evaluate ALL barcodes — never accept the first blindly.
    final result = _selector.select(observations, context: _context);

    if (result.status == CandidateStatus.ambiguous ||
        result.status == CandidateStatus.unstable) {
      if (mounted && result.guidanceMessage != null) {
        setState(() => _guidance = result.guidanceMessage);
      }
      return;
    }

    if (result.status != CandidateStatus.singleMatch ||
        result.selected == null) {
      // Non-matching (GTIN/PN/wrong type): silent ignore.
      return;
    }

    _commitAccept(result.selected!);
  }

  /// Raw / non-serial path (Terminal ID). Still session-locked + one beep.
  void _onDetectRaw(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final normalized = IdentifierNormalizationService.normalize(raw);
      if (normalized.isEmpty) continue;
      if (_dupGuard.isDuplicate(normalized) ||
          _scannedCodes.contains(normalized)) {
        if (_dupGuard.shouldShowToast() && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                DuplicateScannerGuard.duplicateMessage,
                style: TextStyle(fontFamily: 'BeIN'),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      if (!_session.tryLock()) return;
      _session.accept(normalized);
      _dupGuard.markAccepted(normalized);
      if (widget.isMultiScan) {
        _handleMultiAccept(normalized);
      } else {
        _handleSingleAccept(normalized);
      }
      return;
    }
  }

  void _commitAccept(String opaqueSerial) {
    // Duplicate in form / session — toast with cooldown, no success feedback.
    if (_dupGuard.isDuplicate(opaqueSerial) ||
        _scannedCodes.contains(opaqueSerial)) {
      if (_dupGuard.shouldShowToast() && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              DuplicateScannerGuard.duplicateMessage,
              style: TextStyle(fontFamily: 'BeIN'),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // CRITICAL: lock synchronously BEFORE any await.
    if (!_session.tryLock()) return;
    _session.accept(opaqueSerial);
    _dupGuard.markAccepted(opaqueSerial);

    if (widget.isMultiScan) {
      _handleMultiAccept(opaqueSerial);
    } else {
      _handleSingleAccept(opaqueSerial);
    }
  }

  Offset? _barcodeCenter(Barcode barcode, double? imgW, double? imgH) {
    final corners = barcode.corners;
    if (corners.isEmpty) return null;
    double sx = 0, sy = 0;
    for (final c in corners) {
      sx += c.dx;
      sy += c.dy;
    }
    final w = (imgW != null && imgW > 0) ? imgW : 1280.0;
    final h = (imgH != null && imgH > 0) ? imgH : 720.0;
    return Offset(sx / corners.length / w, sy / corners.length / h);
  }

  void _handleMultiAccept(String opaqueSerial) {
    setState(() {
      _scannedCodes.add(opaqueSerial);
      _showGreenFrame = true;
      _showCheckmark = true;
      _guidance = null;
    });

    // Fire feedback once for this accept (async AFTER lock).
    _feedback.fire();

    widget.onBarcodeDetected?.call(opaqueSerial);

    // Brief success UI then unlock for next serial in multi-scan.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _feedback.reset();
      _session.resetForNextScan();
      _session.markScanning();
      _rebuildContext();
      setState(() {
        _showGreenFrame = false;
        _showCheckmark = false;
      });
    });
  }

  void _handleSingleAccept(String opaqueSerial) {
    setState(() {
      _showGreenFrame = true;
      _showCheckmark = true;
      _guidance = null;
    });

    // Async feedback AFTER synchronous lock/accept.
    _feedback.fire().whenComplete(() {});

    widget.onBarcodeDetected?.call(opaqueSerial);

    Future.delayed(_closeDelay, () async {
      if (!mounted) return;
      _session.close();
      await _camera.stop();
      if (!mounted) return;
      if (widget.itemTypes != null) {
        Navigator.of(context).pop({
          'code': opaqueSerial,
          'itemTypeId': _selectedItemTypeId,
        });
      } else {
        Navigator.of(context).pop(opaqueSerial);
      }
    });
  }

  Rect _computeScanWindow(Size size) {
    final scanAreaWidth = size.width * 0.8;
    final left = (size.width - scanAreaWidth) / 2;
    final top = (size.height - _scanAreaHeight) / 2;
    return Rect.fromLTWH(left, top, scanAreaWidth, _scanAreaHeight);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMultiScan) {
      return _buildMultiScanLayout(context);
    }
    return _buildSingleScanLayout(context);
  }

  Widget _buildCameraStack({required double height}) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final window = _computeScanWindow(size);
          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _camera.controller,
                onDetect: _onDetect,
                scanWindow: window,
                errorBuilder: _buildErrorWidget,
              ),
              _buildScannerOverlay(context, size),
              if (widget.itemTypes != null && widget.itemTypes!.isNotEmpty)
                _buildItemTypeDropdown(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMultiScanLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: _buildCameraStack(height: 320),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.backgroundDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الأرقام الممسوحة (${_scannedCodes.length})',
                          style: const TextStyle(
                            fontFamily: 'BeIN',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (_scannedCodes.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _scannedCodes.clear();
                                _dupGuard.clear();
                                _dupGuard.seedExisting(widget.existingValues);
                                _rebuildContext();
                              });
                            },
                            child: const Text(
                              'حذف الكل',
                              style: TextStyle(
                                fontFamily: 'BeIN',
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_scannedCodes.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'لم يتم مسح أي باركود بعد',
                            style: TextStyle(
                              fontFamily: 'BeIN',
                              color: Colors.white30,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _scannedCodes.length,
                        separatorBuilder: (_, __) => Divider(
                          color: AppColors.border.withOpacity(0.1),
                          height: 8,
                        ),
                        itemBuilder: (context, index) {
                          final code = _scannedCodes[index];
                          return Row(
                            children: [
                              const Icon(Icons.qr_code,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  code,
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _scannedCodes.removeAt(index);
                                    _dupGuard.remove(code);
                                    _rebuildContext();
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _scannedCodes.isEmpty
                          ? null
                          : () {
                              if (widget.itemTypes != null) {
                                Navigator.of(context).pop({
                                  'codes': _scannedCodes,
                                  'itemTypeId': _selectedItemTypeId,
                                });
                              } else {
                                Navigator.of(context).pop(_scannedCodes);
                              }
                            },
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white),
                      label: Text(
                        'تأكيد وحفظ الشحنة (${_scannedCodes.length})',
                        style: const TextStyle(
                          fontFamily: 'BeIN',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleScanLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return _buildCameraStack(height: constraints.maxHeight);
        },
      ),
    );
  }

  Widget _buildItemTypeDropdown() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedItemTypeId,
            hint: const Text(
              'اختر نوع الصنف',
              style: TextStyle(fontFamily: 'BeIN', color: Colors.white70),
            ),
            dropdownColor: AppColors.surfaceDark,
            style: const TextStyle(
              fontFamily: 'BeIN',
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            isExpanded: true,
            items: widget.itemTypes!.map((t) {
              final label = t.category == 'sim'
                  ? '[شريحة] ${t.nameAr}'
                  : '[جهاز] ${t.nameAr}';
              return DropdownMenuItem<String>(
                value: t.id,
                child: Text(label,
                    style: const TextStyle(
                        fontFamily: 'BeIN', color: Colors.white)),
              );
            }).toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedItemTypeId = val;
                _rebuildContext();
                _guidance = null;
              });
              widget.onItemTypeChanged?.call(val);
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return RasscoAppBar(
      titleText: widget.title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: _camera.controller.torchState,
          builder: (context, state, child) {
            switch (state) {
              case TorchState.off:
                return IconButton(
                  icon: const Icon(Icons.flash_off, color: Colors.grey),
                  onPressed: () => _camera.toggleTorch(),
                );
              case TorchState.on:
                return IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.yellow),
                  onPressed: () => _camera.toggleTorch(),
                );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
          onPressed: () => _camera.switchCamera(),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(
      BuildContext context, MobileScannerException error, Widget? child) {
    String errorMessage = 'حدث خطأ أثناء فتح الكاميرا';
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      errorMessage =
          'صلاحية الكاميرا غير ممنوحة. يرجى تفعيلها من الإعدادات.';
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'BeIN',
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'رجوع',
                style: TextStyle(fontFamily: 'BeIN', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context, Size size) {
    final scanAreaWidth = size.width * 0.8;
    final frameColor = _showGreenFrame ? AppColors.success : AppColors.primary;
    final hint = _showGreenFrame
        ? 'تم المسح بنجاح'
        : (_guidance ?? 'ضع الرقم التسلسلي داخل الإطار');

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: scanAreaWidth,
                  height: _scanAreaHeight,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: scanAreaWidth,
                height: _scanAreaHeight,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: frameColor, width: _showGreenFrame ? 3.5 : 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _showCheckmark
                    ? const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 64,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontFamily: 'BeIN',
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
