---
title: Maven ou Gradle
version: 1
---

A comparação que quase todo mundo traz é velocidade: o Gradle é o rápido. Neste projeto não há
disputa. O `mvn package` da lição 1 e o `./gradlew build` desta lição terminam em poucos segundos,
porque duas classes e três testes não são nada para nenhuma das duas. **A diferença está no
modelo**, e velocidade é uma das coisas que o modelo compra num projeto grande.

| | Maven | Gradle |
|---|---|---|
| o que é o arquivo de build | uma descrição, em XML | um programa, em Kotlin (ou Groovy) |
| o que roda | uma linha fixa de fases, com plugins associados a elas | um grafo de tarefas, montado para as tarefas que você pediu |
| quando um passo roda de novo | o plugin compiler compara datas de arquivo, e os testes rodam de novo em todo build | toda tarefa compara o conteúdo das entradas e das saídas |
| reaproveitar trabalho feito em outro lugar | uma extensão, fora da instalação padrão | o cache de build, uma linha no `gradle.properties` |
| conflito de versão entre duas dependências | vence a declaração mais próxima do projeto | vence a versão mais alta |
| a versão da própria ferramenta | o `mvn` que estiver instalado, a menos que o projeto acrescente um wrapper | o wrapper, desde o primeiro commit |
| entre um build e outro | nada fica rodando | um daemon fica na memória, ocioso |

Duas linhas merecem uma frase. A regra de conflito apareceu no próprio relatório de dependências
desta lição, onde `commons-logging:1.3.5 -> 1.4.0` é o Gradle escolhendo a mais alta de duas versões
pedidas. O Maven também escolheria a 1.4.0 aqui, por outro motivo: o Commons Validator a pede
diretamente, um nível mais perto do projeto do que o Commons BeanUtils. Em outro projeto as duas
regras podem escolher diferente, e a mesma lista de dependências passa a compilar contra jars
diferentes.

E o daemon é o preço do segundo build rápido. Depois de um build ele continua vivo, guardando o
build script compilado e uma JVM aquecida:

```
ana@vm:~/isbn-gradle$ ./gradlew --status
   PID STATUS   INFO
 25061 IDLE     9.8.1

Only Daemons for the current Gradle version are displayed. For more on this, please refer to https://docs.gradle.org/9.8.1/userguide/gradle_daemon.html#sec:status in the Gradle documentation.
ana@vm:~/isbn-gradle$ ./gradlew --stop
Stopping Daemon(s)
1 Daemon stopped
```

O `--stop` o encerra, e um daemon ocioso se encerra sozinho depois de três horas. Num notebook com
pouca memória, vale saber dessa JVM residente.

## Onde cada um está

**Um arquivo de build que é um programa é o ponto mais forte do Gradle e a reclamação mais comum
sobre ele.** Uma tarefa cabe em poucas linhas de Kotlin onde o Maven precisaria de um plugin, e uma
equipe também pode enterrar no build uma lógica que ninguém mais consegue ler. Um pom só diz o que o
formato POM deixa dizer, o que faz todo pom parecer com todos os outros.

Os dois estão por toda parte no Java. Projetos Android compilam com Gradle, porque o plugin Android
do Google é um plugin Gradle. O próprio código-fonte do Spring Boot é compilado com Gradle, e o
Spring Initializr oferece um projeto novo em qualquer um dos dois. Muitas bases de código de
empresas, sobretudo as mais antigas, são Maven, e quem lê só uma das duas ferramentas vai encontrar
a outra em um ou dois empregos.

## Por que o resto deste curso usa Maven

A partir da lição 4, o projeto do curso é uma aplicação Spring Boot, `~/bookshop`, e o arquivo de
build dela é um pom. O motivo é a leitura, não a ferramenta. Toda lição que muda o build muda um
bloco declarativo que você lê de cima a baixo, seja para acrescentar um starter, um driver ou um
plugin de teste. O pom pai do Spring Boot então decide a versão de quase toda biblioteca, e dá para
ver isso acontecer lendo o arquivo. **Um build Gradle da mesma aplicação funciona igualmente bem**:
o Spring Boot traz um plugin Gradle que faz o que o plugin Maven dele faz, e nada ensinado da lição
4 em diante depende da escolha.

O que você leva desta lição para um projeto Gradle é o vocabulário: uma tarefa, as entradas e saídas
dela, `UP-TO-DATE` e `FROM-CACHE`, o wrapper, e `./gradlew` em vez de `gradle`. A lição 3 apresenta
o Bazel, que leva a ideia de um build guiado por entradas e com cache muito mais longe, para bases
de código muito maiores que esta.
