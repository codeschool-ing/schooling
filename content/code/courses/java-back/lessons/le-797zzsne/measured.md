---
title: Startup and size, measured
version: 1
---

Two numbers are cheap to measure, and they are the ones people quote when they compare frameworks:
how big the jar is, and how long the application takes to start. Both are worth having, and both have
a wrong way to be read. This section takes them for `javalin-hello` and for the bookshop as lesson 7
left it, on the same machine.

Build the bookshop, list the two jars, and count the libraries packed inside the bookshop's:

```
ana@vm:~/bookshop$ mvn -B -q package
ana@vm:~/bookshop$ ls -l target/bookshop-0.1.0.jar ~/javalin-hello/target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana  9534256 Oct 22 19:44 /home/ana/javalin-hello/target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana 21580405 Oct 22 19:44 target/bookshop-0.1.0.jar
```

```
ana@vm:~/bookshop$ unzip -l target/bookshop-0.1.0.jar | grep -c "BOOT-INF/lib/.*\.jar$"
39
```

The bookshop's jar is 21.6 MB against Javalin's 9.5 MB, and the count says where the
difference lives: 39 libraries under `BOOT-INF/lib`, Tomcat, Spring, Jackson, Hibernate
Validator and what each of them needs. For a service that is deployed as a container image, a few
megabytes are rarely the problem; what those libraries do when the application starts is.

**Each framework prints its own startup time, and the two cannot be compared.** Javalin's
`started in` and Spring's `Started BookshopApplication in` each start their stopwatch at a moment the
framework chooses, and neither counts the JVM's own start before it; Spring adds `process running
for`, which does. So
measure from the outside, the way a user waiting on the first request would: from the moment
`java -jar` is launched to the first answer. Save this as `~/first-answer.sh`:

```sh
#!/usr/bin/env bash
# Start a jar, print how long it takes to answer its first request, and the
# line in which the framework reports its own startup time.
jar=$1
url=$2
log=$(mktemp)
java -jar "$jar" > "$log" 2>&1 &
pid=$!
start=$(date +%s%N)
until curl -s -o /dev/null "$url"; do
    sleep 0.02
done
echo "first answer after $(( ($(date +%s%N) - start) / 1000000 )) ms"
grep -E 'Javalin started in|Started [A-Za-z]+ in' "$log"
kill "$pid"
wait "$pid" 2> /dev/null
rm -f "$log"
```

It starts the jar in the background, keeps its log in a temporary file, and asks for the URL every 20
milliseconds until something answers. `curl` exits with 0 for any HTTP answer, even an error, and
fails only while nothing is listening, which is the moment being measured. Then it prints the
framework's own line beside the outside number, stops the process by its pid and deletes the log.
Each `for` loop starts the application three times, because one start is not a measurement:

```
ana@vm:~$ for i in 1 2 3; do bash first-answer.sh javalin-hello/target/javalin-hello-0.1.0.jar localhost:7070/books; done
first answer after 1189 ms
[main] INFO io.javalin.Javalin - Javalin started in 612ms \o/
first answer after 950 ms
[main] INFO io.javalin.Javalin - Javalin started in 490ms \o/
first answer after 1204 ms
[main] INFO io.javalin.Javalin - Javalin started in 618ms \o/
ana@vm:~$ for i in 1 2 3; do bash first-answer.sh bookshop/target/bookshop-0.1.0.jar localhost:8080/books; done
first answer after 4076 ms
2026-10-22T19:44:39.366-03:00  INFO 30387 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 3.249 seconds (process running for 3.886)
first answer after 8039 ms
2026-10-22T19:44:47.337-03:00  INFO 1779 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 6.985 seconds (process running for 7.716)
first answer after 6981 ms
2026-10-22T19:44:54.613-03:00  INFO 6792 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 5.833 seconds (process running for 6.862)
```

Read the first answers, not the self-reports: 950 to 1204 ms for Javalin, 4076 to 8039 ms for the
bookshop. On average the bookshop took about 5.7 times as long as Javalin to answer, and the lines in
between show why the self-reports mislead: on its first run Spring's own `Started ... in` says
3.249 seconds for a start that a client waited 4076 ms for. The runs also disagree with each other, by 254 ms
between Javalin's fastest and slowest and 3963 ms between the bookshop's, which is why a single
run proves nothing.

What the numbers do **not** say is as important:

- **Nothing about speed once running.** Startup is paid once per process. A service that starts and
  then answers for a week pays those seconds once that week; how fast it answers each request is a
  different measurement, and lesson 20 takes one with JMeter.
- **Nothing about the bookshop of lesson 23.** This bookshop has no database, no security and no
  metrics, and each of those adds work at start; Javalin with the same features would also be bigger
  and slower to start than `javalin-hello`.
- **Nothing beyond this machine.** Four cores shared with whatever else was running, a warm disk
  cache, three runs each. A busier machine or a container given a fraction of a core stretches every
  number, Spring's most, because it does the most work at start.

So when is the difference worth acting on? When starts are frequent and somebody waits on each one:
functions, services that scale to zero, short-lived jobs. There, Quarkus or Micronaut keep most of
Spring's conveniences and move the work out of the start, and Javalin removes it by giving the
conveniences up. Everywhere else, which is most back-end services, the seconds are paid at deploy
time, and Spring's ecosystem is what the rest of this course spends them on: data access from lesson 9,
migrations, transactions, security, logging, documentation, testing and metrics, most of them a
starter that configures itself. From lesson 9 on, the course is back in `~/bookshop`.
