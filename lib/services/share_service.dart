import 'dart:convert';
import '../models/exercise.dart';
import '../models/workout_program.dart';

enum ShareDataType {
  program,
  singleExercise,
  exercisesBundle,
  unknown,
}

class SharedDataResult {
  final ShareDataType type;
  final WorkoutProgram? program;
  final List<Exercise> exercises;
  final String? errorMessage;

  SharedDataResult({
    required this.type,
    this.program,
    this.exercises = const [],
    this.errorMessage,
  });

  bool get isSuccess => errorMessage == null && type != ShareDataType.unknown;
}

class ShareService {
  static const int currentSchemaVersion = 1;
  static const String appIdentifier = 'sportilife';

  /// Encode un programme d'entraînement avec ses exercices personnalisés requis
  static String encodeProgram(WorkoutProgram program, List<Exercise> availableExercises) {
    final programExIds = program.exercises.map((e) => e.exerciseId).toSet();
    final customExercises = availableExercises
        .where((e) => programExIds.contains(e.id) && e.isCustom)
        .map((e) => e.toJson())
        .toList();

    final payload = {
      'app': appIdentifier,
      'type': 'program',
      'version': currentSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'program': program.toJson(),
      'customExercises': customExercises,
    };

    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr);
    return 'SPRT1_${base64Url.encode(bytes)}';
  }

  /// Encode un exercice unique
  static String encodeExercise(Exercise exercise) {
    final payload = {
      'app': appIdentifier,
      'type': 'singleExercise',
      'version': currentSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'exercise': exercise.toJson(),
    };

    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr);
    return 'SPRT1_${base64Url.encode(bytes)}';
  }

  /// Encode un lot d'exercices
  static String encodeExercises(List<Exercise> exercises) {
    final payload = {
      'app': appIdentifier,
      'type': 'exercisesBundle',
      'version': currentSchemaVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };

    final jsonStr = jsonEncode(payload);
    final bytes = utf8.encode(jsonStr);
    return 'SPRT1_${base64Url.encode(bytes)}';
  }

  /// Décode une chaîne (Base64 compressé ou JSON brut)
  static SharedDataResult decode(String input) {
    String cleanInput = input.trim();
    if (cleanInput.isEmpty) {
      return SharedDataResult(
        type: ShareDataType.unknown,
        errorMessage: "Code de partage vide.",
      );
    }

    try {
      Map<String, dynamic> jsonMap;

      if (cleanInput.startsWith('SPRT1_')) {
        final b64 = cleanInput.substring(6);
        final decodedBytes = base64Url.decode(b64);
        final jsonStr = utf8.decode(decodedBytes);
        jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      } else if (cleanInput.startsWith('{') && cleanInput.endsWith('}')) {
        jsonMap = jsonDecode(cleanInput) as Map<String, dynamic>;
      } else {
        try {
          final decodedBytes = base64Url.decode(cleanInput);
          final jsonStr = utf8.decode(decodedBytes);
          jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (_) {
          return SharedDataResult(
            type: ShareDataType.unknown,
            errorMessage: "Format de code non reconnu.",
          );
        }
      }

      final type = jsonMap['type'] as String?;

      if (type == 'program') {
        final programJson = jsonMap['program'] as Map<String, dynamic>;
        final program = WorkoutProgram.fromJson(programJson);

        List<Exercise> customExs = [];
        if (jsonMap['customExercises'] != null && jsonMap['customExercises'] is List) {
          customExs = (jsonMap['customExercises'] as List)
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        return SharedDataResult(
          type: ShareDataType.program,
          program: program,
          exercises: customExs,
        );
      } else if (type == 'singleExercise') {
        final exJson = jsonMap['exercise'] as Map<String, dynamic>;
        final exercise = Exercise.fromJson(exJson);
        return SharedDataResult(
          type: ShareDataType.singleExercise,
          exercises: [exercise],
        );
      } else if (type == 'exercisesBundle') {
        final list = (jsonMap['exercises'] as List)
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList();
        return SharedDataResult(
          type: ShareDataType.exercisesBundle,
          exercises: list,
        );
      } else {
        return SharedDataResult(
          type: ShareDataType.unknown,
          errorMessage: "Type de contenu inconnu : $type",
        );
      }
    } catch (e) {
      return SharedDataResult(
        type: ShareDataType.unknown,
        errorMessage: "Impossible de lire le code de partage ($e)",
      );
    }
  }
}
