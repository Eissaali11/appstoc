import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_pages.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/barcode_scanner_widget.dart';
import '../../../../shared/widgets/lottie_feedback_dialog.dart';
import '../controllers/device_handover_controller.dart';
import '../../data/models/received_device.dart';

class DeviceHandoverPage extends StatelessWidget {
  const DeviceHandoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DeviceHandoverController>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'تسليم ونقل عهدة الأجهزة',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر مسح الباركود السريع بالكامل
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            tooltip: 'مسح باركود الجهاز بالكاميرا',
            onPressed: () async {
              final String? scannedValue = await Get.to<String>(
                () => const BarcodeScannerWidget(
                  title: 'مسح باركود جهاز العهدة',
                ),
              );

              if (scannedValue != null && scannedValue.isNotEmpty) {
                final success = controller.scanAndSelectDevice(scannedValue);
                if (success) {
                  Get.snackbar(
                    'تم تحديد الجهاز',
                    'تم التعرف على الرقم التسلسلي $scannedValue وتحديده من العهدة',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.success,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                } else {
                  Get.snackbar(
                    'تنبيه',
                    'الجهاز ذو الرقم التسلسلي $scannedValue غير موجود في عهدتك النشطة أو تم تحديده بالفعل',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.warning,
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(16),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadData(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading && controller.myCustodyDevices.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return Column(
          children: [
            // لوحة إعدادات التحويل (المستلم ونوع التحويل)
            _buildTransferSettingsPanel(context, controller),
            
            // عنوان قسم الأجهزة المتوفرة في العهدة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الأجهزة المتوفرة في عهدتك (${controller.myCustodyDevices.length})',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (controller.selectedDevices.isNotEmpty)
                    TextButton(
                      onPressed: () => controller.clearSelection(),
                      child: Text(
                        'إلغاء التحديد (${controller.selectedDevices.length})',
                        style: GoogleFonts.cairo(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // قائمة الأجهزة المتوفرة
            Expanded(
              child: controller.myCustodyDevices.isEmpty
                  ? _buildEmptyCustoryState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.myCustodyDevices.length,
                      itemBuilder: (context, index) {
                        final device = controller.myCustodyDevices[index];
                        final isSelected = controller.isDeviceSelected(device);

                        return _buildDeviceCustodyCard(context, controller, device, isSelected);
                      },
                    ),
            ),

            // شريط الإجراءات السفلي المثبت
            _buildBottomActionBar(context, controller),
          ],
        );
      }),
    );
  }

  Widget _buildTransferSettingsPanel(BuildContext context, DeviceHandoverController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'وجهة نقل العهدة والتسليم',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // تبديل نوع التحويل (فني آخر / مستودع)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.setHandoverType('technician'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: controller.handoverType == 'technician'
                          ? LinearGradient(colors: AppColors.purpleGradient)
                          : null,
                      color: controller.handoverType == 'technician'
                          ? null
                          : AppColors.cardColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.handoverType == 'technician'
                            ? Colors.indigoAccent
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            color: controller.handoverType == 'technician' ? Colors.white : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'إلى فني آخر',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: controller.handoverType == 'technician' ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => controller.setHandoverType('warehouse'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: controller.handoverType == 'warehouse'
                          ? const LinearGradient(colors: AppColors.orangeGradient)
                          : null,
                      color: controller.handoverType == 'warehouse'
                          ? null
                          : AppColors.cardColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: controller.handoverType == 'warehouse'
                            ? Colors.orangeAccent
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warehouse,
                            color: controller.handoverType == 'warehouse' ? Colors.white : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'إلى مستودع',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: controller.handoverType == 'warehouse' ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // قائمة الاختيار المنسدلة للجهة المستلمة
          Text(
            controller.handoverType == 'technician' ? 'اختر الفني المستلم للعهدة' : 'اختر المستودع المستلم للأجهزة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),

          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: AppColors.surfaceDark,
            ),
            child: DropdownButtonFormField<String>(
              value: controller.selectedRecipientId,
              isExpanded: true,
              hint: Text(
                controller.handoverType == 'technician' ? 'حدد الفني المستلم...' : 'حدد المستودع المستهدف...',
                style: GoogleFonts.cairo(color: AppColors.textSecondary),
              ),
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.cardColor.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white12, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              items: controller.handoverType == 'technician'
                  ? controller.technicians.map((tech) {
                      return DropdownMenuItem<String>(
                        value: tech['id'],
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.indigo,
                              child: Icon(Icons.person, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text(tech['name'] ?? ''),
                            const Spacer(),
                            Text(
                              tech['city'] ?? '',
                              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  : controller.warehouses.map((wh) {
                      return DropdownMenuItem<String>(
                        value: wh['id'],
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.store, size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text(wh['name'] ?? ''),
                            const Spacer(),
                            Text(
                              wh['city'] ?? '',
                              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              onChanged: (val) {
                if (val != null) {
                  controller.selectRecipient(val);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCustoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 72,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد أجهزة في عهدتك حالياً',
            style: GoogleFonts.cairo(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بمسح واستلام أجهزة جديدة أولاً لتظهر هنا',
            style: GoogleFonts.cairo(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCustodyCard(
    BuildContext context,
    DeviceHandoverController controller,
    ReceivedDevice device,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => controller.toggleDeviceSelection(device),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardColor.withOpacity(0.8) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // تشيك بوكس مخصص أو أيقونة اختيار
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.white30,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),

            // بيانات الجهاز بالكامل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'جهاز نقطة بيع POS',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      // بادج نوع المخزون
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.purple.withOpacity(0.4), width: 0.5),
                        ),
                        child: Text(
                          'عهدة متحركة',
                          style: GoogleFonts.cairo(
                            color: Colors.purple[200],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // تفاصيل الأرقام
                  Row(
                    children: [
                      Text(
                        'رقم تسلسلي: ',
                        style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      Text(
                        device.serialNumber,
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  if (device.terminalId != null && device.terminalId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Text(
                            'رقم الجهاز (TID): ',
                            style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          Text(
                            device.terminalId!,
                            style: GoogleFonts.cairo(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),

                  // أيقونات الملحقات المسلمة مع هذا الجهاز
                  Row(
                    children: [
                      Text(
                        'الملحقات بالعهدة: ',
                        style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      _buildMiniAccessoryChip('بطارية', device.battery),
                      const SizedBox(width: 4),
                      _buildMiniAccessoryChip('شاحن سلك', device.chargerCable),
                      const SizedBox(width: 4),
                      _buildMiniAccessoryChip('رأس شاحن', device.chargerHead),
                      if (device.hasSim) ...[
                        const SizedBox(width: 4),
                        _buildMiniAccessoryChip(device.simCardType ?? 'SIM', true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAccessoryChip(String label, bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPresent ? AppColors.primary.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isPresent ? AppColors.primary.withOpacity(0.3) : Colors.white10,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          color: isPresent ? AppColors.primary : AppColors.textSecondary,
          fontSize: 9,
          fontWeight: isPresent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, DeviceHandoverController controller) {
    final hasSelection = controller.selectedDevices.isNotEmpty;
    final hasRecipient = controller.selectedRecipientId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // عداد التحديد
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الأجهزة المحددة للتسليم',
                    style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${controller.selectedDevices.length} جهاز / أجهزة',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // زر النقل
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: (hasSelection && hasRecipient && !controller.isLoading)
                    ? () async {
                        // تجميع معلومات المستلم قبل النقل للتمرير إلى صفحة التفاصيل كـ arguments
                        final recipientName = controller.handoverType == 'technician'
                            ? controller.technicians.firstWhere((t) => t['id'] == controller.selectedRecipientId)['name'] ?? ''
                            : controller.warehouses.firstWhere((w) => w['id'] == controller.selectedRecipientId)['name'] ?? '';

                        final recipientCity = controller.handoverType == 'technician'
                            ? controller.technicians.firstWhere((t) => t['id'] == controller.selectedRecipientId)['city'] ?? ''
                            : controller.warehouses.firstWhere((w) => w['id'] == controller.selectedRecipientId)['city'] ?? '';

                        final List<ReceivedDevice> itemsToTransfer = controller.selectedDevices.toList();

                        final success = await controller.submitHandover();
                        if (success) {
                          await AppLottieFeedback.show(
                            isSuccess: true,
                            title: 'تم إرسال طلب نقل العهدة بنجاح',
                            message: 'بانتظار موافقة الطرف الآخر ($recipientName) لإتمام نقل العهدة',
                            onComplete: () {
                              // التوجيه التلقائي إلى شاشة تفاصيل عملية التسليم مع تمرير التفاصيل الفورية كـ Arguments لتجربة مستخدم مدهشة
                              Get.toNamed(
                                Routes.handoverDetails,
                                arguments: {
                                  'recipientId': controller.selectedRecipientId,
                                  'recipientType': controller.handoverType,
                                  'recipientName': recipientName,
                                  'recipientCity': recipientCity,
                                  'devices': itemsToTransfer,
                                  'date': DateTime.now(),
                                  'status': 'pending', // قيد انتظار موافقة المستلم
                                  'latitude': controller.latitude,
                                  'longitude': controller.longitude,
                                },
                              );
                            },
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.white12,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: controller.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'إجراء نقل العهدة',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (hasSelection && hasRecipient) ? Colors.white : Colors.white30,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

