enum ZpRouteResultType {
  success,
  invalidParams,
  unknownRoute,
  loginRequired,
  limited,
  failed,
}

class ZpRouteResult {
  const ZpRouteResult({
    required this.type,
    required this.route,
    this.reason = '',
    this.paramKey,
  });

  const ZpRouteResult.success({
    required String route,
  }) : this(
          type: ZpRouteResultType.success,
          route: route,
          reason: 'success',
        );

  final ZpRouteResultType type;
  final String route;
  final String reason;
  final String? paramKey;

  bool get isSuccess => type == ZpRouteResultType.success;
}

class ZpRouteValidationResult {
  const ZpRouteValidationResult._({
    required this.valid,
    required this.route,
    required this.reason,
    required this.params,
    this.paramKey,
  });

  const ZpRouteValidationResult.valid({
    required String route,
    required Map<String, Object?> params,
  }) : this._(
          valid: true,
          route: route,
          reason: 'success',
          params: params,
        );

  const ZpRouteValidationResult.invalid({
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
