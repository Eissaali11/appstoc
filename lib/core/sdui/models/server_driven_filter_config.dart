import 'dart:convert';

class FilterItemDefinition {
  final String id;
  final String label;
  final bool enabled;
  final int order;
  final String icon;
  final String colorHex;
  final List<String> statuses;

  const FilterItemDefinition({
    required this.id,
    required this.label,
    required this.enabled,
    required this.order,
    required this.icon,
    required this.colorHex,
    required this.statuses,
  });

  factory FilterItemDefinition.fromJson(Map<String, dynamic> json) {
    return FilterItemDefinition(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      icon: json['icon'] as String? ?? 'inventory_2_outlined',
      colorHex: json['colorHex'] as String? ?? '#18B2B0',
      statuses: (json['statuses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'colorHex': colorHex,
      'enabled': enabled,
      'icon': icon,
      'id': id,
      'label': label,
      'order': order,
      'statuses': statuses..sort(),
    };
  }
}

class ServerDrivenFilterConfig {
  final int schemaVersion;
  final int configVersion;
  final String issuedAt;
  final String expiresAt;
  final String keyId;
  final String minAppVersion;
  final String screenId;
  final String defaultFilterId;
  final List<FilterItemDefinition> filters;

  const ServerDrivenFilterConfig({
    required this.schemaVersion,
    required this.configVersion,
    required this.issuedAt,
    required this.expiresAt,
    required this.keyId,
    required this.minAppVersion,
    required this.screenId,
    required this.defaultFilterId,
    required this.filters,
  });

  factory ServerDrivenFilterConfig.fromJson(Map<String, dynamic> json) {
    final rawFilters = json['filters'] as List<dynamic>? ?? [];
    final parsedFilters = rawFilters
        .map((f) => FilterItemDefinition.fromJson(f as Map<String, dynamic>))
        .where((f) => f.id.isNotEmpty)
        .toList();

    // Sort by order ascending
    parsedFilters.sort((a, b) => a.order.compareTo(b.order));

    return ServerDrivenFilterConfig(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      configVersion: (json['configVersion'] as num?)?.toInt() ?? 1,
      issuedAt: json['issuedAt'] as String? ?? '',
      expiresAt: json['expiresAt'] as String? ?? '',
      keyId: json['keyId'] as String? ?? '',
      minAppVersion: json['minAppVersion'] as String? ?? '1.0.0',
      screenId: json['screenId'] as String? ?? 'custody_screen',
      defaultFilterId: json['defaultFilterId'] as String? ?? 'all',
      filters: parsedFilters,
    );
  }

  Map<String, dynamic> toJson() {
    final sortedFilters = filters.map((f) => f.toJson()).toList()
      ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    return {
      'configVersion': configVersion,
      'defaultFilterId': defaultFilterId,
      'expiresAt': expiresAt,
      'filters': sortedFilters,
      'issuedAt': issuedAt,
      'keyId': keyId,
      'minAppVersion': minAppVersion,
      'schemaVersion': schemaVersion,
      'screenId': screenId,
    };
  }

  /// Converts map to Canonical JSON string (sorted keys, compact whitespace)
  static String toCanonicalJson(Map<String, dynamic> map) {
    final sortedMap = _sortMap(map);
    return jsonEncode(sortedMap);
  }

  static dynamic _sortMap(dynamic input) {
    if (input is Map) {
      final sortedKeys = input.keys.map((e) => e.toString()).toList()..sort();
      final Map<String, dynamic> sorted = {};
      for (final key in sortedKeys) {
        sorted[key] = _sortMap(input[key]);
      }
      return sorted;
    } else if (input is List) {
      return input.map(_sortMap).toList();
    }
    return input;
  }

  bool isExpired([DateTime? now]) {
    if (expiresAt.isEmpty) return false;
    final exp = DateTime.tryParse(expiresAt);
    if (exp == null) return false;
    final current = now ?? DateTime.now().toUtc();
    return current.isAfter(exp);
  }

  /// Performs runtime schema & boundary validation against limits:
  /// - Max payload size: 50 KB (51200 bytes)
  /// - Max filters count: 20
  /// - Max label length: 50 chars
  /// - Max ID length: 36 chars
  /// - Required fields validation
  static bool validateRuntimeSchema(Map<String, dynamic> json) {
    try {
      final jsonString = jsonEncode(json);
      if (jsonString.length > 51200) return false; // 50 KB limit

      if (json['schemaVersion'] is! num) return false;
      if (json['configVersion'] is! num) return false;
      if (json['issuedAt'] is! String) return false;
      if (json['expiresAt'] is! String) return false;
      if (json['keyId'] is! String) return false;
      if (json['minAppVersion'] is! String) return false;
      if (json['screenId'] is! String) return false;
      if (json['filters'] is! List) return false;

      final filters = json['filters'] as List;
      if (filters.length > 20) return false; // Max 20 filters limit

      for (final f in filters) {
        if (f is! Map<String, dynamic>) return false;
        final id = f['id']?.toString() ?? '';
        final label = f['label']?.toString() ?? '';
        if (id.isEmpty || id.length > 36) return false;
        if (label.isEmpty || label.length > 50) return false;
        if (f['enabled'] is! bool) return false;
        if (f['order'] is! num) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
