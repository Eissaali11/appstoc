import 'package:flutter/material.dart';
import '../models/server_driven_filter_config.dart';
import '../security/sdui_allowlist.dart';

class ServerDrivenFilterBar extends StatelessWidget {
  final ServerDrivenFilterConfig config;
  final String activeFilterId;
  final ValueChanged<String> onFilterSelected;

  const ServerDrivenFilterBar({
    super.key,
    required this.config,
    required this.activeFilterId,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out disabled filters and sort by order
    final enabledFilters = config.filters.where((f) => f.enabled).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (enabledFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: enabledFilters.map((filter) {
          final isSelected = filter.id == activeFilterId;
          final iconData = SduiAllowlist.resolveIcon(filter.icon);
          final color = SduiAllowlist.resolveColor(filter.colorHex);

          return Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: InkWell(
              onTap: () => onFilterSelected(filter.id),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Colors.white.withValues(alpha: 0.12),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      iconData,
                      size: 16,
                      color: isSelected ? color : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontFamily: 'BeIN',
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
