import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zp_router/zp_router.dart';

void main() {
  tearDown(() {
    ZpNavigator.instance.resetForTest();
  });

  testWidgets('push uses configured page resolver', (tester) async {
    final visited = <String?>[];
    ZpNavigator.instance.configure(
      pageResolver: (context, request) {
        visited.add(request.route);
        return const Text('target');
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

  testWidgets('pushRequest resolves typed request directly', (tester) async {
    ZpRouteRequest? captured;
    ZpNavigator.instance.configure(
      pageResolver: (context, request) {
        captured = request;
        return const Text('request target');
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: ZpNavigator.navigatorKey,
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => ZpNavigator.instance.pushRequest<void>(
                const ZpRouteRequest(
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
