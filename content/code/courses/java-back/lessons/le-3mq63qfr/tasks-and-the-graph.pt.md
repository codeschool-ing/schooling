---
title: Tarefas e o grafo
version: 1
---

A lição 1 desenhou o ciclo de vida do Maven como uma linha: peça uma fase e todas as fases antes
dela rodam, em ordem. **O Gradle não tem linha. Tem tarefas, cada uma declarando as tarefas de que
precisa, e um pedido seleciona a parte desse grafo que ele alcança.** Peça `build` e quase tudo
roda; peça `run` e o Gradle compila o código principal e o inicia, sem olhar para um teste.

## Tarefas

Uma **tarefa** (task) é uma unidade de trabalho com nome: compilar os fontes principais, gerar o
jar, rodar os testes. Os plugins as trazem. `tasks` lista as que foram feitas para ser pedidas pelo
nome, umas trinta neste projeto, e `--group` restringe a lista a um grupo:

```
ana@vm:~/isbn-gradle$ ./gradlew tasks --group build

> Task :tasks

------------------------------------------------------------
Tasks runnable from root project 'isbn-check'
------------------------------------------------------------

Build tasks
-----------
assemble - Assembles the outputs of this project.
build - Assembles and tests this project.
buildDependents - Assembles and tests this project and all projects that depend on it.
buildNeeded - Assembles and tests this project and all projects it depends on.
classes - Assembles main classes.
clean - Deletes the build directory.
jar - Assembles a jar archive containing the classes of the 'main' feature.
testClasses - Assembles test classes.

To see all tasks and more detail, run gradlew tasks --all

To see more detail about a task, run gradlew help --task <task>

BUILD SUCCESSFUL in 1s
1 actionable task: 1 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

O projeto se chama `isbn-check` aqui, por causa do `settings.gradle.kts`, embora o diretório seja
`isbn-gradle`. `./gradlew tasks` sem `--group` acrescenta os grupos application, distribution,
documentation, help e verification, com `run` e `test` entre eles.

## Um build

`build` é a tarefa que faz tudo de que uma versão precisa:

```
ana@vm:~/isbn-gradle$ ./gradlew build
> Task :compileJava
> Task :processResources NO-SOURCE
> Task :classes
> Task :jar
> Task :startScripts
> Task :distTar
> Task :distZip
> Task :assemble
> Task :compileTestJava
> Task :processTestResources NO-SOURCE
> Task :testClasses
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 21s
7 actionable tasks: 7 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

Cada tarefa imprimiu uma linha, o console plain trabalhando, e cada linha sem nenhuma palavra depois
rodou. `NO-SOURCE` quer dizer que a tarefa não tinha o que ler: não existe `src/main/resources`
neste projeto, então `processResources` se pulou. O resumo conta sete tarefas **actionable**, as
que têm trabalho próprio; `classes`, `testClasses`, `assemble`, `check` e `build` só reúnem outras
tarefas, e `processResources` e `processTestResources` não tinham nada a fazer.

O primeiro build de um projeto é o lento, porque o Gradle compila os dois build scripts e resolve
as dependências antes de qualquer tarefa rodar. Os produtos ficam em `build/`, o equivalente do
`target/` do Maven:

```
ana@vm:~/isbn-gradle$ ls build/libs build/distributions
build/distributions:
isbn-check-1.0.0.tar
isbn-check-1.0.0.zip

build/libs:
isbn-check-1.0.0.jar
ana@vm:~/isbn-gradle$ grep -o 'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' build/test-results/test/*.xml
tests="3" skipped="0" failures="0"
```

O jar traz as classes do próprio projeto, como o do Maven. Os dois arquivos compactados são a
**distribuição** do plugin `application`: descompactado, cada um dá um `bin/` com um script de
execução e um `lib/` com o jar e todos os jars de que ele depende, para que o programa rode em
outra máquina só com um Java. E os resultados dos testes são XML no mesmo formato dos do Maven,
três testes e nenhuma falha; o Gradle escreve um relatório HTML ao lado, em
`build/reports/tests/test/index.html`, e não imprime nada sobre testes que passam.

