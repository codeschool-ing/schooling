---
title: The run, the summary and the report
version: 1
---

**Karate writes two records of every run: what Surefire prints in the terminal, and an HTML report
with every step of every scenario.** The terminal tells you whether to look; the report tells you
what happened. To have something worth looking at, add the defect from lesson 1 as a scenario.
Save it as `karate/src/test/java/boxoffice/head.feature`:

```
Feature: HEAD is answered like GET

  # RFC 9110, §9.1: a general-purpose server must support GET and HEAD.
  # boxoffice answers HEAD with 405, so this scenario fails until it is fixed.
  Scenario: HEAD on a show
    Given url baseUrl
    And path 'v1', 'shows', 'sh-103'
    When method head
    Then status 200
```

Lines starting with `#` are comments, and these say why the scenario exists and why it fails, as
lesson 7's `HeadTest` did. Now run everything, with no `-Dkarate.options`:

```
ana@laptop:~/boxoffice/karate$ mvn -q test
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[ERROR] Tests run: 16, Failures: 0, Errors: 1, Skipped: 0, Time elapsed: 0.929 s <<< FAILURE! -- in boxoffice.BoxofficeTest
[ERROR] boxoffice.BoxofficeTest.[1:5] HEAD on a show -- Time elapsed: 0.014 s <<< ERROR!
io.karatelabs.core.KarateException: 
expected status: 200, actual: 405
/home/ana/boxoffice/karate/target/test-classes/boxoffice/head.feature:9
	at <feature>.Then status 200(/home/ana/boxoffice/karate/target/test-classes/boxoffice/head.feature:9)
	at io.karatelabs.core.StepExecutor.executeStatus(StepExecutor.java:2390)
	at io.karatelabs.core.StepExecutor.execute(StepExecutor.java:244)
	at io.karatelabs.core.ScenarioRuntime.call(ScenarioRuntime.java:1217)
	at io.karatelabs.core.FeatureRuntime.executeScenario(FeatureRuntime.java:368)
	at io.karatelabs.core.FeatureRuntime.call(FeatureRuntime.java:202)
	at io.karatelabs.core.Suite.runFeatureSafely(Suite.java:858)
	at io.karatelabs.core.Suite.runSequential(Suite.java:843)
	at io.karatelabs.core.Suite.run(Suite.java:579)
	at io.karatelabs.core.Runner$Builder.parallel(Runner.java:973)
	at io.karatelabs.junit6.Karate.lambda$stream$0(Karate.java:316)
	at java.base/java.util.concurrent.CompletableFuture$AsyncSupply.run(CompletableFuture.java:1768)
	at java.base/java.util.concurrent.CompletableFuture$AsyncSupply.exec(CompletableFuture.java:1760)
	at java.base/java.util.concurrent.ForkJoinTask.doExec(ForkJoinTask.java:387)
	at java.base/java.util.concurrent.ForkJoinPool$WorkQueue.topLevelExec(ForkJoinPool.java:1312)
	at java.base/java.util.concurrent.ForkJoinPool.scan(ForkJoinPool.java:1843)
	at java.base/java.util.concurrent.ForkJoinPool.runWorker(ForkJoinPool.java:1808)
	at java.base/java.util.concurrent.ForkJoinWorkerThread.run(ForkJoinWorkerThread.java:188)

[ERROR] Errors: 
[ERROR]   BoxofficeTest.[1:5] HEAD on a show » Karate expected status: 200, actual: 405
/home/ana/boxoffice/karate/target/test-classes/boxoffice/head.feature:9
[ERROR] Tests run: 16, Failures: 0, Errors: 1, Skipped: 0
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:3.6.0:test (default-test) on project boxoffice-karate: 
[ERROR] 
[ERROR] See /home/ana/boxoffice/karate/target/surefire-reports for the individual test results.
[ERROR] See dump files (if any exist) [date].dump, [date]-jvmRun[N].dump and [date].dumpstream.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
ana@laptop:~/boxoffice/karate$ echo $?
1
```

Sixteen scenarios from five features: three in `shows.feature`, four in `match.feature`, two in
`orders.feature`, six rows in `seats.feature` and this one. `token.feature` is not among them,
because of its `@ignore`. The failure names the feature file and the line of the step,
`head.feature:9`, and the reason, `expected status: 200, actual: 405`. The exit code is `1`, which
is what a pipeline reads.

## The HTML report

Every run leaves its report in `target/karate-reports`:

```
ana@laptop:~/boxoffice/karate$ ls target/karate-reports target/karate-reports/feature-html
target/karate-reports:
feature-html  index.html  karate-summary.html  karate-timeline.html  res

target/karate-reports/feature-html:
boxoffice.head.html   boxoffice.orders.html  boxoffice.shows.html
boxoffice.match.html  boxoffice.seats.html
```

Open `karate-summary.html` in a browser. For this course it was opened in a headless Chromium
rather than by hand, so it is described here rather than shown. The summary page lists each feature
with its number of scenarios passed and failed, and the failed scenario, `HEAD on a show`, in a
list of failures at the top. Each feature has a page of its own in `feature-html`, and on it each
step of each scenario is a line with the time it took. Under `When method head` there is a `log`
to open, and it holds the request Karate sent and the response it got.

**That log is the evidence for a defect report**, and also the check section 05 asked for: before
calling a red scenario a defect of the server, open the step that sent the request and read what
went out. The token on the auditor's request would have been there, plainly the wrong one.

## A filter that matches nothing

`-Dkarate.options` also selects by tag, as in `--tags @smoke`, and a project with no scenario
tagged `@smoke` gives the result lesson 7 warned about:

```
ana@laptop:~/boxoffice/karate$ mvn test '-Dkarate.options=--tags @smoke' | grep 'Tests run'
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.362 s -- in boxoffice.BoxofficeTest
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
```

`Tests run: 0`, and nothing in the output calls it a problem. The `SLF4J` lines get past the
`grep` because Java prints them on the error stream, which a pipe does not carry. A tag spelled wrong in a pipeline's
command line is a suite that never runs again. **Count the tests on every run**, here as there.
