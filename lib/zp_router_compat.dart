library zp_router_compat;

import 'zp_router.dart';

export 'zp_router.dart';

enum ZPRouteSource {
  internal,
  legacy,
}

enum ZPRouteParamType {
  string,
  int,
  bool,
  stringList,
  object,
}

enum ZPLoginPolicy {
  none,
  loginOptional,
  loginRequired,
  zoteroOptional,
  zoteroRequired,
}

enum ZPFallbackType {
  login,
  limited,
  invalidParams,
  unknownRoute,
  safePage,
}

enum ZPRouteResultType {
  success,
  limited,
  invalidParams,
  loginRequired,
  unknownRoute,
  failed,
}

class ZPRouteParamSpec {
  const ZPRouteParamSpec({
    required this.type,
    this.required = false,
    this.defaultValue,
    this.allowedValues,
    this.sensitive = false,
  });

  final ZPRouteParamType type;
  final bool required;
  final Object? defaultValue;
  final Set<Object?>? allowedValues;
  final bool sensitive;

  bool accepts(Object? value) {
    if (value == null) return !required;
    if (allowedValues != null && !allowedValues!.contains(value)) {
      return false;
    }

    return switch (type) {
      ZPRouteParamType.string => value is String,
      ZPRouteParamType.int => value is int,
      ZPRouteParamType.bool => value is bool,
      ZPRouteParamType.stringList => value is List<String> ||
          (value is List && value.every((item) => item is String)),
      ZPRouteParamType.object => true,
    };
  }

  ZpRouteParamSpec toCore() {
    return ZpRouteParamSpec(
      type: _ZPRouteCompat.paramType(type),
      required: required,
      defaultValue: defaultValue,
      allowedValues: allowedValues,
      sensitive: sensitive,
    );
  }
}

class ZPRouteRequest {
  const ZPRouteRequest({
    required this.route,
    this.version = 1,
    this.routeSource = ZPRouteSource.internal,
    this.params = const <String, Object?>{},
    this.legacyRoute,
  });

  final String route;
  final int version;
  final ZPRouteSource routeSource;
  final Map<String, Object?> params;
  final String? legacyRoute;

  ZpRouteRequest toCore() {
    return ZpRouteRequest(
      route: route,
      version: version,
      source: _ZPRouteCompat.source(routeSource),
      legacyRoute: legacyRoute,
      params: params,
    );
  }
}

class ZPRouteSpec {
  const ZPRouteSpec({
    required this.route,
    required this.path,
    required this.loginPolicy,
    required this.fallbackType,
    this.params = const <String, ZPRouteParamSpec>{},
  });

  final String route;
  final String path;
  final ZPLoginPolicy loginPolicy;
  final ZPFallbackType fallbackType;
  final Map<String, ZPRouteParamSpec> params;

  List<String> get paramKeys => params.keys.toList(growable: false);

  ZPRouteValidationResult validate(Map<String, Object?> input) {
    final normalized = <String, Object?>{};

    for (final entry in params.entries) {
      final key = entry.key;
      final spec = entry.value;
      final hasValue = input.containsKey(key);
      final value = hasValue ? input[key] : spec.defaultValue;

      if (!spec.accepts(value)) {
        return ZPRouteValidationResult.invalid(
          route: route,
          reason: hasValue ? 'invalidParam' : 'missingRequiredParam',
          paramKey: key,
        );
      }

      if (hasValue || spec.defaultValue != null) {
        normalized[key] = value;
      }
    }

    return ZPRouteValidationResult.valid(
      route: route,
      params: normalized,
    );
  }

  ZpRouteSpec toCore({bool preserveUnknownParams = true}) {
    return ZpRouteSpec(
      route: route,
      path: path,
      loginPolicy: _ZPRouteCompat.loginPolicy(loginPolicy),
      fallbackType: _ZPRouteCompat.fallbackType(fallbackType),
      params: <String, ZpRouteParamSpec>{
        for (final entry in params.entries) entry.key: entry.value.toCore(),
      },
      preserveUnknownParams: preserveUnknownParams,
    );
  }
}

