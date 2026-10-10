# How this course is authored

AUTHORING ONLY. The student never sees anything under `lab/`, and no lesson names it.

This file is the working agreement for whoever writes a lesson of `streaming`
(`co-t8j1zx8b`). Lesson 1, `lessons/le-pqqt0zyx/`, is finished and is THE MODEL:
read every file in it before writing anything — the prose voice, the section
sizes, the captures, the `schooling-example` blocks, the figure, the exercises,
the Portuguese.

## Read first

1. `CLAUDE.md` at the repository root — the rules.
2. `docs/CONTENT.md`, `docs/TEACHING.md`, `docs/EXERCISES.md`.
3. `docs/design/streaming.md` — the sheet `tools/check-design` holds us to.
4. The brief: `git show origin/claude/wonderful-cray-nrgjb2:briefs/streaming.md`.
5. Lesson 1 of this course, all of it.

## The student's machine (built in lesson 1)

A Multipass VM `stream`, Ubuntu 24.04, user `ubuntu`, with:

- `~/kafka` — Apache Kafka 4.3.1 (KRaft, no ZooKeeper); its `bin` is on PATH.
- `~/venv` — Python 3.12 venv with `confluent-kafka==2.16.0`; its `bin` is on PATH,
  so `python` and `pip` are the venv's. A lesson that needs more packages installs
  them with `pip install X==VERSION` in a `sh` fence (pinned).
- `~/work` — where every program the student saves lives. Prompts in transcripts
  are `ubuntu@stream:~/work$` (or `ubuntu@stream:~$` from home).
- `~/work/cluster.sh new 1|3`, `start`, `stop`, `status`, `kill N`, `start N`.
  Node N: clients on `localhost:9091+N`, controller on `9191+N`. A one-node
  cluster is `localhost:9092`. Data in `~/kafka-data/nodeN/log`.
- `~/work/tills.py [--count N] [--rate R] [--topic T] [--seed S]` — Ponto Final's
  tills: JSON sales keyed by shop, e.g.
  `{"sale": "nat-000002", "shop": "natal", "book": "bk-08", "qty": 2, "cents": 17980, "at": "2026-03-02T09:00:09-03:00"}`.
  Shops: recife, olinda, caruaru, natal, joao-pessoa. Books bk-01..bk-08.
  Its clock starts 2026-03-02 09:00 -03:00 and advances 1–20 s per sale.

The running example is **Ponto Final**, the fictional chain of five bookshops in
the north-east of Brazil (it appears in `warehouse-modeling` and `pipelines-etl`).
Address the student as "you". Money in cents. British spelling in English.

## The author's lab (this machine)

This container IS the student's VM as far as captures go: user `ubuntu`,
hostname `stream`, the same paths. There is ONE lab shared by several authors:

- **Every capture holds `/var/tmp/lab.lock`** (`capture-lib.sh` takes it). If you
  try something by hand that touches Kafka or any service, wrap it:
  `flock /var/tmp/lab.lock sudo bash lab.sh run '…'`. Never leave the cluster in a
  state other captures would not expect; each `captures.sh` starts from
  `lab reset 1` or `lab reset 3` (and its own topics), never from what is left.
- `sudo bash lab.sh run 'cmd'` runs as ubuntu in `~/work`, login shell.
- `sudo bash lab.sh files` extracts every `~/work/NAME` program from the lessons.
  A program is introduced by a line that names `` `~/work/NAME` `` and ENDS IN A
  COLON, then a blank line, then the fence (or `schooling-example`). Names must be
  unique across the course — use the names in the outline below.
- `sudo bash lab.sh install LESSON SECTION.md` runs that section's ```` ```sh ````
  fences as ubuntu, the way the student types them. Install sections are the ones
  listed in `TOOLS` in `lab.sh`; they must be the exact slugs below.
- `sudo bash lab.sh tools` WIPES ~ubuntu and reinstalls. **Never run it** while
  others are working.
