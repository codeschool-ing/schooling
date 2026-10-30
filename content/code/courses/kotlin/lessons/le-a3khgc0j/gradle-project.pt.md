---
title: Um projeto Gradle, porque corrotinas são uma biblioteca
version: 1
---

Tudo até aqui veio com o compilador. As corrotinas não: a linguagem fornece a palavra `suspend`, e **a
biblioteca `kotlinx-coroutines` fornece tudo o que a usa**, `launch`, `async`, `delay`, os dispatchers
e, nas lições 16 e 17, o `Flow`. Uma biblioteca precisa ser baixada e posta no class path na
compilação e na execução, e controlar isso à mão deixa de ser razoável na segunda biblioteca. Esse é o
trabalho do Gradle, e o Gradle 9.8.2 já está na sua máquina desde a lição 1.

Esta seção monta o menor projeto que funciona; a lição 19 explica cada linha dele direito. Crie uma
pasta para ele, `~/kt/planner`, e dois arquivos no topo dela. O primeiro dá nome ao projeto:

```kotlin
// settings.gradle.kts
rootProject.name = "planner"
```

O segundo diz como construí-lo:

```schooling-example
{"language": "kotlin", "file": "build.gradle.kts", "parts": [{"code": "plugins {\n    kotlin(\"jvm\") version \"2.4.21\"\n    application\n}", "note": "O plugin do Kotlin, fixado na mesma 2.4.21 do compilador da lição 1, e o `application`, que acrescenta uma tarefa `run`."}, {"code": "repositories {\n    mavenCentral()\n}", "note": "De onde as bibliotecas são baixadas: o Maven Central, o repositório público onde a maioria das bibliotecas da JVM é publicada."}, {"code": "dependencies {\n    implementation(\"org.jetbrains.kotlinx:kotlinx-coroutines-core:1.11.0\")\n}", "note": "A única biblioteca, por grupo, nome e versão exata. O Gradle a baixa, junto com tudo de que ela depende, na primeira vez."}, {"code": "kotlin {\n    jvmToolchain(21)\n}", "note": "Compilar para o Java 21, o JDK instalado na lição 1."}, {"code": "application {\n    mainClass = providers.gradleProperty(\"main\").orElse(\"HelloKt\")\n}", "note": "Qual `main` rodar. Cada programa das lições 14 a 17 é um arquivo próprio, e `-Pmain=LaunchKt` na linha de comando escolhe um; sem ele, roda o `Hello.kt`."}]}
```

Os programas vão em `src/main/kotlin/`. O primeiro verifica que a biblioteca chegou:

```kotlin
// src/main/kotlin/Hello.kt
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    println("planner starting")
    delay(200)
    println("coroutines are here")
}
```

## O wrapper, e depois o primeiro build

`gradle wrapper` escreve um pequeno script, `gradlew`, que baixa exatamente a versão do Gradle com que
este projeto foi feito e a roda. **Daqui em diante todo build deste curso roda pelo `./gradlew`, nunca
pelo `gradle` do seu `PATH`**, então o projeto compila igual numa máquina com outro Gradle instalado,
ou com nenhum:

```
ana@vm:~/kt/planner$ gradle wrapper
Starting a Gradle Daemon (subsequent builds will be faster)
> Task :wrapper

BUILD SUCCESSFUL in 42s
1 actionable task: 1 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
ana@vm:~/kt/planner$ ls
build.gradle.kts
gradle
gradlew
gradlew.bat
settings.gradle.kts
src
ana@vm:~/kt/planner$ ./gradlew run
Fetching distribution.
Downloading https://services.gradle.org/distributions/gradle-9.8.2-bin.zip
..............10%..............20%...............30%..............40%...............50%..............60%...............70%..............80%...............90%..............100%
> Task :checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :processResources NO-SOURCE
> Task :compileKotlin
> Task :compileJava NO-SOURCE
> Task :classes UP-TO-DATE

> Task :run
planner starting
coroutines are here

BUILD SUCCESSFUL in 30s
2 actionable tasks: 2 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.2/userguide/configuration_cache_enabling.html
```

O primeiro `./gradlew` baixou o Gradle 9.8.2 de novo, em `~/.gradle/wrapper`, iniciou o daemon do
Gradle, um processo em segundo plano que deixa os builds seguintes rápidos, depois baixou o plugin do
Kotlin e a biblioteca de corrotinas, compilou o `Hello.kt` e o rodou. Esse primeiro build demora e
precisa de rede. **Todo build seguinte reaproveita o que foi baixado**:

```
ana@vm:~/kt/planner$ ./gradlew -q run
planner starting
coroutines are here
```

O `-q` esconde as linhas de progresso do próprio Gradle e deixa só o que o programa imprimiu, que é
como o resto destas lições roda programas.

## Quando o primeiro build falha

Duas falhas valem ser vistas no primeiro dia, e as duas nomeiam a causa. Elas foram feitas numa cópia
do projeto, para o original ficar intacto. Uma versão que não existe:

```
ana@vm:~/kt$ cp -r planner broken-version && cd broken-version && sed -i "s/1.11.0/1.99.0/" build.gradle.kts && ./gradlew -q run 2>&1 | head -9

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':compileKotlin' (registered by plugin 'org.jetbrains.kotlin.jvm').
> Could not resolve all files for configuration ':compileClasspath'.
   > Could not find org.jetbrains.kotlinx:kotlinx-coroutines-core:1.99.0.
     Searched in the following locations:
       - https://maven-central.storage-download.googleapis.com/maven2/org/jetbrains/kotlinx/kotlinx-coroutines-core/1.99.0/kotlinx-coroutines-core-1.99.0.pom
```

`Could not find` com as coordenadas completas quer dizer que o Gradle alcançou o repositório e o
arquivo não estava lá: **confira o grupo, o nome e a versão letra por letra**. Um problema de rede diz
`Could not resolve` ou `Could not GET`, com o endereço que ele tentou.

Uma toolchain que a máquina não tem:

```
ana@vm:~/kt$ cp -r planner broken-toolchain && cd broken-toolchain && sed -i "s/jvmToolchain(21)/jvmToolchain(17)/" build.gradle.kts && ./gradlew -q run 2>&1 | head -8

FAILURE: Build failed with an exception.

* What went wrong:
Could not determine the dependencies of task ':run'.
> Could not resolve all dependencies for configuration ':runtimeClasspath'.
   > Failed to calculate the value of task ':compileJava' property 'javaCompiler'.
      > Cannot find a Java installation on your machine (Linux 6.18.44-fc-v185 amd64) matching: {languageVersion=17, vendor=any vendor, implementation=vendor-specific, nativeImageCapable=false}. Toolchain download repositories have not been configured.
```

O `jvmToolchain(17)` pediu um Java 17 que não está instalado, e o Gradle diz isso, listando o que
procurou. Na máquina da lição 1 a resposta é pedir o 21, o JDK que está lá.
