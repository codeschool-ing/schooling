---
title: Log4j2, TinyLog and the lesson of Log4Shell
version: 1
---

Logback is Spring Boot's default, not the only choice, and a Java developer meets the other two
backends in this lesson's title in real projects. `~/logging-look` has a profile for each, and
`Hello.java` is the same file it was in the first section.

## Log4j2

**Log4j2** is the Apache Logging project's backend, a rewrite of the original Log4j, whose 1.x line
reached its end of life in 2015. Its reputation is throughput: **asynchronous loggers** that hand a
line to a background thread so the caller does not wait for the disk, and a garbage-free mode that
avoids creating objects per line. It also has an API of its own, `log4j-api`, which is the reason the
bookshop carries `log4j-to-slf4j`: a library written against that API still ends up in Logback.

```
ana@vm:~/logging-look$ mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P log4j2
ana@vm:~/logging-look$ java -cp "$(cat cp.txt)" Hello.java
2026-10-22T22:33:20.563038177Z main ERROR Quantity 'two' is not a number
java.lang.NumberFormatException: For input string: "two"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Hello.main(Hello.java:13)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:104)
	at java.base/java.lang.reflect.Method.invoke(Method.java:565)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.execute(SourceLauncher.java:258)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.run(SourceLauncher.java:138)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.main(SourceLauncher.java:76)

```

**One line out of four.** With no configuration file, Log4j2 writes `ERROR` and nothing below it, with
the time in UTC. Logback without a file wrote everything from `DEBUG` up. Neither default is meant for
production, and the difference is a reminder that an unconfigured backend is the backend's opinion,
not yours. In a Spring Boot application the switch is a dependency change: exclude
`spring-boot-starter-logging` and add `spring-boot-starter-log4j2`. Boot then configures Log4j2 with
the same pattern and reads the same `logging.level.*` properties, so the bookshop's lines would look
as they do now. This course does not make that change.

## TinyLog

**TinyLog** is a small backend by a small team, and its size is the point. It has a static API of its
own, `org.tinylog.Logger.info(...)` with no logger field to declare, and a provider for SLF4J, which
is what the profile adds:

```
ana@vm:~/logging-look$ mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P tinylog
ana@vm:~/logging-look$ java -cp "$(cat cp.txt)" Hello.java
2026-10-22 19:33:22 [main] Hello.main()
DEBUG: Looking up book 3
2026-10-22 19:33:22 [main] Hello.main()
INFO: Order 7 placed by ana: 2 line(s)
2026-10-22 19:33:22 [main] Hello.main()
WARN: Only 1 of 'Frankenstein' left
2026-10-22 19:33:22 [main] Hello.main()
ERROR: Quantity 'two' is not a number: java.lang.NumberFormatException: For input string: "two"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Hello.main(Hello.java:13)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:104)
	at java.base/java.lang.reflect.Method.invoke(Method.java:565)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.execute(SourceLauncher.java:258)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.run(SourceLauncher.java:138)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.main(SourceLauncher.java:76)
```

Every level, two lines per event, and the method that logged, `Hello.main()`, which neither of the
others prints by default. The size is easiest to see on disk, each total including `slf4j-api`:

```
ana@vm:~/logging-look$ for p in logback log4j2 tinylog; do mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P $p; printf '%-8s ' $p; du -ch $(tr ':' ' ' < cp.txt) | tail -n 1; done
logback  984K	total
log4j2   2.4M	total
tinylog  288K	total
```

That is why TinyLog turns up in small command-line tools, in Android apps and wherever a jar's size is
counted. It is not a backend Spring Boot configures: Boot's logging support covers Logback, Log4j2
and `java.util.logging`. A Boot application on TinyLog excludes the logging starter and loses what
this lesson used from Boot, the `logging.level.*` properties, the correlation pattern and the
structured formats, and configures everything in TinyLog's own `tinylog.properties` instead.

| | with no configuration | the jars above | in Spring Boot |
|---|---|---|---|
| Logback | every level from `DEBUG`, one line each | 984K | the default |
| Log4j2 | `ERROR` only, time in UTC | 2.4M | `spring-boot-starter-log4j2` |
| TinyLog | every level, two lines each | 288K | not supported |

For a Spring Boot service the sensible default is the one already there. Log4j2 earns the switch when
somebody has measured that logging is what slows the service down.

## Log4Shell, and what the facade could not do

In December 2021 a vulnerability in Log4j2, CVE-2021-44228 and soon called **Log4Shell**, was rated
10 out of 10 for severity, and most of the Java world spent the following weeks on it. Versions from
2.0-beta9 to 2.14.1 of `log4j-core` looked inside every message for **lookups**, expressions written
`${...}` that it replaced with a value, and one kind of lookup, JNDI, could fetch a Java class from a
server on the internet and run it. So anybody who could get a string into a log line, through a
header, a search box or a user name, could make the server run their code. Logging a request's
`User-Agent` was enough.

The facade did not protect anybody. An application that logged
through SLF4J with Log4j2 behind it handed the attacker's string, unchanged, to the same `log4j-core`
that did the lookup: **the vulnerable code was in the backend, and a facade forwards the message to the
backend**, which is its job. What the facade did buy was the cure. A project whose code spoke only
SLF4J could move to a fixed Log4j2, or to Logback, by editing its dependencies and touching no class.

Spring Boot applications on the default starter were not exposed, and the tree in the first section
shows why: `log4j-api` and `log4j-to-slf4j` are there, and `log4j-core` is not. A call to the Log4j
API in that tree goes to Logback, which has no message lookups. The week's most common command was a
dependency tree, run in every project, looking for `log4j-core` arriving through some library nobody
remembered adding.

The fix was to upgrade, and it took several releases: 2.15.0 turned the lookups off by default,
2.16.0 removed lookups in messages altogether, and 2.17.0 and 2.17.1 closed two smaller holes found
while everybody was looking. The 2.25.5 that `~/logging-look` used is long past all of them. The idea
underneath is the one `RequestIdFilter` follows on a smaller scale: **text that came from outside is
data, and nothing on the way to the log should treat it as instructions.**
