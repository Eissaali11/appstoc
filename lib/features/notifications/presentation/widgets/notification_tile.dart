import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../moving_inventory/data/models/warehouse_transfer.dart';

class NotificationTile extends StatelessWidget {
  final WarehouseTransfer transfer;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const NotificationTile({
    super.key,
    required this.transfer,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.pending_actions,
            color: AppColors.warning,
          ),
        ),
        title: Text(
          transfer.warehouseName ?? 'مستودع غير محدد',
          style: AppTextStyles.bodyLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${transfer.itemType} - ${transfer.quantity} ${transfer.packagingType == 'boxes' ? 'كراتين' : 'وحدات'}',
              style: AppTextStyles.bodySmall,
            ),
            Text(
              app_date_utils.DateUtils.formatRelativeTime(transfer.createdAt),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: AppColors.success),
              onPressed: onAccept,
              tooltip: 'قبول',
            ),
            IconButton(
              icon: Icon(Icons.close, color: AppColors.error),
              onPressed: onReject,
              tooltip: 'رفض',
            ),
          ],
        ),
      ),
    );
  }
}
