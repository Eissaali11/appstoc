import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../data/models/inventory_entry.dart';
import '../../../../shared/models/item_type.dart';

class InventoryListTile extends StatelessWidget {
  final InventoryEntry entry;
  final ItemType? itemType;
  final VoidCallback? onTransfer;

  const InventoryListTile({
    super.key,
    required this.entry,
    this.itemType,
    this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: itemType?.colorHex != null
                ? Color(int.parse(itemType!.colorHex!.replaceFirst('#', '0xFF')))
                : AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.inventory_2,
            color: Colors.white,
          ),
        ),
        title: Text(
          itemType?.nameAr ?? 'عنصر',
          style: AppTextStyles.bodyLarge,
        ),
        subtitle: Row(
          children: [
            _InventoryBadge(label: 'كراتين', value: entry.boxes),
            const SizedBox(width: 12),
            _InventoryBadge(label: 'وحدات', value: entry.units),
          ],
        ),
        trailing: onTransfer != null
            ? IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: onTransfer,
                tooltip: 'نقل إلى المخزون المتحرك',
              )
            : null,
      ),
    );
  }
}

class _InventoryBadge extends StatelessWidget {
  final String label;
  final int value;

  const _InventoryBadge({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
