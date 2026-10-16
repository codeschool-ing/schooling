---
title: A execução, o resumo e o relatório
version: 1
---

**O Karate escreve dois registros de cada execução: o que o Surefire imprime no terminal, e um
relatório HTML com cada passo de cada cenário.** O terminal diz se vale a pena olhar; o relatório
diz o que aconteceu. Para ter algo que valha a pena olhar, acrescente o defeito da lição 1 como
cenário. Salve como `karate/src/test/java/boxoffice/head.feature`:

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

Linhas que começam com `#` são comentários, e estes dizem por que o cenário existe e por que falha,
como o `HeadTest` da lição 7 fazia. Agora rode tudo, sem `-Dkarate.options`:

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

Dezesseis cenários de cinco features: três no `shows.feature`, quatro no `match.feature`, dois no
`orders.feature`, seis linhas no `seats.feature` e este. O `token.feature` não está entre eles, por
causa do `@ignore`. A falha cita o arquivo da feature e a linha do passo, `head.feature:9`, e o
motivo, `expected status: 200, actual: 405`. O código de saída é `1`, que é o que um pipeline lê.

## O relatório HTML

Toda execução deixa o seu relatório em `target/karate-reports`:

```
ana@laptop:~/boxoffice/karate$ ls target/karate-reports target/karate-reports/feature-html
target/karate-reports:
feature-html  index.html  karate-summary.html  karate-timeline.html  res

target/karate-reports/feature-html:
boxoffice.head.html   boxoffice.orders.html  boxoffice.shows.html
boxoffice.match.html  boxoffice.seats.html
```

Abra o `karate-summary.html` num navegador. Para este curso ele foi aberto num Chromium sem tela, e
não à mão, então é descrito aqui em vez de mostrado. A página de resumo lista cada feature com o seu
número de cenários aprovados e reprovados, e o cenário que falhou, `HEAD on a show`, numa lista de
falhas no topo. Cada feature tem uma página própria em `feature-html`, e nela cada passo de cada
cenário é uma linha com o tempo que levou. Embaixo de `When method head` há um `log` para abrir, e
ele guarda a requisição que o Karate mandou e a resposta que recebeu.

**Esse log é a evidência para um relatório de defeito**, e também a conferência que a seção 05
pediu: antes de chamar um cenário vermelho de defeito do servidor, abra o passo que mandou a
requisição e leia o que saiu. O token na requisição do auditor estaria ali, claramente o errado.

## Um filtro que não casa com nada

`-Dkarate.options` também seleciona por tag, como em `--tags @smoke`, e um projeto sem nenhum cenário
marcado com `@smoke` dá o resultado de que a lição 7 avisou:

```
ana@laptop:~/boxoffice/karate$ mvn test '-Dkarate.options=--tags @smoke' | grep 'Tests run'
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.362 s -- in boxoffice.BoxofficeTest
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
```

`Tests run: 0`, e nada na saída diz que isso é um problema. As linhas `SLF4J` passam pelo `grep`
porque o Java as imprime na saída de erro, que um pipe não carrega. Uma tag escrita errado na linha de
comando de um pipeline é uma suíte que nunca mais roda. **Conte os testes em toda execução**, aqui
como lá.
