import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/design_system.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../../shared/utils/barcode_validator.dart';

import '../../../moving_inventory/data/models/serialized_item.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../controllers/moving_inventory_controller.dart';


class ScannedBatchItem {
  final String serialNumber;
  final String itemTypeId;
  final String itemTypeName;
  final bool isSim;
  final String? carrierName;

  ScannedBatchItem({
    required this.serialNumber,
    required this.itemTypeId,
    required this.itemTypeName,
    required this.isSim,
    this.carrierName,
  });
}

class ShipmentScanPage extends StatefulWidget {
  const ShipmentScanPage({super.key});

  @override
  State<ShipmentScanPage> createState() => _ShipmentScanPageState();
}

class _ShipmentScanPageState extends State<ShipmentScanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Scan tab state
  final _serialController = TextEditingController();
  final _iccidController = TextEditingController();
  final _scanFocusNode = FocusNode();
  String _selectedCategory = 'devices'; // 'devices' | 'sim'
  String? _selectedItemTypeId;
  List<ItemType> _itemTypes = [];
  final List<ScannedBatchItem> _scannedBatchItems = [];
  bool _isScanLoading = false;
  String? _scanError;
  String? _scanSuccess;
  bool _isSim = false;
  String? _carrierName;

  // Custody tab state
  List<SerializedItem> _custodyItems = [];
  bool _isCustodyLoading = false;
  String? _custodyError;
  final _custodySearchController = TextEditingController();
  String _custodySearchQuery = '';

  final Dio _dio = Get.find<Dio>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItemTypes();
    _loadCustody();
    _tabController.addListener(() {
      if (_tabController.index == 1) _loadCustody();
    });
    _scanFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  String? _getOperatorImg(ScannedBatchItem item) {
    if (item.isSim && item.carrierName != null) {
      return IconMapper.getItemImagePath(item.carrierName, null, 'sim');
    }
    return IconMapper.getItemImagePath(item.itemTypeName, null, item.isSim ? 'sim' : 'devices');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _serialController.dispose();
    _iccidController.dispose();
    _custodySearchController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadItemTypes() async {
    try {
      final response = await _dio.get('/api/item-types/active');
      if (response.data is List) {
        setState(() {
          _itemTypes = (response.data as List)
              .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
              .toList();
          _updateSelectedItemType();
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading item types: $e');
      debugPrint(stack.toString());
    }
  }

  void _updateSelectedItemType() {
    final filtered = _itemTypes.where((t) => t.category == _selectedCategory && t.requiresSerial == true).toList();
    if (filtered.isNotEmpty) {
      _selectedItemTypeId = filtered.first.id;
      _isSim = _selectedCategory == 'sim';
    } else {
      _selectedItemTypeId = null;
      _isSim = _selectedCategory == 'sim';
    }
    _carrierName = _isSim ? 'STC' : null;
  }

  String? _resolveCarrierName(ItemType type, String? defaultCarrier) {
    if (type.category != 'sim') return null;
    final nameEn = type.nameEn.toLowerCase();
    final nameAr = type.nameAr.toLowerCase();
    if (nameEn.contains('stc') || nameAr.contains('stc') || nameEn.contains('اتصالات') || nameAr.contains('اتصالات')) {
      return 'STC';
    }
    if (nameEn.contains('mobily') || nameAr.contains('موبايلي')) {
      return 'Mobily';
    }
    if (nameEn.contains('zain') || nameAr.contains('زين')) {
      return 'Zain';
    }
    if (nameEn.contains('lebara') || nameAr.contains('ليبارا') || nameEn.contains('repara') || nameAr.contains('ريباره') || nameAr.contains('ريبارا')) {
      return 'Lebara';
    }
    return defaultCarrier ?? 'STC';
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _updateSelectedItemType();
      _serialController.clear();
      _iccidController.clear();
      _scanError = null;
      _scanSuccess = null;
    });
  }

  Future<void> _loadCustody() async {
    setState(() { _isCustodyLoading = true; _custodyError = null; });
    try {
      final response = await _dio.get('/api/my-serialized-custody');
      if (response.data is List) {
        setState(() {
          _custodyItems = (response.data as List)
              .map((e) => SerializedItem.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      // Try alternate endpoint
      try {
        final token = _dio.options.headers['Authorization'];
        if (token != null) {
          // Decode JWT to get user id — fallback: use /api/auth/me
          final meResp = await _dio.get('/api/auth/me');
          final userId = meResp.data?['id'] as String?;
          if (userId != null) {
            final resp2 = await _dio.get('/api/technicians/$userId/serialized-custody');
            if (resp2.data is List) {
              setState(() {
                _custodyItems = (resp2.data as List)
                    .map((e) => SerializedItem.fromJson(e as Map<String, dynamic>))
                    .toList();
              });
            }
          }
        }
      } catch (e2) {
        setState(() { _custodyError = e2.toString().replaceAll('Exception: ', ''); });
      }
    } finally {
      setState(() { _isCustodyLoading = false; });
    }
  }

  void _addToScannedBatch() {
    var serial = (_isSim ? _iccidController.text : _serialController.text).trim();
    if (serial.startsWith(']C1')) {
      serial = serial.substring(3);
    } else if (serial.toLowerCase().startsWith('c1')) {
      serial = serial.substring(2);
    }

    if (serial.isEmpty) {
      setState(() {
        _scanError = 'الرجاء إدخال الرقم التسلسلي أو مسحه';
        _scanSuccess = null;
      });
      return;
    }
    if (_selectedItemTypeId == null) {
      setState(() {
        _scanError = 'الرجاء تحديد نوع الصنف';
        _scanSuccess = null;
      });
      return;
    }

    // Check for duplicates in local list
    final isDuplicate = _scannedBatchItems.any((item) => item.serialNumber.toLowerCase() == serial.toLowerCase());
    if (isDuplicate) {
      HapticFeedback.vibrate();
      setState(() {
        _scanError = 'الرقم التسلسلي $serial مضاف بالفعل في القائمة المؤقتة';
        _scanSuccess = null;
      });
      return;
    }

    // Check for duplicates in actual custody
    final isInCustody = _custodyItems.any((item) => item.serialNumber.toLowerCase() == serial.toLowerCase());
    if (isInCustody) {
      HapticFeedback.vibrate();
      setState(() {
        _scanError = 'الرقم التسلسلي $serial موجود بالفعل في عهدتك';
        _scanSuccess = null;
      });
      return;
    }

    final selectedType = _itemTypes.firstWhere((t) => t.id == _selectedItemTypeId);

    // التحقق من صحة الرقم المكتوب يدوياً أو الممسوح
    final validationError = BarcodeValidator.validate(serial, selectedType);
    if (validationError != null) {
      HapticFeedback.vibrate();
      setState(() {
        _scanError = validationError;
        _scanSuccess = null;
      });
      return;
    }

    setState(() {
      final resolvedCarrier = _isSim ? _resolveCarrierName(selectedType, _carrierName) : null;
      _scannedBatchItems.add(ScannedBatchItem(
        serialNumber: serial,
        itemTypeId: _selectedItemTypeId!,
        itemTypeName: selectedType.nameAr,
        isSim: _isSim,
        carrierName: resolvedCarrier,
      ));
      _scanSuccess = 'تمت إضافة ${_isSim ? "الشريحة" : "الجهاز"} $serial للقائمة المؤقتة ✓';
      _scanError = null;
      _serialController.clear();
      _iccidController.clear();
    });

    HapticFeedback.lightImpact();
    _scanFocusNode.requestFocus();
  }

  Future<void> _saveBatchToBackend() async {
    if (_scannedBatchItems.isEmpty) {
      setState(() { _scanError = 'لا توجد عناصر لحفظها'; });
      return;
    }

    setState(() { _isScanLoading = true; _scanError = null; _scanSuccess = null; });

    try {
      final body = <String, dynamic>{
        'items': _scannedBatchItems.map((item) => {
          'serialNumber': item.serialNumber,
          'itemTypeId': item.itemTypeId,
          if (item.isSim && item.carrierName != null && item.carrierName!.isNotEmpty)
            'carrierName': item.carrierName,
        }).toList(),
      };

      await _dio.post('/api/serialized-items/batch-scan-in', data: body);

      HapticFeedback.mediumImpact();
      final count = _scannedBatchItems.length;
      setState(() {
        _scanSuccess = 'تم حفظ $count من الأجهزة والشرائح بنجاح في عهدتك ✓';
        _scannedBatchItems.clear();
      });
      await _loadCustody();

      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().loadDashboardData();
      }
      if (Get.isRegistered<MovingInventoryController>()) {
        Get.find<MovingInventoryController>().refresh();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      setState(() { _scanError = msg ?? 'فشل تسجيل الأجهزة والشرائح دفعة واحدة'; });
    } catch (e) {
      setState(() { _scanError = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() { _isScanLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'استلام شحنة جديدة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(
              icon: const Icon(Icons.qr_code_scanner, size: 20),
              text: 'مسح جهاز / شريحة',
            ),
            Tab(
              icon: const Icon(Icons.inventory_2_outlined, size: 20),
              text: 'عهدتي (${_custodyItems.length})',
            ),
          ],
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildScanTab(),
            _buildCustodyTab(),
          ],
        ),
      ),
    );
  }

  // ── TAB 1: Scan ──────────────────────────────────────────
  Widget _buildScanTab() {
    final activeColor = _selectedCategory == 'sim' ? AppColors.success : AppColors.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category / Request Type selector
          SectionHeader(
            title: 'نوع الطلب / القسم',
            icon: Icons.assignment_outlined,
            color: activeColor,
          ),
          const SizedBox(height: 8),
          _buildCategorySelector(),
          const SizedBox(height: 20),

          // Detailed Item Type selector
          SectionHeader(
            title: 'نوع الصنف التفصيلي',
            icon: Icons.category_outlined,
            color: activeColor,
          ),
          const SizedBox(height: 8),
          _buildItemTypeSelector(),
          const SizedBox(height: 20),

          // Serial / ICCID input
          SectionHeader(
            title: _isSim ? 'رقم ICCID للشريحة' : 'الرقم التسلسلي (SN)',
            icon: _isSim ? Icons.sim_card : Icons.phone_android,
            color: activeColor,
          ),
          const SizedBox(height: 8),
          _buildSerialField(),
          const SizedBox(height: 16),

          // Carrier (SIM only)
          if (_isSim) ...[
            SectionHeader(
              title: 'مزود الخدمة (اختياري)',
              icon: Icons.signal_cellular_alt,
              color: activeColor,
            ),
            const SizedBox(height: 8),
            _buildCarrierField(),
            const SizedBox(height: 16),
          ],

          // Feedback
          if (_scanError != null) _buildFeedbackBanner(_scanError!, isError: true),
          if (_scanSuccess != null) _buildFeedbackBanner(_scanSuccess!, isError: false),
          const SizedBox(height: 8),

          // Add to list button
          _buildAddToListButton(),
          const SizedBox(height: 24),

          // Temporary scanned items list
          _buildScannedBatchList(),
          const SizedBox(height: 24),

          // Helper
          _buildHelperCard(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _toggleCategoryBtn(
              'أجهزة POS',
              Icons.phone_android,
              _selectedCategory == 'devices',
              AppColors.primary,
              () => _onCategoryChanged('devices'),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _toggleCategoryBtn(
              'شرائح SIM',
              Icons.sim_card,
              _selectedCategory == 'sim',
              AppColors.success,
              () => _onCategoryChanged('sim'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleCategoryBtn(String label, IconData icon, bool active, Color activeColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.4) : Colors.transparent,
            width: 1,
          ),
          boxShadow: active ? [
            BoxShadow(
              color: activeColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? activeColor : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: active ? Colors.white : Colors.white.withOpacity(0.5),
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemTypeSelector() {
    if (_itemTypes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'جاري تحميل الأصناف...',
              style: GoogleFonts.cairo(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final filtered = _itemTypes.where((t) => t.category == _selectedCategory && t.requiresSerial == true).toList();
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Text(
          'لا توجد أصناف نشطة لهذا القسم',
          style: GoogleFonts.cairo(color: AppColors.error, fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedItemTypeId,
          dropdownColor: AppColors.backgroundDark,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          isExpanded: true,
          items: filtered.map((t) {
            final isSelected = t.id == _selectedItemTypeId;
            return DropdownMenuItem(
              value: t.id,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (_selectedCategory == 'sim' ? AppColors.success : AppColors.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedCategory == 'sim' ? Icons.sim_card_outlined : Icons.devices_other,
                      color: _selectedCategory == 'sim' ? AppColors.success : AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.nameAr,
                    style: GoogleFonts.cairo(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            final type = _itemTypes.firstWhere((t) => t.id == val);
            setState(() {
              _selectedItemTypeId = val;
              _isSim = type.category == 'sim';
            });
          },
        ),
      ),
    );
  }

  Widget _buildSerialField() {
    final activeColor = _isSim ? AppColors.success : AppColors.primary;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _scanFocusNode.hasFocus ? activeColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: _scanFocusNode.hasFocus
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: TextFormField(
        controller: _isSim ? _iccidController : _serialController,
        focusNode: _scanFocusNode,
        style: GoogleFonts.robotoMono(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.characters,
        onFieldSubmitted: (_) => _addToScannedBatch(),
        decoration: InputDecoration(
          hintText: _isSim ? '8996 6060 9902 0607 187' : 'NCD100233990',
          hintStyle: GoogleFonts.robotoMono(color: Colors.white24, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: InputBorder.none,
          prefixIcon: Icon(
            _isSim ? Icons.sim_card_rounded : Icons.qr_code_rounded,
            color: activeColor,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.qr_code_scanner, color: activeColor),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerWidget(
                        title: 'مسح باركود الأجهزة والشرائح',
                        isMultiScan: true,
                        itemTypes: _itemTypes.where((t) => t.category == _selectedCategory && t.requiresSerial == true).toList(),
                        selectedItemTypeId: _selectedItemTypeId,
                      ),
                    ),
                  );
                  if (result != null) {
                    List<String> codes = [];
                    String? returnedItemTypeId;
                    
                    if (result is Map<String, dynamic>) {
                      codes = List<String>.from(result['codes'] ?? []);
                      returnedItemTypeId = result['itemTypeId'] as String?;
                    } else if (result is List<String>) {
                      codes = result;
                    } else if (result is String && result.trim().isNotEmpty) {
                      codes = [result.trim()];
                    }

                    if (returnedItemTypeId != null) {
                      setState(() {
                        _selectedItemTypeId = returnedItemTypeId;
                        final type = _itemTypes.firstWhere((t) => t.id == returnedItemTypeId);
                        _isSim = type.category == 'sim';
                      });
                    }
                    
                    if (codes.isNotEmpty) {
                      setState(() {
                        int addedCount = 0;
                        for (var code in codes) {
                          var serial = code.trim();
                          if (serial.startsWith(']C1')) {
                            serial = serial.substring(3);
                          } else if (serial.toLowerCase().startsWith('c1')) {
                            serial = serial.substring(2);
                          }
                          if (serial.isEmpty) continue;
                          
                          // تطبيع الكود الخام أولاً
                          final normalized = BarcodeValidator.normalizeRawBarcode(serial);

                          // التحقق من نوع الصنف الأنسب لكل كود ممسوح
                          ItemType? targetType;
                          
                          // 1. أولاً نجرب التحقق من الصنف المختار/المرتجع
                          if (_selectedItemTypeId != null) {
                            final type = _itemTypes.firstWhereOrNull((t) => t.id == _selectedItemTypeId);
                            if (type != null && BarcodeValidator.validate(normalized, type) == null) {
                              targetType = type;
                            }
                          }
                          
                          // 2. إذا لم يطابق، نبحث في بقية الأصناف النشطة المتاحة لهذا القسم
                          if (targetType == null) {
                            final categoryTypes = _itemTypes.where((t) => t.category == _selectedCategory && t.requiresSerial == true).toList();
                            for (final type in categoryTypes) {
                              if (BarcodeValidator.validate(normalized, type) == null) {
                                targetType = type;
                                break;
                              }
                            }
                          }

                          if (targetType != null) {
                            // استخراج الرقم التسلسلي النظيف بناءً على الصنف المكتشف
                            final cleanSerial = BarcodeValidator.extractCleanSerialForType(normalized, targetType);

                            // Check for duplicates in local list
                            final isDuplicate = _scannedBatchItems.any((item) => item.serialNumber.toLowerCase() == cleanSerial.toLowerCase());
                            if (isDuplicate) continue;

                            // Check for duplicates in actual custody
                            final isInCustody = _custodyItems.any((item) => item.serialNumber.toLowerCase() == cleanSerial.toLowerCase());
                            if (isInCustody) continue;

                            final isTargetSim = targetType.category == 'sim';
                            final resolvedCarrier = isTargetSim ? _resolveCarrierName(targetType, _carrierName) : null;
                            _scannedBatchItems.add(ScannedBatchItem(
                              serialNumber: cleanSerial,
                              itemTypeId: targetType.id,
                              itemTypeName: targetType.nameAr,
                              isSim: isTargetSim,
                              carrierName: resolvedCarrier,
                            ));
                            addedCount++;
                          }
                        }
                        if (addedCount > 0) {
                          _scanSuccess = 'تمت إضافة $addedCount من العناصر بنجاح للقائمة المؤقتة ✓';
                          _scanError = null;
                        } else {
                          _scanError = 'لم يتم إضافة أي عناصر جديدة (مكررة أو موجودة مسبقاً)';
                          _scanSuccess = null;
                        }
                      });
                    }
                  }
                },
                tooltip: 'مسح بالكاميرا',
              ),
              IconButton(
                icon: const Icon(Icons.backspace_outlined, color: Colors.white38),
                onPressed: () {
                  (_isSim ? _iccidController : _serialController).clear();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarrierField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _carrierName ?? 'STC',
          dropdownColor: AppColors.backgroundDark,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'STC', child: Text('STC')),
            DropdownMenuItem(value: 'Mobily', child: Text('Mobily')),
            DropdownMenuItem(value: 'Zain', child: Text('Zain')),
            DropdownMenuItem(value: 'Lebara', child: Text('Lebara')),
            DropdownMenuItem(value: 'Virgin Mobile', child: Text('Virgin Mobile')),
            DropdownMenuItem(value: 'Jawwy', child: Text('Jawwy')),
            DropdownMenuItem(value: 'Friendi Mobile', child: Text('Friendi Mobile')),
            DropdownMenuItem(value: 'Salam Mobile', child: Text('Salam Mobile')),
            DropdownMenuItem(value: 'Red Bull Mobile', child: Text('Red Bull Mobile')),
          ],
          onChanged: (val) {
            setState(() {
              _carrierName = val;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner(String msg, {required bool isError}) {
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.cairo(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddToListButton() {
    if (_selectedCategory == 'sim') {
      return NeonButton.success(
        label: 'إضافة للقائمة المؤقتة (+)',
        icon: Icons.add_circle_outline,
        onPressed: _addToScannedBatch,
      );
    }
    return NeonButton(
      label: 'إضافة للقائمة المؤقتة (+)',
      icon: Icons.add_circle_outline,
      onPressed: _addToScannedBatch,
    );
  }

  Widget _buildScannedBatchList() {
    if (_scannedBatchItems.isEmpty) {
      return GlassCard(
        backgroundColor: AppColors.surfaceDark.withOpacity(0.3),
        borderColor: Colors.white.withOpacity(0.03),
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white24, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'القائمة المؤقتة فارغة',
              style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'امسح الأجهزة أو الشرائح لإضافتها للقائمة قبل الحفظ',
              style: GoogleFonts.cairo(color: Colors.white30, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final activeColor = _selectedCategory == 'sim' ? AppColors.success : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SectionHeader(
                title: 'القائمة المؤقتة (${_scannedBatchItems.length})',
                icon: Icons.list_alt,
                color: activeColor,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _scannedBatchItems.clear();
                  _scanSuccess = 'تم تفريغ القائمة المؤقتة';
                  _scanError = null;
                });
              },
              child: Text(
                'مَسح الكل',
                style: GoogleFonts.cairo(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(12),
            itemCount: _scannedBatchItems.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 16),
            itemBuilder: (context, index) {
              final item = _scannedBatchItems[index];
              final color = item.isSim ? AppColors.success : AppColors.primary;
              final opImg = _getOperatorImg(item);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    if (opImg != null)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.isSim ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(opImg, fit: BoxFit.contain),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.2)),
                        ),
                        child: Icon(item.isSim ? Icons.sim_card_outlined : Icons.devices_other, color: color, size: 20),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.serialNumber,
                            style: GoogleFonts.robotoMono(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.itemTypeName}${item.carrierName != null ? " (${item.carrierName})" : ""}',
                            style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      onPressed: () {
                        setState(() {
                          final removed = _scannedBatchItems.removeAt(index);
                          _scanSuccess = 'تمت إزالة الرقم ${removed.serialNumber}';
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        NeonButton(
          label: _isScanLoading ? 'جاري حفظ القائمة...' : 'حفظ القائمة بالكامل في النظام ✓',
          icon: _isScanLoading ? Icons.hourglass_top : Icons.cloud_upload_outlined,
          onPressed: _isScanLoading ? null : _saveBatchToBackend,
          isLoading: _isScanLoading,
        ),
      ],
    );
  }

  Widget _buildHelperCard() {
    return GlassCard(
      backgroundColor: AppColors.surfaceDark.withOpacity(0.4),
      borderColor: AppColors.primary.withOpacity(0.1),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'كيفية الاستخدام',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _helperRow('1', 'اختر نوع الصنف (جهاز POS، شريحة SIM...)'),
          _helperRow('2', 'اختر نوع المسح (جهاز = SN، شريحة = ICCID)'),
          _helperRow('3', 'امسح الباركود أو أدخل الرقم يدوياً'),
          _helperRow('4', 'اضغط زر الإضافة لتجهيز الشحنة في القائمة مؤقتاً، ثم احفظ الكل دفعة واحدة.'),
        ],
      ),
    );
  }

  Widget _helperRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.cairo(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(color: Colors.white60, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: Custody ───────────────────────────────────────
  Widget _buildCustodySearchField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _custodySearchController,
        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
        onChanged: (val) {
          setState(() {
            _custodySearchQuery = val.trim();
          });
        },
        decoration: InputDecoration(
          hintText: 'ابحث بالرقم التسلسلي أو ICCID...',
          hintStyle: GoogleFonts.cairo(color: Colors.white24, fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_custodySearchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                  onPressed: () {
                    _custodySearchController.clear();
                    setState(() {
                      _custodySearchQuery = '';
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 20),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerWidget(
                        title: 'مسح للبحث في العهدة',
                        isMultiScan: false,
                        itemTypes: _itemTypes.where((t) => t.requiresSerial == true).toList(),
                        selectedItemTypeId: _selectedItemTypeId,
                      ),
                    ),
                  );
                  if (result != null) {
                    String scannedCode = '';
                    if (result is Map<String, dynamic>) {
                      final codes = List<String>.from(result['codes'] ?? []);
                      if (codes.isNotEmpty) scannedCode = codes.first.trim();
                    } else if (result is List<String> && result.isNotEmpty) {
                      scannedCode = result.first.trim();
                    } else if (result is String) {
                      scannedCode = result.trim();
                    }

                    if (scannedCode.startsWith(']C1')) {
                      scannedCode = scannedCode.substring(3);
                    } else if (scannedCode.toLowerCase().startsWith('c1')) {
                      scannedCode = scannedCode.substring(2);
                    }

                    if (scannedCode.isNotEmpty) {
                      _custodySearchController.text = scannedCode;
                      setState(() {
                        _custodySearchQuery = scannedCode;
                      });
                    }
                  }
                },
                tooltip: 'البحث عن طريق المسح',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustodyTab() {
    if (_isCustodyLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_custodyError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text('فشل التحميل', style: GoogleFonts.cairo(color: Colors.white)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadCustody,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      );
    }
    if (_custodyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text('لا توجد عهدة مسجلة',
                style: GoogleFonts.cairo(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 8),
            Text('امسح الأجهزة والشرائح لإضافتها',
                style: GoogleFonts.cairo(color: Colors.white24, fontSize: 13)),
          ],
        ),
      );
    }

    // Filter by search query
    final filteredCustody = _custodyItems.where((item) {
      if (_custodySearchQuery.isEmpty) return true;
      final query = _custodySearchQuery.toLowerCase();
      final serial = item.serialNumber.toLowerCase();
      final name = item.displayName.toLowerCase();
      final carrier = (item.carrierName ?? '').toLowerCase();
      return serial.contains(query) || name.contains(query) || carrier.contains(query);
    }).toList();

    // Group filtered items
    final devices = filteredCustody.where((i) => !i.isSim).toList();
    final sims = filteredCustody.where((i) => i.isSim).toList();

    if (filteredCustody.isEmpty && _custodySearchQuery.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCustody,
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCustodySearchField(),
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded, color: Colors.white24, size: 64),
                  const SizedBox(height: 16),
                  Text('لا توجد نتائج مطابقة لـ "$_custodySearchQuery"',
                      style: GoogleFonts.cairo(color: Colors.white38, fontSize: 14)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      _custodySearchController.clear();
                      setState(() {
                        _custodySearchQuery = '';
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text('إعادة تعيين البحث', style: GoogleFonts.cairo(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustody,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCustodySearchField(),
          
          // Summary cards
          Row(children: [
            Expanded(child: _buildSummaryCard('أجهزة POS', devices.length.toString(), Icons.phone_android, AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('شرائح SIM', sims.length.toString(), Icons.sim_card, AppColors.success)),
          ]),
          const SizedBox(height: 20),

          if (devices.isNotEmpty) ...[
            _buildGroupHeader('أجهزة POS', devices.length, Icons.phone_android, AppColors.primary),
            const SizedBox(height: 8),
            ...devices.map((item) => _buildItemCard(item)),
            const SizedBox(height: 20),
          ],

          if (sims.isNotEmpty) ...[
            _buildGroupHeader('شرائح SIM', sims.length, Icons.sim_card, AppColors.success),
            const SizedBox(height: 8),
            ...sims.map((item) => _buildItemCard(item)),
          ],
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.02)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title, int count, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text('$title ($count)',
            style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
      ],
    );
  }

  Widget _buildItemCard(SerializedItem item) {
    final color = item.isSim ? AppColors.success : AppColors.primary;
    // Get operator image using name or carrier
    final opImg = item.isSim && item.carrierName != null
        ? IconMapper.getItemImagePath(item.carrierName, null, 'sim')
        : IconMapper.getItemImagePath(item.displayName, null, item.isSim ? 'sim' : 'devices');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          if (opImg != null)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.isSim ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(opImg, fit: BoxFit.contain),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Icon(item.isSim ? Icons.sim_card_outlined : Icons.devices_other,
                  color: color, size: 20),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.serialNumber,
                  style: GoogleFonts.robotoMono(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                if (item.carrierName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'المزود: ${item.carrierName}',
                    style: GoogleFonts.cairo(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Text(
              'في العهدة',
              style: GoogleFonts.cairo(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
