---
title: Uma feature de token, chamada uma vez
version: 1
---

**Uma feature pode chamar outra feature, do jeito que um método Java chama outro, e receber de volta
as variáveis que ela definiu.** Os cenários de pedido precisam de um token, e pedi-lo são quatro
passos que ninguém quer copiar em todo arquivo. Então a requisição de token vira uma feature
própria, que as outras chamam com o cliente que querem e que responde com o token.

Salve como `karate/src/test/java/boxoffice/token.feature`:

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

- `@ignore` acima de `Feature:` é uma tag, e o runner pula as features marcadas assim. Sem ela, o
  `BoxofficeTest` rodaria este arquivo como um teste próprio, sem `clientId`, e falharia.
- `form field` manda os campos como formulário, como o `formParam` fazia na lição 7.
- `clientId` e `clientSecret` não estão definidos em lugar nenhum do arquivo: chegam de quem o
  chama. **`* def token = response.access_token`** define uma variável, e toda variável que uma
  feature chamada define volta para quem chamou.

Depois os pedidos. Salve como `karate/src/test/java/boxoffice/orders.feature`:

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

## call, callonce e o Background

O `Background` roda antes de cada cenário, e o primeiro passo dele usa **`callonce`**. O primeiro
cenário do arquivo roda o `token.feature` e guarda o que ele devolveu. Todo cenário seguinte do
mesmo arquivo recebe o resultado guardado sem uma requisição nova. `call` roda a feature toda vez,
que é o que o cenário do auditor quer para o seu único token. `read('token.feature')` acha o arquivo
ao lado deste, e o JSON depois dele vira as variáveis de quem chamou lá dentro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 258\" role=\"img\" aria-label=\"O orders.feature tem dois cenários. Antes do cenário 1, o Background roda callonce no token.feature, que manda POST /oauth/token como ci-tests e devolve um token que fica guardado. Antes do cenário 2, o callonce devolve o token guardado sem requisição, e o cenário então usa call para rodar o token.feature de novo como auditor, que manda um segundo POST /oauth/token.\"><defs><marker id=\"f08calls-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">orders.feature</text><text x=\"575\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">token.feature</text><rect x=\"20\" y=\"30\" width=\"220\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um pedido pode ser lido de volta</text><text x=\"130\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cenário 1</text><rect x=\"20\" y=\"170\" width=\"220\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o auditor pode ler e não comprar</text><text x=\"130\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cenário 2</text><rect x=\"470\" y=\"30\" width=\"210\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda, como ci-tests</text><text x=\"575\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /oauth/token</text><rect x=\"470\" y=\"170\" width=\"210\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">roda, como auditor</text><text x=\"575\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /oauth/token</text><rect x=\"285\" y=\"102\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">guardado: ci.token</text><line x1=\"240\" y1=\"55\" x2=\"468\" y2=\"55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"354\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">callonce</text><line x1=\"520\" y1=\"80\" x2=\"437\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"505\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">devolve o token</text><line x1=\"320\" y1=\"142\" x2=\"242\" y2=\"175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"250\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">callonce: sem requisição</text><line x1=\"240\" y1=\"195\" x2=\"468\" y2=\"195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f08calls-ah)\"></line><text x=\"354\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">call</text><text x=\"350\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o Background roda antes de cada cenário; o callonce só pede na primeira vez</text></svg>", "caption": "O callonce roda a feature de token para o primeiro cenário e entrega o resultado guardado aos demais; o call a roda toda vez."}
```

**`configure headers` define cabeçalhos para toda requisição seguinte**, até alguma coisa
configurá-los de novo. Essa é a diferença para o passo `header`, que acrescenta um cabeçalho só à
próxima requisição. Escrito no `Background`, o `header` poria o token no pedido e o deixaria de fora
do `GET` que lê o pedido de volta. O `#( … )` em volta do valor é o jeito do Karate de dizer
"calcule isto", aqui colando `Bearer ` ao token.

O primeiro cenário faz duas requisições seguidas, um `POST` e um `GET`, e passa um valor entre elas
com `* def id = response.id`, do jeito que a lição 7 usava o `extract()`. Rode a feature e veja o que
o boxoffice viu:

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

Duas requisições de token: `ci-tests` uma vez, pelo `callonce`, e `auditor` uma vez, pelo `call`.
Depois o pedido, a leitura de volta ainda com o token, e o `POST` recusado do auditor.

## O teste que estava errado

O cenário do auditor reconfigura os cabeçalhos em vez de acrescentar um. Eis o porquê. Troque a linha
`configure headers` dele por `And header Authorization = 'Bearer ' + auditor.token`, que se lê
igualmente bem, e rode a feature:

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

`expected status: 403, actual: 201`. **O boxoffice não fez nada de errado.** O `configure headers`
do `Background` continuou valendo e prevaleceu sobre o passo `header`, então a requisição saiu com o
token do `ci-tests`, que pode comprar. O cenário comprou um lugar e chamou isso de falha nas
permissões do servidor. Um teste vermelho é uma afirmação de que algo está quebrado. Antes de
registrá-lo como defeito, confira o que o teste mandou; o relatório da seção 07 mostra isso para
cada passo. Ponha a linha `configure headers` de volta.
