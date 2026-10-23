---
title: O wrapper, e por que a equipe faz commit dele
version: 1
---

Um build que depende do Gradle que cada pessoa da equipe instalou é um build que se comporta
diferente em cada máquina. Um Gradle anterior ao 9.1 nem roda no Java 25, e duas versões com um ano
de distância diferem no que presumem, como o launcher do JUnit mostra na seção sobre tarefas. **O
wrapper tira essa escolha da máquina**: um script e um jar pequenos, no commit junto com o projeto,
que baixam exatamente o Gradle que o projeto nomeia e rodam o build com ele.

## Gerando o wrapper

Esta é a outra vez em que o Gradle de `~/opt` roda. A tarefa `wrapper` escreve os arquivos do
wrapper, e as duas opções fixam a versão e o checksum dela, o mesmo conferido no olho na primeira
seção:

```
ana@vm:~/isbn-gradle$ ~/opt/gradle-9.8.1/bin/gradle wrapper --gradle-version 9.8.1 --gradle-distribution-sha256-sum dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f
Starting a Gradle Daemon (subsequent builds will be faster)
> Task :wrapper

BUILD SUCCESSFUL in 16s
1 actionable task: 1 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
ana@vm:~/isbn-gradle$ find . -type f -not -path "./src/*" -not -path "./.gradle/*" | sort
./build.gradle.kts
./gradle.properties
./gradle/wrapper/gradle-wrapper.jar
./gradle/wrapper/gradle-wrapper.properties
./gradlew
./gradlew.bat
./settings.gradle.kts
```

Dezesseis segundos para uma tarefa minúscula são, em boa parte, o Gradle iniciando o daemon que
ele menciona e compilando os dois scripts Kotlin pela primeira vez; a última seção volta aos dois. A
sugestão sobre o cache de configuração é retomada na seção sobre build incremental.

Quatro arquivos são novos:

| arquivo | o que é |
|---|---|
| `gradlew` | o script que você roda no Linux e no macOS |
| `gradlew.bat` | o mesmo para Windows |
| `gradle/wrapper/gradle-wrapper.jar` | um programa pequeno que os scripts iniciam, que lê as propriedades e busca o Gradle |
| `gradle/wrapper/gradle-wrapper.properties` | qual Gradle, de onde, e o checksum dele |

O arquivo de propriedades é o que vale ler:

```
ana@vm:~/isbn-gradle$ cat gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionSha256Sum=dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f
distributionUrl=https\://services.gradle.org/distributions/gradle-9.8.1-bin.zip
networkTimeout=10000
retries=0
retryBackOffMs=500
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

`distributionUrl` é a versão, escrita como o endereço do zip dela. A barra invertida antes dos dois
pontos é como um arquivo de propriedades escapa esse caractere, e não faz parte do endereço.
`distributionSha256Sum` é o checksum contra o qual o wrapper compara todo download. Se os bytes que
chegam forem diferentes, ele os recusa e para. A comparação que a primeira seção fez no olho, numa
máquina só, agora é feita por um programa em toda máquina. As linhas `dists` dizem onde
ficam as versões baixadas, dentro de `~/.gradle`.

## O primeiro ./gradlew

Rode o wrapper em vez do Gradle instalado:

```
ana@vm:~/isbn-gradle$ ./gradlew --version
Fetching distribution.
Downloading https://services.gradle.org/distributions/gradle-9.8.1-bin.zip
..............10%..............20%...............30%..............40%...............50%..............60%...............70%..............80%...............90%..............100%

------------------------------------------------------------
Gradle 9.8.1
------------------------------------------------------------

Build time:    2026-10-07 16:57:46 UTC
Revision:      39daf39feb60a18b1b6ddccde53366522fef516f

Kotlin:        2.4.10
Groovy:        4.0.33
Ant:           Apache Ant(TM) version 1.10.17 compiled on April 6 2026
Launcher JVM:  25.0.4.1 (Ubuntu 25.0.4.1+1-1-24.04.4-Ubuntu)
Daemon JVM:    /usr/lib/jvm/java-25-openjdk-amd64 (no Daemon JVM specified, using current Java home)
OS:            Linux 6.18.44-fc-v153 amd64

ana@vm:~/isbn-gradle$ ls ~/.gradle/wrapper/dists/
gradle-9.8.1-bin
```

**Ele baixou o Gradle de novo**, o mesmo zip que você já tem em `~/opt`. O wrapper não procura um
Gradle instalado e nunca usa um: lê o `distributionUrl`, baixa esse zip uma vez para
`~/.gradle/wrapper/dists`, confere, e o reaproveita em todo build seguinte de todo projeto que
nomeia a mesma versão. Essa indiferença é o objetivo. Um colega com o Gradle 8 instalado, um
servidor de CI sem nenhum e você rodam todos o 9.8.1, porque o projeto disse.

A imagem errada mais comum é que o wrapper é uma comodidade para quem não instalou o Gradle. É o
contrário: **é assim que um projeto escolhe a versão da sua ferramenta de build**, e é por isso que
a documentação do Gradle e a maioria dos projetos Gradle escrevem `./gradlew` e quase nunca
`gradle`. Atualizar é uma mudança no arquivo de propriedades, feita rodando de novo a tarefa
`wrapper` com uma versão nova, e ela chega a toda máquina pelo mesmo commit que qualquer outra
mudança.

## O que vai para o repositório

Os quatro arquivos do wrapper vão para o commit junto com os build scripts e os fontes, inclusive o
jar, que é praticamente o único binário que um repositório Java costuma carregar. Dois diretórios
não vão: `build/`, que guarda tudo o que o build produz, e `.gradle/`, que o Gradle mantém dentro
do projeto para controle próprio. Os dois são recriados pelo próximo build, e os dois pertencem ao
`.gitignore`. Ignorar arquivos é Git comum, e num projeto Gradle essas duas linhas são tudo.
