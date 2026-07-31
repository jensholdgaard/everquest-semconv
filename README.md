# EverQuest Semantic Conventions

OpenTelemetry semantic conventions for **EverQuest** telemetry emitted by the
[Zeal](https://github.com/coastalredwood/Zeal) client over OTLP/HTTP.

This is a [Weaver](https://github.com/open-telemetry/weaver) semantic-convention
registry. It defines the `eq.*` attribute namespace and the telemetry signals
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
  metrics/combat.yaml    # metric definitions (eq.combat.damage, ...)
```

## Attributes (`eq.*`)

| Attribute | Type | Brief |
|---|---|---|
| `eq.character.name` | string | Player character name (may be personal data) |
| `eq.character.class` | string | Character class/archetype |
| `eq.zone.id` | int | Numeric zone id |
| `eq.zone.name` | string | Human-readable zone name |
| `eq.chat.color` | int | EQ chat color index (message channel/category) |
| `eq.combat.direction` | enum `outgoing`/`incoming` | Damage direction relative to the player |
| `eq.combat.damage.type` | string | Damage kind (melee verb, or `spell`) |
| `eq.spell.name` | string | Spell/song name |
| `eq.discipline.name` | string | Active combat discipline |

## Metrics

| Metric | Instrument | Unit | Attributes |
|---|---|---|---|
| `eq.combat.damage` | counter | `{hitpoint}` | `eq.combat.direction`, `eq.combat.damage.type` |

Aggregating `eq.combat.damage` across all attributes gives total hit points of
damage; splitting by `eq.combat.direction` separates the player's output (the
basis of a DPS meter) from damage taken.

## Validate with Weaver

```bash
weaver registry check -r model --future
```

## Status

All conventions are `development` stability — expect breaking changes while the
model matures alongside the Zeal OTLP exporter.
