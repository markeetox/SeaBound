import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/core/map_layer_config.dart';
import 'package:seabound/features/map_layers/artificial_reefs_service.dart';
import 'package:seabound/features/map_layers/lupita_service.dart';
import 'package:seabound/features/map_layers/map_layers_provider.dart';
import 'package:seabound/features/spots/spots_providers.dart';
import 'package:seabound/features/spots/spots_screen.dart';

class MockFailingReefsService implements ArtificialReefsService {
  bool shouldFail = true;
  int fetchCount = 0;

  @override
  Future<List<ArtificialReefPoint>> fetchReefsInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    fetchCount++;
    if (shouldFail) {
      throw Exception('Network connection failed');
    }
    return [
      const ArtificialReefPoint(
        id: 'reef_1',
        reefName: 'Test Reef',
        latitude: 25.76,
        longitude: -80.19,
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockActiveMapLayersNotifier extends ActiveMapLayersNotifier {
  final Set<String> initialLayers;
  MockActiveMapLayersNotifier(this.initialLayers);

  @override
  Set<String> build() => initialLayers;
}

void main() {
  testWidgets('SpotsScreen renders compact top map controls (Layers & Location) and icon-only Add Opinion FAB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SpotsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Layers button tooltip exists
    expect(find.byTooltip('Layers'), findsOneWidget);

    // Check Locate toggle button tooltip exists
    expect(find.byKey(const ValueKey('locate_toggle_button')), findsOneWidget);

    // Check standalone Community Spots button text is gone from top overlay
    expect(find.text('Community Spots'), findsNothing);

    // Check Icon-only FAB exists with Add Spot / Trip tooltip
    expect(find.byTooltip('Add Spot / Trip'), findsOneWidget);
  });

  testWidgets('SpotsScreen displays error banner with Retry button when artificial reefs fails to load',
      (WidgetTester tester) async {
    final mockReefsService = MockFailingReefsService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
          activeMapLayersProvider.overrideWith(
            () => MockActiveMapLayersNotifier({MapLayerConfig.artificialReefsId}),
          ),
          artificialReefsServiceProvider.overrideWithValue(mockReefsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SpotsScreen(),
        ),
      ),
    );

    // Pump to render widget, trigger onMapReady and advance debounce timer (800ms)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    // Verify artificial reefs fetch was called at least once
    expect(mockReefsService.fetchCount, greaterThanOrEqualTo(1));

    // Verify error banner is shown
    expect(find.text("Couldn't load reef data"), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Now make mock service succeed and tap Retry
    mockReefsService.shouldFail = false;
    final initialFetchCount = mockReefsService.fetchCount;

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    // Verify another fetch request was triggered
    expect(mockReefsService.fetchCount, greaterThan(initialFetchCount));

    // Verify error banner is cleared on success
    expect(find.text("Couldn't load reef data"), findsNothing);
  });

  testWidgets('SpotsScreen renders user avatar location pointer on map and toggles locate mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SpotsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final locateToggleFinder = find.byKey(const ValueKey('locate_toggle_button'));
    expect(locateToggleFinder, findsOneWidget);

    // Tap locate toggle button
    await tester.tap(locateToggleFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify toggle tooltip updates to active tracking
    expect(find.byTooltip('Tracking Location (On)'), findsOneWidget);
  });

  testWidgets('Tapping Add button opens option sheet with Secret Spot and Trip options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SpotsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addButtonFinder = find.byTooltip('Add Spot / Trip');
    expect(addButtonFinder, findsOneWidget);

    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();

    // Verify bottom sheet title and options
    expect(find.text('Add to Map'), findsOneWidget);
    expect(find.text('Secret Spot'), findsOneWidget);
    expect(find.text('Start Trip Recording'), findsOneWidget);
  });

  testWidgets('SpotsScreen renders Lupita top species dropdown when Lupita layer is active',
      (WidgetTester tester) async {
    final sampleLupitaData = LupitaData(
      version: 1,
      generatedUtc: '2026-10-24T20:00:00Z',
      disclaimer: 'Test',
      species: [
        const LupitaSpecies(
          id: 'cobia',
          name: 'Cobia',
          sci: 'Rachycentron canadum',
          colorHex: '#c084fc',
          specs: [],
          status: 'ok',
          message: '',
          spotCount: 1,
          spots: [
            LupitaSpot(
              id: 'spot-1',
              speciesId: 'cobia',
              title: 'Cobia Spot 1',
              score: 0.88,
              confidence: 'High',
              dataCoverage: 1.0,
              latitude: 25.76,
              longitude: -80.19,
              reasons: [],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
          activeMapLayersProvider.overrideWith(
            () => MockActiveMapLayersNotifier({MapLayerConfig.lupitaFishId}),
          ),
          lupitaDataProvider.overrideWith((ref) async => sampleLupitaData),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SpotsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Lupita dropdown exists
    expect(find.byKey(const ValueKey('lupita_species_dropdown')), findsOneWidget);
    expect(find.text('Lupita: All Species'), findsOneWidget);

    // Verify score badge for Lupita spot marker
    expect(find.text('88%'), findsOneWidget);
  });
}
