---
title: Lendo um script de build
version: 1
---

Um build do Gradle tem dois tipos de script, e a aula 14 escreveu um de cada sem se demorar neles. **O
`settings.gradle.kts` diz do que o build é feito**: o nome e, na seção 06, os módulos. **O
`build.gradle.kts` diz como um projeto é construído**: quais plugins, de onde vêm as dependências, quais
dependências, e como as tarefas são configuradas. Os dois são Kotlin, com a API do Gradle à mão.

O script de build do planejador, lido de cima para baixo:

| bloco | diz |
|---|---|
| `plugins { … }` | que tipo de projeto é este: Kotlin na JVM, e um `application` com uma tarefa `run` |
| `repositories { … }` | de onde baixar as dependências |
| `dependencies { … }` | o que baixar, e para qual parte do build |
| `kotlin { … }`, `application { … }` | configurações do que esses plugins acrescentaram |
| `tasks.test { … }` | configurações de uma tarefa |

## Configurações: para qual parte do build é uma dependência

A palavra antes de cada dependência é uma **configuração**, e ela decide onde a biblioteca é visível:

| configuração | compila contra ela | presente quando o programa roda | vista por projetos que dependem deste |
|---|---|---|---|
| `implementation` | sim | sim | não |
| `api` | sim | sim | sim |
| `compileOnly` | sim | não | não |
| `runtimeOnly` | não | sim | não |
| `testImplementation` | só os testes | só os testes | não |

O `implementation` é a resposta padrão. O `api` é para uma biblioteca cujas funções públicas recebem ou
devolvem os tipos da dependência, de modo que quem usa a biblioteca precisa dessa dependência também.

O Gradle consegue imprimir em que uma configuração resultou, incluindo o que cada dependência trouxe
junto:

```
ana@vm:~/kt/planner$ ./gradlew -q dependencies --configuration runtimeClasspath

------------------------------------------------------------
Root project 'planner'
------------------------------------------------------------

runtimeClasspath - Runtime classpath of 'main'.
+--- org.jetbrains.kotlin:kotlin-stdlib:2.4.21
|    \--- org.jetbrains:annotations:13.0 -> 23.0.0
\--- org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0
     \--- org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.11.0
          +--- org.jetbrains:annotations:23.0.0
          +--- org.jetbrains.kotlinx:kotlinx-coroutines-bom:1.11.0
          |    +--- org.jetbrains.kotlinx:kotlinx-coroutines-core-jvm:1.11.0 (c)
          |    \--- org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0 (c)
          \--- org.jetbrains.kotlin:kotlin-stdlib:2.2.20 -> 2.4.21 (*)

(c) - A dependency constraint, not a dependency. The dependency affected by the constraint occurs elsewhere in the tree.
(*) - Indicates repeated occurrences of a transitive dependency subtree. Gradle expands transitive dependency subtrees only once per project; repeat occurrences only display the root of the subtree, followed by this annotation.

A web-based, searchable dependency report is available by adding the --scan option.
```

O planejador nomeou uma biblioteca além da biblioteca padrão, e essa biblioteca trouxe as dela. **Cada
linha abaixo de uma dependência é uma dependência daquela dependência**: o `kotlinx-coroutines-core` é
uma entrada pequena que aponta para o `kotlinx-coroutines-core-jvm`, o código para a JVM, e o `(c)` marca
uma restrição de versão, não mais um jar.

As setas são as linhas a ler. **`2.2.20 -> 2.4.21` quer dizer que uma biblioteca pediu uma biblioteca
padrão mais velha e recebeu a mais nova**, porque duas versões de uma biblioteca não cabem juntas num
classpath e o Gradle fica com a versão mais alta que alguém pediu. O `annotations` foi resolvido do
mesmo jeito, de 13.0 para 23.0.0. Isso em geral está certo, e quando um programa falha com
`NoSuchMethodError` depois de atualizar uma dependência, é neste relatório que se procura.
