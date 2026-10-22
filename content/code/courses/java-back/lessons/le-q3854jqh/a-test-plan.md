---
title: A test plan, run without the window
version: 1
---

REST Assured asked whether each answer is right. A load test asks how the application behaves
when many requests arrive together: how many it answers a second, and how long the slow ones take.
JMeter describes that in a **test plan**, a file with the extension `.jmx`. Its editor is a
desktop window, and most guides start there. A plan is also plain XML, small enough to read, and
the window has nothing to do with running it: **a load test runs from the command line**, on a
machine with no screen, as part of a script.

This plan sends twenty virtual readers at the catalogue. Create it in the project, where it is
versioned beside the code it tests, as `src/test/jmeter/books.jmx`. Maven ignores the directory.

```schooling-example
{
  "language": "xml",
  "file": "books.jmx",
  "parts": [
    {
      "code": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<jmeterTestPlan version=\"1.2\" properties=\"5.0\" jmeter=\"5.6.3\">\n  <hashTree>\n    <TestPlan guiclass=\"TestPlanGui\" testclass=\"TestPlan\" testname=\"Bookshop catalogue\"/>\n    <hashTree>",
      "note": "A test plan is a tree. Each element is followed by a `<hashTree>` holding its children, so the empty `<hashTree/>` after an element says it has none. This is the format JMeter's own editor saves."
    },
    {
      "code": "      <ThreadGroup guiclass=\"ThreadGroupGui\" testclass=\"ThreadGroup\" testname=\"Readers\">\n        <stringProp name=\"ThreadGroup.num_threads\">${__P(threads,20)}</stringProp>\n        <stringProp name=\"ThreadGroup.ramp_time\">${__P(rampup,2)}</stringProp>\n        <stringProp name=\"ThreadGroup.on_sample_error\">continue</stringProp>\n        <elementProp name=\"ThreadGroup.main_controller\" elementType=\"LoopController\" guiclass=\"LoopControlPanel\" testclass=\"LoopController\">\n          <boolProp name=\"LoopController.continue_forever\">false</boolProp>\n          <stringProp name=\"LoopController.loops\">${__P(loops,500)}</stringProp>\n        </elementProp>\n      </ThreadGroup>",
      "note": "A **thread group** is a set of virtual users. Each thread runs the samplers below it in order, waits for every answer, and starts again until it has gone round `loops` times. Twenty threads, started over two seconds, each going round 500 times. `${__P(threads,20)}` reads the property `threads` and falls back to 20, so a run can change the load from the command line without editing the file."
    },
    {
      "code": "      <hashTree>\n        <ConfigTestElement guiclass=\"HttpDefaultsGui\" testclass=\"ConfigTestElement\" testname=\"The bookshop\">\n          <stringProp name=\"HTTPSampler.protocol\">http</stringProp>\n          <stringProp name=\"HTTPSampler.domain\">${__P(host,localhost)}</stringProp>\n          <stringProp name=\"HTTPSampler.port\">${__P(port,8080)}</stringProp>\n        </ConfigTestElement>\n        <hashTree/>",
      "note": "Defaults for every HTTP request in the group: the scheme, the host and the port, each also a property."
    },
    {
      "code": "        <HTTPSamplerProxy guiclass=\"HttpTestSampleGui\" testclass=\"HTTPSamplerProxy\" testname=\"GET /books/{id}\">\n          <stringProp name=\"HTTPSampler.method\">GET</stringProp>\n          <stringProp name=\"HTTPSampler.path\">/books/${__Random(1,6)}</stringProp>\n          <boolProp name=\"HTTPSampler.use_keepalive\">true</boolProp>\n        </HTTPSamplerProxy>\n        <hashTree/>",
      "note": "The first **sampler**: one request per turn, to a random book from 1 to 6, the six titles of lesson 13's migration. `testname` is the label every result and every line of the report is grouped by. Keep-alive reuses the connection, as a browser or an HTTP client would."
    },
    {
      "code": "        <HTTPSamplerProxy guiclass=\"HttpTestSampleGui\" testclass=\"HTTPSamplerProxy\" testname=\"GET /books/search\">\n          <stringProp name=\"HTTPSampler.method\">GET</stringProp>\n          <stringProp name=\"HTTPSampler.path\">/books/search?q=the</stringProp>\n          <boolProp name=\"HTTPSampler.use_keepalive\">true</boolProp>\n        </HTTPSamplerProxy>\n        <hashTree/>",
      "note": "The second sampler, a search that matches two titles."
    },
    {
      "code": "        <ResponseAssertion guiclass=\"AssertionGui\" testclass=\"ResponseAssertion\" testname=\"The answer names a book\">\n          <collectionProp name=\"Asserion.test_strings\">\n            <stringProp name=\"1073884426\">\"isbn\"</stringProp>\n          </collectionProp>\n          <stringProp name=\"Assertion.test_field\">Assertion.response_data</stringProp>\n          <intProp name=\"Assertion.test_type\">16</intProp>\n        </ResponseAssertion>\n        <hashTree/>",
      "note": "JMeter already counts a 4xx or a 5xx as an error. An **assertion** checks what a status cannot: here, that the body contains `\"isbn\"`, which any book or list of books does and an error page does not. Placed beside the samplers, it applies to both. `Asserion` is misspelt in JMeter's own source, and the name of each string is its Java hash code, which is how JMeter writes it."
    },
    {
      "code": "      </hashTree>\n    </hashTree>\n  </hashTree>\n</jmeterTestPlan>"
    }
  ]
}
```

## The application, as it runs in production

A load test measures a running application, so the bookshop runs the way it ships: built into a
jar and started with `java -jar`, not inside `mvn`, whose own JVM and plugins would share the
machine with it. Build the jar. The tests have just passed, and `-DskipTests` skips them this once:

```
ana@vm:~/bookshop$ mvn -q package -DskipTests
```

In a second terminal, where `BOOKSHOP_JWT_SECRET` is set as lesson 15 arranged, start it and leave
it running:

```sh
java -jar target/bookshop-0.1.0.jar
```

## Running the plan

```
ana@vm:~/bookshop$ jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -e -o target/jmeter/report
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.thoughtworks.xstream.converters.reflection.SunUnsafeReflectionProvider (file:/home/ana/opt/apache-jmeter-5.6.3/lib/xstream-1.4.20.jar)
WARNING: Please consider reporting this to the maintainers of class com.thoughtworks.xstream.converters.reflection.SunUnsafeReflectionProvider
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
Creating summariser <summary>
Created the tree successfully using src/test/jmeter/books.jmx
Starting standalone test @ 2026 Oct 22 20:16:04 GMT-03:00 (1792710964849)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary +      1 in 00:00:00 =    3.5/s Avg:   174 Min:   174 Max:   174 Err:     0 (0.00%) Active: 3 Started: 3 Finished: 0
summary +  19999 in 00:00:15 = 1347.6/s Avg:    13 Min:     0 Max:   137 Err:     0 (0.00%) Active: 0 Started: 20 Finished: 20
summary =  20000 in 00:00:15 = 1322.4/s Avg:    13 Min:     0 Max:   174 Err:     0 (0.00%)
Tidying up ...    @ 2026 Oct 22 20:16:20 GMT-03:00 (1792710980041)
... end of run
```

Five flags, and each has a job. `-n` runs without the window. `-t` names the plan. `-l` is the
**results file**: one line per request, with its label, its time, its status and whether it
passed. `-j` puts JMeter's own log under `target/` instead of in the directory you ran it from.
`-e` builds an HTML report from the results once the run ends, and `-o` says where.

The four `WARN StatusConsoleListener` lines are about JMeter's logging configuration, and every
JMeter command prints them. The four `WARNING` lines are the same complaint lesson 1 met in Maven:
a library inside JMeter, XStream, calls `sun.misc.Unsafe`, which Java 25 warns about. They are about
JMeter, not about the bookshop, and the next step silences them.

While a run goes on, JMeter prints a `summary +` line for each stretch of it, with `Active` saying
how many threads were running. The line that matters comes at the end: `summary =`, for the whole
run. It counts 20000 requests, the twenty threads times 500 rounds times two samplers, in
COLD-TIME, at COLD-RATE requests a second. Then come the average, smallest and largest response
time in milliseconds, and the errors. None failed. The next section reads those numbers. First, run the same command
again:

```
ana@vm:~/bookshop$ jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -e -o target/jmeter/report
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
An error occurred: Cannot write to '/home/ana/bookshop/target/jmeter/report' as folder is not empty
```

JMeter refuses to write a report into a folder that already holds one. It would also have appended
the second run's lines to the same results file, so a report built from it would mix two runs.
**`-f` deletes both before the run**, and it belongs on every command you repeat.

JMeter reads `bin/setenv.sh` from its own directory at every start, if the file exists, and
`JVM_ARGS` is the variable it passes to Java. The same flag lesson 1 gave Maven silences the
warnings:

```
ana@vm:~/bookshop$ echo 'JVM_ARGS="$JVM_ARGS --sun-misc-unsafe-memory-access=allow"' > ~/opt/apache-jmeter-5.6.3/bin/setenv.sh
```

```
ana@vm:~/bookshop$ time jmeter -n -t src/test/jmeter/books.jmx -l target/jmeter/results.jtl -j target/jmeter/jmeter.log -f -e -o target/jmeter/report
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using src/test/jmeter/books.jmx
Starting standalone test @ 2026 Oct 22 20:16:24 GMT-03:00 (1792710984070)
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary +  10497 in 00:00:06 = 1790.7/s Avg:     9 Min:     0 Max:   108 Err:     0 (0.00%) Active: 20 Started: 20 Finished: 0
summary +   9503 in 00:00:04 = 2533.5/s Avg:     7 Min:     0 Max:   167 Err:     0 (0.00%) Active: 0 Started: 20 Finished: 20
summary =  20000 in 00:00:10 = 2080.3/s Avg:     8 Min:     0 Max:   167 Err:     0 (0.00%)
Tidying up ...    @ 2026 Oct 22 20:16:33 GMT-03:00 (1792710993752)
... end of run

real	0m12.874s
user	0m10.597s
sys	0m0.892s
```

`time` is the shell's, and it measures JMeter itself: the elapsed time, and the processor time JMeter used. The next section needs both.

The report is a directory of HTML. Open `target/jmeter/report/index.html` in a browser and it
shows the same run as tables and charts: a summary of requests that passed and failed, statistics
per label, and response times over the course of the run.

```
ana@vm:~/bookshop$ ls target/jmeter target/jmeter/report
target/jmeter:
jmeter.log
report
results.jtl

target/jmeter/report:
content
index.html
sbadmin2-1.0.7
statistics.json
```
