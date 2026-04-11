# Gallimaufry

A Quarto filter extension bundling a gallimaufry of opt-in Lua filters.

## Installation

```bash
quarto add mcanouil/quarto-gallimaufry
```

## Usage

```yaml
filters:
  - gallimaufry
extensions:
  gallimaufry:
    count-cite: true
```

All filters are disabled by default.
Enable a filter by setting its flag to `true` under `extensions.gallimaufry`.
Format-specific filters self-gate on the output format, so enabling a Typst-only filter while rendering to HTML is a safe no-op.

## Examples

- Per-filter examples in [examples/](examples/).
