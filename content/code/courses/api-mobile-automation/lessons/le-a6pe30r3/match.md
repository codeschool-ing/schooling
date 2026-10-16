---
title: match, and the values you cannot know
version: 1
---

**`match` compares a whole value at once, and the markers inside it say what a field must be when
you cannot say what it is.** Lesson 7 checked one field per line. A Karate test usually writes the
whole expected body as JSON and compares it in one step, which also checks that nothing is
missing, and nothing is there that should not be. The difficulty is the fields whose value changes:
an order id, a count of seats, a fingerprint. Those get a **marker** in place of a value.

Save it as `karate/src/test/java/boxoffice/match.feature`:

```
Feature: Whole responses, compared with match

  Background:
    * url baseUrl

  Scenario: every show has the same shape
    Given path 'v1', 'shows'
    When method get
    Then status 200
    And match each response.shows == { id: '#regex sh-[0-9]{3}', title: '#string', starts_at: '#string', price_cents: '#number', seats_left: '#number' }

  Scenario: one show, whole
    Given path 'v1', 'shows', 'sh-103'
    When method get
    Then status 200
    And match response == { id: 'sh-103', title: 'O Pagador de Promessas', starts_at: '2026-11-08T18:00:00-03:00', price_cents: 6500, seats_left: '#number' }
    And match header etag == '#regex "[0-9a-f]{16}"'

  Scenario: the list holds the small show
    Given path 'v1', 'shows'
    When method get
    Then status 200
    And match response.shows contains { id: 'sh-103', title: 'O Pagador de Promessas', starts_at: '#string', price_cents: 6500, seats_left: '#notnull' }

  Scenario: an error has the problem shape
    Given path 'v1', 'shows', 'sh-999'
    When method get
    Then status 404
    And match header content-type == 'application/problem+json'
    And match response == { type: 'about:blank', title: 'Not Found', status: 404, detail: '#string' }
```

## The markers

A marker is a string starting with `#`, written where a value would be:

| marker | the field must be | used here for |
|---|---|---|
| `'#string'` | text, any text | a title, a date in a list |
| `'#number'` | a number, any number | `seats_left`, which other tests change |
| `'#notnull'` | present, and not `null` | `seats_left` again, more loosely |
| `'#regex sh-[0-9]{3}'` | text the regular expression matches whole | the shape of an id |
| `'#[3]'` | an array of three | section 03's list |
| `'#ignore'` | anything, or absent | (a field the test does not care about) |

**A marker is still a check.** `'#number'` fails on `"4"`, the string, and on a missing field, so
`seats_left: '#number'` says the field exists and is a number without saying which number. That
is the right claim for a value another test can change, and it is the answer to the problem
lesson 7, section 04, solved by not asserting at all.

## The three ways to compare

- `match a == b` is strict: the same keys, the same values, nothing extra. `one show, whole` uses
  it, so a new field in boxoffice's answer fails that scenario until somebody decides whether the
  new field is right.
- `match a contains b` passes when `a` holds `b`: a list that has this item among others, an object
  that has these keys among others. `the list holds the small show` finds `sh-103` without caring
  where it sits.
- `match each a == b` applies `b` to every item of the list `a`. `every show has the same shape`
  checks all three shows against one template, and a fourth show added tomorrow is checked too.

`match header etag == …` reads a response header by name, in any case, the way lesson 1 said a
test must.

## Strict on purpose

Run the feature on its own; `-Dkarate.options` takes the path of one feature on the classpath:

```
ana@laptop:~/boxoffice/karate$ mvn -q test -Dkarate.options=classpath:boxoffice/match.feature
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
ana@laptop:~/boxoffice/karate$ echo $?
0
```

Nothing but the three `SLF4J` lines, and `0`. Now see the strictness at work: in `one show, whole`, delete `, seats_left:
'#number'` from the expected object and run it again:

```
ana@laptop:~/boxoffice/karate$ mvn -q test -Dkarate.options=classpath:boxoffice/match.feature
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[ERROR] Tests run: 4, Failures: 0, Errors: 1, Skipped: 0, Time elapsed: 0.864 s <<< FAILURE! -- in boxoffice.BoxofficeTest
[ERROR] boxoffice.BoxofficeTest.[2:12] one show, whole -- Time elapsed: 0.003 s <<< ERROR!
io.karatelabs.core.KarateException: 
match failed: EQUALS
  $ | not equal | actual has 1 more key(s) than expected - {"seats_left":4} (MAP:MAP)
  {"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500,"seats_left":4}
  {"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500}

/home/ana/boxoffice/karate/target/test-classes/boxoffice/match.feature:16
	at <feature>.And match response == { id: 'sh-103', title: 'O Pagador de Promessas', starts_at: '2026-11-08T18:00:00-03:00', price_cents: 6500 }(/home/ana/boxoffice/karate/target/test-classes/boxoffice/match.feature:16)
	at io.karatelabs.core.StepExecutor.executeMatch(StepExecutor.java:1309)
	at io.karatelabs.core.StepExecutor.execute(StepExecutor.java:225)
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
[ERROR]   BoxofficeTest.[2:12] one show, whole » Karate match failed: EQUALS
  $ | not equal | actual has 1 more key(s) than expected - {"seats_left":4} (MAP:MAP)
  {"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500,"seats_left":4}
  {"id":"sh-103","title":"O Pagador de Promessas","starts_at":"2026-11-08T18:00:00-03:00","price_cents":6500}

/home/ana/boxoffice/karate/target/test-classes/boxoffice/match.feature:16
[ERROR] Tests run: 4, Failures: 0, Errors: 1, Skipped: 0
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
```

`actual has 1 more key(s) than expected - {"seats_left":4}`, and below it the actual body and the
expected one, one above the other. **The failure names the extra field and shows its value**, so
nobody has to rerun anything with a debugger to find out what came back. Karate reports a failed
step as an error rather than a failure, `Errors: 1`; the build is red either way. Put the field
back before going on.

That strictness is a choice. Lesson 2 found that boxoffice accepts unknown fields in a request
without complaint. `==` is the opposite habit on the response side, and it notices when an API
starts saying more than its contract promised.
