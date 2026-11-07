import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:red_vitalys/main.dart';

void main() {
  testWidgets('dashboard opens the static indicator detail preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RedVitalysApp());
    expect(find.text('Tablero de indicadores'), findsOneWidget);
    expect(find.text('Dónde actuar primero'), findsOneWidget);

    await tester.tap(find.text('Detalle'));
    await tester.pumpAndSettle();

    expect(find.text('Tendencia mensual'), findsOneWidget);
    expect(find.text('Comparación entre sedes'), findsOneWidget);
    expect(find.text('Mediciones recientes'), findsOneWidget);
    await tester.tap(find.text('Tablero'));
    await tester.pumpAndSettle();
    expect(find.text('Tablero de indicadores'), findsOneWidget);
  });

  testWidgets('indicator screens fit a 360 pixel viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const RedVitalysApp());
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Detalle'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
