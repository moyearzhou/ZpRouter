import 'package:flutter/material.dart';

import 'zp_page_route.dart';
import 'zp_route_request.dart';
import 'zp_route_result.dart';

class ZpNavigator {
  static final ZpNavigator instance = ZpNavigator._internal();

  factory ZpNavigator() => instance;

  ZpNavigator._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  ZpPageResolver? _pageResolver;
  ZpPageRouteBuilder _pageRouteBuilder = zpPlatformPageRoute;

  void configure({
    required ZpPageResolver pageResolver,
    ZpPageRouteBuilder pageRouteBuilder = zpPlatformPageRoute,
  }) {
    _pageResolver = pageResolver;
    _pageRouteBuilder = pageRouteBuilder;
  }

  @visibleForTesting
  void resetForTest() {
    _pageResolver = null;
    _pageRouteBuilder = zpPlatformPageRoute;
  }

  Future<T> push<T extends Object?>(
    String name, {
    Map<String, dynamic>? arguments,
    bool withContainer = false,
    bool opaque = true,
  }) async {
    final context = _requireContext();
    final route = _requireRoute(
      _buildRequestRoute(
        ZpRouteRequest(
          route: name,
          params: <String, Object?>{
            ...?arguments,
          },
        ),
      ),
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
      _buildRequestRoute(normalizedRequest),
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
      _buildRequestRoute(
        ZpRouteRequest(
          route: name,
          params: <String, Object?>{
            ...?arguments,
          },
        ),
      ),
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
      _buildRequestRoute(normalizedRequest),
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

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    final params = arguments is Map<String, Object?>
        ? arguments
        : arguments is Map<String, dynamic>
            ? arguments.map<String, Object?>(
                (key, value) => MapEntry<String, Object?>(key, value),
              )
            : arguments == null
                ? const <String, Object?>{}
                : <String, Object?>{'value': arguments};
    return _buildRequestRoute(
      ZpRouteRequest(route: settings.name ?? '', params: params),
      settings: settings,
    );
  }

  Route<dynamic>? _buildRequestRoute(
    ZpRouteRequest request, {
    RouteSettings? settings,
  }) {
    final resolver = _pageResolver;
    if (resolver == null) {
      throw StateError('ZpNavigator pageResolver is not configured');
    }
    return _pageRouteBuilder(
      Builder(
        builder: (context) {
          // Resolve pages inside the route builder so MaterialApp.onGenerateRoute
          // does not depend on navigatorKey.currentContext during app startup.
          return resolver(context, request) ??
              ErrorWidget('Route not found: ${request.route}');
        },
      ),
      settings ??
          RouteSettings(
            name: request.route,
            arguments: request.params,
          ),
    );
  }

  ZpRouteRequest _normalizeRequest(Object request) {
    if (request is ZpRouteRequest) {
      return request;
    }

    throw ArgumentError.value(
      request,
      'request',
      'Expected ZpRouteRequest',
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
