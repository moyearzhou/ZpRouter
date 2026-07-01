import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zp_router/zp_router.dart';
import 'package:zp_router/zp_router_compat.dart' as compat;

void main() {
  tearDown(() {
    ZpNavigator.instance.resetForTest();
  });

  testWidgets('push uses configured route factory', (tester) async {
    final visited = <String?>[];
    ZpNavigator.instance.configure(
      routeFactory: (settings, uniqueId) {
        visited.add(settings.name);
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const Text('target'),
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: ZpNavigator.navigatorKey,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => ZpNavigator.instance.push<void>('app.target'),
              child: const Text('go'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(visited, <String?>['app.target']);
    expect(find.text('target'), findsOneWidget);
  });

  testWidgets('pushRequest accepts compat request through toCore', (
    tester,
  ) async {
    ZpRouteRequest? captured;
    ZpNavigator.instance.configure(
      routeFactory: (settings, uniqueId) => null,
      requestRouteFactory: (request, uniqueId, context) {
        captured = request;
        return MaterialPageRoute<void>(
          settings: RouteSettings(
            name: request.route,
            arguments: request.params,
          ),
          builder: (_) => const Text('request target'),
        );
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: ZpNavigator.navigatorKey,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => ZpNavigator.instance.pushRequest<void>(
                const compat.ZPRouteRequest(
                  route: 'library.item.detail',
                  params: <String, Object?>{'itemKey': 'A'},
                ),
              ),
              child: const Text('go request'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go request'));
    await tester.pumpAndSettle();

    expect(captured?.route, 'library.item.detail');
    expect(captured?.params['itemKey'], 'A');
    expect(find.text('request target'), findsOneWidget);
  });
}
