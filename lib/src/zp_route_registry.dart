import 'zp_route_spec.dart';

class ZpRouteRegistry {
  ZpRouteRegistry(Iterable<ZpRouteSpec> specs)
      : _specs = Map<String, ZpRouteSpec>.unmodifiable(
          <String, ZpRouteSpec>{
            for (final spec in specs) spec.route: spec,
          },
        );

  final Map<String, ZpRouteSpec> _specs;

  ZpRouteSpec? specOf(String route) => _specs[route];

  bool contains(String route) => _specs.containsKey(route);

  List<ZpRouteSpec> get specs => _specs.values.toList(growable: false);

  List<String> get routes => _specs.keys.toList(growable: false);
}