- Background programs: start with `setsid … </dev/null &`, kill by pid. Never
  `pkill -f PATTERN` where PATTERN could match your own shell's command line
  (it killed a session already). The cluster's own processes are matched by
  `^[^ ]*java .*kafka-data/node`.

### Captures

Each lesson with a terminal has `lessons/<id>/captures.sh`, sourcing
`../../lab/capture-lib.sh` (read it: `vm`, `home`, `shown`, `term2`, `stop2`,
`wait2`, `put`, `block`). Header comment: what is STAGED rather than typed (say
it), what was NOT run. Output goes to a file, never committed:

    cd content/code/courses/streaming
    sudo bash lab.sh files
    sudo bash lessons/<id>/captures.sh > /tmp/<id>.out 2>&1
    /var/tmp/lab/bin/fill.py lessons/<id> /tmp/<id>.out

`fill.py` puts each `##### block` into the bare fence (in `.md` AND `.pt.md`)
whose first line is the block's first line, in order. So in a draft you write a
fence holding only the first line (prompt + command) and fill does the rest; it
is idempotent and re-runnable after every recapture. Two fences with the same
first line take blocks with that first line in order. To show a command as typed
before its output appears elsewhere, use `shown` in the capture.

Determinism: fixed seeds, fixed dates, TZ=America/Sao_Paulo. Anything random in
output (cluster ids, PIDs, UUIDs) is fine but the prose must not quote it. After
every recapture, re-read every number the prose quotes.

**Never invent output.** A command you could not run is marked in the prose as
not run. No TLS verification disabled, no proxy unset.

### Programs the student runs

Shown whole in the lesson (prefer `schooling-example` with notes for anything
over ~15 lines that the prose walks through; a plain fence for short ones). The
file the capture runs IS the one extracted from the lesson. Keep them small.

## Authoring tools (in /var/tmp/lab/bin; copies in lab/authoring/)

- `newid se 9` / `newid vd 1` — fresh ids, unique across the repo. Never derive.
- `render.py FILE.md FILE.pt.md` — turns a draft `schooling-example` into JSON:

      ```schooling-example
      @file x.py
      @lang python
      --- the note for the first part (ONE line)
      code lines…
      --- note for part 2
      code…
      @output
      what it printed (optional; must be real)
      ```

  In the `.pt.md`, write `@same` and one `--- nota` line per part; code and output
  are copied from the English file at the same position.
- `ptfill.py X.pt.md` — each line `@@fence@@` becomes the next plain fence of
  `X.md` (figures and examples excluded), so PT fences are byte-identical.
- `figput.py FIGMODULE X.md X.pt.md` — builds a figure (see `lab/authoring/figs/l1_batch_stream.py`
  and `/var/tmp/lab/bin/fig.py`) and puts it at `@@fig:NAME@@`, or replaces the
  existing one with `data-fig="NAME"`. PT labels via the `PT` dict; labels that
  are the same word in PT go in `SAME` (only labels containing letters).
  Palette: `--amber --ink --panel --paper --paper-dim --phosphor --phosphor-dim
  --scan --wire`. Look at it: `node tools/figure-shot/figure-shot.mjs FILE.md 0 /tmp/shots/x`
  then view the PNG. Keep figure modules in `lab/authoring/figs/`.
- `exbuild.py SPEC.py lessons/<id>` — writes `exercises.json` and
  `exercises.pt.json` from a compact spec (see `lab/authoring/specs/le-pqqt0zyx.py`):
  `Q` quiz, `MC` multiple-choice, `N` numeric, `C` cloze, `O` ordering, `M`
  matching. Keep specs in `lab/authoring/specs/<lesson-id>.py`.
- `exrank.py lessons/<id>` — the length rank of each key (1 = longest), EN and PT.
- `patchspec.py SPEC PATCH` — replace choice texts by their old English text.

## Exercises (about 24 per lesson; the drill section gets 2–4)

