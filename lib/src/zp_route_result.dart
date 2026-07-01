enum ZpRouteResultType {
  success,
  invalidParams,
  unknownRoute,
  loginRequired,
  gateRejected,
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

  const ZpRouteResult.invalidParams({
    required String route,
    required String reason,
    String? paramKey,
  }) : this(
          type: ZpRouteResultType.invalidParams,
          route: route,
          reason: reason,
          paramKey: paramKey,
        );

  const ZpRouteResult.unknownRoute({
    required String route,
  }) : this(
          type: ZpRouteResultType.unknownRoute,
          route: route,
          reason: 'unknownRoute',
        );

  const ZpRouteResult.loginRequired({
    required String route,
    String reason = 'loginRequired',
  }) : this(
          type: ZpRouteResultType.loginRequired,
          route: route,
          reason: reason,
        );

  const ZpRouteResult.gateRejected({
    required String route,
    required String reason,
  }) : this(
          type: ZpRouteResultType.gateRejected,
          route: route,
          reason: reason,
        );

  const ZpRouteResult.limited({
    required String route,
    String reason = 'limited',
  }) : this(
          type: ZpRouteResultType.limited,
          route: route,
          reason: reason,
        );

  const ZpRouteResult.failed({
    required String route,
    required String reason,
  }) : this(
          type: ZpRouteResultType.failed,
          route: route,
          reason: reason,
        );

  final ZpRouteResultType type;
  final String route;
  final String reason;
  final String? paramKey;

  bool get isSuccess =>
      type == ZpRouteResultType.success || type == ZpRouteResultType.limited;
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
