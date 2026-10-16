---
title: match, e os valores que você não tem como saber
version: 1
---

**`match` compara um valor inteiro de uma vez, e os marcadores dentro dele dizem o que um campo
precisa ser quando você não tem como dizer o que ele é.** A lição 7 conferia um campo por linha. Um
teste do Karate em geral escreve o corpo esperado inteiro como JSON e o compara num passo só, o que
também confere que nada falta e que nada está ali sem dever estar. A dificuldade são os campos cujo
valor muda: um id de pedido, uma contagem de lugares, uma impressão digital. Esses recebem um
**marcador** no lugar do valor.

Salve como `karate/src/test/java/boxoffice/match.feature`:

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

## Os marcadores

Um marcador é um texto que começa com `#`, escrito onde iria um valor:

| marcador | o campo precisa ser | usado aqui para |
|---|---|---|
| `'#string'` | texto, qualquer texto | um título, uma data numa lista |
| `'#number'` | um número, qualquer número | `seats_left`, que outros testes mudam |
| `'#notnull'` | presente, e não `null` | `seats_left` de novo, de forma mais frouxa |
| `'#regex sh-[0-9]{3}'` | texto que a expressão regular casa inteiro | a forma de um id |
| `'#[3]'` | um array de três | a lista da seção 03 |
| `'#ignore'` | qualquer coisa, ou ausente | (um campo que não importa ao teste) |

**Um marcador continua sendo uma verificação.** `'#number'` falha com `"4"`, o texto, e com um campo
ausente, então `seats_left: '#number'` diz que o campo existe e é um número sem dizer qual. É a
afirmação certa para um valor que outro teste pode mudar, e é a resposta ao problema que a seção 04
da lição 7 resolveu não afirmando nada.

## Os três jeitos de comparar

- `match a == b` é estrito: as mesmas chaves, os mesmos valores, nada a mais. `one show, whole` o
  usa, então um campo novo na resposta do boxoffice reprova esse cenário até alguém decidir se o
  campo novo está certo.
- `match a contains b` passa quando `a` contém `b`: uma lista que tem este item entre outros, um
  objeto que tem estas chaves entre outras. `the list holds the small show` acha o `sh-103` sem se
  importar com a posição.
- `match each a == b` aplica `b` a cada item da lista `a`. `every show has the same shape` confere
  os três espetáculos contra um modelo só, e um quarto espetáculo acrescentado amanhã também é
  conferido.

`match header etag == …` lê um cabeçalho da resposta pelo nome, sem ligar para maiúsculas, do jeito
que a lição 1 disse que um teste deve fazer.

## Estrito de propósito

Rode a feature sozinha; `-Dkarate.options` aceita o caminho de uma feature no classpath:

```
ana@laptop:~/boxoffice/karate$ mvn -q test -Dkarate.options=classpath:boxoffice/match.feature
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
ana@laptop:~/boxoffice/karate$ echo $?
0
```

Nada além das três linhas `SLF4J`, e `0`. Agora veja a rigidez trabalhando: em `one show, whole`, apague `, seats_left:
'#number'` do objeto esperado e rode de novo:

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

`actual has 1 more key(s) than expected - {"seats_left":4}`, e embaixo o corpo real e o esperado, um
sobre o outro. **A falha cita o campo a mais e mostra o valor dele**, então ninguém precisa rodar
nada de novo com um depurador para descobrir o que voltou. O Karate informa um passo que falhou como
error, e não como failure, `Errors: 1`; o build fica vermelho do mesmo jeito. Ponha o campo de volta
antes de continuar.

Essa rigidez é uma escolha. A lição 2 descobriu que o boxoffice aceita campos desconhecidos numa
requisição sem reclamar. `==` é o hábito oposto do lado da resposta, e percebe quando uma API começa
a dizer mais do que o contrato prometeu.
