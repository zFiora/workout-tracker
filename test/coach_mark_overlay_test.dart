import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/common/tutorial/tutorial_runner.dart';

CoachMarkStep _step(GlobalKey key, String title) => CoachMarkStep(
      targetKey: key,
      title: title,
      description: '$title description',
    );

/// Pumps a page with the given keyed target boxes and hands back a context
/// suitable for launching the overlay.
Future<BuildContext> _pumpTargets(
  WidgetTester tester,
  List<GlobalKey> keys,
) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (c) {
            ctx = c;
            return Column(
              children: [
                for (var i = 0; i < keys.length; i++)
                  Container(
                    key: keys[i],
                    width: 160,
                    height: 44,
                    alignment: Alignment.center,
                    child: Text('Target$i'),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
  return ctx;
}

/// A page that kicks off a tutorial from initState via [TutorialRunner], the
/// way real pages do.
class _RunnerPage extends StatefulWidget {
  const _RunnerPage({required this.targetKey});
  final GlobalKey targetKey;

  @override
  State<_RunnerPage> createState() => _RunnerPageState();
}

class _RunnerPageState extends State<_RunnerPage> {
  @override
  void initState() {
    super.initState();
    TutorialRunner.schedule(
      context,
      id: 'runner_test',
      version: 1,
      settle: Duration.zero,
      steps: () => [_step(widget.targetKey, 'Runner')],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          key: widget.targetKey,
          width: 160,
          height: 44,
          alignment: Alignment.center,
          child: const Text('RunnerTarget'),
        ),
      );
}

void main() {
  group('coach-mark overlay', () {
    testWidgets('shows progress and advances with Next', (tester) async {
      final a = GlobalKey();
      final b = GlobalKey();
      final ctx = await _pumpTargets(tester, [a, b]);

      runCoachMarks(ctx, [_step(a, 'Title A'), _step(b, 'Title B')]);
      await tester.pumpAndSettle();

      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Title A'), findsOneWidget);
      expect(find.text('Back'), findsNothing); // no Back on the first step

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('Title B'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget); // last step → Done

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Title B'), findsNothing); // overlay dismissed
    });

    testWidgets('Back returns to the previous step', (tester) async {
      final a = GlobalKey();
      final b = GlobalKey();
      final ctx = await _pumpTargets(tester, [a, b]);

      runCoachMarks(ctx, [_step(a, 'Title A'), _step(b, 'Title B')]);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Title B'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Title A'), findsOneWidget);
    });

    testWidgets('Skip dismisses the whole tutorial', (tester) async {
      final a = GlobalKey();
      final b = GlobalKey();
      final ctx = await _pumpTargets(tester, [a, b]);

      runCoachMarks(ctx, [_step(a, 'Title A'), _step(b, 'Title B')]);
      await tester.pumpAndSettle();
      expect(find.text('Title A'), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Title A'), findsNothing);
      expect(find.text('Title B'), findsNothing);
    });

    testWidgets('a step whose target is missing is skipped', (tester) async {
      final a = GlobalKey();
      final missing = GlobalKey(); // never attached to the tree
      final ctx = await _pumpTargets(tester, [a]);

      runCoachMarks(ctx, [_step(a, 'Title A'), _step(missing, 'Missing')]);
      await tester.pumpAndSettle();

      expect(find.text('Title A'), findsOneWidget);

      // Advancing past the only visible step ends the tutorial rather than
      // showing the missing one.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Missing'), findsNothing);
      expect(find.text('Title A'), findsNothing);
    });

    testWidgets('empty step list shows nothing', (tester) async {
      final ctx = await _pumpTargets(tester, []);
      final shown = await runCoachMarks(ctx, const []);
      await tester.pumpAndSettle();
      expect(shown, isFalse);
    });
  });

  group('TutorialRunner integration', () {
    testWidgets('shows on first visit, then records it as seen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      const store = TutorialStore();
      final a = GlobalKey();

      await tester.pumpWidget(MaterialApp(home: _RunnerPage(targetKey: a)));
      await tester.pump(); // run initState scheduling + shouldShow
      await tester.pump(const Duration(milliseconds: 20)); // fire settle timer
      await tester.pumpAndSettle();

      expect(find.text('1 of 1'), findsOneWidget);
      expect(find.text('Runner'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(await store.seenVersion('runner_test'), 1);
    });

    testWidgets('does not show when already seen at the current version',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        TutorialStore.storageKey('runner_test'): 1,
      });
      final a = GlobalKey();

      await tester.pumpWidget(MaterialApp(home: _RunnerPage(targetKey: a)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();

      expect(find.text('Runner'), findsNothing);
    });
  });
}