class ZPRouteValidationResult {
  const ZPRouteValidationResult._({
    required this.valid,
    required this.route,
    required this.reason,
    required this.params,
    this.paramKey,
  });

  const ZPRouteValidationResult.valid({
    required String route,
    required Map<String, Object?> params,
  }) : this._(
          valid: true,
          route: route,
          reason: 'success',
          params: params,
        );

  const ZPRouteValidationResult.invalid({
    required String route,
    required String reason,
    required String paramKey,
  }) : this._(
          valid: false,
          route: route,
          reason: reason,
          params: const <String, Object?>{},
          paramKey: paramKey,
        );

  final bool valid;
  final String route;
  final String reason;
  final Map<String, Object?> params;
  final String? paramKey;
}

class ZPRouteResult {
  const ZPRouteResult({
    required this.type,
    required this.route,
    required this.reason,
  });

  const ZPRouteResult.success(String route)
      : this(
          type: ZPRouteResultType.success,
          route: route,
          reason: 'success',
        );

  final ZPRouteResultType type;
  final String route;
  final String reason;

  bool get isSuccess => type == ZPRouteResultType.success;

  ZpRouteResult toCore() {
    return ZpRouteResult(
      type: _ZPRouteCompat.resultType(type),
      route: route,
      reason: reason,
    );
  }
}

class _ZPRouteCompat {
  const _ZPRouteCompat._();

  static ZpRouteSource source(ZPRouteSource source) {
    return switch (source) {
      ZPRouteSource.internal => ZpRouteSource.internal,
      ZPRouteSource.legacy => ZpRouteSource.legacy,
    };
  }

  static ZpRouteParamType paramType(ZPRouteParamType type) {
    return switch (type) {
      ZPRouteParamType.string => ZpRouteParamType.string,
      ZPRouteParamType.int => ZpRouteParamType.integer,
      ZPRouteParamType.bool => ZpRouteParamType.boolean,
      ZPRouteParamType.stringList => ZpRouteParamType.stringList,
      ZPRouteParamType.object => ZpRouteParamType.object,
    };
  }

  static ZpLoginPolicy loginPolicy(ZPLoginPolicy policy) {
    return switch (policy) {
      ZPLoginPolicy.none => ZpLoginPolicy.none,
      ZPLoginPolicy.loginOptional => ZpLoginPolicy.loginOptional,
      ZPLoginPolicy.loginRequired => ZpLoginPolicy.loginRequired,
      ZPLoginPolicy.zoteroOptional => ZpLoginPolicy.zoteroOptional,
      ZPLoginPolicy.zoteroRequired => ZpLoginPolicy.zoteroRequired,
    };
  }

  static ZpFallbackType fallbackType(ZPFallbackType type) {
    return switch (type) {
      ZPFallbackType.login => ZpFallbackType.login,
      ZPFallbackType.limited => ZpFallbackType.limited,
      ZPFallbackType.invalidParams => ZpFallbackType.invalidParams,
      ZPFallbackType.unknownRoute => ZpFallbackType.safePage,
      ZPFallbackType.safePage => ZpFallbackType.safePage,
    };
  }

  static ZpRouteResultType resultType(ZPRouteResultType type) {
    return switch (type) {
      ZPRouteResultType.success => ZpRouteResultType.success,
      ZPRouteResultType.limited => ZpRouteResultType.limited,
      ZPRouteResultType.invalidParams => ZpRouteResultType.invalidParams,
      ZPRouteResultType.loginRequired => ZpRouteResultType.loginRequired,
      ZPRouteResultType.unknownRoute => ZpRouteResultType.unknownRoute,
      ZPRouteResultType.failed => ZpRouteResultType.failed,
    };
  }
}
