import 'dart:async';

import 'zp_route_registry.dart';
import 'zp_route_request.dart';
import 'zp_route_result.dart';

class ZpRouteDispatchContext {
  const ZpRouteDispatchContext({
    this.traceId,
    this.metadata = const <String, Object?>{},
  });

  final String? traceId;
  final Map<String, Object?> metadata;
}

class ZpRouteDispatchResult<T> {
  const ZpRouteDispatchResult({
    required this.routeResult,
    this.value,
  });

  final ZpRouteResult routeResult;
  final T? value;

  bool get isSuccess => routeResult.isSuccess;
}

abstract interface class ZpRouteDispatcher<T> {
  ZpRouteRegistry get registry;

  FutureOr<ZpRouteDispatchResult<T>> dispatch(
    ZpRouteRequest request,
    ZpRouteDispatchContext context,
  );
}
