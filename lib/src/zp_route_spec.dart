import 'zp_route_param_spec.dart';
import 'zp_route_result.dart';

enum ZpLoginPolicy {
  none,
  loginOptional,
  loginRequired,
  zoteroOptional,
  zoteroRequired,
}

enum ZpFallbackType {
  none,
  safePage,
  login,
  limited,
  invalidParams,
}

class ZpRouteSpec {
  const ZpRouteSpec({
    required this.route,
    required this.path,
    required this.loginPolicy,
    required this.fallbackType,
    this.params = const <String, ZpRouteParamSpec>{},
    this.preserveUnknownParams = true,
  });

  final String route;
  final String path;
  final ZpLoginPolicy loginPolicy;
  final ZpFallbackType fallbackType;
  final Map<String, ZpRouteParamSpec> params;

  /// Keeps page-constructor arguments that are not part of the public schema.
  final bool preserveUnknownParams;

  List<String> get paramKeys => params.keys.toList(growable: false);

  ZpRouteValidationResult validate(Map<String, Object?> input) {
    final normalized = preserveUnknownParams
        ? <String, Object?>{...input}
        : <String, Object?>{};

    for (final entry in params.entries) {
      final key = entry.key;
      final spec = entry.value;
      final hasValue = input.containsKey(key);
      final value = hasValue ? input[key] : spec.defaultValue;

      if (!spec.accepts(value)) {
        return ZpRouteValidationResult.invalid(
          route: route,
          reason: hasValue ? 'invalidParam' : 'missingRequiredParam',
          paramKey: key,
        );
      }

      if (hasValue || spec.defaultValue != null) {
        normalized[key] = value;
      }
    }

    return ZpRouteValidationResult.valid(
      route: route,
      params: normalized,
    );
  }
}
