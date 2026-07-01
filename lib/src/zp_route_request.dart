enum ZpRouteSource {
  internal,
  legacy,
  external,
}

class ZpRouteRequest {
  const ZpRouteRequest({
    required this.route,
    this.version = 1,
    this.source = ZpRouteSource.internal,
    this.legacyRoute,
    this.params = const <String, Object?>{},
  });

  final String route;
  final int version;
  final ZpRouteSource source;
  final String? legacyRoute;
  final Map<String, Object?> params;

  ZpRouteRequest copyWith({
    String? route,
    int? version,
    ZpRouteSource? source,
    String? legacyRoute,
    Map<String, Object?>? params,
  }) {
    return ZpRouteRequest(
      route: route ?? this.route,
      version: version ?? this.version,
      source: source ?? this.source,
      legacyRoute: legacyRoute ?? this.legacyRoute,
      params: params ?? this.params,
    );
  }
}