Types: mostly `quiz`, plus per lesson at least one each of `cloze`, `numeric` or
`ordering`, `matching`, `multiple-choice` where it fits. All `drillable: true`.
Every option has a `why`. `difficulty` per `docs/EXERCISES.md`.

What `go run ./tools/check-exercises` refuses (per lesson, EN and PT separately):

- **The key on any ONE length rank in more than 45% of quiz questions** — at
  either end or in the middle. Plan it: rotate the key's rank on purpose
  (longest / shortest / 2nd / 3rd) and lengthen or shorten distractors. My first
  draft of lesson 1 had the key longest in 89%; write against the habit.
- A student who picks by a length rule scoring over the ceiling.
- **Hedges** (EN usually, often, can, may, tends to, generally, sometimes,
  typically; PT geralmente, normalmente, pode, podem, costuma, às vezes, talvez…)
  appearing only in the correct option — text OR why. Simplest: no hedges in
  options or whys at all.
- **Echo**: the key repeating more of the prompt's words of 6+ letters than any
  other option. A cloze whose answer is a word of its own prompt.
- Position: the key in the same position too often — vary it.
- A cloze hole is exactly `___`; the PT cloze has its own accept list.
- No "all/none of the above"; never two options.

## Portuguese

Every `.md` has a `.pt.md`; `exercises.pt.json` complete. Natural Brazilian
Portuguese, not a calque. Fences byte-identical (use `ptfill.py`); figure labels
translated; example notes translated. Same `version`.

## Checks before reporting a lesson done

    export PATH=/usr/local/go1.25.1/bin:$PATH GOTOOLCHAIN=local
    cd /home/user/schooling
    go run ./tools/validate-content
    go run ./tools/check-exercises 2>&1 | grep <lesson-id>    # no " - " lines for it
    go run ./tools/check-figures 2>&1 | grep streaming        # nothing
    node tools/check-highlight/check-highlight.mjs content
    node tools/figure-fit/figure-fit.mjs

