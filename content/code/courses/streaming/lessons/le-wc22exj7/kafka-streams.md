---
title: Kafka Streams, a library in your program
version: 1
---

A Kafka Streams application is an ordinary Java program with a `main` method. **There is no server
to install and nothing to submit a job to**: the program reads its topics, keeps its state and
writes its results by itself, using the library's jars, which have been in `~/kafka/libs` since
lesson 1. This section writes one that counts sales per shop and per book, compiles it with the
JDK's `javac`, and runs it.

The description of the work is a **topology**: where records come from, what happens to them, and
where they go. You build it with a few calls on a `StreamsBuilder`, and the library runs it. Two
words carry most of it. A **KStream** is a stream of records, each one an event: a sale. A
**KTable** is a table kept up to date from a stream, one row per key, where a new record for a key
replaces the old one: the count of sales of a shop so far.

Save this as `~/work/SalesPerShop.java`:

```schooling-example
@file SalesPerShop.java
@lang java
--- The imports: the configuration, the builder, the stream type and the serialisers that turn Java strings and numbers into Kafka's bytes and back.
// SalesPerShop.java: sales counted per shop and per book, by Kafka Streams.
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.kafka.common.serialization.Serdes;
import org.apache.kafka.streams.KafkaStreams;
import org.apache.kafka.streams.StreamsBuilder;
import org.apache.kafka.streams.StreamsConfig;
import org.apache.kafka.streams.kstream.KStream;
import org.apache.kafka.streams.kstream.Produced;

--- The book is read out of the sale's JSON with a regular expression, to keep the program to Kafka's own jars. A real application would use a JSON library or, better, a schema, as lesson 6 does.
public class SalesPerShop {
    static final Pattern BOOK = Pattern.compile("\"book\": \"([^\"]+)\"");

    static String book(String sale) {
        Matcher m = BOOK.matcher(sale);
        return m.find() ? m.group(1) : "unknown";
    }

--- **The application id names everything**: the consumer group the copies share, the prefix of the topics the library creates, and the directory of its local state. Each copy running on one machine needs a state directory of its own, so the first argument names it.
    public static void main(String[] args) {
        String copy = args.length > 0 ? args[0] : "a";
        Properties p = new Properties();
        p.put(StreamsConfig.APPLICATION_ID_CONFIG, "sales-per-shop");
        p.put(StreamsConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        p.put(StreamsConfig.DEFAULT_KEY_SERDE_CLASS_CONFIG, Serdes.StringSerde.class);
        p.put(StreamsConfig.DEFAULT_VALUE_SERDE_CLASS_CONFIG, Serdes.StringSerde.class);
        p.put(StreamsConfig.STATE_DIR_CONFIG, System.getProperty("user.home") + "/streams-state/" + copy);
        p.put(StreamsConfig.COMMIT_INTERVAL_MS_CONFIG, 1000);

--- The topology. **`groupByKey` keeps the shop that is already the key**, so counting per shop needs nothing moved. `groupBy` picks a new key, the book, and that is a different matter, which section 04 opens. Each `count` is a KTable, and `toStream().to(...)` sends every change of it to an output topic, with the count as a Java `long`.
        StreamsBuilder builder = new StreamsBuilder();
        KStream<String, String> sales = builder.stream("sales");
        sales.groupByKey().count()
             .toStream().to("sales-per-shop", Produced.with(Serdes.String(), Serdes.Long()));
        sales.groupBy((shop, sale) -> book(sale)).count()
             .toStream().to("sales-per-book", Produced.with(Serdes.String(), Serdes.Long()));

--- Start it, and say what happens. The listener prints each change of state, and once the application is running, the **tasks** this copy was given: one per input partition of each part of the topology. Ctrl+C runs the shutdown hook, which closes the application cleanly.
        KafkaStreams streams = new KafkaStreams(builder.build(), p);
        streams.setStateListener((now, before) -> {
            System.out.println("state: " + before + " -> " + now);
            if (now == KafkaStreams.State.RUNNING) {
                streams.metadataForLocalThreads().forEach(t ->
                    System.out.println("tasks here: " + t.activeTasks().stream()
                        .map(a -> a.taskId().toString()).sorted().toList()));
            }
        });
        Runtime.getRuntime().addShutdownHook(new Thread(streams::close));
        streams.start();
    }
}
```

## Compiling and running it

Start from a clean cluster and the same two hundred sales as lesson 12. `./cluster.sh stop`,
`./cluster.sh new 1` and `./cluster.sh start` first, if the cluster has other topics in it:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3
```

```
ubuntu@stream:~/work$ python tills.py --count 200 --rate 0
```

`javac` compiles the file against every jar in Kafka's `libs` directory. The quotes keep the shell
from expanding the `*`, which Java expands itself:

```
ubuntu@stream:~/work$ javac -cp "$HOME/kafka/libs/*" SalesPerShop.java
```

The note is about annotation processors, which some of Kafka's jars carry and which this program
does not use; it is a note, not an error, and `SalesPerShop.class` is now beside the source. Run it
in the **second shell**, with the same classpath plus `.`, the current directory, where the class
is:

```
ubuntu@stream:~/work$ java -cp "$HOME/kafka/libs/*:." SalesPerShop a
```

It joined the group, was given six tasks, and went on running: three for the count per shop, one
per partition of `sales`, and three for the count per book. Leave it running, and in the first
shell read what it wrote. The counts are `long` numbers in binary, so the consumer is told how to
turn them back into digits:

```
ubuntu@stream:~/work$ kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-per-book --from-beginning --formatter-property print.key=true --formatter-property value.deserializer=org.apache.kafka.common.serialization.LongDeserializer --timeout-ms 5000 2>/dev/null
```

`2>/dev/null` hides two lines on standard error: the notice about the new consumer protocol from
lesson 1, and the complaint the consumer makes when `--timeout-ms` ends it. Eight books, and the
counts add up to the two hundred sales. **The output topic is the KTable's changelog as seen from
outside**: each record is the new count of one key, and the library does not send every change. It
keeps changes in a cache and sends the latest per key each time it commits, every second here, so
a key that changed forty times in a second appears once. The counts per shop are in
`sales-per-shop`, read the same way, and a shop may appear there more than once, with the last line
for each shop its total.

Stop the application with Ctrl+C in the second shell when you have read this; the next section
starts it again, twice.
