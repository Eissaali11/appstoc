import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/dashboard_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/utils/icon_mapper.dart';

class RequestInventoryPage extends StatefulWidget {
  const RequestInventoryPage({super.key});

  @override
  State<RequestInventoryPage> createState() => _RequestInventoryPageState();
}

class _RequestInventoryPageState extends State<RequestInventoryPage> {
  final DashboardController controller = Get.find<DashboardController>();
  ItemType? _selectedItemType;
  String _packagingType = 'boxes'; // 'boxes' or 'units'
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (_selectedItemType == null) {
      Get.snackbar(
        'خطأ',
        'يرجى اختيار نوع الصنف',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال كمية صحيحة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    // TODO: Implement API call to request inventory
    Get.snackbar(
      'نجح',
      'تم إرسال طلب المخزون بنجاح',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );

    // Clear form
    setState(() {
      _selectedItemType = null;
      _packagingType = 'boxes';
      _quantityController.clear();
      _notesController.clear();
    });
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
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
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
                    Icon(
                      Icons.request_quote,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'طلب مخزون من المستودع',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Item Type Selection
              Text(
                'نوع الصنف',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: DropdownButtonFormField<ItemType>(
                  value: _selectedItemType,
                  decoration: InputDecoration(
                    labelText: 'اختر نوع الصنف',
                    labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  items: controller.itemTypes.map((itemType) {
                    return DropdownMenuItem(
                      value: itemType,
                      child: Row(
                        children: [
                          Icon(
                            IconMapper.getIcon(itemType.iconName),
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            itemType.nameAr,
                            style: GoogleFonts.cairo(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItemType = value;
                    });
                  },
                  dropdownColor: AppColors.surfaceDark,
                  style: GoogleFonts.cairo(color: Colors.white),
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

              // Packaging Type
              Text(
                'نوع التعبئة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PackagingTypeCard(
                      title: 'كراتين',
                      icon: Icons.inventory_2,
                      isSelected: _packagingType == 'boxes',
                      onTap: () => setState(() => _packagingType = 'boxes'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PackagingTypeCard(
                      title: 'وحدات',
                      icon: Icons.circle,
                      isSelected: _packagingType == 'units',
                      onTap: () => setState(() => _packagingType = 'units'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quantity
              Text(
                'الكمية',
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
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.cairo(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'أدخل الكمية',
                    labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.numbers, color: AppColors.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
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
                    labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.note, color: AppColors.primary),
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
                  onPressed: _submitRequest,
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
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      }),
    );
  }
}

class _PackagingTypeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackagingTypeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
