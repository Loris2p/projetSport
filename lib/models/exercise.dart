export 'exercise_type.dart';

class Exercise {
  final String id;
  final String name;
  final List<String> categories;
  final String? equipment;
  final String? notes;
  final String? videoUrl;
  final bool isCustom;

  Exercise({
    required this.id,
    required this.name,
    List<String>? categories,
    String? category,
    this.equipment,
    this.notes,
    this.videoUrl,
    this.isCustom = false,
  }) : categories = (categories != null && categories.isNotEmpty)
            ? categories
            : (category != null && category.isNotEmpty ? [category] : const ['Autre']);

  /// Getter de compatibilité renvoyant la catégorie principale
  String get category => categories.isNotEmpty ? categories.first : 'Autre';

  Exercise copyWith({
    String? id,
    String? name,
    List<String>? categories,
    String? equipment,
    String? notes,
    String? videoUrl,
    bool? isCustom,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      categories: categories ?? this.categories,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categories': categories,
      'category': category,
      'equipment': equipment,
      'notes': notes,
      'videoUrl': videoUrl,
      'isCustom': isCustom,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    List<String> parsedCategories = [];
    if (json['categories'] != null && json['categories'] is List) {
      parsedCategories = (json['categories'] as List<dynamic>).map((e) => e.toString()).toList();
    } else if (json['category'] != null && json['category'] is String) {
      parsedCategories = [(json['category'] as String)];
    }

    if (parsedCategories.isEmpty) {
      parsedCategories = ['Autre'];
    }

    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      categories: parsedCategories,
      equipment: json['equipment'] as String? ?? json['machine'] as String? ?? json['materiel'] as String?,
      notes: json['notes'] as String?,
      videoUrl: json['videoUrl'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

