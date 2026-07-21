import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/widgets/category_badge.dart';

void main() {
  group('CategoryBadge Widget Tests', () {
    testWidgets('Should display category name and icon for known category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBadge(category: 'Pectoraux'),
          ),
        ),
      );

      expect(find.text('Pectoraux'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('Should render fallback CategoryBadge for unknown category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBadge(category: 'Inconnue'),
          ),
        ),
      );

      expect(find.text('Inconnue'), findsOneWidget);
      expect(find.byIcon(Icons.label_outlined), findsOneWidget);
    });

    testWidgets('MultiCategoryBadges should render list of badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MultiCategoryBadges(categories: ['Pectoraux', 'Triceps']),
          ),
        ),
      );

      expect(find.text('Pectoraux'), findsOneWidget);
      expect(find.text('Triceps'), findsOneWidget);
    });

    testWidgets('MultiCategoryBadges with empty list should display Autre badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MultiCategoryBadges(categories: []),
          ),
        ),
      );

      expect(find.text('Autre'), findsOneWidget);
    });

    testWidgets('CategoryMultiSelect should display filter chips and allow selection', (WidgetTester tester) async {
      List<String> selected = ['Pectoraux'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryMultiSelect(
                  selectedCategories: selected,
                  onChanged: (newVal) {
                    setState(() {
                      selected = newVal;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Pectoraux'), findsOneWidget);
      expect(find.text('Dos'), findsOneWidget);

      // Tap 'Dos' chip to add it
      await tester.tap(find.text('Dos'));
      await tester.pump();

      expect(selected.contains('Dos'), isTrue);
    });
  });
}
