---
title: Build incremental
version: 1
---

A imagem errada de um build é uma receita, executada do começo toda vez. **O Gradle trata cada
tarefa como uma função: as mesmas entradas dão as mesmas saídas, então uma tarefa cujas entradas não
mudaram desde que as saídas foram feitas não tem nada a fazer.** Antes de rodar uma tarefa, o Gradle
tira a impressão digital de tudo o que ela declarou como entrada e compara com o que gravou da
última vez. Esta seção acompanha essa comparação, a partir do build que acabou de ser feito.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Antes de uma tarefa rodar, o Gradle tira a impressão digital do que entra: arquivos-fonte, classpath, versão do Java e opções do compilador. Se ela bate com a última execução neste diretório, a tarefa fica UP-TO-DATE e nada roda. Se não bate e o cache de build tem saídas para essa impressão digital, elas são copiadas e a tarefa fica FROM-CACHE. Senão a ação roda, e as saídas e a impressão digital são gravadas.\"><defs><marker id=\"gdc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"130\" height=\"150\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que entra</text><text x=\"75\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arquivos-fonte</text><text x=\"75\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">classpath</text><text x=\"75\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">versão do Java</text><text x=\"75\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">opções do compilador</text><line x1=\"140\" y1=\"115\" x2=\"168\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><rect x=\"170\" y=\"95\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">impressão digital</text><line x1=\"280\" y1=\"115\" x2=\"308\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><rect x=\"310\" y=\"92\" width=\"200\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">igual à última execução aqui?</text><line x1=\"510\" y1=\"115\" x2=\"548\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"529\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"550\" y=\"92\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UP-TO-DATE</text><text x=\"630\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nada é executado</text><line x1=\"410\" y1=\"138\" x2=\"410\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"420\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"310\" y=\"168\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">está no cache de build?</text><line x1=\"510\" y1=\"188\" x2=\"548\" y2=\"188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"529\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"550\" y=\"168\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FROM-CACHE</text><text x=\"630\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">saídas copiadas</text><line x1=\"410\" y1=\"208\" x2=\"410\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"420\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"310\" y=\"238\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">executa a ação</text><line x1=\"510\" y1=\"256\" x2=\"548\" y2=\"256\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><rect x=\"550\" y=\"238\" width=\"160\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.6\" fill=\"var(--paper)\">grava saídas e impressão digital</text><text x=\"630\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o trabalho é feito</text></svg>", "caption": "A pergunta que o Gradle faz a cada tarefa antes de rodá-la. Duas das três respostas não fazem trabalho nenhum, e a comparação é de conteúdo, nunca de data de modificação.", "same": ["classpath"]}
```

## Nada mudou

Compile de novo, sem editar nada:

```
ana@vm:~/isbn-gradle$ ./gradlew build
> Task :compileJava UP-TO-DATE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :startScripts UP-TO-DATE
> Task :distTar UP-TO-DATE
> Task :distZip UP-TO-DATE
> Task :assemble UP-TO-DATE
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE
> Task :test UP-TO-DATE
> Task :check UP-TO-DATE
> Task :build UP-TO-DATE

BUILD SUCCESSFUL in 651ms
7 actionable tasks: 7 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

Toda tarefa com trabalho a fazer está **`UP-TO-DATE`**, e o resumo diz `7 up-to-date`: o Gradle
comparou, achou as entradas e as saídas como as deixou, e não rodou nada. O tempo que levou foi
para iniciar, ler os scripts e comparar.

Agora mude a data de modificação de um arquivo-fonte sem mudar um byte dele:

