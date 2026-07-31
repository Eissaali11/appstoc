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
  final TextEditingController _confirmController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      final matches = _confirmController.text.trim() == widget.serialNumber;
      if (matches != _matches) {
        setState(() => _matches = matches);
      }
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_matches || _isSubmitting) return;

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
                    Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 26),
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
                  'سيتم حذف الرقم التسلسلي نهائيًا من قاعدة البيانات ومن تفاصيل مخزون الصنف. '
                  'لا يمكن التراجع عن هذه العملية بعد تأكيدها.',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.5,
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
                const SizedBox(height: 16),
                Text(
                  'اكتب الرقم التسلسلي كاملاً لتأكيد الحذف:',
                  style: TextStyle(
                    fontFamily: 'BeIN',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmController,
                  enabled: !_isSubmitting,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                  decoration: InputDecoration(
                    hintText: widget.serialNumber,
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 2),
                    ),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorText!,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.error),
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
                      child: ElevatedButton(
                        onPressed: (_matches && !_isSubmitting) ? _handleConfirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          disabledBackgroundColor: AppColors.error.withOpacity(0.3),
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
                                'تأكيد الحذف النهائي',
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
