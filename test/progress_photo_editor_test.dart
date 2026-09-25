// Overlay editor interactions: gestures, opacity, modes, reset, and the
// Save / Close / Share contract. The photo file never needs to exist.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/common/widgets/muscle_map/muscle_overlay.dart';
import 'package:workout_tracker/home/exercises/models/muscle.dart';
import 'package:workout_tracker/home/session/pages/progress_photo_editor_page.dart';

const _frameKey = ValueKey('overlay-editor-frame');

class EditorHost {
  OverlayConfig? result;
  bool popped = false;
  final shared = <OverlayConfig>[];
}

Future<EditorHost> pumpEditor(
  WidgetTester tester, {
  OverlayConfig initial = OverlayConfig.defaults,
  bool withShare = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2340); // phone portrait
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  final host = EditorHost();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                host.result = await Navigator.of(ctx).push<OverlayConfig>(
                  MaterialPageRoute(
                    builder: (_) => ProgressPhotoEditorPage(
                      photo: File('/fake/photo.jpg'),
                      primary: const {Muscle.chest},
                      secondary: const {Muscle.triceps},
                      initial: initial,
                      onShare: withShare
                          ? (c) async => host.shared.add(c)
                          : null,
                    ),
                  ),
                );
                host.popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return host;
}

OverlayConfig current(WidgetTester tester) =>
    tester.widget<MuscleOverlay>(find.byType(MuscleOverlay)).config;

Size frameSize(WidgetTester tester) => tester.getSize(find.byKey(_frameKey));

