import 'package:commet/diagnostic/benchmark_values.dart';
import 'package:commet/ui/pages/developer/benchmarks/benchmark_utils.dart';
import 'package:commet/ui/pages/developer/benchmarks/timeline_viewer_benchmark.dart';
import 'package:commet/utils/emoji/unicode_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tiamat/config/style/theme_dark.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Timeline Viewer Test', (tester) async {
    // TimelineEventMenu reads UnicodeEmojis.packs; main() normally loads them.
    await UnicodeEmojis.load();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      theme: ThemeDark.theme,
      home: const Scaffold(
        body: BenchmarkTimelineViewer(),
      ),
    ));

    // Timeline is created asynchronously; wait until the viewer mounts a
    // Scrollable before scrolling (otherwise scrollUntilVisible throws).
    final listFinder = find.byType(Scrollable);
    final itemFinder = find.text(finalEventMessage);
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (listFinder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for BenchmarkTimelineViewer Scrollable');
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Give the newest (marker) event a chance to build before scrolling.
    while (itemFinder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    var reportKey = 'TimelineViewer Scrolling';

    await binding.traceAction(
      () async {
        // Always generate scroll frames for the timeline driver summary,
        // even when the marker is already in view.
        final scrollable = listFinder;
        for (var i = 0; i < 40; i++) {
          await tester.fling(scrollable, const Offset(0, -300), 1000);
          await tester.pump(const Duration(milliseconds: 16));
        }
        for (var i = 0; i < 40; i++) {
          await tester.fling(scrollable, const Offset(0, 300), 1000);
          await tester.pump(const Duration(milliseconds: 16));
        }
        if (itemFinder.evaluate().isEmpty) {
          try {
            await tester.scrollUntilVisible(
              itemFinder,
              -50.0,
              maxScrolls: 500,
              scrollable: scrollable,
            );
          } catch (_) {
            await tester.scrollUntilVisible(
              itemFinder,
              50.0,
              maxScrolls: 500,
              scrollable: scrollable,
            );
          }
        }
        expect(itemFinder, findsWidgets);
      },
      reportKey: reportKey,
    );

    binding.reportData?[reportKey]["extra_values"] = [
      {
        "name": "$reportKey - Timeline Event Build Count",
        "value": BenchmarkValues.numTimelineEventsBuilt,
        "unit": "Builds",
      },
      {
        "name": "$reportKey - Timeline Event Message Body Build Count",
        "value": BenchmarkValues.numTimelineMessageBodyBuilt,
        "unit": "Builds",
      },
      {
        "name": "$reportKey - Timeline Event Message Reply Body Build Count",
        "value": BenchmarkValues.numTimelineReplyBodyBuilt,
        "unit": "Builds",
      },
      {
        "name": "$reportKey - Timeline Event Message Url Preview Build Count",
        "value": BenchmarkValues.numTimelineUrlPreviewBuilt,
        "unit": "Builds",
      }
    ];
  });
}
