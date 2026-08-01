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
/// Professional success dialog for custody operations.
Future<void> showCustodySuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  await showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.success.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'BeIN',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BeIN',
                fontSize: 14.5,
                color: Colors.white.withOpacity(0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF00E5FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'رائع، تم',
                    style: TextStyle(
                      fontFamily: 'BeIN',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Second, explicit confirmation step before permanently deleting a serial
/// number from the technician's own custody.
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
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
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
                        'تأكيد الإزالة من العهدة',
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
                  'هل أنت تأكد من رغبتك في إزالة هذا العنصر من عهدتك النشطة؟',
                  style: TextStyle(
                    fontFamily: 'BeIN',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 8),
                _detailRow('الرقم التسلسلي:', widget.serialNumber, isCode: true),
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
                      style: TextStyle(fontFamily: 'BeIN', fontSize: 13, color: AppColors.error),
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
                        child: const Text('إلغاء', style: TextStyle(color: Colors.white70, fontFamily: 'BeIN', fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'نعم، حذف من عهدتي',
                                style: TextStyle(color: Colors.white, fontFamily: 'BeIN', fontWeight: FontWeight.bold),
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

  Widget _detailRow(String label, String value, {bool isCode = false}) {
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
              style: TextStyle(
                fontFamily: isCode ? 'Cairo' : 'BeIN',
                fontSize: 12.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
