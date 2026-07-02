enum ZpRouteSource {
  internal,
  external,
}

class ZpRouteRequest {
  const ZpRouteRequest({
    required this.route,
    this.version = 1,
    this.source = ZpRouteSource.internal,
    this.params = const <String, Object?>{},
  });

  final String route;
  final int version;
  final ZpRouteSource source;
  final Map<String, Object?> params;

  ZpRouteRequest copyWith({
    String? route,
    int? version,
    ZpRouteSource? source,
    Map<String, Object?>? params,
  }) {
    return ZpRouteRequest(
      route: route ?? this.route,
      version: version ?? this.version,
      source: source ?? this.source,
      params: params ?? this.params,
    );
  }
}
