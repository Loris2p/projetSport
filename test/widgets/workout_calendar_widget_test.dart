import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_app/models/workout_session.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/repositories/workout_repository.dart';
import 'package:sport_app/widgets/workout_calendar_widget.dart';

class MockWorkoutRepository implements WorkoutRepository {
  Future<List<WorkoutSession>> getWorkoutHistory() async => [];
  Future<void> saveWorkoutSession(WorkoutSession session) async {}
  Future<void> deleteWorkoutSession(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR', null);
  });

  testWidgets('WorkoutCalendarWidget renders properly and displays header', (WidgetTester tester) async {
    final mockRepo = MockWorkoutRepository();
    final provider = WorkoutProvider(repository: mockRepo);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<WorkoutProvider>.value(
            value: provider,
            child: const SingleChildScrollView(
              child: WorkoutCalendarWidget(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text("MON HISTORIQUE"), findsOneWidget);
    expect(find.byType(WorkoutCalendarWidget), findsOneWidget);
  });
}
