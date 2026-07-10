import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/routing/app_pages.dart';
import '../../../../core/utils/gps_helper.dart';
import '../../data/models/received_device.dart';

class HandoverDetailsPage extends StatefulWidget {
  const HandoverDetailsPage({super.key});

  @override
  State<HandoverDetailsPage> createState() => _HandoverDetailsPageState();
}

class _HandoverDetailsPageState extends State<HandoverDetailsPage> {
  Uint8List? _signatureBytes;

  @override
  Widget build(BuildContext context) {
    // قراءة البيانات الممررة من صفحة التسليم أو استخدام بيانات تجريبية افتراضية للحيلولة دون تعطل التطبيق
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    
    final String recipientType = args['recipientType'] ?? 'technician';
    final String recipientName = args['recipientName'] ?? 'عيسى علي البشري';
    final String recipientCity = args['recipientCity'] ?? 'مكة المكرمة';
    final String status = args['status'] ?? 'pending';
    final DateTime date = args['date'] ?? DateTime.now().subtract(const Duration(hours: 2));
    final double? latitude = args['latitude'];
    final double? longitude = args['longitude'];
    
    // الأجهزة المحولة
    final List<ReceivedDevice> devices = (args['devices'] as List<dynamic>?)?.cast<ReceivedDevice>() ?? [
      ReceivedDevice(
        id: 'mock-1',
        serialNumber: 'SN-950-8821',
        terminalId: 'T8821',
        battery: true,
        chargerCable: true,
        chargerHead: true,
        hasSim: true,
        simCardType: 'STC',
        status: 'approved',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      ReceivedDevice(
        id: 'mock-2',
        serialNumber: 'SN-950-7612',
        terminalId: 'T7612',
        battery: true,
        chargerCable: true,
        chargerHead: false,
        hasSim: false,
        status: 'approved',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    final formattedDate = intl.DateFormat('yyyy/MM/dd - hh:mm a').format(date);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text(
          'تفاصيل عملية التسليم',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // بطاقة حالة الطلب الرئيسية
            _buildStatusHeaderCard(status, formattedDate),
            
            // تفاصيل الجهة المستلمة
            _buildRecipientDetailsCard(recipientType, recipientName, recipientCity),
            
            // الخريطة الجغرافية للعملية
            _buildMapThumbnail(latitude, longitude),
            
            // قائمة الأجهزة المحولة
            _buildTransferredDevicesSection(devices),
            
            // الخط الزمني لعملية النقل
            _buildHandoverTimeline(status, formattedDate),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionsBar(context, recipientName, formattedDate, devices),
    );
  }

  Widget _buildStatusHeaderCard(String status, String dateStr) {
    Color statusColor;
    String statusTitle;
    String statusDesc;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'approved':
      case 'accepted':
        statusColor = AppColors.success;
        statusTitle = 'تم قبول التسليم ونقل العهدة';
        statusDesc = 'قام المستلم بتأكيد فحص واستلام الأجهزة وانتقلت العهدة رسمياً';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusTitle = 'تم رفض طلب التسليم';
        statusDesc = 'رفض المستلم استلام العهدة بسبب عدم مطابقة الأجهزة المادية للبيانات';
        statusIcon = Icons.cancel;
        break;
      case 'pending':
      default:
        statusColor = AppColors.warning;
        statusTitle = 'قيد انتظار قبول المستلم';
        statusDesc = 'تم إرسال الأجهزة بنجاح، وبانتظار قيام الطرف الآخر بتأكيد الاستلام من تطبيقه';
        statusIcon = Icons.pending;
        break;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 54),
          const SizedBox(height: 12),
          Text(
            statusTitle,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تاريخ وتوقيت العملية',
                style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                dateStr,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientDetailsCard(String type, String name, String city) {
    final isTech = type == 'technician';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الجهة المستلمة للعهدة',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isTech ? Colors.indigo.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                child: Icon(
                  isTech ? Icons.person : Icons.warehouse,
                  color: isTech ? Colors.indigo[300] : Colors.orange[300],
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isTech ? Colors.indigo.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isTech ? 'فني صيانة ميداني' : 'مستودع فرعي',
                            style: GoogleFonts.cairo(
                              color: isTech ? Colors.indigo[200] : Colors.orange[200],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on, color: AppColors.textSecondary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          city,
                          style: GoogleFonts.cairo(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferredDevicesSection(List<ReceivedDevice> devices) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الأجهزة المشمولة بالنقل (${devices.length})',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: devices.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 16),
            itemBuilder: (context, index) {
              final dev = devices[index];
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.devices, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جهاز نقطة بيع POS',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'رقم تسلسلي: ',
                              style: GoogleFonts.cairo(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            Text(
                              dev.serialNumber,
                              style: GoogleFonts.cairo(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // كاونتر الملحقات
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${dev.accessoriesCount} ملحقات',
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverTimeline(String status, String createDate) {
    final isApproved = status.toLowerCase() == 'approved' || status.toLowerCase() == 'accepted';
    final isRejected = status.toLowerCase() == 'rejected';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مراحل خط سير العملية',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // خط زمني تفصيلي
          _buildTimelineItem(
            title: 'تم إرسال طلب نقل العهدة',
            subtitle: 'قام الفني الحالي بإنشاء العملية وتحديد الأجهزة بنجاح',
            date: createDate,
            isCompleted: true,
            isLast: false,
            activeColor: AppColors.primary,
          ),
          
          _buildTimelineItem(
            title: 'مراجعة الطرف المستلم والفحص المادي',
            subtitle: isApproved 
                ? 'تم الفحص المادي للأجهزة وتطابقت كافة الأرقام التسلسلية'
                : isRejected
                    ? 'فشل الفحص المادي وتأكيد الأجهزة من المستلم'
                    : 'بانتظار قيام المستلم بفتح التطبيق وفحص الأجهزة المستلمة يدوياً',
            date: isApproved || isRejected ? createDate : 'جاري العمل...',
            isCompleted: isApproved || isRejected,
            isLast: false,
            activeColor: isApproved ? AppColors.success : (isRejected ? AppColors.error : AppColors.warning),
          ),

          _buildTimelineItem(
            title: isApproved 
                ? 'اكتمل نقل العهدة بنجاح' 
                : isRejected 
                    ? 'تم إلغاء العملية وإرجاع العهدة' 
                    : 'اعتماد نقل العهدة النهائي في النظام',
            subtitle: isApproved 
                ? 'تم تسجيل الأجهزة بعهدة الفني الجديد وإلغاؤها من عهدتك' 
                : isRejected
                    ? 'عادت الأجهزة لعهدتك السابقة لعدم القبول المادي'
                    : 'تتم تلقائياً فور تأكيد المستلم لطلب الاستلام',
            date: isApproved || isRejected ? createDate : '',
            isCompleted: isApproved || isRejected,
            isLast: true,
            activeColor: isApproved ? AppColors.success : (isRejected ? AppColors.error : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String date,
    required bool isCompleted,
    required bool isLast,
    required Color activeColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عمود المؤشر والخط العمودي
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? activeColor : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isCompleted ? activeColor.withOpacity(0.5) : Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // نصوص الخط الزمني
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: isCompleted ? Colors.white70 : AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionsBar(
    BuildContext context,
    String recipientName,
    String dateStr,
    List<ReceivedDevice> devices,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // زر مشاركة سريع
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // محاكاة مشاركة نص الإيصال
                  final buffer = StringBuffer();
                  buffer.writeln('📋 *محضر نقل عهدة أجهزة رسمي*');
                  buffer.writeln('----------------------------------');
                  buffer.writeln('👤 *المستلم:* $recipientName');
                  buffer.writeln('📅 *التاريخ:* $dateStr');
                  buffer.writeln('🔢 *عدد الأجهزة:* ${devices.length} أجهزة');
                  buffer.writeln('----------------------------------');
                  for (var d in devices) {
                    buffer.writeln('📱 جهاز POS: ${d.serialNumber} (TID: ${d.terminalId ?? 'N/A'})');
                  }
                  
                  Get.dialog(
                    AlertDialog(
                      backgroundColor: AppColors.surfaceDark,
                      title: Text(
                        'مشاركة المحضر الفني',
                        style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تم إنشاء نص المشاركة الفوري، يمكنك نسخه ومشاركته عبر الواتساب أو التطبيقات الفنية المعتمدة:',
                            style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  buffer.toString(),
                                  style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'مشاركة النص',
                      style: GoogleFonts.cairo(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // زر تحميل المحضر PDF
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _showPdfReceiptDialog(context, recipientName, dateStr, devices);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'تحميل محضر PDF',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPdfReceiptDialog(
    BuildContext context,
    String recipientName,
    String dateStr,
    List<ReceivedDevice> devices,
  ) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الهيدر الفني
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.account_balance, color: Colors.indigo, size: 36),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'شركة ناقل والعهدة الوطنية',
                        style: GoogleFonts.cairo(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'مستند تسليم عهدة رقم #${DateTime.now().millisecond}',
                        style: GoogleFonts.cairo(color: Colors.grey[600], fontSize: 9),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.black12, thickness: 1.5),
              const SizedBox(height: 12),

              Text(
                'محضر تسليم ونقل عهدة أجهزة',
                style: GoogleFonts.cairo(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // جدول البيانات الأساسية
              Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildReceiptRow('الفني المسلّم:', 'عهدتك الفنية الحالية (أنت)', isDark: true),
                    const SizedBox(height: 6),
                    _buildReceiptRow('الجهة المستلمة:', recipientName, isDark: true),
                    const SizedBox(height: 6),
                    _buildReceiptRow('تاريخ النقل:', dateStr, isDark: true),
                    const SizedBox(height: 6),
                    _buildReceiptRow('نوع المستند:', 'محضر رسمي معتمد', isDark: true),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الأجهزة المسلمة في هذا المحضر:',
                  style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),

              // قائمة الأجهزة في الإيصال
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  itemBuilder: (context, i) {
                    final d = devices[i];
                    return Container(
                      color: i % 2 == 0 ? Colors.grey[50] : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            d.serialNumber,
                            style: GoogleFonts.cairo(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            d.terminalId != null ? 'TID: ${d.terminalId}' : 'جهاز POS',
                            style: GoogleFonts.cairo(color: Colors.black54, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              
              // التوقيعات الحقيقية
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text('توقيع الفني المسلّم', style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 9)),
                      const SizedBox(height: 10),
                      Text('موقّع رقمياً ✔', style: GoogleFonts.cairo(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                    ],
                  ),
                  Column(
                    children: [
                      Text('توقيع الطرف المستلم', style: GoogleFonts.cairo(color: Colors.grey[700], fontSize: 9)),
                      const SizedBox(height: 10),
                      _signatureBytes != null
                          ? Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Image.memory(
                                _signatureBytes!,
                                height: 40,
                                width: 80,
                                fit: BoxFit.contain,
                              ),
                            )
                          : TextButton(
                              onPressed: () {
                                Get.back(); // close PDF preview
                                _showSignatureDialog(context, recipientName, dateStr, devices);
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'إضافة توقيع إلكتروني',
                                style: GoogleFonts.cairo(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Get.back(),
                      child: Text('إغلاق المعاينة', style: GoogleFonts.cairo(color: Colors.black87)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Get.back();
                        _generateAndPrintPdf(recipientName, dateStr, devices);
                      },
                      child: Text('تحميل وطباعة PDF', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapThumbnail(double? lat, double? lng) {
    if (lat == null || lng == null) return const SizedBox.shrink();

    final mapUrl = GpsHelper.getStaticMapUrl(lat, lng);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.map, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'الموقع الجغرافي للعملية (GPS)',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                children: [
                  Image.network(
                    mapUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black26,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off, color: Colors.orangeAccent, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'تعذر تحميل الخريطة (غير متصل بالشبكة)',
                                style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignatureDialog(
    BuildContext context,
    String recipientName,
    String dateStr,
    List<ReceivedDevice> devices,
  ) {
    final GlobalKey<SfSignaturePadState> signaturePadKey = GlobalKey();

    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'توقيع الطرف المستلم الإلكتروني',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SfSignaturePad(
                    key: signaturePadKey,
                    backgroundColor: Colors.white,
                    strokeColor: Colors.black,
                    minimumStrokeWidth: 2.0,
                    maximumStrokeWidth: 4.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        signaturePadKey.currentState?.clear();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('مسح المعاينة', style: GoogleFonts.cairo(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final image = await signaturePadKey.currentState?.toImage(pixelRatio: 3.0);
                          final bytes = await image?.toByteData(format: ImageByteFormat.png);
                          if (bytes != null) {
                            setState(() {
                              _signatureBytes = bytes.buffer.asUint8List();
                            });
                          }
                          Get.back();
                          _showPdfReceiptDialog(context, recipientName, dateStr, devices);
                        } catch (e) {
                          Get.snackbar('خطأ', 'فشل التقاط التوقيع الإلكتروني');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('اعتماد التوقيع', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateAndPrintPdf(
    String recipientName,
    String dateStr,
    List<ReceivedDevice> devices,
  ) async {
    try {
      final doc = pw.Document();
      
      // Load Arabic Font from network (Google Fonts)
      final arabicFont = await PdfGoogleFonts.cairoRegular();
      final arabicFontBold = await PdfGoogleFonts.cairoBold();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: arabicFont,
            bold: arabicFontBold,
          ),
          build: (pw.Context context) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'شركة ناقل والعهدة الوطنية',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'مستند تسليم عهدة رسمي',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 2),
                  pw.SizedBox(height: 20),

                  pw.Center(
                    child: pw.Text(
                      'محضر تسليم ونقل عهدة أجهزة',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('الفني المسلّم: عهدتك الفنية الحالية'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('الجهة المستلمة: $recipientName'),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('تاريخ النقل: $dateStr'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('نوع المستند: محضر رسمي معتمد'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),

                  pw.Text(
                    'الأجهزة المسلمة في هذا المحضر:',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),

                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('الرقم التسلسلي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('رقم الجهاز (TID)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...devices.map((d) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(d.serialNumber),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(d.terminalId ?? 'N/A'),
                              ),
                            ],
                          )),
                    ],
                  ),
                  pw.SizedBox(height: 40),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text('توقيع الفني المسلّم'),
                          pw.SizedBox(height: 10),
                          pw.Text('موقّع رقمياً ✔', style: const pw.TextStyle(color: PdfColors.green)),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text('توقيع الطرف المستلم'),
                          pw.SizedBox(height: 10),
                          if (_signatureBytes != null)
                            pw.Image(
                              pw.MemoryImage(_signatureBytes!),
                              width: 100,
                              height: 50,
                            )
                          else
                            pw.Text('بانتظار التوقيع المادي', style: const pw.TextStyle(color: PdfColors.orange)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'محضر_تسليم_عهدة_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إنشاء أو طباعة ملف الـ PDF: $e');
    }
  }

  Widget _buildReceiptRow(String label, String value, {bool isDark = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            color: isDark ? Colors.black54 : Colors.grey[700],
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.cairo(
            color: isDark ? Colors.black87 : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

