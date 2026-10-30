---
title: O wrapper fixa o Gradle
version: 1
---

Desde a lição 14 todo build começou com `./gradlew`, não `gradle`. A diferença é a razão inteira de um
projeto Gradle construir igual em duas máquinas. **O `gradlew` é um script pequeno, guardado no projeto,
que baixa uma versão exata do Gradle e a roda**, seja qual for o Gradle instalado na máquina, ou nenhum.
A versão mora num arquivo:

```
ana@vm:~/kt/planner$ cat gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.8.2-bin.zip
networkTimeout=10000
retries=0
retryBackOffMs=500
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

O `distributionUrl` nomeia a versão, 9.8.2. O primeiro `./gradlew` numa máquina baixa aquele zip para
`~/.gradle/wrapper/dists`, que foi a espera que a lição 14 viu; toda execução seguinte o encontra lá. O
resto são configurações desse download.

```
ana@vm:~/kt/planner$ ./gradlew --version

------------------------------------------------------------
Gradle 9.8.2
------------------------------------------------------------

Build time:    2026-10-19 16:29:26 UTC
Revision:      8de7bcf76e785507ad92f0741ab9235a430c95e6

Kotlin:        2.4.10
Groovy:        4.0.33
Ant:           Apache Ant(TM) version 1.10.17 compiled on April 6 2026
Launcher JVM:  21.0.12.1 (Ubuntu 21.0.12.1+1-1-24.04.4-Ubuntu)
Daemon JVM:    /usr/lib/jvm/java-21-openjdk-amd64 (no Daemon JVM specified, using current Java home)
OS:            Linux 6.18.44-fc-v185 amd64
```

Duas versões do Kotlin estão em jogo, e esta saída mostra a que as pessoas confundem. **A linha
`Kotlin: 2.4.10` é o Kotlin que o Gradle usa para rodar os seus scripts `.gradle.kts`**, embutido no
próprio Gradle. O Kotlin que compila o seu programa é o do plugin, `2.4.21`, nomeado no
`build.gradle.kts`. Os dois andam separados, e nenhum precisa coincidir com o outro.

## O que vai para o controle de versão

| arquivo | commitar? |
|---|---|
| `gradlew`, `gradlew.bat` | sim: os scripts para Linux e macOS, e para Windows |
| `gradle/wrapper/gradle-wrapper.jar`, `gradle-wrapper.properties` | sim: o baixador e a versão dele |
| `build/`, `.gradle/` | não: produzidos pelo build, e refeitos a partir do resto |

Atualizar o Gradle é um comando que reescreve o arquivo de propriedades, `./gradlew wrapper --gradle-version`
seguido da versão, e a mudança é uma linha que quem revisa consegue ler.
