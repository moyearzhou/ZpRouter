import 'package:test/test.dart';
import 'package:zp_router/zp_router_compat.dart';

void main() {
  group('ZpRouteSpec', () {
    test('normalizes defaults and preserves unknown params by default', () {
      const spec = ZpRouteSpec(
        route: 'app.settings',
        path: '/app/settings',
        loginPolicy: ZpLoginPolicy.none,
        fallbackType: ZpFallbackType.safePage,
        params: <String, ZpRouteParamSpec>{
          'tab': ZpRouteParamSpec(
            type: ZpRouteParamType.string,
            defaultValue: 'general',
            allowedValues: <String>{'general', 'account'},
          ),
        },
      );

      final result = spec.validate(<String, Object?>{'legacy': true});

      expect(result.valid, isTrue);
      expect(result.params['tab'], 'general');
      expect(result.params['legacy'], true);
    });

    test('rejects missing required params', () {
      const spec = ZpRouteSpec(
        route: 'library.item.detail',
        path: '/library/item/detail',
        loginPolicy: ZpLoginPolicy.zoteroOptional,
        fallbackType: ZpFallbackType.limited,
        params: <String, ZpRouteParamSpec>{
          'itemKey': ZpRouteParamSpec(
            type: ZpRouteParamType.string,
            required: true,
          ),
        },
      );

      final result = spec.validate(const <String, Object?>{});

      expect(result.valid, isFalse);
      expect(result.reason, 'missingRequiredParam');
      expect(result.paramKey, 'itemKey');
    });

    test('rejects invalid param types', () {
      const spec = ZpRouteSpec(
        route: 'library.collection.select',
        path: '/library/collection/select',
        loginPolicy: ZpLoginPolicy.zoteroRequired,
        fallbackType: ZpFallbackType.login,
        params: <String, ZpRouteParamSpec>{
          'isMultiSelect': ZpRouteParamSpec(
            type: ZpRouteParamType.boolean,
            defaultValue: true,
          ),
        },
      );

      final result = spec.validate(<String, Object?>{'isMultiSelect': 'false'});

      expect(result.valid, isFalse);
      expect(result.reason, 'invalidParam');
      expect(result.paramKey, 'isMultiSelect');
    });

    test('marks sensitive params without leaking values through specs', () {
      const spec = ZpRouteParamSpec(
        type: ZpRouteParamType.string,
        sensitive: true,
      );

      expect(spec.sensitive, isTrue);
      expect(spec.accepts('/private/file.pdf'), isTrue);
    });
  });

  group('ZpRouteRegistry', () {
    test('looks up specs by route name', () {
      const spec = ZpRouteSpec(
        route: 'zotero.auth',
        path: '/zotero/auth',
        loginPolicy: ZpLoginPolicy.none,
        fallbackType: ZpFallbackType.safePage,
      );

      final registry = ZpRouteRegistry(<ZpRouteSpec>[spec]);

      expect(registry.contains('zotero.auth'), isTrue);
      expect(registry.specOf('zotero.auth'), same(spec));
      expect(registry.specOf('missing'), isNull);
    });
  });

  group('ZpRouteRuntimeDispatcher', () {
    const spec = ZpRouteSpec(
      route: 'app.settings',
      path: '/app/settings',
      loginPolicy: ZpLoginPolicy.none,
      fallbackType: ZpFallbackType.safePage,
      params: <String, ZpRouteParamSpec>{
        'tab': ZpRouteParamSpec(
          type: ZpRouteParamType.string,
          defaultValue: 'general',
          allowedValues: <String>{'general', 'account'},
        ),
      },
    );

    test('dispatches normalized request to handler', () async {
      ZpRouteResolvedRequest? captured;
      final dispatcher = ZpRouteRuntimeDispatcher<String>(
        registry: ZpRouteRegistry(const <ZpRouteSpec>[spec]),
        handler: (resolved, context) {
          captured = resolved;
          return 'done';
        },
      );

      final result = await dispatcher.dispatch(
        const ZpRouteRequest(route: 'app.settings'),
        const ZpRouteDispatchContext(traceId: 'trace-1'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, 'done');
      expect(captured?.request.params['tab'], 'general');
      expect(captured?.spec, same(spec));
    });

    test('routes unknown route through fallback', () async {
      ZpRouteResult? fallbackReason;
      final dispatcher = ZpRouteRuntimeDispatcher<String>(
        registry: ZpRouteRegistry(const <ZpRouteSpec>[spec]),
        handler: (resolved, context) => 'unused',
        fallback: (resolved, request, reason, context) {
          fallbackReason = reason;
          return ZpRouteDispatchResult<String>(
            routeResult: ZpRouteResult.failed(
              route: request.route,
              reason: 'fallbackPage',
            ),
          );
        },
      );

      final result = await dispatcher.dispatch(
        const ZpRouteRequest(route: 'missing'),
        const ZpRouteDispatchContext(),
      );

      expect(fallbackReason?.type, ZpRouteResultType.unknownRoute);
      expect(result.routeResult.reason, 'fallbackPage');
    });

    test('routes invalid params through fallback before handler', () async {
      var handlerCalled = false;
      final dispatcher = ZpRouteRuntimeDispatcher<void>(
        registry: ZpRouteRegistry(const <ZpRouteSpec>[spec]),
        handler: (resolved, context) {
          handlerCalled = true;
        },
        fallback: (resolved, request, reason, context) {
          return ZpRouteDispatchResult<void>(routeResult: reason);
        },
      );

      final result = await dispatcher.dispatch(
        const ZpRouteRequest(
          route: 'app.settings',
          params: <String, Object?>{'tab': 'bad'},
        ),
        const ZpRouteDispatchContext(),
      );

      expect(handlerCalled, isFalse);
      expect(result.routeResult.type, ZpRouteResultType.invalidParams);
      expect(result.routeResult.paramKey, 'tab');
    });

    test('routes gate rejection through fallback', () async {
      final dispatcher = ZpRouteRuntimeDispatcher<void>(
        registry: ZpRouteRegistry(const <ZpRouteSpec>[spec]),
        handler: (resolved, context) {
          fail('handler should not run after gate rejection');
        },
        gate: (resolved, context) {
          return const ZpRouteGateDecision.reject(
            ZpRouteResult.loginRequired(route: 'app.settings'),
          );
        },
        fallback: (resolved, request, reason, context) {
          return ZpRouteDispatchResult<void>(routeResult: reason);
        },
      );

      final result = await dispatcher.dispatch(
        const ZpRouteRequest(route: 'app.settings'),
        const ZpRouteDispatchContext(),
      );

      expect(result.routeResult.type, ZpRouteResultType.loginRequired);
    });

    test('logs handler failure with error type only', () async {
      final events = <ZpRouteLogEvent>[];
      const sensitiveSpec = ZpRouteSpec(
        route: 'attachment.reader',
        path: '/attachment/reader',
        loginPolicy: ZpLoginPolicy.zoteroOptional,
        fallbackType: ZpFallbackType.limited,
        params: <String, ZpRouteParamSpec>{
          'filePath': ZpRouteParamSpec(
            type: ZpRouteParamType.string,
            required: true,
            sensitive: true,
          ),
        },
      );
      final dispatcher = ZpRouteRuntimeDispatcher<void>(
        registry: ZpRouteRegistry(const <ZpRouteSpec>[sensitiveSpec]),
        handler: (resolved, context) {
          throw StateError('private token');
        },
        logger: events.add,
      );

      final result = await dispatcher.dispatch(
        const ZpRouteRequest(
          route: 'attachment.reader',
          params: <String, Object?>{'filePath': '/private/file.pdf'},
        ),
        const ZpRouteDispatchContext(),
      );

      expect(result.routeResult.type, ZpRouteResultType.failed);
      expect(events.last.stage, ZpRouteDispatchStage.failed);
      expect(events.last.errorType, 'StateError');
      expect(events.last.errorType, isNot(contains('private token')));
      expect(events.last.request.params['filePath'], '<sensitive>');
      expect(
          events.last.request.params['filePath'], isNot('/private/file.pdf'));
    });
  });

  group('ZPRoute compat', () {
    test('keeps legacy enum names and converts specs to core model', () {
      const compatSpec = ZPRouteSpec(
        route: 'library.collection.select',
        path: '/library/collection/select',
        loginPolicy: ZPLoginPolicy.zoteroRequired,
        fallbackType: ZPFallbackType.login,
        params: <String, ZPRouteParamSpec>{
          'isMultiSelect': ZPRouteParamSpec(
            type: ZPRouteParamType.bool,
            defaultValue: true,
          ),
          'failCount': ZPRouteParamSpec(
            type: ZPRouteParamType.int,
            defaultValue: 0,
          ),
        },
      );

      final result = compatSpec.validate(const <String, Object?>{});
      final coreSpec = compatSpec.toCore();

      expect(result.valid, isTrue);
      expect(result.params['isMultiSelect'], true);
      expect(coreSpec.params['isMultiSelect']?.type, ZpRouteParamType.boolean);
      expect(coreSpec.params['failCount']?.type, ZpRouteParamType.integer);
    });

    test('converts legacy route requests to core requests', () {
      const request = ZPRouteRequest(
        route: 'app.settings',
        routeSource: ZPRouteSource.legacy,
        legacyRoute: 'settingsPage',
      );

      final coreRequest = request.toCore();

      expect(coreRequest.route, 'app.settings');
      expect(coreRequest.source, ZpRouteSource.legacy);
      expect(coreRequest.legacyRoute, 'settingsPage');
    });
  });
}