Fence labels: plain ```` ``` ```` for transcripts, or a language the highlighter
knows (`python`, `sh`, `json`, `sql`, `java`, `properties`, `yaml`, `ini`…).
Never `text`. Do not add the lesson to `course.json`'s `lessons` — the lead
does that when committing. Do NOT commit or push; the lead commits.

## Style, measured

Reading prose: median sentence about 19 words; bold for the key claim of a
paragraph (house style); lead with the shape; say what is wrong before what is
right where a wrong picture is common; every doubtful claim gets a concrete
instance; forward references name a lesson number. A reading section is about
350–700 words. Video `intro` script: 60–90 s, sentences ~13 words, no bold,
`{{mark}}` words where the scene changes, and an `intro.md`/`intro.pt.md` with
only the title. `drill` (practice) has a `drill.md` with only the title "Putting
it together" / "Juntando tudo".

No attack material. Security is taught from the defender's side.

---

# The course outline

17 lessons, ~150 sections. Section budget: intro (video) + 7 reading + drill
(practice) = 9 per lesson, ±1. Lesson ids are fixed (course.json `topics`).
The student files are the names the lesson uses; do not reuse a name.

1. **le-pqqt0zyx — Batch and streaming** (DONE). the-nightly-job, what-changes,
   when-it-pays, your-lab, building-it, first-stream, when-setup-fails.
   Files: cluster.sh, tills.py. Topic `sales` (3 partitions).

2. **le-k989vykk — Events, the log as a data structure, and why order matters.**
   Sections: what-an-event-is (fact vs command vs state; what goes in one: id,
   time, key, version; thin vs fat), the-log (append-only, offsets, readers keep
   their own position — `minilog.py`, a log in a file in ~25 lines: append,
   read from offset), state-from-the-log (fold events into state — `balance.py`
   computes stock per book from a list of events; the table/stream duality),
   why-order-matters (same events reordered → different state, captured),
   order-per-key (total order costs one writer; per-entity order is enough;
   hash the key → one place; previews lesson 3), the-log-as-integration (one
   write, many readers, each at its own pace; replay; contrast with a queue,
   lesson 15), designing-events (naming in the past tense, ids for dedup —
   lesson 8 — event time inside — lesson 9 — schema version — lesson 6).
   Files: minilog.py, balance.py. Mostly pure Python; may show Kafka at the end.

3. **le-yrqy4qc1 — Kafka: topics, partitions, offsets and retention.**
   Sections: topics-and-partitions (create/describe; partition = unit of order
   and parallelism; `kafka-topics.sh --describe`), keys-to-partitions (same key →
   same partition; console consumer with print.partition/print.offset; NOTE the
   Python client's default partitioner is librdkafka `consistent_random`
   (CRC32), Java's is murmur2 — demonstrate that the same key lands in different
   partitions from the Java console producer and from Python, and that
   `partitioner: murmur2_random` makes them agree), offsets
   (`kafka-get-offsets.sh`; offsets per partition; earliest/latest), on-disk
   (segment files `.log .index .timeindex`, `kafka-dump-log.sh
   --print-data-log`), retention (retention.ms/bytes, segment.bytes; deletion is
   per segment; show a small segment.bytes topic losing old segments and the log
   start offset moving — capture), compaction (cleanup.policy=compact; last value
   per key; tombstones; capture with small segment.ms/min.cleanable.dirty.ratio),
   choosing-partitions (more partitions = more parallelism and more cost; adding
   partitions later moves keys; never fewer).
   Files: maybe none beyond a tiny keyed producer `keys.py`.

4. **le-cffmbdb1 — Producers, consumers and consumer groups.**
   Sections: a-producer (`producer.py` as schooling-example: config, delivery
   report callback, batching linger.ms/batch.size, flush), a-consumer
   (`consumer.py`: group.id, auto.offset.reset, poll loop, printing partition
   and offset, on_assign/on_revoke callbacks), consumer-groups (two and three
   copies of consumer.py in terminals share the 3 partitions;
   `kafka-consumer-groups.sh --describe`), rebalancing (a member joins/leaves;
   assignment moves; classic eager vs cooperative; Kafka 4's new protocol
   KIP-848 `group.protocol=consumer` — check whether librdkafka 2.16 supports it
   and capture what it does), more-consumers-than-partitions (the fourth one
   idle), committing-offsets (auto commit every 5 s vs manual `commit()`;
   `__consumer_offsets`; what a commit means — previews lesson 7),
   reading-from-a-point (seek / offsets_for_times; reset with the group tool).
   Files: producer.py, consumer.py.

5. **le-ny9ardjk — Replication, in-sync replicas and what a broker failure costs.**
   `./cluster.sh new 3`. Sections: three-nodes (RF=3 topic; describe: Leader,
   Replicas, Isr), leaders-and-followers (leader takes writes; followers fetch;
   high watermark; consumers read only committed), in-sync-replicas
   (replica.lag.time.max.ms; ISR shrinks), acks (acks=0/1/all,
   min.insync.replicas=2; kill two nodes → NotEnoughReplicas, captured),
   a-node-dies (kill -9 the leader of a partition; leadership moves; producer
   keeps going; node returns; ISR grows; preferred leader election), the-
   controllers (KRaft quorum; `kafka-metadata-quorum.sh describe --status`;
   losing a majority), unclean-election (availability vs loss; off by default;
   ELR in Kafka 4 — explain the Elr column seen in describe), what-it-costs
   (3x disk, network; rack awareness — concept; this lab is one machine, so a
   real failure domain is not demonstrated: say so).
   Files: `acks.py` (produce with a given acks, report errors).

6. **le-94k5phwh — Schemas and the schema registry.**
   Sections: why-schemas (a renamed field breaks a JSON consumer silently —
   capture: `.get()` returns None, totals wrong), avro (schema, binary
   encoding, writer vs reader schema resolution with fastavro, capture),
   installing-a-registry (INSTALL SECTION, slug exact: Apicurio Registry 3.3.3
   from Maven Central `io/apicurio/apicurio-registry-app/3.3.3/apicurio-registry-app-3.3.3-all.tar.gz`,
   `java -jar quarkus-run.jar` on port 8080 in-memory; it serves a
   Confluent-compatible API at `/apis/ccompat/v7`; pip install
   `fastavro==1.13.1`, `requests` / whatever confluent-kafka's schema-registry
   extras need — pin them), the-registry (register a subject with curl; ids;
   the wire format: magic byte 0 + 4-byte id + Avro body — hexdump a message),
   producing-with-a-schema (`avro_tills.py` with AvroSerializer), compatibility
   (BACKWARD/FORWARD/FULL; add a field with default ok; remove/rename refused —
   capture the 409), evolving-safely (who upgrades first under each mode;
   JSON Schema and Protobuf mentioned).
   Files: avro_tills.py, avro_read.py.

7. **le-2q5apnvb — Delivery guarantees.**
   Sections: where-it-breaks (producer retry after a lost ack; consumer crash
   between process and commit), at-most-once (commit before processing; a
   consumer that crashes with os._exit mid-batch loses sales — count them),
   at-least-once (process then commit; crash → duplicates — count them),
   the-idempotent-producer (enable.idempotence; producer id + sequence; on by
   default in recent clients — check librdkafka's default and say what it is),
   transactions (transactional.id, begin/commit/abort; consumer isolation.level
   read_committed vs read_uncommitted, capture an aborted transaction visible to
   one and not the other), exactly-once-in-kafka (consume–transform–produce with
   send_offsets_to_transaction: `eos_copy.py`), the-edge (side effects outside
   Kafka — an email, a database row — are not covered; lesson 8).
   Files: crash_consumer.py, txn.py, eos_copy.py.

8. **le-mkxyxfag — Idempotency and deduplication downstream.**
   SQLite (Python stdlib) is the downstream store. Sections:
   idempotent-writes (set vs add; upsert), dedup-by-event-id (a processed-ids
   table written in the same SQLite transaction as the effect; replay twice →
   same totals, captured), offsets-in-the-sink (store the Kafka offset in the
   same transaction and seek to it on start; the consumer group's commit becomes
   a hint), how-long-to-remember (bounded dedup windows; memory vs risk),
   versions-and-last-writer (out-of-order updates; keep the highest version),
   the-outbox (write the event to an outbox table in the same DB transaction;
   relay it; previews CDC lesson 14), testing-for-duplicates (run the consumer
   twice over the same input; compare outputs).
   Files: stock_sink.py (and variants as needed).

9. **le-jzre5f62 — Event time against processing time.**
   Mostly Python, plus Kafka timestamps. Sections: three-clocks (event time,
   log-append/ingestion time, processing time; Kafka record timestamp CreateTime
   vs LogAppendTime — `message.timestamp.type`, capture both), skew (a till
   offline 10:20–14:00 sends a burst; `late_tills.py` produces sales whose `at`
   is hours old), out-of-order (arrival order vs event order; how far out of
   order — measure), counting-by-arrival (`per_minute.py` counts per minute by
   processing time vs by event time on the same input; different numbers,
   captured), clocks-lie (a till with a wrong clock; future timestamps;
   clamping and bounds; NTP), which-time (decision table), timestamps-in-kafka
   (producer sets the record timestamp; `print.timestamp=true`; offsets_for_times).
   Files: late_tills.py, per_minute.py.

10. **le-szves118 — Windows: tumbling, sliding and session.**
    Python implementations shown whole, run over a fixed list of events (paste-
    able). Sections: why-windows, tumbling (start = floor(t/size)*size; half-open
    [start, end)), hopping (size + advance; each event in size/advance windows),
    sliding (the word means different things: Flink's "sliding" = hopping; Kafka
    Streams' sliding windows are defined by the time difference between events —
    say so and show both), session (gap; merging when an event bridges two),
    keyed-windows (per shop), emitting-results (when a window's result is
    final — leads to lesson 11). Numeric/ordering questions with no broker
    ("given these timestamps and this window, which events are in it") are
    the most gradeable part of the course — make many.
    Files: windows.py.

11. **le-sp8kafjn — Watermarks, late data, and deciding what to do with it.**
    Sections: when-is-it-complete, watermarks (max event time seen minus a
    bound; monotonic), watermark-in-action (`watermark.py` over a fixed event
    list: windows close, a late event dropped — captured), allowed-lateness
    (keep state; update a result already emitted; append vs update downstream),
    late-data-elsewhere (side output / dead-letter topic for late events),
    choosing-the-bound (measure the lateness distribution: percentiles from
    data; latency vs completeness), idle-sources (watermark = min over
    partitions; one idle partition stalls everything; idleness timeouts).
    Files: watermark.py.

12. **le-2hfcpm40 — Spark Structured Streaming: micro-batch and continuous.**
    Sections: the-model (unbounded table, incremental query, micro-batches,
    triggers), installing-spark (INSTALL SECTION, exact slug: `pip install
    pyspark==4.1.3`; the Kafka source comes from Maven Central via
    `--packages org.apache.spark:spark-sql-kafka-0-10_2.13:4.1.3` or
    `spark.jars.packages`), reading-kafka (readStream kafka; columns key, value,
    topic, partition, offset, timestamp), a-windowed-count (from_json; groupBy
    window + withWatermark; output modes append/update/complete — capture
    batches), checkpoints (checkpointLocation; stop and restart; offsets live in
    the checkpoint, not in a consumer group), triggers (processingTime,
    availableNow, continuous — and its limits), sinks (console, files, Kafka;
    exactly-once needs an idempotent or transactional sink). Measure memory used
    (broker + Spark) and report it — lesson 1 claims under 3 GB; tell the lead
    the number.
    Files: spark_sales.py (+ variants).

13. **le-wc22exj7 — An overview of Apache Flink and Kafka Streams.**
    Sections: three-engines (Spark micro-batch; Flink record-at-a-time with
    native event time; Kafka Streams a library inside your app), kafka-streams
    (a small Java program `SalesPerShop.java` compiled with `javac -cp
    "$HOME/kafka/libs/*"`, run with `java`; KStream → groupByKey → count →
    to topic; capture), streams-state (KTable, state store, changelog and
    repartition internal topics listed with kafka-topics.sh; a second instance
    shares the work), installing-flink (INSTALL SECTION, exact slug: Flink
    2.2.1 from archive.apache.org `flink-2.2.1-bin-scala_2.12.tgz` + the jar
    `org/apache/flink/flink-sql-connector-kafka/5.0.0-2.2` from Maven Central;
    check Java 21 works), flink-sql (sql-client: CREATE TABLE with the kafka
    connector and a WATERMARK; a TUMBLE window query; captured via `-f` script
    file if interactive is awkward), flink-state (checkpoints, savepoints,
    state backends — concept + `flink list` / savepoint if feasible),
    choosing (table: latency, state, deployment, language, who runs it).
    Measure memory; tell the lead.
    Files: SalesPerShop.java, sales.sql.

14. **le-504hnm11 — Change data capture with Debezium.**
    Sections: the-dual-write (writing to the DB and to Kafka in two steps;
    the failure in between; refers back to `pipelines-etl` lesson 5 for logical
    decoding by hand), logical-decoding (wal_level=logical; replication slot;
    publication; pgoutput), installing-debezium (INSTALL SECTION, exact slug:
    `sudo apt-get install -y postgresql`; configure wal_level; Debezium
    3.7.0.Final postgres connector plugin tarball from Maven Central; Kafka
    Connect from ~/kafka in standalone mode), a-connector (connector properties;
    snapshot; topic per table), a-change-event (envelope: before, after, op,
    source, ts_ms — read with kafka-console-consumer + jq), updates-and-deletes
    (op u/d; REPLICA IDENTITY; tombstones and compaction), the-slot-holds-wal
    (stop the connector, write rows, watch `pg_replication_slots` retained WAL
    grow — the operational danger; what to monitor). On this container there is
    no systemd: start PostgreSQL with `pg_ctlcluster` and SAY in captures.sh
    header that a VM's systemd starts it automatically; the student's commands
    must be the VM's (`sudo systemctl restart postgresql`), marked as not run
    here if they could not be.
    Files: stock.sql, connector properties file(s).

15. **le-djz1b49h — RabbitMQ, Amazon SQS and SNS: when a queue beats a log.**
    Sections: queue-and-log (a queue removes on ack; competing consumers;
    no replay), installing-rabbitmq (INSTALL SECTION, exact slug: apt
    rabbitmq-server 3.12; `pip install pika==1.4.4`; `pip install
    'moto[server]==5.x'` + boto3 for an SQS/SNS emulator — name it as an
    emulator), rabbit-basics (exchange, queue, binding; pika producer/consumer;
    ack, prefetch, redelivery after a consumer dies without ack — captured),
    routing (direct/topic/fanout), dead-letters (DLX, TTL, rejected messages),
    sqs-and-sns (SQS: visibility timeout, at-least-once, FIFO with dedup id;
    SNS fan-out to SQS; captured against moto, with the prose saying it is an
    emulator and not AWS), choosing (decision table: per-message work vs
    history/replay/many readers; ordering; throughput; cost). No systemd here:
    start rabbitmq-server detached in the capture and say so.
    Files: rabbit_send.py, rabbit_work.py, sqs_demo.py.

16. **le-83cbx5tp — Operating a stream: lag, backpressure, replay and reprocessing.**
    Sections: consumer-lag (`kafka-consumer-groups.sh --describe`: CURRENT-
    OFFSET, LOG-END-OFFSET, LAG; a slow consumer `slow_consumer.py` falling
    behind tills.py at a higher rate — captured over time), lag-in-time (lag in
    messages vs seconds; compute from timestamps), backpressure (pull-based, the
    log is the buffer; max.poll.interval.ms exceeded → the member is evicted →
    rebalance loop — captured), poison-messages (one bad record stops a
    partition; a dead-letter topic), replay (reset offsets --to-datetime /
    --to-earliest --dry-run then --execute; group must be inactive — capture the
    refusal), reprocessing (new group / new output topic; blue-green switch),
    what-to-alert-on (lag growth, under-replicated partitions, offline
    partitions, disk; `kafka-topics.sh --under-replicated-partitions`).
    Files: slow_consumer.py.

17. **le-bg6rxmx7 — Cost: retention, throughput and the bill for a pipeline that never sleeps.**
    Sections: what-you-pay-for (compute always on, storage = throughput ×
    retention × replication, network incl. cross-zone), measuring-a-message
    (bytes per sale on disk: produce N sales, `kafka-log-dirs.sh --describe`,
    divide), compression (same 100 000 sales with compression.type none / gzip /
    lz4 / zstd — real sizes, captured), retention-arithmetic (worked example for
    Ponto Final: sales/day × bytes × days × RF), compaction-and-tiering (compact
    for state; tiered storage as a concept — not run), managed-or-self (pricing
    models in general — by throughput, partition-hour, storage; NO quoted prices,
    they change), the-quiet-hours (a stream costs at 3 a.m.; when batch is
    cheaper; back to lesson 1).
    Files: maybe `measure.py`.

## The exam

`exam.json` / `exam.pt.json` beside `course.json`, ~100 questions, ~6 per
lesson, not drillable — written by the lead at the end.
