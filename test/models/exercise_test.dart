import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise.dart';

void main() {
  group('Exercise Model Tests', () {
    test('Should create Exercise with equipment and notes correctly', () {
      final exercise = Exercise(
        id: 'ex_1',
        name: 'Développé Couché',
        categories: ['Pectoraux', 'Triceps'],
        equipment: 'Banc & Barre',
        notes: 'Barre droite',
        videoUrl: 'https://youtube.com/watch?v=123',
        isCustom: false,
      );

      expect(exercise.id, equals('ex_1'));
      expect(exercise.name, equals('Développé Couché'));
      expect(exercise.categories, equals(['Pectoraux', 'Triceps']));
      expect(exercise.category, equals('Pectoraux'));
      expect(exercise.equipment, equals('Banc & Barre'));
      expect(exercise.notes, equals('Barre droite'));
      expect(exercise.videoUrl, equals('https://youtube.com/watch?v=123'));
      expect(exercise.isCustom, isFalse);
    });

    test('Should fallback to single category parameter when categories is null', () {
      final exercise = Exercise(
        id: 'ex_2',
        name: 'Squat',
        category: 'Jambes',
        equipment: 'Cage à squat',
      );

      expect(exercise.categories, equals(['Jambes']));
      expect(exercise.category, equals('Jambes'));
      expect(exercise.equipment, equals('Cage à squat'));
    });

    test('Should fallback to default Autre when neither category nor categories provided', () {
      final exercise = Exercise(
        id: 'ex_3',
        name: 'Exercice Mystère',
      );

      expect(exercise.categories, equals(['Autre']));
      expect(exercise.category, equals('Autre'));
      expect(exercise.equipment, isNull);
    });

    test('Should convert Exercise with equipment to JSON and back (Roundtrip)', () {
      final original = Exercise(
        id: 'ex_4',
        name: 'Traction',
        categories: ['Dos', 'Biceps'],
        equipment: 'Barre de traction',
        notes: 'Prise pronation',
        videoUrl: 'https://youtube.com/watch?v=456',
        isCustom: true,
      );

      final json = original.toJson();
      expect(json['id'], equals('ex_4'));
      expect(json['name'], equals('Traction'));
      expect(json['categories'], equals(['Dos', 'Biceps']));
      expect(json['category'], equals('Dos'));
      expect(json['equipment'], equals('Barre de traction'));
      expect(json['isCustom'], isTrue);

      final restored = Exercise.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.categories, equals(original.categories));
      expect(restored.category, equals(original.category));
      expect(restored.equipment, equals(original.equipment));
      expect(restored.notes, equals(original.notes));
      expect(restored.videoUrl, equals(original.videoUrl));
      expect(restored.isCustom, equals(original.isCustom));
    });

    test('Should support copyWith for Exercise model', () {
      final original = Exercise(
        id: 'ex_copy',
        name: 'Rowing barre',
        categories: ['Dos'],
        equipment: 'Barre olympique',
      );

      final updated = original.copyWith(
        name: 'Rowing T-Bar',
        equipment: 'Machine T-Bar',
        notes: 'Prise neutre',
      );

      expect(updated.id, equals('ex_copy'));
      expect(updated.name, equals('Rowing T-Bar'));
      expect(updated.categories, equals(['Dos']));
      expect(updated.equipment, equals('Machine T-Bar'));
      expect(updated.notes, equals('Prise neutre'));
    });

    test('Should handle legacy machine and materiel json aliases in fromJson', () {
      final json1 = {
        'id': 'ex_m1',
        'name': 'Pec Deck',
        'machine': 'Machine Butterfly',
      };
      final ex1 = Exercise.fromJson(json1);
      expect(ex1.equipment, equals('Machine Butterfly'));

      final json2 = {
        'id': 'ex_m2',
        'name': 'Pompes',
        'materiel': 'Poignées de pompes',
      };
      final ex2 = Exercise.fromJson(json2);
      expect(ex2.equipment, equals('Poignées de pompes'));
    });

    test('Should handle fallback category in fromJson when categories list is empty', () {
      final json = {
        'id': 'ex_5',
        'name': 'Fentes',
        'categories': [],
      };

      final exercise = Exercise.fromJson(json);
      expect(exercise.categories, equals(['Autre']));
      expect(exercise.category, equals('Autre'));
    });

    test('Should handle legacy category string field in fromJson', () {
      final json = {
        'id': 'ex_6',
        'name': 'Curl Biceps',
        'category': 'Biceps',
      };

      final exercise = Exercise.fromJson(json);
      expect(exercise.categories, equals(['Biceps']));
      expect(exercise.category, equals('Biceps'));
    });
  });
}
