## 私有 pub 安装

```yaml
dependencies:
  zp_router:
    hosted: https://pub.zotpaper.cn
    version: ^1.0.2
```

先配置私有仓库 token，再执行 `flutter pub get`。本地联调可使用不提交的 `pubspec_overrides.yaml`；发布验证使用无 override 的独立项目。

# ZpRouter

`ZpRouter` is a lightweight Dart routing core for ZotPaper-style modular apps.

## Goals

- Provide shared route contracts for multiple modules.
- Provide one navigation entry for app and module code.
- Keep route contracts independent from app shell, Zotero runtime state, and business models.
- Keep page construction behind host-registered resolvers.

## Non Goals

- No direct dependency on `module_base`, `module_library`, or Zotero providers.
- No app-specific page construction.

## Initial Core

- `ZpRouteRequest`: typed route request with source, version, and params.
- `ZpRouteSpec`: route contract with path, login policy, fallback type, and param specs.
- `ZpRouteParamSpec`: param type, required/default/allowed/sensitive rules.
- `ZpRouteResult`: structured dispatch / validation result.
- `ZpRouteRegistry`: immutable route spec lookup.
- `ZpRouteDispatcher`: pure dispatcher interface for host apps to implement.
- `ZpRouteRuntimeDispatcher`: default runtime chain for lookup, validation, gate, handler, fallback, and logging.
- `ZpRouteGate` / `ZpRouteFallback` / `ZpRouteLogger`: host-provided extension points for login checks, fallback routing, and observability.
- `ZpNavigator`: Flutter navigation entry with host-registered page resolver and platform route transition.

## Suggested Layering

```text
Business module
  -> builds ZpRouteRequest

Host app / Flutter module
  -> registers route specs, page resolver, login gate, fallback UI, logging
  -> delegates Route creation and navigation to ZpNavigator
```

The route contract layer still avoids app-specific login providers, page classes,
and business models. Flutter page construction stays behind the resolver
registered by the host app.