void main() {
  testWidgets(
    'opens at the default position with the photo, overlay and controls',
    (tester) async {
      await pumpEditor(tester);
      expect(current(tester), OverlayConfig.defaults);
      expect(find.byType(Image), findsOneWidget);
      for (final label in [
        'Front',
        'Back',
        'Both',
        'None',
        'Save',
        'Share',
        'Reset',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final frame = frameSize(tester);
      expect(
        frame.width / frame.height,
        closeTo(MuscleOverlayLayout.photoAspect, 0.01),
      );
    },
  );

  testWidgets('restores a previously saved composition', (tester) async {
    const saved = OverlayConfig(
      view: OverlayView.back,
      transform: OverlayTransform(
        offset: Offset(0.1, -0.05),
        scale: 1.3,
        rotation: 0.2,
      ),
      opacity: 0.45,
    );
    await pumpEditor(tester, initial: saved);
    expect(current(tester), saved);
    expect(find.text('45%'), findsOneWidget);
  });

  testWidgets('drag moves the overlay by the finger movement', (tester) async {
    await pumpEditor(tester);
    final frame = frameSize(tester);
    await tester.drag(find.byKey(_frameKey), const Offset(60, -40));
    await tester.pumpAndSettle();

    final offset = current(tester).transform.offset;
    // Gesture recognition consumes a small touch slop before tracking starts.
    expect(offset.dx * frame.width, inInclusiveRange(60 - 20, 60 + 0.5));
    expect(offset.dy * frame.height, inInclusiveRange(-40 - 0.5, -40 + 20));
    expect(current(tester).transform.scale, 1);
  });

  testWidgets('dragging far away keeps the overlay on screen', (tester) async {
    await pumpEditor(tester);
    final frame = frameSize(tester);
    await tester.drag(find.byKey(_frameKey), const Offset(4000, 4000));
    await tester.pumpAndSettle();

    final t = current(tester).transform;
    final center =
        MuscleOverlayLayout.anchor(frame, OverlayView.both) +
        Offset(t.offset.dx * frame.width, t.offset.dy * frame.height);
    expect(center.dx, lessThanOrEqualTo(frame.width * 0.95 + 0.01));
    expect(center.dy, lessThanOrEqualTo(frame.height * 0.95 + 0.01));
  });

  testWidgets('pinch out enlarges the overlay', (tester) async {
    await pumpEditor(tester);
    final c = tester.getCenter(find.byKey(_frameKey));
    final a = await tester.startGesture(c - const Offset(40, 0), pointer: 1);
    final b = await tester.startGesture(c + const Offset(40, 0), pointer: 2);
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(c - Offset(40.0 + i * 8, 0));
      await b.moveTo(c + Offset(40.0 + i * 8, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();

    expect(current(tester).transform.scale, greaterThan(1.5));
    expect(
      current(tester).transform.scale,
      lessThanOrEqualTo(OverlayTransform.maxScale),
    );
  });

  testWidgets('two-finger twist rotates the overlay', (tester) async {
    await pumpEditor(tester);
    final c = tester.getCenter(find.byKey(_frameKey));
    const r = 60.0;
    final a = await tester.startGesture(c + const Offset(-r, 0), pointer: 1);
    final b = await tester.startGesture(c + const Offset(r, 0), pointer: 2);
    for (var i = 1; i <= 10; i++) {
      final angle = i * (math.pi / 4) / 10; // up to 45°
      final d = Offset(math.cos(angle) * r, math.sin(angle) * r);
      await a.moveTo(c - d);
      await b.moveTo(c + d);
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();

    // Clockwise, and at most the twist applied. The recogniser only starts
    // tracking after a small movement threshold, so part of the twist is
    // consumed before rotation is measured (as on a real phone).
    expect(
      current(tester).transform.rotation,
      inInclusiveRange(0.35, math.pi / 4 + 0.05),
    );
  });

  testWidgets('opacity slider changes the overlay opacity', (tester) async {
    await pumpEditor(tester);
    await tester.drag(
      find.byKey(const ValueKey('overlay-editor-opacity')),
      const Offset(-1000, 0),
    );
    await tester.pumpAndSettle();
    expect(current(tester).opacity, closeTo(OverlayConfig.minOpacity, 1e-9));
    expect(find.text('15%'), findsOneWidget);
  });

  testWidgets('front / back / both / none selection', (tester) async {
    await pumpEditor(tester);
    for (final view in [
      OverlayView.front,
      OverlayView.back,
      OverlayView.both,
    ]) {
      await tester.tap(find.byKey(ValueKey('overlay-mode-${view.name}')));
      await tester.pumpAndSettle();
      expect(current(tester).view, view);
    }

    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(current(tester).view, OverlayView.none);
    expect(current(tester).visible, isFalse);
    // Nothing to move or fade while hidden.
    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('overlay-editor-opacity')),
    );
    expect(slider.onChanged, isNull);
    await tester.drag(find.byKey(_frameKey), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(current(tester).transform, OverlayTransform.identity);
  });

  testWidgets(
    'reset returns to the default position but keeps mode and opacity',
    (tester) async {
      await pumpEditor(
        tester,
        initial: const OverlayConfig(
          view: OverlayView.front,
          transform: OverlayTransform(
            offset: Offset(0.2, 0.1),
            scale: 2,
            rotation: 0.5,
          ),
          opacity: 0.5,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('overlay-editor-reset')));
      await tester.pumpAndSettle();
      expect(current(tester).transform, OverlayTransform.identity);
      expect(current(tester).view, OverlayView.front);
      expect(current(tester).opacity, 0.5);
    },
  );

  testWidgets('double-tap also resets', (tester) async {
    await pumpEditor(
      tester,
      initial: const OverlayConfig(transform: OverlayTransform(scale: 2)),
    );
    await tester.tap(find.byKey(_frameKey));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(_frameKey));
    await tester.pumpAndSettle();
    expect(current(tester).transform, OverlayTransform.identity);
  });

  testWidgets('Save returns the edited composition', (tester) async {
    final host = await pumpEditor(tester);
    await tester.drag(find.byKey(_frameKey), const Offset(50, 0));
    await tester.tap(find.byKey(const ValueKey('overlay-mode-front')));
    await tester.pumpAndSettle();
    final edited = current(tester);

    await tester.tap(find.byKey(const ValueKey('overlay-editor-save')));
    await tester.pumpAndSettle();
    expect(host.popped, isTrue);
    expect(host.result, edited);
    expect(host.result!.transform.offset.dx, greaterThan(0));
  });

  testWidgets('Close discards changes', (tester) async {
    final host = await pumpEditor(tester);
    await tester.drag(find.byKey(_frameKey), const Offset(50, 0));
    await tester.tap(find.byKey(const ValueKey('overlay-editor-close')));
    await tester.pumpAndSettle();
    expect(host.popped, isTrue);
    expect(host.result, isNull);
  });

  testWidgets(
    'Share exports the current composition without saving or closing',
    (tester) async {
      final host = await pumpEditor(tester);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('overlay-editor-share')));
      await tester.pumpAndSettle();

      expect(host.shared, [current(tester)]);
      expect(host.shared.single.view, OverlayView.back);
      expect(host.popped, isFalse, reason: 'still editing');
    },
  );

  testWidgets('Share is hidden when no share handler is given', (tester) async {
    await pumpEditor(tester, withShare: false);
    expect(find.text('Share'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
  });
}
