# EverQuest Semantic Conventions

OpenTelemetry semantic conventions for **EverQuest** telemetry emitted by the
[Zeal](https://github.com/coastalredwood/Zeal) client over OTLP/HTTP.

This is a [Weaver](https://github.com/open-telemetry/weaver) semantic-convention
registry. It defines the `everquest.*` attribute namespace and the telemetry signals
(metrics, logs, spans) that the EverQuest observability stack produces and consumes,
so the game client, the backend, and the dashboards all share one contract.

## Layout

The `model/` directory is the registry root (Weaver's `[model]` sub-folder
convention): it holds the manifest alongside the model files.

```
model/
  manifest.yaml               # registry manifest (name, description, schema_url)
  registry/everquest.yaml     # the everquest.* attribute registry
  registry/entities.yaml      # the everquest.character entity
  metrics/combat.yaml         # everquest.combat.damage
  metrics/heal.yaml           # everquest.combat.heal
  metrics/character.yaml      # everquest.character.attack / .haste
  metrics/group.yaml          # everquest.group.member
  spans.yaml                  # zone session and fight spans
  server/events.yaml          # eqmacemu server events
  server/metrics.yaml         # eqmacemu server metrics
  server/spans.yaml           # views of the OTel db/rpc spans the server emits
  network/metrics.yaml        # EQStream datagram counters, emitted by both peers
templates/registry/
  cpp/                        # everquest_semconv.h for Zeal
  rust/                       # everquest_semconv.rs for eqmacemu
```

## Attributes (`everquest.*`)

| Attribute | Type | Brief |
|---|---|---|
| `everquest.character.name` | string | Player character name (personal data) |
| `everquest.character.class` | string | Character class/archetype |
| `everquest.character.level` | int | Character level |
| `everquest.character.deity` | int | Deity id |
| `everquest.character.aa.unspent` | int | Unspent AA points |
| `everquest.character.stat` | string | Which base stat a value refers to |
| `everquest.zone.id` | int | Numeric zone id |
| `everquest.zone.name` | string | Human-readable zone name |
| `everquest.chat.color` | int | EQ chat color index (message channel/category) |
| `everquest.combat.source` | string | Who dealt the damage or healing |
| `everquest.combat.source_type` | enum `player`/`npc` | What kind of entity the source is |
| `everquest.combat.target` | string | What was hit (raw spawn name) |
| `everquest.combat.direction` | enum `outgoing`/`incoming` | Direction relative to the reporting player |
| `everquest.combat.damage.type` | string | Damage kind — see below |
| `everquest.group.leader` | string | The group's leader, which identifies the group; absent when solo |
| `everquest.fight.outcome` | enum `killed`/`idle`/`zoned` | How an encounter ended |
| `everquest.fight.damage.dealt` | int | Damage dealt during a fight span |
| `everquest.fight.damage.taken` | int | Damage taken during a fight span |
| `everquest.spell.name` | string | Spell/song name |
| `everquest.discipline.name` | string | Active combat discipline |

### `everquest.combat.damage.type`

The melee skill used (`slash`, `crush`, `pierce`, `bash`, `kick`, `backstab`,
`archery`, `hth`, `special`, or `melee` for anything unrecognised), `spell` for direct
spell damage, `dot` for a damage-over-time tick, or `damage_shield`.

Damage shields need an explicit test: the damage packet carries a `DmgShieldType`
(244–249) in the field that otherwise holds a `SkillType`. Without it they are
indistinguishable from spell damage (a buff-granted shield carries a spell id) or from
melee (item and innate shields carry no spell id at all).

## Metrics

| Metric | Instrument | Unit | Key attributes |
|---|---|---|---|
| `everquest.combat.damage` | counter | `{hitpoint}` | `source`, `source_type`, `target`, `direction`, `damage.type`, `zone.name`, `group.leader` |
| `everquest.combat.heal` | counter | `{hitpoint}` | `source`, `direction`, `zone.name`, `group.leader` |
| `everquest.character.attack` | gauge | `1` | `zone.name` |
| `everquest.character.haste` | gauge | `%` | `zone.name` |
| `everquest.group.member` | updowncounter | `{member}` | `group.leader`, `character.name`, `zone.name` |

Aggregating `everquest.combat.damage` across all attributes gives total hit points of
damage; splitting by `everquest.combat.direction` separates the player's output (the
basis of a DPS meter) from damage taken, and by `everquest.group.leader` separates one
group from another sharing a zone.

`everquest.group.member` is an **info-style metric**: one point of value 1 per group
member, including members who do not run the client at all and therefore emit no other
telemetry. It is a non-monotonic sum rather than a gauge, following the
[OTLP Prometheus compatibility spec](https://opentelemetry.io/docs/specs/otel/compatibility/prometheus_and_openmetrics/#info)
— the value 1 is meant to be read as a count, so aggregating away `character.name`
yields the group size. Comparing that against the set of characters reporting damage is
what makes "4 of 6 reporting" expressible.

Because every grouped member running the client reports the *same* roster, consumers
must collapse by character name (`count by (everquest_character_name)`) rather than
summing, or the group size is multiplied by the number of people reporting it.

## Spans

| Span | Kind | Brief |
|---|---|---|
| `everquest.zone.session` | internal | A stay in one zone; parents the fights within it |
| `everquest.fight` | internal | One encounter: opened on first damage, closed by a kill message, 30s of idle, or zoning |

## Server signals (`model/server`, `model/network`)

The Rust server ([eqmacemu](https://github.com/jensholdgaard/wood-blend-aurora-lark))
emits from the same registry. Its own groups live beside the client's:

| File | Holds |
|---|---|
| `model/server/events.yaml` | Every event the server logs: `everquest.login.*`, `everquest.world.*`, `everquest.zone.*` (entry, spawns, chat, consider, shop, content), `everquest.script.*`, `everquest.server.*`, `everquest.rpc.dispatch`; wire notes extend `everquest.server.wire_note` |
| `model/server/metrics.yaml` | `everquest.login.attempts`, `everquest.character.created`, `everquest.script.missing_binding`, `everquest.server.up`, `everquest.zone.movement.updates` |
| `model/network/metrics.yaml` | `everquest.network.datagrams` (+ `.retransmitted`, `.lost`, `.abandoned`): both peers emit these from their own side; packet loss is a ratio in the query |
| `model/server/spans.yaml` | `span.everquest.db.client` and `span.everquest.rpc.server`: views of the OpenTelemetry `db` and `rpc` spans the server emits as-is |

Standard signals the server reuses (`db.client.operation.duration`,
`rpc.server.call.duration`, `feature_flag.evaluation`, the `service` and
`telemetry.sdk` entities) come from the OpenTelemetry semantic conventions 1.40
dependency declared in `model/manifest.yaml` and are imported there so
`weaver registry live-check` validates them too. The server's
`scripts/weaver_check.sh` runs that live check against a running instance.

## Code generation

The registry is the source of truth for names. Regenerate the C++ constants Zeal
compiles against:

```bash
./generate.sh                          # writes ../NewZeal/Zeal/everquest_semconv.h
WEAVER=/path/to/weaver ./generate.sh   # if weaver is not on PATH
```

The Rust server takes the same constants (plus `attribute_type()` for typed OTLP export):

```bash
./generate.sh rust ../wood-blend-aurora-lark/eqmacemu/src   # writes src/everquest_semconv.rs
```

A mistyped attribute then fails to compile instead of silently splitting a timeseries.

## Validate with Weaver

```bash
weaver registry check -r model --future
```

## Status

All conventions are `development` stability — expect breaking changes while the model
matures alongside the Zeal OTLP exporter. Nothing here has consumers beyond this
project's own stack, so names are still cheap to change.