## O grafo por trás

`--dry-run` mostra o que um pedido executaria, em ordem, sem executar nada:

```
ana@vm:~/isbn-gradle$ ./gradlew build --dry-run
:compileJava SKIPPED
:processResources SKIPPED
:classes SKIPPED
:jar SKIPPED
:startScripts SKIPPED
:distTar SKIPPED
:distZip SKIPPED
:assemble SKIPPED
:compileTestJava SKIPPED
:processTestResources SKIPPED
:testClasses SKIPPED
:test SKIPPED
:check SKIPPED
:build SKIPPED

BUILD SUCCESSFUL in 2s
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

Essa é a ordem, e a ordem é só uma maneira de percorrer o grafo que o Gradle montou. O grafo em si
é o que vale guardar na cabeça:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 790 250\" role=\"img\" aria-label=\"As tarefas dos plugins java e application como um grafo. compileJava leva a classes, depois jar, startScripts, distTar e distZip, depois assemble. De classes sai um segundo ramo: compileTestJava, testClasses, test e check. assemble e check levam a build. run depende só de classes.\"><defs><marker id=\"gtg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"112\" y1=\"55.0\" x2=\"117\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"225\" y1=\"55.0\" x2=\"230\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"338\" y1=\"55.0\" x2=\"343\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"451\" y1=\"55.0\" x2=\"456\" y2=\"33.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"451\" y1=\"55.0\" x2=\"456\" y2=\"77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"564\" y1=\"33.0\" x2=\"569\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"564\" y1=\"77.0\" x2=\"569\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"172.0\" y1=\"70\" x2=\"172.0\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"172.0\" y1=\"70\" x2=\"230\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"338\" y1=\"185.0\" x2=\"343\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"451\" y1=\"185.0\" x2=\"456\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"564\" y1=\"185.0\" x2=\"569\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"677\" y1=\"55.0\" x2=\"682\" y2=\"120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"677\" y1=\"185.0\" x2=\"682\" y2=\"120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><rect x=\"6\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"59.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">compileJava</text><rect x=\"119\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"172.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">classes</text><rect x=\"232\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jar</text><rect x=\"345\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"398.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">startScripts</text><rect x=\"458\" y=\"18\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"511.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distTar</text><rect x=\"458\" y=\"62\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"511.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distZip</text><rect x=\"571\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"624.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">assemble</text><rect x=\"119\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"172.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run</text><rect x=\"232\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">compileTestJava</text><rect x=\"345\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"398.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">testClasses</text><rect x=\"458\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"511.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">test</text><rect x=\"571\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"624.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check</text><rect x=\"684\" y=\"105.0\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"737.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">build</text><text x=\"59.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código principal</text><text x=\"398.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">testes</text><text x=\"172.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só para ./gradlew run</text></svg>", "caption": "As tarefas que os plugins `java` e `application` acrescentam, cada seta saindo de uma tarefa para outra que precisa dela. `build` puxa os dois ramos; `run` só precisa de `classes`, então nunca compila nem roda um teste."}
```

`build` precisa de `assemble` e de `check`, e cada um puxa o seu ramo. `test` precisa das classes de
teste, que são compiladas contra as classes principais, então o código principal sempre compila
primeiro. Nada faz um jar esperar pelos testes: no Maven, `package` vem depois de `test` na linha,
enquanto aqui `./gradlew jar` compila e empacota e nunca encosta num teste. Para ter um jar só de
código testado, você pede `build`.

`run` é a outra ponta do desenho. Precisa das classes compiladas e do classpath delas, então roda
três tarefas e inicia o programa. O `-q` deixa o Gradle quieto, e sobra só o que o programa
imprimiu:

```
ana@vm:~/isbn-gradle$ ./gradlew -q run --args="978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8"
978-0-306-40615-7: valid, ISBN-13 9780306406157
0-306-40615-2: valid, ISBN-13 9780306406157
978-0-306-40615-8: invalid
```

