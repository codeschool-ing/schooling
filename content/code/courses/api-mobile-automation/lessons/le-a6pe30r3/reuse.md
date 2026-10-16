---
title: A token feature, called once
version: 1
---

**A feature can call another feature, the way one Java method calls another, and get back the
variables it defined.** The order scenarios need a token, and asking for it is four steps nobody
wants to copy into every file. So the token request becomes a feature of its own, which the
others call with the client they want and which answers with the token.

Save it as `karate/src/test/java/boxoffice/token.feature`:

```
@ignore
Feature: A token for one client, called by other features

  Scenario: ask for a token
    Given url baseUrl
    And path 'oauth', 'token'
    And form field grant_type = 'client_credentials'
    And form field client_id = clientId
    And form field client_secret = clientSecret
    When method post
    Then status 200
    * def token = response.access_token
```

- **`@ignore`** above `Feature:` is a tag, and the runner skips features tagged so. Without it,
  `BoxofficeTest` would run this file as a test of its own, with no `clientId`, and fail.
- **`form field`** sends the fields as a form, as `formParam` did in lesson 7.
- `clientId` and `clientSecret` are not defined anywhere in the file: they arrive from whoever
  calls it. **`* def token = response.access_token`** defines a variable, and every variable a
  called feature defines comes back to the caller.

Then the orders. Save it as `karate/src/test/java/boxoffice/orders.feature`:

```
Feature: Orders, which need a token

  Background:
    * def ci = callonce read('token.feature') { clientId: 'ci-tests', clientSecret: 'ci-secret' }
    * url baseUrl
    * configure headers = { Authorization: '#("Bearer " + ci.token)' }

  Scenario: an order can be read back
    Given path 'v1', 'orders'
    And request { show_id: 'sh-101', seats: 2 }
    When method post
    Then status 201
    And match response == { id: '#regex ord-[0-9]+', show_id: 'sh-101', seats: 2, total_cents: 16000, status: 'confirmed', payment: '#string' }
    * def id = response.id

    Given path 'v1', 'orders', id
    When method get
    Then status 200
    And match response.status == 'confirmed'

  Scenario: the auditor may read and not buy
    * def auditor = call read('token.feature') { clientId: 'auditor', clientSecret: 'auditor-secret' }
    * configure headers = { Authorization: '#("Bearer " + auditor.token)' }
    Given path 'v1', 'orders'
    And request { show_id: 'sh-101', seats: 1 }
    When method post
    Then status 403
    And match responseHeaders['www-authenticate'][0] contains 'insufficient_scope'
```

## call, callonce and the Background

The `Background` runs before each scenario, and its first step uses **`callonce`**: the first
scenario of the file runs `token.feature` and keeps what it returned, and every later scenario of
the same file gets the kept result without a new request. `call` runs the feature every time, which
is what the auditor's scenario wants for its one token. `read('token.feature')` finds the file
beside this one, and the JSON after it becomes the caller's variables inside it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 258\" role=\"img\" aria-label=\"orders.feature has two scenarios. Before scenario 1, the Background runs callonce on token.feature, which sends POST /oauth/token as ci-tests and returns a token that is kept. Before scenario 2, callonce hands back the kept token without a request, and the scenario then uses call to run token.feature again as auditor, which sends a second POST /oauth/token.\"><defs><marker id=\"f08calls-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">orders.feature</text><text x=\"575\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">token.feature</text><rect x=\"20\" y=\"30\" width=\"220\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an order can be read back</text><text x=\"130\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">scenario 1</text><rect x=\"20\" y=\"170\" width=\"220\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the auditor may read and not buy</text><text x=\"130\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">scenario 2</text><rect x=\"470\" y=\"30\" width=\"210\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs, as ci-tests</text><text x=\"575\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /oauth/token</text><rect x=\"470\" y=\"170\" width=\"210\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">runs, as auditor</text><text x=\"575\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /oauth/token</text><rect x=\"285\" y=\"102\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">kept: ci.token</text><line x1=\"240\" y1=\"55\" x2=\"468\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"354\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">callonce</text><line x1=\"520\" y1=\"80\" x2=\"437\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"505\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">returns the token</text><line x1=\"320\" y1=\"142\" x2=\"242\" y2=\"175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"250\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">callonce: no request</text><line x1=\"240\" y1=\"195\" x2=\"468\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"354\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">call</text><text x=\"350\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the Background runs before each scenario; callonce asks only the first time</text></svg>", "caption": "callonce runs the token feature for the first scenario and hands the kept result to the rest; call runs it every time."}
```

**`configure headers` sets headers for every request that follows**, until something configures
them again. That is the difference from the `header` step, which adds a header to the next request
only: written in the `Background`, `header` would put the token on the order and leave it off the
`GET` that reads the order back. The `#( … )` around the value is Karate's way of saying "compute
this", here gluing `Bearer ` to the token.

The first scenario makes two requests in a row, a `POST` and a `GET`, and passes a value between
them with `* def id = response.id`, the way lesson 7 used `extract()`. Run the feature and look at
what boxoffice saw:

```
ana@laptop:~/boxoffice/karate$ mvn -q test -Dkarate.options=classpath:boxoffice/orders.feature
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
ana@laptop:~/boxoffice/karate$ echo $?
0
```

```
POST /oauth/token 200
POST /v1/orders 201
GET /v1/orders/ord-1001 200
POST /oauth/token 200
POST /v1/orders 403
```

Two token requests: `ci-tests` once, by `callonce`, and `auditor` once, by `call`. Then the order,
the read-back with the token still on it, and the auditor's refused `POST`.

## The test that was wrong

The auditor's scenario reconfigures the headers rather than adding one. Here is why. Replace its
`configure headers` line with `And header Authorization = 'Bearer ' + auditor.token`, which reads
just as well, and run the feature:

```
ana@laptop:~/boxoffice/karate$ mvn -q test -Dkarate.options=classpath:boxoffice/orders.feature
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[ERROR] Tests run: 2, Failures: 0, Errors: 1, Skipped: 0, Time elapsed: 0.800 s <<< FAILURE! -- in boxoffice.BoxofficeTest
[ERROR] boxoffice.BoxofficeTest.[2:21] the auditor may read and not buy -- Time elapsed: 0.006 s <<< ERROR!
io.karatelabs.core.KarateException: 
expected status: 403, actual: 201
/home/ana/boxoffice/karate/target/test-classes/boxoffice/orders.feature:27
	at <feature>.Then status 403(/home/ana/boxoffice/karate/target/test-classes/boxoffice/orders.feature:27)
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
[ERROR]   BoxofficeTest.[2:21] the auditor may read and not buy » Karate expected status: 403, actual: 201
/home/ana/boxoffice/karate/target/test-classes/boxoffice/orders.feature:27
[ERROR] Tests run: 2, Failures: 0, Errors: 1, Skipped: 0
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

`expected status: 403, actual: 201`. **boxoffice did nothing wrong**: the `configure headers` of
the `Background` still applied, it won over the `header` step, and the request went out with the
`ci-tests` token, which may buy. The scenario bought a seat and called it a failure of the
server's permissions. A red test is a claim that something is broken, and before writing it up as
a defect, check what the test sent, which is what the report of section 07 shows for every step.
Put the `configure headers` line back.
