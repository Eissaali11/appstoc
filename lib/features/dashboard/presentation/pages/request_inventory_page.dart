import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/utils/icon_mapper.dart';
import '../../../inventory_requests/presentation/controllers/inventory_request_controller.dart';
import '../../../inventory_requests/data/repositories/inventory_request_repository_impl.dart';
import '../../../inventory_requests/domain/repositories/inventory_request_repository.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../../shared/models/item_type.dart';

class RequestInventoryPage extends StatefulWidget {
  const RequestInventoryPage({super.key});

  @override
  State<RequestInventoryPage> createState() => _RequestInventoryPageState();
}

class _RequestInventoryPageState extends State<RequestInventoryPage> {
  late InventoryRequestController controller;
  
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
    
    // Wait for item types to load, then initialize controllers
    _initializeControllers();
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
    super.dispose();
  }

  int _parseInt(TextEditingController controller) {
    return int.tryParse(controller.text) ?? 0;
  }

  Future<void> _submitRequest() async {
    // Build entries from controllers
    final entries = <InventoryEntry>[];
    
    for (var itemType in controller.itemTypes) {
      final boxesController = _boxesControllers[itemType.id];
      final unitsController = _unitsControllers[itemType.id];
      
      if (boxesController != null && unitsController != null) {
        final boxes = _parseInt(boxesController);
        final units = _parseInt(unitsController);
        
        if (boxes > 0 || units > 0) {
          entries.add(InventoryEntry(
            itemTypeId: itemType.id,
            boxes: boxes,
            units: units,
          ));
        }
      }
    }

    if (entries.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى إدخال كمية لصنف واحد على الأقل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    final success = await controller.createRequestWithEntries(
      entries: entries,
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
      style: GoogleFonts.cairo(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: AppColors.backgroundDark,
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
      ),
      body: Obx(() {
        if (controller.isLoading && controller.itemTypes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        // Initialize controllers when item types are loaded
        if (controller.itemTypes.isNotEmpty && 
            _boxesControllers.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              for (var itemType in controller.itemTypes) {
                _boxesControllers[itemType.id] = TextEditingController(text: '0');
                _unitsControllers[itemType.id] = TextEditingController(text: '0');
              }
            });
          });
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
                            '${controller.itemTypes.length} نوع متاح',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
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
                ...controller.itemTypes.map((itemType) => _buildItemRow(itemType)),

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
                    prefixIcon: const Icon(Icons.note, color: AppColors.primary),
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
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
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
