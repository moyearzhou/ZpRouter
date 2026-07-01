import 'dart:async';

import 'zp_route_registry.dart';
import 'zp_route_request.dart';
import 'zp_route_result.dart';
import 'zp_route_spec.dart';

enum ZpRouteDispatchStage {
  started,
  unknownRoute,
  invalidParams,
  gateRejected,
  fallback,
  success,
  failed,
}

class ZpRouteDispatchContext {
  const ZpRouteDispatchContext({
    this.traceId,
    this.metadata = const <String, Object?>{},
    this.startedAt,
  });

  final String? traceId;
  final Map<String, Object?> metadata;
  final DateTime? startedAt;

  int? elapsedMs(DateTime now) {
    final startedAt = this.startedAt;
    if (startedAt == null) return null;
    return now.difference(startedAt).inMilliseconds;
  }
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

class ZpRouteResolvedRequest {
  const ZpRouteResolvedRequest({
    required this.request,
    required this.spec,
  });

  final ZpRouteRequest request;
  final ZpRouteSpec spec;
}

class ZpRouteGateDecision {
  const ZpRouteGateDecision._({
    required this.allowed,
    required this.result,
  });

  const ZpRouteGateDecision.allow()
      : this._(
          allowed: true,
          result: null,
        );

  const ZpRouteGateDecision.reject(ZpRouteResult result)
      : this._(
          allowed: false,
          result: result,
        );

  final bool allowed;
  final ZpRouteResult? result;
}

class ZpRouteLogEvent {
  const ZpRouteLogEvent({
    required this.stage,
    required this.request,
    required this.context,
    this.spec,
    this.result,
    this.errorType,
    this.elapsedMs,
  });

  final ZpRouteDispatchStage stage;
  final ZpRouteRequest request;
  final ZpRouteDispatchContext context;
  final ZpRouteSpec? spec;
  final ZpRouteResult? result;
  final String? errorType;
  final int? elapsedMs;
}

typedef ZpRouteHandler<T> = FutureOr<T?> Function(
  ZpRouteResolvedRequest resolved,
  ZpRouteDispatchContext context,
);

typedef ZpRouteGate = FutureOr<ZpRouteGateDecision> Function(
  ZpRouteResolvedRequest resolved,
  ZpRouteDispatchContext context,
);

typedef ZpRouteFallback<T> = FutureOr<ZpRouteDispatchResult<T>> Function(
  ZpRouteResolvedRequest? resolved,
  ZpRouteRequest request,
  ZpRouteResult reason,
  ZpRouteDispatchContext context,
);

typedef ZpRouteLogger = void Function(ZpRouteLogEvent event);

class ZpRouteRuntimeDispatcher<T> implements ZpRouteDispatcher<T> {
  const ZpRouteRuntimeDispatcher({
    required this.registry,
    required this.handler,
    this.gate,
    this.fallback,
    this.logger,
    this.clock = DateTime.now,
  });

  @override
  final ZpRouteRegistry registry;
  final ZpRouteHandler<T> handler;
  final ZpRouteGate? gate;
  final ZpRouteFallback<T>? fallback;
  final ZpRouteLogger? logger;
  final DateTime Function() clock;

