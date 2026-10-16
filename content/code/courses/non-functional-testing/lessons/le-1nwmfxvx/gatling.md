---
title: Gatling, from one zip
version: 1
---

Gatling was written in Scala, and its tests were first written in Scala too, so for years
"Gatling" and "a Scala DSL" meant the same thing. **Today the same DSL exists in Java,
Kotlin, Scala and JavaScript**, and the bundle you download is set up for Java. The tests stay
code, like k6's in lesson 5, so they live in the repository and go through review; what changes
is the language, and the language is often the reason a team picks the tool. A team that writes
its services in Java or Kotlin can write its load tests in the same language, with the same
editor and the same build.

## One zip

Gatling is published on Maven Central as a bundle: a small Maven project with a wrapper, `mvnw`,
and every library it needs inside. In the VM's shell:

```sh
cd ~
curl -fsSLO https://repo.maven.apache.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/3.15.1/gatling-charts-highcharts-bundle-3.15.1-bundle.zip
unzip -q gatling-charts-highcharts-bundle-3.15.1-bundle.zip -d ~
```

The machine in the transcripts unzipped the same file the same way when it was built. It needs
the JDK from lesson 1, because Gatling compiles a simulation before it runs it. Inside, the
bundle is an ordinary Maven project:

```
ana@nft:~/gatling-charts-highcharts-bundle-3.15.1$ ls; ls src/test/java/*
README.md
mvnw
mvnw.cmd
pom.xml
src
src/test/java/boxoffice:
BoxOfficeSimulation.java

src/test/java/example:
BasicSimulation.java
```

**`src/test/java/` is where simulations go.** The example the bundle ships with,
`BasicSimulation.java`, sends its requests to a host on the internet, so it fails on a machine
with no network. The simulation below asks the box office instead.

## A simulation of the box office

Make its package directory and open the file:

```sh
cd ~/gatling-charts-highcharts-bundle-3.15.1
mkdir -p src/test/java/boxoffice && nano src/test/java/boxoffice/BoxOfficeSimulation.java
```

It is the same journey as lesson 5's script, written in Gatling's vocabulary: look at a show,
think, book a seat.

```schooling-example
{"language": "java", "file": "BoxOfficeSimulation.java", "parts": [{"code": "// gatling-charts-highcharts-bundle-3.15.1/src/test/java/boxoffice/BoxOfficeSimulation.java\npackage boxoffice;\n\nimport static io.gatling.javaapi.core.CoreDsl.*;\nimport static io.gatling.javaapi.http.HttpDsl.*;\n\nimport io.gatling.javaapi.core.*;\nimport io.gatling.javaapi.http.*;\nimport java.util.Iterator;\nimport java.util.Map;\nimport java.util.concurrent.ThreadLocalRandom;\nimport java.util.stream.Stream;\n", "note": "The first line names where the file goes: inside the bundle, under `src/test/java/`, in a package directory called `boxoffice`. The two static imports bring in Gatling's Java DSL, the vocabulary of `scenario`, `exec`, `http` and the rest, so the code below reads almost like a description of the test."}, {"code": "public class BoxOfficeSimulation extends Simulation {\n\n  HttpProtocolBuilder protocol = http\n      .baseUrl(\"http://127.0.0.1:8000\")\n      .contentTypeHeader(\"application/json\");\n", "note": "A simulation is a class that extends `Simulation`. The protocol is set once for every request: the base address, and the header saying that bodies are JSON."}, {"code": "  Iterator<Map<String, Object>> orders = Stream.generate(() -> Map.<String, Object>of(\n      \"show\", 981 + ThreadLocalRandom.current().nextInt(20),\n      \"seat\", 1 + ThreadLocalRandom.current().nextInt(300))).iterator();\n", "note": "A feeder hands each virtual user a record of values. This one never runs out: every record is a show picked at random among the twenty on sale, 981 to 1000, and a seat from 1 to 300. A CSV file of real values is the other common feeder, `csv(\"orders.csv\").random()`."}, {"code": "  ScenarioBuilder visitor = scenario(\"visitor\")\n      .feed(orders)\n      .exec(http(\"show\").get(\"/shows/#{show}\")\n          .check(status().in(200), jmesPath(\"left\").ofInt().exists()))\n      .pause(1, 3)\n      .exec(http(\"booking\").post(\"/bookings\")\n          .body(StringBody(\"{\\\"show_id\\\": #{show}, \\\"seat\\\": #{seat}, \\\"customer\\\": \\\"gatling\\\"}\"))\n          .check(status().in(201, 409)));\n", "note": "The scenario is one visitor's journey, as a chain. `#{show}` is replaced by the value the feeder gave this user. The first check accepts only a 200 and the second asks for a `left` field holding a number; the pause between the two requests is the think time, one to three seconds. The booking accepts 201 and 409, so a seat already taken is the box office answering correctly and does not count as KO."}, {"code": "  {\n    setUp(visitor.injectOpen(\n            rampUsersPerSec(1).to(3).during(5),\n            constantUsersPerSec(3).during(15)))\n        .protocols(protocol)\n        .assertions(\n            details(\"show\").responseTime().percentile(95.0).lt(Integer.getInteger(\"p95\", 200)),\n            global().failedRequests().percent().lt(1.0));\n  }\n}", "note": "The injection profile is an open model: `rampUsersPerSec` starts new users at a rate rising from 1 to 3 a second over 5 seconds, and `constantUsersPerSec` holds 3 a second for 15 more. A Gatling user runs the scenario once and leaves. The assertions are lesson 1's requirement for `GET /shows/{id}` and an error rate under 1%; a crossed assertion fails the Maven build. `Integer.getInteger` reads `-Dp95=` from the command line, with 200 when it is not given."}]}
```

**A Gatling user is a visitor who arrives, does the journey once and leaves.** That is the
difference from a k6 virtual user, which loops for as long as the scenario lasts. So
`constantUsersPerSec(3)` is three arrivals a second, whatever the box office does with them: an
open model, the same as lesson 5's arrival-rate executor. `injectClosed` is the other family,
with `constantConcurrentUsers(10)` keeping ten users inside the system at once, a new one
starting as each one leaves. The two families cannot be mixed in one injection profile, because
they answer different questions.
