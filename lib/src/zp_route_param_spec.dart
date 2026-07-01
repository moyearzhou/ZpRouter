enum ZpRouteParamType {
  string,
  integer,
  boolean,
  stringList,
  object,
}

class ZpRouteParamSpec {
  const ZpRouteParamSpec({
    required this.type,
    this.required = false,
    this.defaultValue,
    this.allowedValues,
    this.sensitive = false,
  });

  final ZpRouteParamType type;
  final bool required;
  final Object? defaultValue;
  final Set<Object?>? allowedValues;

  /// Sensitive params must only appear as keys in logs.
  final bool sensitive;

  bool accepts(Object? value) {
    if (value == null) return !required;
    if (allowedValues != null && !allowedValues!.contains(value)) {
      return false;
    }

    return switch (type) {
      ZpRouteParamType.string => value is String,
      ZpRouteParamType.integer => value is int,
      ZpRouteParamType.boolean => value is bool,
      ZpRouteParamType.stringList => value is List<String> ||
          (value is List && value.every((item) => item is String)),
      ZpRouteParamType.object => true,
    };
  }
}