  @override
  Future<ZpRouteDispatchResult<T>> dispatch(
    ZpRouteRequest request,
    ZpRouteDispatchContext context,
  ) async {
    final startedContext = context.startedAt == null
        ? ZpRouteDispatchContext(
            traceId: context.traceId,
            metadata: context.metadata,
            startedAt: clock(),
          )
        : context;

    _log(
      ZpRouteLogEvent(
        stage: ZpRouteDispatchStage.started,
        request: request,
        context: startedContext,
        elapsedMs: _elapsedMs(startedContext),
      ),
    );

    final spec = registry.specOf(request.route);
    if (spec == null) {
      return _fallbackOrResult(
        resolved: null,
        request: request,
        result: ZpRouteResult.unknownRoute(route: request.route),
        context: startedContext,
        stage: ZpRouteDispatchStage.unknownRoute,
      );
    }

    final validation = spec.validate(request.params);
    if (!validation.valid) {
      return _fallbackOrResult(
        resolved: ZpRouteResolvedRequest(request: request, spec: spec),
        request: request,
        result: ZpRouteResult.invalidParams(
          route: request.route,
          reason: validation.reason,
          paramKey: validation.paramKey,
        ),
        context: startedContext,
        stage: ZpRouteDispatchStage.invalidParams,
      );
    }

    final normalizedRequest = request.copyWith(params: validation.params);
    final resolved = ZpRouteResolvedRequest(
      request: normalizedRequest,
      spec: spec,
    );

    final gate = this.gate;
    if (gate != null) {
      final decision = await gate(resolved, startedContext);
      if (!decision.allowed) {
        return _fallbackOrResult(
          resolved: resolved,
          request: normalizedRequest,
          result: decision.result ??
              ZpRouteResult.gateRejected(
                route: normalizedRequest.route,
                reason: 'gateRejected',
              ),
          context: startedContext,
          stage: ZpRouteDispatchStage.gateRejected,
        );
      }
    }

    try {
      final value = await handler(resolved, startedContext);
      final result = ZpRouteDispatchResult<T>(
        routeResult: ZpRouteResult.success(route: normalizedRequest.route),
        value: value,
      );
      _log(
        ZpRouteLogEvent(
          stage: ZpRouteDispatchStage.success,
          request: normalizedRequest,
          context: startedContext,
          spec: spec,
          result: result.routeResult,
          elapsedMs: _elapsedMs(startedContext),
        ),
      );
      return result;
    } catch (error) {
      final result = ZpRouteDispatchResult<T>(
        routeResult: ZpRouteResult.failed(
          route: normalizedRequest.route,
          reason: 'handlerFailed',
        ),
      );
      _log(
        ZpRouteLogEvent(
          stage: ZpRouteDispatchStage.failed,
          request: normalizedRequest,
          context: startedContext,
          spec: spec,
          result: result.routeResult,
          errorType: error.runtimeType.toString(),
          elapsedMs: _elapsedMs(startedContext),
        ),
      );
      return result;
    }
  }

  Future<ZpRouteDispatchResult<T>> _fallbackOrResult({
    required ZpRouteResolvedRequest? resolved,
    required ZpRouteRequest request,
    required ZpRouteResult result,
    required ZpRouteDispatchContext context,
    required ZpRouteDispatchStage stage,
  }) async {
    _log(
      ZpRouteLogEvent(
        stage: stage,
        request: request,
        context: context,
        spec: resolved?.spec,
        result: result,
        elapsedMs: _elapsedMs(context),
      ),
    );

    final fallback = this.fallback;
    if (fallback == null) {
      return ZpRouteDispatchResult<T>(routeResult: result);
    }

    final fallbackResult = await fallback(
      resolved,
      request,
      result,
      context,
    );
    _log(
      ZpRouteLogEvent(
        stage: ZpRouteDispatchStage.fallback,
        request: request,
        context: context,
        spec: resolved?.spec,
        result: fallbackResult.routeResult,
        elapsedMs: _elapsedMs(context),
      ),
    );
    return fallbackResult;
  }

  int? _elapsedMs(ZpRouteDispatchContext context) {
    return context.elapsedMs(clock());
  }

  void _log(ZpRouteLogEvent event) {
    final spec = event.spec;
    final request = spec == null
        ? event.request.copyWith(params: _presenceOnlyParams(event.request))
        : event.request.copyWith(params: _redactedParams(event.request, spec));
    logger?.call(
      ZpRouteLogEvent(
        stage: event.stage,
        request: request,
        context: event.context,
        spec: event.spec,
        result: event.result,
        errorType: event.errorType,
        elapsedMs: event.elapsedMs,
      ),
    );
  }

  Map<String, Object?> _redactedParams(
    ZpRouteRequest request,
    ZpRouteSpec spec,
  ) {
    return <String, Object?>{
      for (final key in request.params.keys)
        key: spec.params[key]?.sensitive == true ? '<sensitive>' : '<present>',
    };
  }

  Map<String, Object?> _presenceOnlyParams(ZpRouteRequest request) {
    return <String, Object?>{
      for (final key in request.params.keys) key: '<present>',
    };
  }
}
