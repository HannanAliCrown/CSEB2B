import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';

/// One destination in [DsBottomNav].
class DsNavItem {
  const DsNavItem({
    required this.id,
    required this.label,
    required this.icon,
    this.badge,
  });

  final String id;
  final String label;
  final IconData icon;
  final int? badge;
}

/// The design system's `BottomNav`: 64px tall, hairline top border, accent
/// icon/label when active, 10px labels and a red count badge.
class DsBottomNav extends StatelessWidget {
  const DsBottomNav({
    super.key,
    required this.items,
    required this.activeId,
    this.onChanged,
  });

  final List<DsNavItem> items;
  final String activeId;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: items.map((item) {
              final active = item.id == activeId;
              final color = active
                  ? context.colors.primary
                  : context.palette.textTertiary;
              return Expanded(
                child: InkWell(
                  onTap: onChanged == null ? null : () => onChanged!(item.id),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(item.icon, size: 22, color: color),
                          if (item.badge != null && item.badge! > 0)
                            Positioned(
                              top: -3,
                              right: -8,
                              child: Container(
                                constraints: const BoxConstraints(minWidth: 16),
                                height: 16,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: context.colors.error,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                ),
                                child: Text(
                                  '${item.badge}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// The design system's `SegmentedControl`: a sunken track with a raised
/// surface pill on the selected option.
class DsSegmentedControl extends StatelessWidget {
  const DsSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
    this.small = false,
  });

  final List<String> options;
  final String value;
  final ValueChanged<String>? onChanged;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.palette.sunken,
        borderRadius: AppRadii.mdRadius,
      ),
      child: Row(
        children: options.map((option) {
          final active = option == value;
          return Expanded(
            child: GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(option),
              child: Container(
                height: small ? 32 : 38,
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: active ? context.colors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.md - 3),
                  boxShadow: active ? AppShadows.card : null,
                ),
                child: Text(
                  option,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// The design system's `Tabs`: underlined, scrollable, accent indicator.
class DsTabs extends StatelessWidget {
  const DsTabs({
    super.key,
    required this.tabs,
    required this.value,
    this.onChanged,
    this.padding,
  });

  final List<String> tabs;
  final String value;
  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: padding,
        child: Row(
          children: tabs.map((tab) {
            final active = tab == value;
            return GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(tab),
              child: Container(
                margin: const EdgeInsets.only(right: 22),
                padding: const EdgeInsets.only(top: 10, bottom: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: active
                          ? context.colors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: active
                        ? context.colors.primary
                        : context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
