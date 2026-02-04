import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../inventory_requests/presentation/controllers/inventory_request_controller.dart';
import '../../../inventory_requests/data/repositories/inventory_request_repository_impl.dart';
import '../../../inventory_requests/domain/repositories/inventory_request_repository.dart';
import '../../../../shared/models/item_type.dart';

class RequestInventoryPage extends StatefulWidget {
  const RequestInventoryPage({super.key});

  @override
  State<RequestInventoryPage> createState() => _RequestInventoryPageState();
}

class _RequestInventoryPageState extends State<RequestInventoryPage>
    with SingleTickerProviderStateMixin {
  late InventoryRequestController controller;
  late TabController _tabController;
  
  // Dynamic controllers based on item types from API
  final Map<String, TextEditingController> _boxesControllers = {};
  final Map<String, TextEditingController> _unitsControllers = {};
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ensure binding is initialized
    if (!Get.isRegistered<InventoryRequestRepository>()) {
      Get.put<InventoryRequestRepository>(InventoryRequestRepositoryImpl());
    }
    if (!Get.isRegistered<InventoryRequestController>()) {
      Get.put(InventoryRequestController(
        repository: Get.find<InventoryRequestRepository>(),
      ));
    }
    controller = Get.find<InventoryRequestController>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Wait for item types to load, then initialize controllers
    _initializeControllers();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      controller.loadMyRequests();
    }
  }

  void _initializeControllers() {
    // Initialize controllers for all active item types
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.itemTypes.isNotEmpty) {
        setState(() {
          for (var itemType in controller.itemTypes) {
            _boxesControllers[itemType.id] = TextEditingController(text: '0');
            _unitsControllers[itemType.id] = TextEditingController(text: '0');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _boxesControllers.values) {
      controller.dispose();
    }
    for (var controller in _unitsControllers.values) {
      controller.dispose();
    }
    _notesController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  int _parseInt(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 0;
  }

  Future<void> _submitRequest() async {
    // نبني الكميات لكل صنف، وسنحوّلها إلى الحقول الثابتة
    // التي يتوقعها الـ API (n950Boxes, rollPaperUnits, ...).
    int n950Boxes = 0,
        n950Units = 0,
        i9000sBoxes = 0,
        i9000sUnits = 0,
        i9100Boxes = 0,
        i9100Units = 0,
        rollPaperBoxes = 0,
        rollPaperUnits = 0,
        stickersBoxes = 0,
        stickersUnits = 0,
        newBatteriesBoxes = 0,
        newBatteriesUnits = 0,
        mobilySimBoxes = 0,
        mobilySimUnits = 0,
        stcSimBoxes = 0,
        stcSimUnits = 0,
        zainSimBoxes = 0,
        zainSimUnits = 0;

    bool hasAnyQuantity = false;

    for (var itemType in controller.itemTypes) {
      final boxesController = _boxesControllers[itemType.id];
      final unitsController = _unitsControllers[itemType.id];
      
      if (boxesController != null && unitsController != null) {
        final boxes = _parseInt(boxesController);
        final units = _parseInt(unitsController);
        if (boxes > 0 || units > 0) {
          hasAnyQuantity = true;

          final nameEn = itemType.nameEn.toLowerCase();
          final nameAr = itemType.nameAr;

          if (nameEn.contains('n950')) {
            n950Boxes = boxes;
            n950Units = units;
          } else if (nameEn.contains('i9000s')) {
            i9000sBoxes = boxes;
            i9000sUnits = units;
          } else if (nameEn.contains('i9100')) {
            i9100Boxes = boxes;
            i9100Units = units;
          } else if (nameEn.contains('roll') ||
              nameEn.contains('paper') ||
              nameAr.contains('ورق')) {
            rollPaperBoxes = boxes;
            rollPaperUnits = units;
          } else if (nameEn.contains('sticker') ||
              nameAr.contains('ملصق')) {
            stickersBoxes = boxes;
            stickersUnits = units;
          } else if (nameEn.contains('battery') ||
              nameAr.contains('بطاري')) {
            newBatteriesBoxes = boxes;
            newBatteriesUnits = units;
          } else if (nameEn.contains('mobily')) {
            mobilySimBoxes = boxes;
            mobilySimUnits = units;
          } else if (nameEn.contains('stc')) {
            stcSimBoxes = boxes;
            stcSimUnits = units;
          } else if (nameEn.contains('zain')) {
            zainSimBoxes = boxes;
            zainSimUnits = units;
          }
        }
      }
    }

    if (!hasAnyQuantity) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال كمية لصنف واحد على الأقل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final success = await controller.createRequest(
      n950Boxes: n950Boxes,
      n950Units: n950Units,
      i9000sBoxes: i9000sBoxes,
      i9000sUnits: i9000sUnits,
      i9100Boxes: i9100Boxes,
      i9100Units: i9100Units,
      rollPaperBoxes: rollPaperBoxes,
      rollPaperUnits: rollPaperUnits,
      stickersBoxes: stickersBoxes,
      stickersUnits: stickersUnits,
      newBatteriesBoxes: newBatteriesBoxes,
      newBatteriesUnits: newBatteriesUnits,
      mobilySimBoxes: mobilySimBoxes,
      mobilySimUnits: mobilySimUnits,
      stcSimBoxes: stcSimBoxes,
      stcSimUnits: stcSimUnits,
      zainSimBoxes: zainSimBoxes,
      zainSimUnits: zainSimUnits,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (success) {
      Get.snackbar(
        'نجح',
        'تم إرسال طلب المخزون بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
      
      // Clear form
      setState(() {
        for (var controller in _boxesControllers.values) {
          controller.text = '0';
        }
        for (var controller in _unitsControllers.values) {
          controller.text = '0';
        }
        _notesController.clear();
      });
    } else {
      Get.snackbar(
        'خطأ',
        controller.error ?? 'فشل إرسال الطلب',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildItemRow(ItemType itemType) {
    final boxesController = _boxesControllers[itemType.id];
    final unitsController = _unitsControllers[itemType.id];
    
    if (boxesController == null || unitsController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: itemType.colorHex != null
                      ? Color(int.parse(itemType.colorHex!.replaceFirst('#', '0xFF')))
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  IconMapper.getIcon(itemType.iconName),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemType.nameAr,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuantityField(
                  'كراتين',
                  boxesController,
                  Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuantityField(
                  'وحدات',
                  unitsController,
                  Icons.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.cairo(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppColors.border.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'طلب مخزون',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_shopping_cart), text: 'طلب جديد'),
            Tab(icon: Icon(Icons.history), text: 'طلباتي'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // تبويب الطلب الجديد
          Obx(() {
            if (controller.isLoading && controller.itemTypes.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            // Initialize controllers when item types are loaded
            if (controller.itemTypes.isNotEmpty && _boxesControllers.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  for (var itemType in controller.itemTypes) {
                    _boxesControllers[itemType.id] =
                        TextEditingController(text: '0');
                    _unitsControllers[itemType.id] =
                        TextEditingController(text: '0');
                  }
                });
              });
            }

            final totalItems = _boxesControllers.entries.fold<int>(
                  0,
                  (sum, e) =>
                      sum + _parseInt(e.value),
                ) +
                _unitsControllers.entries.fold<int>(
                  0,
                  (sum, e) =>
                      sum + _parseInt(e.value),
                );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary + Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.orangeGradient,
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.request_quote,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'طلب مخزون من المستودع',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${controller.itemTypes.length} نوع متاح • إجمالي الكمية: $totalItems',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Items List (Dynamic from API)
                  if (controller.itemTypes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'جاري تحميل الأصناف...',
                              style: GoogleFonts.cairo(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...controller.itemTypes
                        .map((itemType) => _buildItemRow(itemType)),

                  const SizedBox(height: 24),

                  // Notes
                  Text(
                    'ملاحظات (اختياري)',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      style: GoogleFonts.cairo(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'أضف ملاحظات',
                        labelStyle: GoogleFonts.cairo(
                            color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.note,
                            color: AppColors.primary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isLoading ? null : _submitRequest,
                      icon: const Icon(Icons.send),
                      label: Text(
                        'إرسال الطلب',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          }),

          // تبويب طلباتي
          Obx(() {
            if (controller.isLoading && controller.myRequests.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (controller.myRequests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inbox_outlined,
                        size: 72,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد طلبات مخزون سابقة',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final requests = controller.myRequests;

            return RefreshIndicator(
              onRefresh: () => controller.loadMyRequests(),
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  Color statusColor;
                  IconData statusIcon;
                  String statusText;

                  final status = request.status.toLowerCase();
                  switch (status) {
                    case 'approved':
                      statusColor = AppColors.success;
                      statusIcon = Icons.check_circle_rounded;
                      statusText = 'تمت الموافقة';
                      break;
                    case 'rejected':
                      statusColor = AppColors.error;
                      statusIcon = Icons.cancel_rounded;
                      statusText = 'مرفوض';
                      break;
                    default:
                      statusColor = AppColors.warning;
                      statusIcon = Icons.schedule_rounded;
                      statusText = 'قيد الانتظار';
                  }

                  final dateStr = request.createdAt.toLocal();
                  final dateFormatted =
                      '${dateStr.day}/${dateStr.month}/${dateStr.year}';
                  final timeFormatted =
                      '${dateStr.hour.toString().padLeft(2, '0')}:${dateStr.minute.toString().padLeft(2, '0')}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Material(
                      color: Colors.transparent,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor,
                                statusColor.withOpacity(0.85),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            statusIcon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusText,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dateFormatted,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeFormatted,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${request.totalItems}',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 28,
                        ),
                        iconColor: AppColors.textSecondary,
                        collapsedIconColor: AppColors.textSecondary,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_rounded,
                                      size: 20,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تفاصيل الطلب',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...[
                                  _buildRequestItemRow(
                                    'جهاز N950',
                                    request.n950Boxes,
                                    request.n950Units,
                                  ),
                                  _buildRequestItemRow(
                                    'جهاز I9000s',
                                    request.i9000sBoxes,
                                    request.i9000sUnits,
                                  ),
                                  _buildRequestItemRow(
                                    'جهاز I9100',
                                    request.i9100Boxes,
                                    request.i9100Units,
                                  ),
                                  _buildRequestItemRow(
                                    'ورق حراري',
                                    request.rollPaperBoxes,
                                    request.rollPaperUnits,
                                  ),
                                  _buildRequestItemRow(
                                    'ملصقات',
                                    request.stickersBoxes,
                                    request.stickersUnits,
                                  ),
                                  _buildRequestItemRow(
                                    'بطاريات جديدة',
                                    request.newBatteriesBoxes,
                                    request.newBatteriesUnits,
                                  ),
                                  _buildRequestItemRow(
                                    'شرائح موبايلي',
                                    request.mobilySimBoxes,
                                    request.mobilySimUnits,
                                  ),
                                  _buildRequestItemRow(
                                    'شرائح STC',
                                    request.stcSimBoxes,
                                    request.stcSimUnits,
                                  ),
                                  _buildRequestItemRow(
                                    'شرائح زين',
                                    request.zainSimBoxes,
                                    request.zainSimUnits,
                                  ),
                                ].whereType<Widget>().toList(),
                              ],
                            ),
                          ),
                          if (request.notes != null &&
                              request.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildNoteCard(
                              icon: Icons.note_alt_rounded,
                              title: 'ملاحظات الفني',
                              content: request.notes!,
                              color: AppColors.primary,
                            ),
                          ],
                          if (request.adminNotes != null &&
                              request.adminNotes!.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildNoteCard(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'رد الإدارة',
                              content: request.adminNotes!,
                              color: statusColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  /// يبني صفاً لعرض كميات صنف واحد (صناديق / وحدات) في بطاقة "طلباتي".
  Widget? _buildRequestItemRow(
    String label,
    int? boxes,
    int? units,
  ) {
    final b = boxes ?? 0;
    final u = units ?? 0;
    if (b == 0 && u == 0) return null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ),
          if (b > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$b كرتون',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          if (b > 0 && u > 0) const SizedBox(width: 8),
          if (u > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$u وحدة',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بطاقة عرض ملاحظة (فني أو إدارة)
  Widget _buildNoteCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.cairo(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}