```
ana@vm:~/isbn-gradle$ touch src/main/java/com/example/isbn/IsbnCheck.java && ./gradlew build
> Task :compileJava UP-TO-DATE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :startScripts UP-TO-DATE
> Task :distTar UP-TO-DATE
> Task :distZip UP-TO-DATE
> Task :assemble UP-TO-DATE
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE
> Task :test UP-TO-DATE
> Task :check UP-TO-DATE
> Task :build UP-TO-DATE

BUILD SUCCESSFUL in 767ms
7 actionable tasks: 7 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

Nada de novo. O Gradle tira a impressão digital de um arquivo pelo conteúdo, não pela data, então
um `touch`, um `git checkout` novo ou uma cópia que zera as datas não fazem uma tarefa rodar. O
plugin compiler do Maven decide se um fonte está desatualizado comparando a data dele com a do
arquivo de classe, e o mesmo `touch` teria mandado o build da lição 1 de volta ao `javac`.

## Um arquivo mudou

Mude o que o programa imprime entre um ISBN e o veredito, de `: ` para ` -> `:

```
ana@vm:~/isbn-gradle$ sed -i 's/": "/" -> "/' src/main/java/com/example/isbn/IsbnCheck.java
ana@vm:~/isbn-gradle$ ./gradlew build
> Task :compileJava
> Task :processResources NO-SOURCE
> Task :classes
> Task :jar
> Task :startScripts
> Task :distTar
> Task :distZip
> Task :assemble
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 1s
7 actionable tasks: 6 executed, 1 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
ana@vm:~/isbn-gradle$ ./gradlew -q run --args="0-306-40615-2"
0-306-40615-2 -> valid, ISBN-13 9780306406157
```

Veja quais tarefas rodaram. `compileJava` rodou, porque a entrada dela mudou. `jar`, `startScripts`
e as distribuições rodaram, porque a entrada delas é o arquivo de classe que o `compileJava` acabou
de reescrever: **uma mudança desce pelo grafo só até onde as saídas de fato mudam**. `test` rodou,
porque as classes que ele executa são outras. E o `run` imprime o separador novo, da classe que
acabou de ser compilada.

E o `compileTestJava` ficou `UP-TO-DATE`, que é o caso sutil. A edição foi dentro do corpo do
`main`; nenhuma classe, método ou assinatura contra a qual um teste pudesse compilar mudou. O Gradle
compara a **ABI** das classes principais, as assinaturas públicas delas, para decidir se recompila o
código que depende delas, e pula a recompilação quando as assinaturas são as mesmas. Isso se chama
compile avoidance, e num projeto de cinquenta módulos é a diferença entre recompilar um módulo e
recompilar tudo o que está abaixo dele.

`--info` faz o Gradle dizer por que cada tarefa rodou. Volte o separador ao que era e pergunte:

```
ana@vm:~/isbn-gradle$ sed -i 's/" -> "/": "/' src/main/java/com/example/isbn/IsbnCheck.java
ana@vm:~/isbn-gradle$ ./gradlew build --info | grep -A1 'is not up-to-date'
Task ':compileJava' is not up-to-date because:
  Input property 'stableSources' file /home/ana/isbn-gradle/src/main/java/com/example/isbn/IsbnCheck.java has changed.
--
Task ':jar' is not up-to-date because:
  Input property 'rootSpec$1' file /home/ana/isbn-gradle/build/classes/java/main/com/example/isbn/IsbnCheck.class has changed.
--
Task ':startScripts' is not up-to-date because:
  Input property 'classpath' file /home/ana/isbn-gradle/build/libs/isbn-check-1.0.0.jar has changed.
--
Task ':distTar' is not up-to-date because:
  Input property 'rootSpec$1$1$1$1$1' file /home/ana/isbn-gradle/build/libs/isbn-check-1.0.0.jar has changed.
--
Task ':distZip' is not up-to-date because:
  Input property 'rootSpec$1$1$1$1$1' file /home/ana/isbn-gradle/build/libs/isbn-check-1.0.0.jar has changed.
--
Task ':test' is not up-to-date because:
  Input property 'stableClasspath' file /home/ana/isbn-gradle/build/classes/java/main/com/example/isbn/IsbnCheck.class has changed.
