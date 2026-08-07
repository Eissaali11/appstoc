import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Professional success dialog for custody operations.
Future<void> showCustodySuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
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
              color: AppColors.success.withOpacity(0.25),
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
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 56,
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
              height: 48,
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
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'رائع، تم',
                    style: TextStyle(
                      fontFamily: 'BeIN',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.backgroundDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.25),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.error, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.35),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: AppColors.error,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تأكيد الإزالة من العهدة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BeIN',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت تأكد من رغبتك في إزالة هذا العنصر من عهدتك النشطة؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BeIN',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
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
                    ],
                  ),
                ),
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
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'BeIN', fontSize: 13, color: AppColors.error),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'BeIN',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isSubmitting
                                ? null
                                : const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                  ),
                            color: _isSubmitting ? AppColors.error.withOpacity(0.5) : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.error.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _handleConfirm,
                            icon: _isSubmitting
                                ? const SizedBox.shrink()
                                : const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                            label: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'نعم، حذف من عهدتي',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'BeIN',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
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
