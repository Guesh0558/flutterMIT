// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: creates a standard AnimationController with a given duration.
// addTearDown must be called in the test body, not here.
// ─────────────────────────────────────────────────────────────────────────────
AnimationController makeController({required Duration duration, required TickerProvider vsync}) {
  return AnimationController(duration: duration, vsync: vsync);
}

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // Group 1: Awaiting animation controllers sequentially
  // ───────────────────────────────────────────────────────────────────────────
  group('Awaiting animation controllers sequentially', () {
    testWidgets('using direct future', (WidgetTester tester) async {
      final vsync = const TestVSync();
      final controller1 = makeController(duration: const Duration(milliseconds: 100), vsync: vsync);
      final controller2 = makeController(duration: const Duration(milliseconds: 600), vsync: vsync);
      final controller3 = makeController(duration: const Duration(milliseconds: 300), vsync: vsync);
      addTearDown(controller1.dispose);
      addTearDown(controller2.dispose);
      addTearDown(controller3.dispose);

      final log = <String>[];

      Future<void> runTest() async {
        log.add('a'); // t=0
        await controller1.forward();
        log.add('b'); // t≈150
        await controller2.forward();
        log.add('c'); // t≈799
        await controller3.forward();
        log.add('d'); // t≈1200
      }

      log.add('start');
      runTest().then((_) => log.add('end'));

      await tester.pump(); // t=0
      expect(log, <String>['start', 'a']);
      await tester.pump(); // t=0 again
      expect(log, <String>['start', 'a']);
      await tester.pump(const Duration(milliseconds: 50)); // t=50
      expect(log, <String>['start', 'a']);
      await tester.pump(const Duration(milliseconds: 100)); // t=150
      expect(log, <String>['start', 'a', 'b']);
      await tester.pump(const Duration(milliseconds: 50)); // t=200
      expect(log, <String>['start', 'a', 'b']);
      await tester.pump(const Duration(milliseconds: 400)); // t=600
      expect(log, <String>['start', 'a', 'b']);
      await tester.pump(const Duration(milliseconds: 199)); // t=799
      expect(log, <String>['start', 'a', 'b', 'c']);
      await tester.pump(const Duration(milliseconds: 51)); // t=850
      expect(log, <String>['start', 'a', 'b', 'c']);
      await tester.pump(const Duration(milliseconds: 400)); // t=1200
      expect(log, <String>['start', 'a', 'b', 'c', 'd', 'end']);
      await tester.pump(const Duration(milliseconds: 400)); // t=1600
      expect(log, <String>['start', 'a', 'b', 'c', 'd', 'end']);
    });

    testWidgets('using orCancel', (WidgetTester tester) async {
      final vsync = const TestVSync();
      final controller1 = makeController(duration: const Duration(milliseconds: 100), vsync: vsync);
      final controller2 = makeController(duration: const Duration(milliseconds: 600), vsync: vsync);
      final controller3 = makeController(duration: const Duration(milliseconds: 300), vsync: vsync);
      addTearDown(controller1.dispose);
      addTearDown(controller2.dispose);
      addTearDown(controller3.dispose);

      final log = <String>[];

      Future<void> runTest() async {
        log.add('a'); // t=0
        await controller1.forward().orCancel;
        log.add('b'); // t≈150
        await controller2.forward().orCancel;
        log.add('c'); // t≈799
        await controller3.forward().orCancel;
        log.add('d'); // t≈1200
      }

      log.add('start');
      runTest().then((_) => log.add('end'));

      await tester.pump(); // t=0
      expect(log, <String>['start', 'a']);
      await tester.pump(); // t=0 again
      expect(log, <String>['start', 'a']);
      await tester.pump(const Duration(milliseconds: 50)); // t=50
      expect(log, <String>['start', 'a']);
      await tester.pump(const Duration(milliseconds: 100)); // t=150
      expect(log, <String>['start', 'a', 'b']);
      await tester.pump(const Duration(milliseconds: 50)); // t=200
      expect(log, <String>['start', 'a', 'b']);
      await tester.pump(const Duration(milliseconds: 400)); // t=600
      expect(log, <String>['start', 'a', 'b']);
      await tester.pump(const Duration(milliseconds: 199)); // t=799
      expect(log, <String>['start', 'a', 'b', 'c']);
      await tester.pump(const Duration(milliseconds: 51)); // t=850
      expect(log, <String>['start', 'a', 'b', 'c']);
      await tester.pump(const Duration(milliseconds: 400)); // t=1200
      expect(log, <String>['start', 'a', 'b', 'c', 'd', 'end']);
      await tester.pump(const Duration(milliseconds: 400)); // t=1600
      expect(log, <String>['start', 'a', 'b', 'c', 'd', 'end']);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 2: Cancellation and error handling
  // ───────────────────────────────────────────────────────────────────────────
  group('Cancellation and error handling', () {
    testWidgets('disposing controller mid-animation throws TickerCanceled', (
      WidgetTester tester,
    ) async {
      final controller1 = makeController(
        duration: const Duration(milliseconds: 100),
        vsync: const TestVSync(),
      );
      // No addTearDown — disposed manually inside the test below

      final log = <String>[];

      Future<void> runTest() async {
        try {
          log.add('start');
          await controller1.forward().orCancel;
          log.add('fail'); // should never be reached
        } on TickerCanceled {
          log.add('caught');
        }
      }

      runTest().then((_) => log.add('end'));

      await tester.pump(); // start ticker
      expect(log, <String>['start']);
      await tester.pump(const Duration(milliseconds: 50)); // mid-animation
      expect(log, <String>['start']);
      controller1.dispose(); // triggers TickerCanceled
      expect(log, <String>['start']);
      await tester.idle(); // microtask queue flushes
      expect(log, <String>['start', 'caught', 'end']);
    });

    testWidgets('orCancel resolves cleanly after animation completes', (WidgetTester tester) async {
      final controller1 = makeController(
        duration: const Duration(milliseconds: 100),
        vsync: const TestVSync(),
      );
      addTearDown(controller1.dispose);

      final TickerFuture f = controller1.forward();
      await tester.pump(); // start ticker
      await tester.pump(const Duration(milliseconds: 200)); // animation completes

      await f; // direct await — no-op
      await f.orCancel; // should also resolve cleanly

      expect(true, isTrue); // confirms no exception was thrown
    });

    testWidgets('orCancel throws TickerCanceled when stopped before completion', (
      WidgetTester tester,
    ) async {
      final controller1 = makeController(
        duration: const Duration(milliseconds: 100),
        vsync: const TestVSync(),
      );
      addTearDown(controller1.dispose);

      final TickerFuture f = controller1.forward();
      await tester.pump(); // start ticker
      controller1.stop(); // cancel before completion

      bool caughtCancellation = false;
      try {
        await f.orCancel;
      } on TickerCanceled {
        caughtCancellation = true;
      }

      expect(caughtCancellation, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Group 3: TickerFuture API conformance
  // ───────────────────────────────────────────────────────────────────────────
  group('TickerFuture implements Future interface', () {
    testWidgets('all Future methods are available and return correct types', (
      WidgetTester tester,
    ) async {
      final controller1 = makeController(
        duration: const Duration(milliseconds: 100),
        vsync: const TestVSync(),
      );
      addTearDown(controller1.dispose);

      final TickerFuture f = controller1.forward();
      await tester.pump(); // start ticker
      await tester.pump(const Duration(milliseconds: 200)); // end ticker

      expect(f.asStream().single, isA<Future<void>>());
      await f.catchError((dynamic e) {
        throw 'should not reach here';
      });
      expect(await f.then<bool>((_) => true), isTrue);
      expect(f.whenComplete(() => false), isA<Future<void>>());
      expect(f.timeout(const Duration(seconds: 5)), isA<Future<void>>());
    });
  });
}
