import 'package:petfriendly/core/display_numbers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';

void main() {
  testWidgets(
    'portfolio map zooms and shows a simulated position without services',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(402, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const FullscreenMapScreen(
              args: FullscreenMapArgs(
                places: DemoPlaceRepository.places,
                city: 'Минск',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(AppConfig.backendEnabled, isFalse);
      expect(displayDecimal(4.8), '4.8');
      expect(find.text('Mock map · fictional places'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      final controller = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;
      final original = controller.value.getMaxScaleOnAxis();
      await tester.tap(find.byTooltip('Zoom in'));
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), greaterThan(original));
      await tester.tap(find.byTooltip('Zoom out'));
      await tester.pumpAndSettle();
      expect(controller.value.getMaxScaleOnAxis(), closeTo(original, .001));
      await tester.tap(find.byTooltip('Show simulated position'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Simulated position'), findsOneWidget);
      expect(find.byTooltip('Зелёный парк'), findsOneWidget);
    },
    skip: !AppConfig.portfolio,
  );
}