```

Cada motivo diz qual entrada mudou e qual arquivo foi. A cadeia aparece nos caminhos: o arquivo
`.java` mudou, então o `.class` mudou, então o jar mudou, então tudo o que contém o jar rodou.
Quando uma tarefa rodar sem você esperar, o `--info` diz a entrada, e a entrada costuma estar onde
você não pensou em olhar.

## O cache de build e o cache de configuração

`UP-TO-DATE` precisa das saídas ainda em `build/`. Depois de um `clean`, ou num clone novo, não há
nada com que estar atualizado. O **cache de build** (build cache) cobre esse caso: um depósito, em
`~/.gradle/caches`, de saídas de tarefas indexadas pela impressão digital das entradas. Se a
impressão digital de uma tarefa está nele, o Gradle copia as saídas em vez de rodar a tarefa.

O **cache de configuração** (configuration cache) é outra economia. Antes de qualquer tarefa rodar,
o Gradle executa os build scripts para montar o grafo, e essa fase é paga em todo build: é a maior parte do
tempo que levou um build que não fez nada. Com o cache de configuração, o Gradle guarda o grafo
que calculou para um pedido e o reaproveita até um script ou uma propriedade mudar. É o cache que o
Gradle vem sugerindo no fim de todo build desta lição.

Os dois são ligados no `gradle.properties`. Substitua o arquivo por este:

```properties
org.gradle.console=plain
org.gradle.caching=true
org.gradle.configuration-cache=true
```

Depois limpe e compile duas vezes:

```
ana@vm:~/isbn-gradle$ ./gradlew clean build
Calculating task graph as no cached configuration is available for tasks: clean build
> Task :clean
> Task :processResources NO-SOURCE
> Task :processTestResources NO-SOURCE
> Task :compileJava
> Task :classes
> Task :jar
> Task :startScripts
> Task :distTar
> Task :compileTestJava
> Task :testClasses
> Task :distZip
> Task :assemble
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 3s
8 actionable tasks: 8 executed
Configuration cache entry stored.
ana@vm:~/isbn-gradle$ ./gradlew clean build
Reusing configuration cache.
> Task :clean
> Task :processResources NO-SOURCE
> Task :processTestResources NO-SOURCE
> Task :compileJava FROM-CACHE
> Task :classes UP-TO-DATE
> Task :jar
> Task :compileTestJava FROM-CACHE
> Task :testClasses UP-TO-DATE
> Task :test FROM-CACHE
> Task :check UP-TO-DATE
> Task :startScripts
> Task :distTar
> Task :distZip
> Task :assemble
> Task :build

BUILD SUCCESSFUL in 1s
8 actionable tasks: 5 executed, 3 from cache
Configuration cache entry reused.
```

A primeira execução não tinha grafo guardado (`Calculating task graph as no cached configuration is
available`) nem nada no cache de build, então executou as oito tarefas, `clean` inclusive, e
guardou as duas coisas. A segunda apagou o `build/` de novo com o `clean` e depois trouxe
**`compileJava`, `compileTestJava` e `test` `FROM-CACHE`**: as saídas deles, resultados de teste
inclusive, foram copiadas do cache, e nenhum compilador nem teste rodou. A ordem das linhas também
mudou, porque com o cache de configuração o Gradle roda tarefas independentes ao mesmo tempo.

`jar` e as distribuições rodaram mesmo assim. O Gradle não guarda em cache as tarefas que montam
arquivos compactados, porque compactar uns poucos arquivos sai mais barato do que procurá-los e
copiá-los de volta. O tempo caiu de 3 segundos para 1, e num projeto em que compilar e testar leva
minutos, essa é a economia que importa.

O cache em `~/.gradle` atende os projetos desta máquina. Uma equipe ou um servidor de CI pode
apontar o Gradle para um **cache de build remoto** num servidor, de modo que um pull request
compilado numa máquina deixa saídas que todas as outras podem reaproveitar. É o mesmo mecanismo com
alcance maior, e é por isso que um checkout novo no CI não precisa recompilar o que outra pessoa já
compilou.
