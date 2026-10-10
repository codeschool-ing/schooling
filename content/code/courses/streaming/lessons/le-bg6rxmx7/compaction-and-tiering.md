---
title: Compaction and tiered storage, two ways to keep less
version: 1
---

Retention by time throws away the oldest messages whatever they say. Two other arrangements keep
data for longer without paying for all of it at the price of a broker's disk.

## Compaction: keep the last value of each key

**A compacted topic is bounded by the number of keys, not by time.** With
`cleanup.policy=compact`, the broker's cleaner removes every message that a later message with the
same key has replaced, so the topic tends towards one message per key: the current state of each
one. Lesson 3 watched it happen.

That fits a topic that holds state rather than history. Ponto Final's stock per book, published as a
message keyed by the book every time it changes, is eight keys however many sales there are: after
cleaning, the topic is eight messages and some recent ones the cleaner has not reached. The sales
themselves could never be compacted, because each sale is its own fact; compacting by shop would keep
one sale per shop and throw away the day.

Compaction has costs of its own, and they are not on the disk:

- **The cleaner works.** It reads and rewrites segments in the background, which is processor time
  and disk reads on every broker, scaled by how often keys change.
- **"Last value" only means anything with a key.** A message without one cannot be compacted, and a
  compacted topic refuses it.
- **A deleted key needs a tombstone**, a message with the key and no value, and the tombstone itself
  is kept for `delete.retention.ms` (a day by default) so that consumers see the deletion.

Retention and compaction combine: `cleanup.policy=compact,delete` keeps the last value per key, and
also drops everything older than the retention.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Above, a topic of stock updates keyed by book, in the order they were written: bk-01, bk-02, bk-01, bk-03, bk-02, bk-01. Below, the same topic after compaction: only the last message for each key remains, bk-03, bk-02 and bk-01, at their original offsets.\" data-fig=\"l17-compact\"><defs><marker id=\"l17-compact-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">before cleaning</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">after cleaning</text><rect x=\"150\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"189.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"189.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bk-01: 12</text><rect x=\"238\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"277.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"277.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bk-02: 7</text><rect x=\"326\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"365.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"365.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">bk-01: 11</text><rect x=\"414\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"453.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-03: 4</text><rect x=\"414\" y=\"130\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"453.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"453.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-03: 4</text><line x1=\"453.0\" y1=\"84\" x2=\"453.0\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-compact-ah-0)\"></line><rect x=\"502\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"541.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-02: 6</text><rect x=\"502\" y=\"130\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"541.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"541.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-02: 6</text><line x1=\"541.0\" y1=\"84\" x2=\"541.0\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-compact-ah-0)\"></line><rect x=\"590\" y=\"40\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"629.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-01: 9</text><rect x=\"590\" y=\"130\" width=\"78\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"629.0\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"629.0\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">bk-01: 9</text><line x1=\"629.0\" y1=\"84\" x2=\"629.0\" y2=\"126\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-compact-ah-0)\"></line><text x=\"277\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replaced by a later value</text></svg>", "caption": "Compaction keeps the last value of each key: the topic is bounded by its keys, not by time."}
```

## Tiered storage: old segments somewhere cheaper

**Tiered storage moves closed segments from the broker's disk to an object store**, the kind of
storage cloud providers sell by the gigabyte-month at a fraction of the price of a fast disk, and
keeps only the recent segments locally. Consumers reading recent data are served from the local
disk as before; a consumer replaying last month is served from the object store, more slowly.

Kafka has it since version 3.6 and made it ready for production in 3.9: `remote.log.storage.system.enable`
on the brokers, `remote.storage.enable` on the topic, and two retention settings instead of one,
`local.retention.ms` for the broker's disk and `retention.ms` for the whole. What Kafka does not ship
is the piece that talks to a particular object store; that is a plugin, from the store's vendor or
from a third party. **Tiered storage was not run for this course**: the lab has no object store, and
installing a plugin to write to a local directory would demonstrate the configuration and not the
economics.

The arithmetic of the last section is where it pays. When retention is long and replays are rare,
most of the bytes are old and read almost never; moving them to cheaper storage cuts the largest
line on the bill. When retention is a week and every consumer reads within minutes, the saving is
small and the plugin is one more thing to operate.

| arrangement | bounded by | fits |
|---|---|---|
| `delete` (the default) | time, or bytes per partition | events, history, anything replayed within the retention |
| `compact` | the number of keys | current state per key: stock, prices, a customer's address |
| tiered | time, at two prices | long retention with rare reads of the old part |
