import 'package:flutter/material.dart';

/// Définition des données visuelles (icône, couleurs) pour chaque catégorie musculaire
class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  const CategoryInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class CategoryHelper {
  static const Map<String, CategoryInfo> categoriesMap = {
    'Pectoraux': CategoryInfo(
      name: 'Pectoraux',
      icon: Icons.fitness_center,
      color: Color(0xffef4444), // Crimson
    ),
    'Dos': CategoryInfo(
      name: 'Dos',
      icon: Icons.straighten,
      color: Color(0xff3b82f6), // Blue
    ),
    'Jambes': CategoryInfo(
      name: 'Jambes',
      icon: Icons.directions_walk,
      color: Color(0xff10b981), // Emerald Green
    ),
    'Épaules': CategoryInfo(
      name: 'Épaules',
      icon: Icons.accessibility_new,
      color: Color(0xff8b5cf6), // Purple
    ),
    'Biceps': CategoryInfo(
      name: 'Biceps',
      icon: Icons.fitness_center,
      color: Color(0xfff59e0b), // Amber
    ),
    'Triceps': CategoryInfo(
      name: 'Triceps',
      icon: Icons.fitness_center,
      color: Color(0xfff97316), // Orange
    ),
    'Bras': CategoryInfo(
      name: 'Bras',
      icon: Icons.fitness_center,
      color: Color(0xfff59e0b), // Amber
    ),
    'Abdominaux': CategoryInfo(
      name: 'Abdominaux',
      icon: Icons.shield_outlined,
      color: Color(0xff14b8a6), // Teal
    ),
    'Fessiers': CategoryInfo(
      name: 'Fessiers',
      icon: Icons.airline_seat_recline_extra,
      color: Color(0xffec4899), // Pink
    ),
    'Cardio': CategoryInfo(
      name: 'Cardio',
      icon: Icons.favorite,
      color: Color(0xfff43f5e), // Coral Rose
    ),
    'Autre': CategoryInfo(
      name: 'Autre',
      icon: Icons.more_horiz,
      color: Color(0xff64748b), // Slate Grey
    ),
  };

  static const List<String> allCategoryNames = [
    'Pectoraux',
    'Dos',
    'Jambes',
    'Épaules',
    'Biceps',
    'Triceps',
    'Abdominaux',
    'Fessiers',
    'Cardio',
    'Autre',
  ];

  static CategoryInfo getInfo(String categoryName) {
    return categoriesMap[categoryName] ??
        CategoryInfo(
          name: categoryName,
          icon: Icons.label_outlined,
          color: const Color(0xff64748b),
        );
  }
}

/// Widget affichant un badge coloré dynamique pour une catégorie
class CategoryBadge extends StatelessWidget {
  final String category;
  final double fontSize;
  final double iconSize;
  final bool compact;

  const CategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 11.0,
    this.iconSize = 13.0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final info = CategoryHelper.getInfo(category);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6.0 : 8.0,
        vertical: compact ? 2.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: info.color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            info.icon,
            size: iconSize,
            color: info.color,
          ),
          SizedBox(width: compact ? 3.0 : 5.0),
          Text(
            info.name,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: info.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget réutilisable affichant une rangée de badges pour une liste multi-catégories
class MultiCategoryBadges extends StatelessWidget {
  final List<String> categories;
  final double fontSize;
  final double iconSize;
  final bool compact;

  const MultiCategoryBadges({
    super.key,
    required this.categories,
    this.fontSize = 11.0,
    this.iconSize = 13.0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return CategoryBadge(
        category: 'Autre',
        fontSize: fontSize,
        iconSize: iconSize,
        compact: compact,
      );
    }

    return Wrap(
      spacing: 6.0,
      runSpacing: 4.0,
      children: categories
          .map((cat) => CategoryBadge(
                category: cat,
                fontSize: fontSize,
                iconSize: iconSize,
                compact: compact,
              ))
          .toList(),
    );
  }
}

/// Widget de sélection par puces (FilterChip) pour choisir une ou plusieurs catégories
class CategoryMultiSelect extends StatelessWidget {
  final List<String> selectedCategories;
  final ValueChanged<List<String>> onChanged;

  const CategoryMultiSelect({
    super.key,
    required this.selectedCategories,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: CategoryHelper.allCategoryNames.map((cat) {
        final info = CategoryHelper.getInfo(cat);
        final isSelected = selectedCategories.contains(cat);

        return FilterChip(
          selected: isSelected,
          showCheckmark: true,
          checkmarkColor: Colors.white,
          avatar: Icon(
            info.icon,
            size: 16,
            color: isSelected ? Colors.white : info.color,
          ),
          label: Text(
            cat,
            style: TextStyle(
              color: isSelected ? Colors.white : info.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
          selectedColor: info.color,
          backgroundColor: info.color.withValues(alpha: 0.12),
          side: BorderSide(
            color: isSelected ? info.color : info.color.withValues(alpha: 0.3),
            width: 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (selected) {
            final updated = List<String>.from(selectedCategories);
            if (selected) {
              if (!updated.contains(cat)) updated.add(cat);
            } else {
              // Garder au moins 1 catégorie si possible
              if (updated.length > 1) {
                updated.remove(cat);
              }
            }
            onChanged(updated);
          },
        );
      }).toList(),
    );
  }
}
