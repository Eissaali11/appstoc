import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../data/models/received_device.dart';
import '../controllers/devices_controller.dart';

class WithdrawnDeviceDetailsPage extends StatefulWidget {
  const WithdrawnDeviceDetailsPage({super.key});

  @override
  State<WithdrawnDeviceDetailsPage> createState() => _WithdrawnDeviceDetailsPageState();
}

class _WithdrawnDeviceDetailsPageState extends State<WithdrawnDeviceDetailsPage> {
  int _activeStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    final device = Get.arguments as ReceivedDevice;
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

    // Format date
    final dateStr = device.createdAt != null
        ? device.createdAt!.toLocal().toString().split('.').first
        : 'غير محدد';

    void _shareReceipt() {
      final buffer = StringBuffer();
      buffer.writeln('📋 *إيصال استلام جهاز مسحوب* 📋');
      buffer.writeln('-----------------------------------');
      buffer.writeln('📦 *المنتج:* $itemName');
      buffer.writeln('🔢 *الرقم التسلسلي (S/N):* ${device.serialNumber}');
      if (device.terminalId != null && device.terminalId!.isNotEmpty) {
        buffer.writeln('📟 *رقم الجهاز (Terminal ID):* ${device.terminalId}');
      }
      buffer.writeln('🏢 *نوع المستودع:* ${device.inventoryType == 'moving' ? 'مخزون متحرك' : 'مخزون ثابت'}');
      buffer.writeln('📅 *التاريخ والوقت:* $dateStr');
      buffer.writeln('-----------------------------------');
      buffer.writeln('🔌 *الملحقات المستلمة:*');
      buffer.writeln('  - بطارية: ${device.battery ? '✅ موجودة' : '❌ غير موجودة'}');
      buffer.writeln('  - كابل شاحن: ${device.chargerCable ? '✅ موجود' : '❌ غير موجود'}');
      buffer.writeln('  - رأس شاحن: ${device.chargerHead ? '✅ موجود' : '❌ غير موجود'}');
      buffer.writeln('  - شريحة SIM: ${device.hasSim ? '✅ موجودة (${device.simCardType ?? 'غير محدد'})' : '❌ غير موجودة'}');
      
      if (device.damagePart != null && device.damagePart!.trim().isNotEmpty) {
        buffer.writeln('-----------------------------------');
        buffer.writeln('⚠️ *الضرر/الأعطال:* ${device.damagePart}');
      }
      
      buffer.writeln('-----------------------------------');
      buffer.writeln('📌 *الحالة الحالية:* ${device.statusText}');
      if (device.adminNotes != null && device.adminNotes!.trim().isNotEmpty) {
        buffer.writeln('💬 *ملاحظات المشرف:* ${device.adminNotes}');
      }
      buffer.writeln('\n*تم التوريد عبر تطبيق المخزون الذكي*');

      Share.share(buffer.toString(), subject: 'إيصال استلام جهاز');
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'تفاصيل ودورة حياة الجهاز',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: _shareReceipt,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Header Card with Neon Glow Gradient & Metadata
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Icon(
                    itemIcon,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.qr_code, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              device.serialNumber,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: device.statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: device.statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    device.statusText,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: device.statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Interactive Graphical Stepper (دورة حياة الجهاز التفاعلية)
          _buildSectionTitle('دورة حياة الجهاز الميدانية'),
          _buildInteractiveStepper(device),
          const SizedBox(height: 20),

          // 3. Interactive Step Details Container (تفاصيل المرحلة النشطة)
          _buildStepDetailsCard(device, itemName, dateStr, _shareReceipt),
          const SizedBox(height: 24),

          // 4. Hardware Diagnostic Profile (الملحقات والتشخيص الفني)
          if (itemType?.category == 'devices') ...[
            _buildSectionTitle('التشخيص الفني والملحقات'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                _buildAccessoryVisualCard('بطارية الجهاز', device.battery, Icons.battery_charging_full),
                _buildAccessoryVisualCard('كابل الشاحن', device.chargerCable, Icons.cable),
                _buildAccessoryVisualCard('رأس الشاحن', device.chargerHead, Icons.power),
                _buildAccessoryVisualCard(
                  device.hasSim ? (device.simCardType ?? 'شريحة SIM') : 'شريحة SIM', 
                  device.hasSim, 
                  Icons.sim_card
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // 5. Damage Section (If present)
          if (device.damagePart != null && device.damagePart!.trim().isNotEmpty) ...[
            _buildSectionTitle('تقرير الضرر والأعطال'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.2), width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الجزء المتضرر عند الاستلام',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.damagePart!,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 6. Action Button
          ElevatedButton.icon(
            onPressed: _shareReceipt,
            icon: const Icon(Icons.share_rounded),
            label: Text(
              'مشاركة إيصال الاستلام الرقمي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4, top: 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  // المكون الرسومي التفاعلي للخط الزمني ودورة حياة الأجهزة
  Widget _buildInteractiveStepper(ReceivedDevice device) {
    final List<Map<String, dynamic>> steps = [
      {'title': 'التوريد', 'icon': Icons.qr_code_scanner},
      {'title': 'الاعتماد', 'icon': Icons.fact_check},
      {'title': 'العهدة', 'icon': Icons.inventory},
      {'title': 'التسليم', 'icon': Icons.local_shipping},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = _isStepCompleted(index, device);
          final isActive = _activeStepIndex == index;
          
          Color stateColor = Colors.grey.withOpacity(0.4);
          if (isActive) {
            stateColor = AppColors.primary;
          } else if (isCompleted) {
            stateColor = AppColors.success;
          }

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeStepIndex = index;
                });
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      // Line connecting steps
                      Expanded(
                        child: Container(
                          height: 2.5,
                          color: index == 0 
                              ? Colors.transparent 
                              : (_isStepCompleted(index - 1, device) 
                                  ? AppColors.success.withOpacity(0.5) 
                                  : Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      
                      // Step Circle Icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isActive ? 44 : 36,
                        height: isActive ? 44 : 36,
                        decoration: BoxDecoration(
                          color: isActive 
                              ? AppColors.primary.withOpacity(0.12) 
                              : (isCompleted ? AppColors.success.withOpacity(0.08) : Colors.white.withOpacity(0.02)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: stateColor,
                            width: isActive ? 2.5 : 1.5,
                          ),
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ] : [],
                        ),
                        child: Center(
                          child: Icon(
                            steps[index]['icon'] as IconData,
                            color: stateColor,
                            size: isActive ? 20 : 16,
                          ),
                        ),
                      ),
                      
                      // Line connecting steps
                      Expanded(
                        child: Container(
                          height: 2.5,
                          color: index == steps.length - 1 
                              ? Colors.transparent 
                              : (isCompleted 
                                  ? AppColors.success.withOpacity(0.5) 
                                  : Colors.white.withOpacity(0.05)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[index]['title'] as String,
                    style: GoogleFonts.cairo(
                      fontSize: isActive ? 13 : 11,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.white : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  bool _isStepCompleted(int stepIndex, ReceivedDevice device) {
    final status = (device.status ?? '').toLowerCase();
    switch (stepIndex) {
      case 0:
        return true; // scanned in is always complete
      case 1:
        return status == 'approved' || status == 'rejected' || status == 'delivered';
      case 2:
        return status == 'approved' || status == 'delivered';
      case 3:
        return status == 'delivered';
      default:
        return false;
    }
  }

  // بطاقة تفاصيل المرحلة النشطة التي تظهر وتتغير بحسب نقرة المستخدم
  Widget _buildStepDetailsCard(ReceivedDevice device, String itemName, String dateStr, VoidCallback onShare) {
    switch (_activeStepIndex) {
      case 0:
        return _buildDetailsContainer(
          title: 'تفاصيل التوريد والمسح الضوئي (Intake)',
          icon: Icons.qr_code_scanner,
          rows: [
            _buildDetailItem('الاسم والنوع', itemName),
            _buildDetailItem('الرقم التسلسلي S/N', device.serialNumber, copyable: true),
            _buildDetailItem('تاريخ المسح', dateStr),
            _buildDetailItem('العهدة المحددة', device.inventoryType == 'moving' ? 'مخزون متحرك' : 'مخزون ثابت'),
            _buildDetailItem('حالة الرفع', 'مزامنة فورية (قاعدة البيانات)'),
          ],
        );
      case 1:
        final bool isApproved = device.status == 'approved' || device.status == 'delivered';
        final bool isRejected = device.status == 'rejected';
        
        return _buildDetailsContainer(
          title: 'الاعتماد وموافقة المشرف (Approval)',
          icon: Icons.fact_check,
          accentColor: isApproved ? AppColors.success : (isRejected ? AppColors.error : AppColors.warning),
          rows: [
            _buildDetailItem('حالة الطلب الحالية', device.statusText),
            _buildDetailItem('اسم المشرف المعتمد', device.approvedBy ?? 'بانتظار المراجعة...'),
            _buildDetailItem(
              'تاريخ الاعتماد', 
              device.approvedAt != null 
                  ? device.approvedAt!.toLocal().toString().split('.').first 
                  : 'معلق'
            ),
            _buildDetailItem('ملاحظات المراجعة', device.adminNotes ?? 'لا توجد ملاحظات مدونة'),
          ],
        );
      case 2:
        final bool isCustodyActive = device.status == 'approved' || device.status == 'delivered';
        return _buildDetailsContainer(
          title: 'حالة العهدة الميدانية (Active Custody)',
          icon: Icons.inventory,
          accentColor: isCustodyActive ? AppColors.success : Colors.grey,
          rows: [
            _buildDetailItem('حائز العهدة الحالي', 'المندوب التجريبي (tech1)'),
            _buildDetailItem('حالة العهدة فنية', isCustodyActive ? 'نشطة (في عهدة المندوب)' : 'غير مفعلة (بانتظار الاعتماد)'),
            _buildDetailItem('نوع العهدة الجغرافية', device.inventoryType == 'moving' ? 'حقيبة المندوب الميدانية' : 'الموقع الرئيسي المستودع'),
            _buildDetailItem('الموقع الجغرافي المسجل', 'الرياض، المملكة العربية السعودية'),
          ],
        );
      case 3:
        final bool isDelivered = device.status == 'delivered';
        return _buildDetailsContainer(
          title: 'تسليم الجهاز النهائي (Handover)',
          icon: Icons.local_shipping,
          accentColor: isDelivered ? AppColors.success : Colors.grey,
          rows: [
            _buildDetailItem('حالة التسليم النهائي', isDelivered ? 'تم تسليم الجهاز بنجاح' : 'لم يتم التسليم بعد (عهدة نشطة)'),
            _buildDetailItem('إيصال التسليم الرقمي', isDelivered ? 'متوفر للتصدير والمشاركة' : 'سيتم إصداره فور تسليم الجهاز'),
            _buildDetailItem('التوقيع الإلكتروني للمستلم', isDelivered ? 'موقع رقمياً ومحفوظ بالقاعدة' : 'غير متوفر بعد'),
            _buildDetailItem('إحداثيات التحقق GPS', '24.7136° N, 46.6753° E', copyable: true),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsContainer({
    required String title,
    required IconData icon,
    required List<Widget> rows,
    Color accentColor = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'نسخ',
      'تم نسخ $label إلى الحافظة',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildDetailItem(String label, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                    textDirection: TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _copyToClipboard(value, label),
                    child: const Icon(
                      Icons.copy_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoryVisualCard(String title, bool isPresent, IconData icon) {
    final activeColor = isPresent ? AppColors.success : AppColors.textSecondary.withOpacity(0.4);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPresent ? AppColors.success.withOpacity(0.4) : AppColors.border.withOpacity(0.05),
          width: isPresent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: activeColor, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: isPresent ? FontWeight.bold : FontWeight.normal,
                color: isPresent ? Colors.white : AppColors.textSecondary.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: activeColor,
            size: 18,
          ),
        ],
      ),
    );
  }
}
