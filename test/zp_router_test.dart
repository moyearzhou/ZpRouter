import 'package:test/test.dart';
import 'package:zp_router/zp_router.dart';

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
}
