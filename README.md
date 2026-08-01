# EverQuest Semantic Conventions

OpenTelemetry semantic conventions for **EverQuest** telemetry emitted by the
[Zeal](https://github.com/coastalredwood/Zeal) client over OTLP/HTTP.

This is a [Weaver](https://github.com/open-telemetry/weaver) semantic-convention
registry. It defines the `everquest.*` attribute namespace and the telemetry signals
(metrics, and — as they land — logs and spans) that the EverQuest observability
stack produces and consumes, so the game client, the backend, and dashboards all
share one contract.

## Layout

The `model/` directory is the registry root (Weaver's `[model]` sub-folder
convention): it holds the manifest alongside the model files.

```
model/
  manifest.yaml          # registry manifest (name, description, schema_url)
  registry/eq.yaml       # the eq.* attribute registry
  metrics/combat.yaml    # metric definitions (everquest.combat.damage, ...)
```

## Attributes (`everquest.*`)

| Attribute | Type | Brief |
|---|---|---|
| `everquest.character.name` | string | Player character name (may be personal data) |
| `everquest.character.class` | string | Character class/archetype |
| `everquest.zone.id` | int | Numeric zone id |
| `everquest.zone.name` | string | Human-readable zone name |
| `everquest.chat.color` | int | EQ chat color index (message channel/category) |
| `everquest.combat.direction` | enum `outgoing`/`incoming` | Damage direction relative to the player |
| `everquest.combat.damage.type` | string | Damage kind (melee verb, or `spell`) |
| `everquest.spell.name` | string | Spell/song name |
| `everquest.discipline.name` | string | Active combat discipline |

## Metrics

| Metric | Instrument | Unit | Attributes |
|---|---|---|---|
| `everquest.combat.damage` | counter | `{hitpoint}` | `everquest.combat.direction`, `everquest.combat.damage.type` |

Aggregating `everquest.combat.damage` across all attributes gives total hit points of
damage; splitting by `eq.combat.direction` separates the player's output (the
basis of a DPS meter) from damage taken.

## Code generation

The registry is the source of truth for names. Regenerate the C++ constants Zeal compiles against:

```bash
./generate.sh                 # writes ../NewZeal/Zeal/everquest_semconv.h
```

A mistyped attribute then fails to compile instead of silently splitting a timeseries.

## Validate with Weaver

```bash
weaver registry check -r model --future
```

## Status

All conventions are `development` stability — expect breaking changes while the
model matures alongside the Zeal OTLP exporter.
