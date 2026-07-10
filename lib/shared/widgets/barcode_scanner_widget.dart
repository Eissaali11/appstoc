import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_colors.dart';
import '../models/item_type.dart';

/// مكون مسح الباركود التفاعلي باستخدام الكاميرا.
/// يدعم قراءة الأكواد الخطية 1D (أجهزة نقاط البيع POS وشرائح SIM والسلع).
/// يدعم المسح الفردي والمسح المستمر المتعدد.
class BarcodeScannerWidget extends StatefulWidget {
  final Function(String)? onBarcodeDetected;
  final String title;
  final bool isMultiScan;
  final List<ItemType>? itemTypes;
  final String? selectedItemTypeId;
  final Function(String)? onItemTypeChanged;

  const BarcodeScannerWidget({
    super.key,
    this.onBarcodeDetected,
    this.title = 'مسح الباركود بالكاميرا',
    this.isMultiScan = false,
    this.itemTypes,
    this.selectedItemTypeId,
    this.onItemTypeChanged,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  late final MobileScannerController _scannerController;
  bool _isScanCompleted = false;
  final List<String> _scannedCodes = [];
  String? _selectedItemTypeId;

  @override
  void initState() {
    super.initState();
    _selectedItemTypeId = widget.selectedItemTypeId;
    // إعداد متحكم المسح مع حصر صيغ الباركود المطلوبة لرفع كفاءة وسرعة القراءة
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.ean13,
        BarcodeFormat.qrCode, // دعم الـ QR أيضاً للمرونة
      ],
    );
  }

  @override
  void dispose() {
    // إغلاق المتحكم لتفادي تسريب الذاكرة وتحرير موارد الكاميرا
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanCompleted) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        // تنظيف الكود ومسح البادئات غير الصحيحة مثل c1 أو ]C1 الخاصة بـ GS1-128
        var cleaned = barcode.rawValue!.trim();
        if (cleaned.startsWith(']C1')) {
          cleaned = cleaned.substring(3);
        } else if (cleaned.toLowerCase().startsWith('c1')) {
          cleaned = cleaned.substring(2);
        }
        final String scannedValue = cleaned;

        if (widget.isMultiScan) {
          if (!_scannedCodes.contains(scannedValue)) {
            setState(() {
              _scannedCodes.add(scannedValue);
            });
            // تشغيل اهتزاز خفيف
            HapticFeedback.lightImpact();
            if (widget.onBarcodeDetected != null) {
              widget.onBarcodeDetected!(scannedValue);
            }
          }
        } else {
          setState(() {
            _isScanCompleted = true;
          });
          HapticFeedback.lightImpact();

          if (widget.onBarcodeDetected != null) {
            widget.onBarcodeDetected!(scannedValue);
          }

          // إرجاع النتيجة وإغلاق الشاشة
          if (mounted) {
            if (widget.itemTypes != null) {
              Navigator.of(context).pop({
                'code': scannedValue,
                'itemTypeId': _selectedItemTypeId,
              });
            } else {
              Navigator.of(context).pop(scannedValue);
            }
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMultiScan) {
      return _buildMultiScanLayout(context);
    }
    return _buildSingleScanLayout(context);
  }

  // ─── واجهة المسح المتعدد ───
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
              // 1. كاميرا المسح مع قائمة الاختيار العائمة
              Container(
                height: 320,
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: _buildErrorWidget,
                    ),
                    _buildScannerOverlay(context),
                    if (widget.itemTypes != null && widget.itemTypes!.isNotEmpty)
                      Positioned(
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
                              dropdownColor: AppColors.surfaceDark,
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              isExpanded: true,
                              items: widget.itemTypes!.map((t) {
                                final label = t.category == 'sim' ? '[شريحة] ${t.nameAr}' : '[جهاز] ${t.nameAr}';
                                return DropdownMenuItem<String>(
                                  value: t.id,
                                  child: Text(label, style: GoogleFonts.cairo(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  _selectedItemTypeId = val;
                                });
                                if (widget.onItemTypeChanged != null) {
                                  widget.onItemTypeChanged!(val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // 2. حاوية قائمة الأرقام الممسوحة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundDark,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // العنوان وإجراء الحذف الكل
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الأرقام الممسوحة (${_scannedCodes.length})',
                          style: GoogleFonts.cairo(
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
                              });
                            },
                            child: Text(
                              'حذف الكل',
                              style: GoogleFonts.cairo(
                                color: AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // قائمة الأكواد الممسوحة فعلياً
                    if (_scannedCodes.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'لم يتم مسح أي باركود بعد',
                            style: GoogleFonts.cairo(
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
                              const Icon(Icons.qr_code, color: AppColors.primary, size: 18),
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
                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _scannedCodes.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // زر التأكيد النهائي
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
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: Text(
                        'تأكيد وحفظ الشحنة (${_scannedCodes.length})',
                        style: GoogleFonts.cairo(
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

  // ─── واجهة المسح المفرد ───
  Widget _buildSingleScanLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            errorBuilder: _buildErrorWidget,
          ),
          _buildScannerOverlay(context),
          if (widget.itemTypes != null && widget.itemTypes!.isNotEmpty)
            Positioned(
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
                    dropdownColor: AppColors.surfaceDark,
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    isExpanded: true,
                    items: widget.itemTypes!.map((t) {
                      final label = t.category == 'sim' ? '[شريحة] ${t.nameAr}' : '[جهاز] ${t.nameAr}';
                      return DropdownMenuItem<String>(
                        value: t.id,
                        child: Text(label, style: GoogleFonts.cairo(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedItemTypeId = val;
                      });
                      if (widget.onItemTypeChanged != null) {
                        widget.onItemTypeChanged!(val);
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        widget.title,
        style: GoogleFonts.cairo(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        ValueListenableBuilder(
          valueListenable: _scannerController.torchState,
          builder: (context, state, child) {
            switch (state) {
              case TorchState.off:
                return IconButton(
                  icon: const Icon(Icons.flash_off, color: Colors.grey),
                  onPressed: () => _scannerController.toggleTorch(),
                );
              case TorchState.on:
                return IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.yellow),
                  onPressed: () => _scannerController.toggleTorch(),
                );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
          onPressed: () => _scannerController.switchCamera(),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, MobileScannerException error, Widget? child) {
    String errorMessage = 'حدث خطأ أثناء فتح الكاميرا';
    if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
      errorMessage = 'صلاحية الكاميرا غير ممنوحة. يرجى تفعيلها من الإعدادات.';
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
              style: GoogleFonts.cairo(
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
              child: Text(
                'رجوع',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final double scanAreaWidth = MediaQuery.of(context).size.width * 0.8;
    final double scanAreaHeight = 200.0;

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
                  height: scanAreaHeight,
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
              Container(
                width: scanAreaWidth,
                height: scanAreaHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ضع الباركود داخل المربع للمسح التلقائي',
                  style: GoogleFonts.cairo(
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
