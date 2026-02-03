import '../../../../shared/models/inventory_request.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';

abstract class InventoryRequestRepository {
  /// Create inventory request using dynamic entries (preferred method)
  Future<InventoryRequest> createInventoryRequestWithEntries({
    required List<InventoryEntry> entries,
    String? notes,
  });

  /// Create inventory request using legacy fields (for backward compatibility)
  Future<InventoryRequest> createInventoryRequest({
    int n950Boxes = 0,
    int n950Units = 0,
    int i9000sBoxes = 0,
    int i9000sUnits = 0,
    int i9100Boxes = 0,
    int i9100Units = 0,
    int rollPaperBoxes = 0,
    int rollPaperUnits = 0,
    int stickersBoxes = 0,
    int stickersUnits = 0,
    int newBatteriesBoxes = 0,
    int newBatteriesUnits = 0,
    int mobilySimBoxes = 0,
    int mobilySimUnits = 0,
    int stcSimBoxes = 0,
    int stcSimUnits = 0,
    int zainSimBoxes = 0,
    int zainSimUnits = 0,
    String? notes,
  });

  Future<List<InventoryRequest>> getMyInventoryRequests();
}
