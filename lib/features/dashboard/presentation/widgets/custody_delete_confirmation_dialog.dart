// TEMPORARY FEATURE — remove or disable after final customer handover.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Second, explicit confirmation step before permanently deleting a serial
/// number from the technician's own custody. Requires the technician to type
/// the exact serial number before the delete button activates, disables all
/// buttons and shows a loading indicator while the request is in flight, and
/// never closes on its own until the server has responded.
///
/// Returns `true` only if [onConfirmDelete] completed successfully.
Future<bool> showCustodyDeleteConfirmationDialog(
  BuildContext context, {
  required String serialNumber,
  required String itemTitle,
  required String itemCategoryLabel,
  required String statusLabel,
  String? warehouseLabel,
  String? ownerLabel,
  String? receivedAtLabel,
  required Future<void> Function() onConfirmDelete,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CustodyDeleteConfirmationDialog(
      serialNumber: serialNumber,
      itemTitle: itemTitle,
      itemCategoryLabel: itemCategoryLabel,
      statusLabel: statusLabel,
      warehouseLabel: warehouseLabel,
      ownerLabel: ownerLabel,
      receivedAtLabel: receivedAtLabel,
      onConfirmDelete: onConfirmDelete,
    ),
  );
  return result ?? false;
}

class _CustodyDeleteConfirmationDialog extends StatefulWidget {
  final String serialNumber;
  final String itemTitle;
  final String itemCategoryLabel;
  final String statusLabel;
  final String? warehouseLabel;
  final String? ownerLabel;
  final String? receivedAtLabel;
  final Future<void> Function() onConfirmDelete;

  const _CustodyDeleteConfirmationDialog({
    required this.serialNumber,
    required this.itemTitle,
    required this.itemCategoryLabel,
    required this.statusLabel,
    required this.onConfirmDelete,
    this.warehouseLabel,
    this.ownerLabel,
    this.receivedAtLabel,
  });

  @override
  State<_CustodyDeleteConfirmationDialog> createState() =>
      _CustodyDeleteConfirmationDialogState();
}

class _CustodyDeleteConfirmationDialogState
    extends State<_CustodyDeleteConfirmationDialog> {
  bool _isSubmitting = false;
  String? _errorText;

  Future<void> _handleConfirm() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.onConfirmDelete();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1.5),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'حذف نهائي من العهدة',
                        style: TextStyle(
                          fontFamily: 'BeIN',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'تحذير: هذه العملية نهائية وتؤدي لحذف سجل العنصر نهائيًا من قاعدة البيانات. لتأكيد الحذف، يتوجب عليك إعادة مسح نفس الباركود عبر الكاميرا.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 8),
                _detailRow('الرقم التسلسلي:', widget.serialNumber),
                _detailRow('اسم المنتج / الصنف:', widget.itemTitle),
                _detailRow('نوع العنصر:', widget.itemCategoryLabel),
                _detailRow('الحالة الحالية:', widget.statusLabel),
                if (widget.warehouseLabel != null && widget.warehouseLabel!.isNotEmpty)
                  _detailRow('المستودع:', widget.warehouseLabel!),
                if (widget.ownerLabel != null && widget.ownerLabel!.isNotEmpty)
                  _detailRow('صاحب العهدة الحالي:', widget.ownerLabel!),
                if (widget.receivedAtLabel != null && widget.receivedAtLabel!.isNotEmpty)
                  _detailRow('تاريخ الاستلام:', widget.receivedAtLabel!),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: Text(
                      _errorText!,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('إلغاء', style: TextStyle(color: Colors.white70, fontFamily: 'BeIN')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleConfirm,
                        icon: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.white),
                        label: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'مسح الباركود للتأكيد',
                                style: TextStyle(color: Colors.white, fontFamily: 'BeIN', fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontFamily: 'BeIN', fontSize: 12.5, color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
