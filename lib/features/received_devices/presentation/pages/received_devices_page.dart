import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../presentation/controllers/devices_controller.dart';
import '../../data/models/received_device.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../core/routing/app_pages.dart';

class ReceivedDevicesPage extends StatefulWidget {
  const ReceivedDevicesPage({super.key});

  @override
  State<ReceivedDevicesPage> createState() => _ReceivedDevicesPageState();
}

class _ReceivedDevicesPageState extends State<ReceivedDevicesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild on tab change to filter
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ReceivedDevice> _filterDevices(List<ReceivedDevice> allDevices) {
    switch (_tabController.index) {
      case 1: // Pending
        return allDevices.where((d) => (d.status ?? '').toLowerCase() == 'pending').toList();
      case 2: // Approved
        return allDevices.where((d) => (d.status ?? '').toLowerCase() == 'approved' || (d.status ?? '').toLowerCase() == 'accepted').toList();
      case 3: // Rejected
        return allDevices.where((d) => (d.status ?? '').toLowerCase() == 'rejected').toList();
      case 0: // All
      default:
        return allDevices;
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceDark.withOpacity(0.6),
      highlightColor: AppColors.border.withOpacity(0.15),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 50,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DevicesController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'سجل الأجهزة المسحوبة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadDevices(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'معلق'),
            Tab(text: 'مقبول'),
            Tab(text: 'مرفوض'),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading && controller.devices.isEmpty) {
          return _buildShimmerLoading();
        }

        final filteredDevices = _filterDevices(controller.devices);

        if (filteredDevices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.devices_other,
                    size: 72,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد أجهزة مسحوبة في هذا التبويب',
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

        return RefreshIndicator(
          onRefresh: () => controller.loadDevices(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDevices.length,
            itemBuilder: (context, index) {
              final device = filteredDevices[index];
              return _ReceivedDeviceCard(device: device);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDeliveryOptions(context, controller),
        label: Text(
          'تسليم العهدة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showDeliveryOptions(BuildContext context, DevicesController controller) {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تسليم العهدة (الأجهزة المسحوبة)',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اختر طريقة إدخال بيانات الجهاز لتأكيد التسليم',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              
              // Option 1: Camera Scan
              InkWell(
                onTap: () async {
                  Get.back(); // close bottom sheet
                  final result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BarcodeScannerWidget(
                        title: 'مسح باركود تسليم العهدة',
                      ),
                    ),
                  );
                  if (result != null && result.trim().isNotEmpty) {
                    await controller.deliverDeviceByBarcode(result.trim());
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مسح باركود بالكاميرا',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'استخدم كاميرا الجوال لمسح باركود الجهاز تلقائياً',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Manual entry
              InkWell(
                onTap: () {
                  Get.back(); // close bottom sheet
                  _showManualEntryDialog(context, controller);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_note, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إدخال يدوي للبيانات',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'كتابة الرقم التسلسلي أو باركود الجهاز يدوياً',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white54, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showManualEntryDialog(BuildContext context, DevicesController controller) {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'إدخال يدوي للعهد المستلمة',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يرجى كتابة الرقم التسلسلي (Serial Number) أو الباركود الخاص بالجهاز المُراد تأكيد تسليمه:',
                  style: GoogleFonts.cairo(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: textController,
                  autofocus: true,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'أدخل الرقم التسلسلي هنا...',
                    hintStyle: GoogleFonts.cairo(color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.backgroundDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'حقل الرقم التسلسلي مطلوب';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final barcode = textController.text.trim();
                  Get.back(); // close dialog
                  await controller.deliverDeviceByBarcode(barcode);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'تأكيد التسليم',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceivedDeviceCard extends StatelessWidget {
  final ReceivedDevice device;

  const _ReceivedDeviceCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DevicesController>();
    ItemType? itemType;
    if (device.itemTypeId != null) {
      for (var type in controller.itemTypes) {
        if (type.id == device.itemTypeId) {
          itemType = type;
          break;
        }
      }
    }

    final itemName = itemType?.nameAr ?? 
        (device.terminalId != null && device.terminalId!.isNotEmpty 
            ? 'جهاز ${device.terminalId}' 
            : 'جهاز غير معروف');

    // Dynamic icon based on category
    IconData itemIcon = Icons.smartphone;
    if (itemType?.category == 'papers') {
      itemIcon = Icons.description;
    } else if (itemType?.category == 'sim') {
      itemIcon = Icons.sim_card;
    } else if (itemType?.category == 'accessories') {
      itemIcon = Icons.headset;
    }

    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withOpacity(0.08), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.toNamed(Routes.withdrawnDeviceDetails, arguments: device),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: device.statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      itemIcon,
                      color: device.statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'باركود: ${device.serialNumber}',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: device.statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: device.statusColor.withOpacity(0.4), width: 0.8),
                        ),
                        child: Text(
                          device.statusText,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: device.statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        device.inventoryType == 'moving' ? 'مخزون متحرك' : 'مخزون ثابت',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: device.inventoryType == 'moving'
                              ? Colors.purple[300]
                              : Colors.blueGrey[300],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (device.damagePart != null &&
                  device.damagePart!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          device.damagePart!,
                          style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (device.createdAt ?? DateTime.now())
                        .toLocal()
                        .toString()
                        .split('.')
                        .first,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'عرض التفاصيل',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
