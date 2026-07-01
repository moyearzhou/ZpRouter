import 'package:flutter/material.dart';

import 'zp_route_request.dart';
import 'zp_route_result.dart';

typedef ZpRouteFactory = Route<dynamic>? Function(
  RouteSettings settings,
  String? uniqueId,
);

typedef ZpRequestRouteFactory = Route<dynamic>? Function(
  ZpRouteRequest request,
  String? uniqueId,
  BuildContext context,
);

class ZpNavigator {
  static final ZpNavigator instance = ZpNavigator._internal();

  factory ZpNavigator() => instance;

  ZpNavigator._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ZpRouteFactory? _routeFactory;
  ZpRequestRouteFactory? _requestRouteFactory;

  void configure({
    required ZpRouteFactory routeFactory,
    ZpRequestRouteFactory? requestRouteFactory,
  }) {
    _routeFactory = routeFactory;
    _requestRouteFactory = requestRouteFactory;
  }

  @visibleForTesting
  void resetForTest() {
    _routeFactory = null;
    _requestRouteFactory = null;
  }

  Future<T> push<T extends Object?>(
    String name, {
    Map<String, dynamic>? arguments,
    bool withContainer = false,
    bool opaque = true,
  }) async {
    final context = _requireContext();
    final route = _requireRoute(
      _buildNamedRoute(name, arguments: arguments),
      name,
    );
    final result = await Navigator.of(context).push(route);
    return result as T;
  }

  Future<T> pushRequest<T extends Object?>(
    Object request, {
    bool withContainer = false,
    bool opaque = true,
  }) async {
    final normalizedRequest = _normalizeRequest(request);
    final context = _requireContext();
    final route = _requireRoute(
      _buildRequestRoute(normalizedRequest, context),
      normalizedRequest.route,
    );
    final result = await Navigator.of(context).push(route);
    return result as T;
  }

  Future<T> pushReplacement<T extends Object?>(
    String name, {
    Map<String, dynamic>? arguments,
    bool withContainer = false,
  }) async {
    final context = _requireContext();
    final route = _requireRoute(
      _buildNamedRoute(name, arguments: arguments),
      name,
    );
    final result = await Navigator.of(context).pushAndRemoveUntil(
      route,
      (Route<dynamic> route) => false,
    );
    return result as T;
  }

  Future<T> pushReplacementRequest<T extends Object?>(
    Object request, {
    bool withContainer = false,
  }) async {
    final normalizedRequest = _normalizeRequest(request);
    final context = _requireContext();
    final route = _requireRoute(
      _buildRequestRoute(normalizedRequest, context),
      normalizedRequest.route,
    );
    final result = await Navigator.of(context).pushAndRemoveUntil(
      route,
      (Route<dynamic> route) => false,
    );
    return result as T;
  }

  Future<bool> pop<T extends Object?>([T? result]) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return false;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop<T>(result);
      return true;
    }
    return false;
  }

  bool canPop() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      return false;
    }
    return Navigator.of(context).canPop();
  }

  BuildContext _requireContext() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      throw const ZpRouteException(
        ZpRouteResult(
          type: ZpRouteResultType.failed,
          route: '<unknown>',
          reason: 'navigatorContextNull',
        ),
      );
    }
    return context;
  }

  Route<dynamic>? _buildNamedRoute(
    String name, {
    Map<String, dynamic>? arguments,
  }) {
    final routeFactory = _routeFactory;
    if (routeFactory == null) {
      throw StateError('ZpNavigator routeFactory is not configured');
    }
    return routeFactory(RouteSettings(name: name, arguments: arguments), null);
  }

  Route<dynamic>? _buildRequestRoute(
    ZpRouteRequest request,
    BuildContext context,
  ) {
    final requestRouteFactory = _requestRouteFactory;
    if (requestRouteFactory != null) {
      return requestRouteFactory(request, null, context);
    }
    return _buildNamedRoute(
      request.route,
      arguments: request.params.map<String, dynamic>(
        (key, value) => MapEntry(key, value),
      ),
    );
  }

  ZpRouteRequest _normalizeRequest(Object request) {
    if (request is ZpRouteRequest) {
      return request;
    }

    final dynamic compatRequest = request;
    try {
      final coreRequest = compatRequest.toCore();
      if (coreRequest is ZpRouteRequest) {
        return coreRequest;
      }
    } on NoSuchMethodError {
      // Fall through to the typed error below.
    }

    throw ArgumentError.value(
      request,
      'request',
      'Expected ZpRouteRequest or a compat request exposing toCore()',
    );
  }

  Route<dynamic> _requireRoute(Route<dynamic>? route, String name) {
    if (route == null) {
      throw ZpRouteException(
        ZpRouteResult(
          type: ZpRouteResultType.unknownRoute,
          route: name,
          reason: 'routeNotFound',
        ),
      );
    }
    return route;
  }
}

class ZpRouteException implements Exception {
  const ZpRouteException(this.result);

  final ZpRouteResult result;

  @override
  String toString() {
    return 'ZpRouteException(type: ${result.type}, route: ${result.route}, reason: ${result.reason})';
  }
}
