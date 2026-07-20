export 'exercise_type.dart';

class Exercise {
  final String id;
  final String name;
  final List<String> categories;
  final String? notes;
  final String? videoUrl;
  final bool isCustom;

  Exercise({
    required this.id,
    required this.name,
    List<String>? categories,
    String? category,
    this.notes,
    this.videoUrl,
    this.isCustom = false,
  }) : categories = categories ?? (category != null && category.isNotEmpty ? [category] : const ['Pectoraux']);

  /// Getter de compatibilité renvoyant la catégorie principale
  String get category => categories.isNotEmpty ? categories.first : 'Autre';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categories': categories,
      'category': category,
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
      notes: json['notes'] as String?,
      videoUrl: json['videoUrl'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

