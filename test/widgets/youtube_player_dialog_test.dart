import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/widgets/youtube_player_dialog.dart';

void main() {
  group('YoutubePlayerDialog Widget Tests', () {
    test('extractVideoId should extract video ID from YouTube URLs', () {
      expect(
        YoutubePlayerDialog.extractVideoId('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        YoutubePlayerDialog.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        equals('dQw4w9WgXcQ'),
      );
    });

    testWidgets('Should display exercise name and close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  YoutubePlayerDialog.show(
                    context,
                    'Développé Couché Video',
                    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Développé Couché Video'), findsOneWidget);
      expect(find.text('Ouvrir dans YouTube'), findsOneWidget);
      expect(find.text('Fermer'), findsOneWidget);

      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();

      expect(find.text('Développé Couché Video'), findsNothing);
    });

    testWidgets('Should show unrecognised video format message for invalid URL', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => YoutubePlayerDialog(
                exerciseName: 'Test Invalid',
                videoUrl: 'not_a_url',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Format de vidéo non reconnu'), findsOneWidget);
    });
  });
}
