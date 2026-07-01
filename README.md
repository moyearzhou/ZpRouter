# ZpRouter

`ZpRouter` is a lightweight Dart routing core for ZotPaper-style modular apps.

## Goals

- Provide shared route contracts for multiple modules.
- Keep the core independent from Flutter UI, app shell, Zotero runtime state, and business models.
- Let legacy routers such as `MyRouter` and `NeatRouter` become facade / adapter layers.

## Non Goals

- No Flutter `Route` or `BuildContext` dependency in the core package.
- No direct dependency on `module_base`, `module_library`, or Zotero providers.
- No app-specific page construction.

## Initial Core

- `ZpRouteRequest`: typed route request with source, version, params, and optional legacy route.
- `ZpRouteSpec`: route contract with path, login policy, fallback type, and param specs.
- `ZpRouteParamSpec`: param type, required/default/allowed/sensitive rules.
- `ZpRouteResult`: structured dispatch / validation result.
- `ZpRouteRegistry`: immutable route spec lookup.
- `ZpRouteDispatcher`: pure dispatcher interface for host apps to implement.
- `ZpRouteRuntimeDispatcher`: default runtime chain for lookup, validation, gate, handler, fallback, and logging.
- `ZpRouteGate` / `ZpRouteFallback` / `ZpRouteLogger`: host-provided extension points for login checks, fallback routing, and observability.

## Suggested Layering

```text
Business module
  -> builds ZpRouteRequest

Legacy MyRouter / NeatRouter
  -> facade / adapter
  -> converts old route names into ZpRouteRequest

Host app / Flutter module
  -> owns page factory / route handler, login gate, fallback UI, logging
  -> depends on ZpRouter core contracts
```

The runtime dispatcher is still UI-agnostic: it does not know about Flutter
`BuildContext`, app-specific login providers, page classes, or business models.