Os mesmos três vereditos que os testes da lição 1 conferem. A lição 1 precisou montar um classpath
à mão para rodar o jar, porque o jar não leva o Commons Validator; o `run` monta esse classpath a
partir das dependências declaradas no script.

## O relatório de dependências

As dependências formam um grafo próprio, e `dependencies` o imprime para uma configuração:

```
ana@vm:~/isbn-gradle$ ./gradlew -q dependencies --configuration runtimeClasspath

------------------------------------------------------------
Root project 'isbn-check'
------------------------------------------------------------

runtimeClasspath - Runtime classpath of source set 'main'.
\--- commons-validator:commons-validator:1.11.0
     +--- commons-beanutils:commons-beanutils:1.11.0
     |    +--- commons-logging:commons-logging:1.3.5 -> 1.4.0
     |    \--- commons-collections:commons-collections:3.2.2
     +--- commons-digester:commons-digester:2.1
     +--- commons-logging:commons-logging:1.4.0
     \--- commons-collections:commons-collections:3.2.2

(*) - Indicates repeated occurrences of a transitive dependency subtree. Gradle expands transitive dependency subtrees only once per project; repeat occurrences only display the root of the subtree, followed by this annotation.

A web-based, searchable dependency report is available by adding the --scan option.
```

É a árvore que a lição 1 imprimiu com `mvn dependency:tree`, em outra notação. Uma linha merece
atenção: `commons-logging:commons-logging:1.3.5 -> 1.4.0`. O Commons BeanUtils pediu a 1.3.5, o
Commons Validator pediu a 1.4.0, e **o Gradle resolveu o conflito ficando com a versão mais alta**.
A seta é como o relatório diz isso. A última seção compara essa regra com a do Maven.

## Uma falha, de propósito

O script tem uma linha que parecia opcional, a do launcher do JUnit. Tire-a e rode os testes:

```
ana@vm:~/isbn-gradle$ sed -i '/junit-platform-launcher/d' build.gradle.kts
ana@vm:~/isbn-gradle$ ./gradlew test
> Task :compileJava UP-TO-DATE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test FAILED

Gradle Test Executor 2 FAILED
    org.gradle.api.internal.tasks.testing.TestSuiteExecutionException at SuiteTestDefinitionProcessor.java:45
        Caused by: org.gradle.api.internal.tasks.testing.RequiresTestFrameworkTestDefinitionProcessor$TestFrameworkNotAvailableException at JUnitPlatformTestDefinitionProcessor.java:101

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':test' (registered by plugin 'org.gradle.jvm-test-suite').
> Test process encountered an unexpected problem.
   > Could not start Gradle Test Executor 2.
      > Failed to load JUnit Platform.  Please ensure that all JUnit Platform dependencies are available on the test's runtime classpath, including the JUnit Platform launcher.

* Try:
> Check common problems https://docs.gradle.org/9.8.1/userguide/java_testing.html#sec:java_testing_troubleshooting.
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 8s
3 actionable tasks: 1 executed, 2 up-to-date
```

Duas coisas para ler. As tarefas de compilação estão `UP-TO-DATE`: o launcher nunca esteve no
classpath contra o qual os testes compilam, então tirá-lo não mudou nada ali, e só iniciar os
testes precisava dele. E a mensagem diz exatamente o que falta, `the JUnit Platform launcher`. O
Gradle 8 colocava o launcher sozinho no classpath dos testes; o Gradle 9 parou, e um build
atualizado do 8 para o 9 que nunca o nomeou encontra essa mensagem na primeira vez que roda os
testes.

Ponha a linha de volta onde estava no `build.gradle.kts`,
`testRuntimeOnly("org.junit.platform:junit-platform-launcher:6.0.3")` depois da linha
`testImplementation`, e compile de novo. Os testes rodam e passam, e o resto do build, que a
mudança não tocou, não é refeito. A próxima seção é sobre como o Gradle sabe disso.
