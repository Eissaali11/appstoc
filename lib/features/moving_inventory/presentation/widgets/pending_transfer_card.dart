import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../data/models/warehouse_transfer.dart';

class PendingTransferCard extends StatelessWidget {
  final WarehouseTransfer transfer;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const PendingTransferCard({
    super.key,
    required this.transfer,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.warning.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transfer.warehouseName ?? 'مستودع غير محدد',
                    style: AppTextStyles.heading3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'نوع العنصر: ${transfer.itemType}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'الكمية: ${transfer.quantity} ${transfer.packagingType == 'boxes' ? 'كراتين' : 'وحدات'}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              app_date_utils.DateUtils.formatRelativeTime(transfer.createdAt),
              style: AppTextStyles.bodySmall,
            ),
            if (transfer.notes != null) ...[
              const SizedBox(height: 8),
              Text(
                'ملاحظات: ${transfer.notes}',
                style: AppTextStyles.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('رفض'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('قبول'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
