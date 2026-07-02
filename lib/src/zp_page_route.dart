import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'zp_route_request.dart';

typedef ZpPageResolver = Widget? Function(
  BuildContext context,
  ZpRouteRequest request,
);

typedef ZpPageRouteBuilder = Route<dynamic> Function(
  Widget page,
  RouteSettings settings,
);

Route<dynamic> zpPlatformPageRoute(
  Widget page,
  RouteSettings settings,
) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPageRoute<dynamic>(
      builder: (_) => page,
      settings: settings,
    );
  }
  return MaterialPageRoute<dynamic>(
    builder: (_) => page,
    settings: settings,
  );
}
