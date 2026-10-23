---
title: Fases, objetivos e o ciclo de vida do build
version: 1
---

`mvn compile`, `mvn package` e `mvn dependency:tree` parecem três comandos do mesmo tipo. São dois
tipos. `dependency:tree` nomeia um **objetivo** (goal): uma tarefa de um plugin, rodada uma vez.
`compile` e `package` nomeiam uma **fase**: um passo numa sequência fixa chamada **ciclo de vida**
(lifecycle), e pedir uma fase roda também todas as fases antes dela.

O Maven em si quase não faz nada. **O trabalho é feito por plugins**, cada um um jar de objetivos,
e o ciclo de vida é a ordem em que esses objetivos rodam. Um projeto com empacotamento `jar` ganha
um objetivo ligado a seis fases do ciclo de vida padrão sem escrever uma linha sobre isso, e mais
dois, `install` e `deploy`, no fim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 328\" role=\"img\" aria-label=\"Dez fases do ciclo de vida padrão, de validate a deploy, cada uma com o objetivo de plugin que um projeto jar liga a ela: resources:resources em process-resources, compiler:compile em compile, resources:testResources em process-test-resources, compiler:testCompile em test-compile, surefire:test em test, jar:jar em package, install:install em install e deploy:deploy em deploy; validate e verify não têm nada ligado. Colchetes mostram que mvn test roda as fases até test, mvn package até package e mvn install até install.\"><text x=\"130\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">fase</text><text x=\"300\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">objetivo ligado a ela, num jar</text><rect x=\"30\" y=\"44\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">validate</text><line x1=\"130\" y1=\"66\" x2=\"130\" y2=\"72\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"300\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada ligado</text><rect x=\"30\" y=\"72\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">process-resources</text><line x1=\"130\" y1=\"94\" x2=\"130\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"83.0\" x2=\"292\" y2=\"83.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">resources:resources</text><rect x=\"30\" y=\"100\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">compile</text><line x1=\"130\" y1=\"122\" x2=\"130\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"111.0\" x2=\"292\" y2=\"111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"111.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">compiler:compile</text><rect x=\"30\" y=\"128\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">process-test-resources</text><line x1=\"130\" y1=\"150\" x2=\"130\" y2=\"156\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"139.0\" x2=\"292\" y2=\"139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">resources:testResources</text><rect x=\"30\" y=\"156\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">test-compile</text><line x1=\"130\" y1=\"178\" x2=\"130\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"167.0\" x2=\"292\" y2=\"167.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">compiler:testCompile</text><rect x=\"30\" y=\"184\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">test</text><line x1=\"130\" y1=\"206\" x2=\"130\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"195.0\" x2=\"292\" y2=\"195.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">surefire:test</text><rect x=\"30\" y=\"212\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package</text><line x1=\"130\" y1=\"234\" x2=\"130\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"223.0\" x2=\"292\" y2=\"223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">jar:jar</text><rect x=\"30\" y=\"240\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">verify</text><line x1=\"130\" y1=\"262\" x2=\"130\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"300\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nada ligado</text><rect x=\"30\" y=\"268\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">install</text><line x1=\"130\" y1=\"290\" x2=\"130\" y2=\"296\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"279.0\" x2=\"292\" y2=\"279.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">install:install</text><rect x=\"30\" y=\"296\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"307.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">deploy</text><line x1=\"232\" y1=\"307.0\" x2=\"292\" y2=\"307.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"307.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">deploy:deploy</text><path d=\"M 492 46 H 500 V 204 H 492\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"500\" y=\"217\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mvn test</text><path d=\"M 557 46 H 565 V 232 H 557\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"565\" y=\"245\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mvn package</text><path d=\"M 622 46 H 630 V 288 H 622\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"630\" y=\"301\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mvn install</text></svg>", "caption": "Dez das 23 fases do ciclo de vida padrão: as que um jar liga a um objetivo, mais validate e verify. Um comando nomeia uma fase e roda também todas as fases antes dela."}
```

## Lendo um build

A figura é o que passa na tela quando você empacota o projeto. Cada linha entre traços é um objetivo
rodando, na forma `plugin:versão:objetivo (execução) @ projeto`:

```
ana@vm:~/isbn-check$ mvn package
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ isbn-check ---
[INFO] skip non existing resourceDirectory /home/ana/isbn-check/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ isbn-check ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ isbn-check ---
[INFO] skip non existing resourceDirectory /home/ana/isbn-check/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ isbn-check ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ isbn-check ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.isbn.IsbnCheckTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.058 s -- in com.example.isbn.IsbnCheckTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- maven-jar-plugin:3.5.1:jar (default-jar) @ isbn-check ---
[INFO] Building jar: /home/ana/isbn-check/target/isbn-check-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.020 s
[INFO] Finished at: 2026-10-22T19:33:40-03:00
[INFO] ------------------------------------------------------------------------
```

Seis objetivos rodaram, na ordem da figura, e o nome entre parênteses, `default-compile` e os
outros, é a **execução**: a ligação que o Maven fez por conta própria porque o empacotamento é
`jar`. O compilador não teve nada a fazer pelo programa, que o primeiro build tinha compilado e
ninguém tinha mudado desde então, e compilou a classe de teste, que era nova. O Surefire achou essa
classe em `src/test/java`, rodou os 3 testes dela e somou o resultado. Se um tivesse falhado, o
build teria terminado ali com `BUILD FAILURE`, e o plugin de jar nunca teria rodado: **uma fase só
roda se todas as fases antes dela passaram**, então um jar que o `mvn package` deixa em `target/` é
um jar cujos testes passaram. O nome dele é o artifact id e a versão, `isbn-check-1.0.0.jar`.

## As fases que você vai digitar

`mvn test` para depois dos testes, que é a pergunta rápida "ainda funciona?", e o `-q` (quiet)
imprime só avisos e erros, então uma execução que passa não imprime nada:

```
ana@vm:~/isbn-check$ mvn -q test
```

`mvn package` é o de cima. `mvn verify` roda tudo que o `package` roda e depois a fase onde ficam
testes de integração e verificações; este projeto não tem nenhum, e a aula 19 os acrescenta.
`mvn install` copia o jar e o pom do projeto para o seu repositório local, onde outro projeto da
mesma máquina pode citá-lo como dependência, como qualquer biblioteca de fora. A saída dele é o
build de cima mais duas linhas, então o `tail -n 8` guarda só o fim:

```
ana@vm:~/isbn-check$ mvn install | tail -n 8
[INFO] Installing /home/ana/isbn-check/pom.xml to /home/ana/.m2/repository/com/example/isbn-check/1.0.0/isbn-check-1.0.0.pom
[INFO] Installing /home/ana/isbn-check/target/isbn-check-1.0.0.jar to /home/ana/.m2/repository/com/example/isbn-check/1.0.0/isbn-check-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.376 s
[INFO] Finished at: 2026-10-22T19:33:44-03:00
[INFO] ------------------------------------------------------------------------
ana@vm:~/isbn-check$ ls ~/.m2/repository/com/example/isbn-check/1.0.0
_remote.repositories
isbn-check-1.0.0.jar
isbn-check-1.0.0.pom
```

`mvn deploy` enviaria os dois para um repositório compartilhado, o que exige um servidor e
credenciais que este curso não monta.

## Outro ciclo de vida, e opções que vale conhecer

O `target/` é a saída do build e mais nada, e o `mvn clean` o apaga. `clean` é uma fase de um
segundo ciclo de vida, separado, então `mvn clean package` nomeia uma fase de cada e roda as duas
em ordem: primeiro um `target/` vazio, depois um build completo. Use quando um build se comporta de
um jeito que você não consegue explicar, e não por hábito, já que ele joga fora classes compiladas
que o próximo build reaproveitaria.

Três opções aparecem neste curso. O `-q` está acima. O `-B` (batch mode) desliga as cores e os
contadores de progresso dos downloads, que é o que você quer num script ou num arquivo de log. E o
`-DskipTests` roda todas as fases mas não executa teste nenhum, para um build cujos testes você
acabou de rodar; um build que vai para produção nunca deve usá-lo.
