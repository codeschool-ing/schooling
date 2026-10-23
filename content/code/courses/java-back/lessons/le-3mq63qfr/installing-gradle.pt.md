---
title: Instalando o Gradle, uma vez
version: 1
---

O repositório do Ubuntu tem um pacote `gradle`, e ele é o errado para instalar. Está anos atrás da
versão atual e não consegue compilar o projeto desta lição: o Gradle precisa ser mais novo que o
Java em que roda, e o Java 25 exige o Gradle 9.1 ou posterior. **O Gradle é instalado pela própria
distribuição, um arquivo zip**, e num projeto você o instala uma vez, para uma única tarefa, que as
duas próximas seções explicam.

## O zip e o checksum dele

O Gradle publica todas as versões em `services.gradle.org/distributions`. Esta lição usa a 9.8.1:

```
ana@vm:~$ curl -sLO https://services.gradle.org/distributions/gradle-9.8.1-bin.zip
ana@vm:~$ ls -l gradle-9.8.1-bin.zip
-rw-r--r-- 1 ana ana 151620101 Oct 22 19:33 gradle-9.8.1-bin.zip
```

O `-L` segue redirecionamentos, e isso importa aqui: o endereço responde com um redirecionamento
para o GitHub, onde o arquivo de fato fica. O `-O` mantém o nome do arquivo. O zip `-bin` traz o
Gradle em si; o zip `-all` acrescenta os fontes e a documentação, que um editor pode usar e um
build nunca usa.

Um arquivo que passou por dois servidores deve ser conferido antes de qualquer coisa rodar a partir
dele. **O checksum SHA-256 dos bytes no seu disco** tem de ser igual ao que o Gradle publicou para a
versão. O site do Gradle mostra esse valor ao lado de cada download, na página de checksums das
versões, e o mesmo valor está no serviço de versões, que um comando consegue ler:

```
ana@vm:~$ sha256sum gradle-9.8.1-bin.zip
dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f  gradle-9.8.1-bin.zip
ana@vm:~$ curl -s https://services.gradle.org/versions/all | python3 -c 'import json, sys; print(next(v["checksum"] for v in json.load(sys.stdin) if v["version"] == "9.8.1"))'
dce76f55f8e251a3a1f130eb120f30b3d271de2b76c9b0729d316b5a1b6dc01f
```

As duas linhas coincidem. Comparar 64 caracteres no olho é o ponto fraco deste passo, e a seção
depois da próxima entrega a comparação a um programa, em toda máquina que um dia compilar o
projeto.

## Descompactando onde ninguém mais olha

O zip se abre num diretório só, e um diretório na sua home não precisa de `sudo`:

```
ana@vm:~$ mkdir -p ~/opt && unzip -q gradle-9.8.1-bin.zip -d ~/opt
ana@vm:~$ ls ~/opt/gradle-9.8.1
LICENSE
NOTICE
README
bin
init.d
lib
```

Um Ubuntu Server recém-instalado pode não ter o `unzip`, e aí o shell avisa que não encontra o
comando. `sudo apt install unzip` resolve; esta máquina já tinha o programa, então esse comando
aparece aqui e não foi executado.

Rode o Gradle pelo caminho completo:

```
ana@vm:~$ ~/opt/gradle-9.8.1/bin/gradle --version

Welcome to Gradle 9.8.1!

Here are the highlights of this release:
 - Java 27 support
 - Maven mirror settings reuse
 - Linked problem locations in build output

For more details see https://docs.gradle.org/9.8.1/release-notes.html


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

ana@vm:~$ command -v gradle || echo "not on PATH"
not on PATH
```

O texto de boas-vindas aparece na primeira vez que cada versão do Gradle roda para um usuário, e
não volta. Abaixo dele, leia três linhas. `Kotlin: 2.4.10` é a linguagem em que o build script da
próxima seção é escrito, e o Gradle traz o próprio compilador dela, então não há mais nada a
instalar. `Launcher JVM` é o Java que iniciou o Gradle: o JDK 25 do repositório do Ubuntu, o mesmo
que a lição 1 de `java` instalou. `Daemon JVM` é o Java do processo em segundo plano que faz o build de
verdade, que a última seção desta lição apresenta, e aqui é o mesmo JDK.

**O `gradle` fica fora do `PATH` de propósito.** A maioria dos guias o coloca lá. Esta lição não
precisa, porque o Gradle instalado vai rodar só mais uma vez, pelo caminho completo, para dar um
wrapper ao projeto. Depois disso todo build passa pelo `./gradlew` do próprio projeto, e a cópia em
`~/opt` só volta a importar no dia em que você começar outro projeto.
