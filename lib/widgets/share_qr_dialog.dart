import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../services/share_service.dart';
import '../theme.dart';

class ShareQrDialog extends StatelessWidget {
  final String title;
  final String shareCode;
  final String? subtitle;
  final IconData icon;

  const ShareQrDialog({
    super.key,
    required this.title,
    required this.shareCode,
    this.subtitle,
    this.icon = Icons.qr_code_rounded,
  });

  /// Factory helper pour partager un programme
  static void showForProgram(
    BuildContext context, {
    required WorkoutProgram program,
    required List<Exercise> availableExercises,
  }) {
    final code = ShareService.encodeProgram(program, availableExercises);
    showDialog(
      context: context,
      builder: (ctx) => ShareQrDialog(
        title: program.name,
        subtitle: "${program.exercises.length} exercices • ${program.exercises.fold(0, (sum, e) => sum + e.setsCount)} séries",
        shareCode: code,
        icon: Icons.fitness_center,
      ),
    );
  }

  /// Factory helper pour partager un exercice
  static void showForExercise(BuildContext context, Exercise exercise) {
    final code = ShareService.encodeExercise(exercise);
    showDialog(
      context: context,
      builder: (ctx) => ShareQrDialog(
        title: exercise.name,
        subtitle: "Catégorie : ${exercise.category}",
        shareCode: code,
        icon: Icons.sports_gymnastics,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.athleticBlue.withValues(alpha: 0.15),
                  radius: 20,
                  child: Icon(icon, color: AppTheme.athleticBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // QR Code Container (fond blanc pour un contraste maximal de scan)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: shareCode,
                version: QrVersions.auto,
                size: 220,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Scannez ce QR Code depuis l'application SportiLife d'un ami pour importer instantanément.",
              style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Copy code button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text("Code de partage copié dans le presse-papier !"),
                        ],
                      ),
                      backgroundColor: AppTheme.athleticBlue,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                label: const Text(
                  "Copier le code de partage",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.athleticBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
