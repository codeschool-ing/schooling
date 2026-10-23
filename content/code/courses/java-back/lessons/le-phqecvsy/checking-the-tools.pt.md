---
title: Conferindo o que está instalado
version: 1
---

Três comandos dizem se a máquina está pronta, e cada um imprime mais que um número de versão. Leia
tudo uma vez, porque as linhas que parecem ruído são as que explicam uma falha mais tarde.

```
ana@vm:~$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version
javac 25.0.4.1
```

O `java -version` nomeia o **runtime**: OpenJDK, a versão 25.0.4.1 e o build que o Ubuntu
empacotou (o `24.04` no texto do build é a versão do Ubuntu para a qual ele foi feito). O
`javac -version` nomeia o **compilador**, e ele importa à parte: uma máquina com só um runtime Java
instalado responde ao primeiro comando e não ao segundo, e o Maven precisa dos dois.

```
ana@vm:~$ mvn -v
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 25.0.4.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-25-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v153", arch: "amd64", family: "unix"
```

O `mvn -v` é o que se lê linha por linha, porque ele diz **qual Java o Maven vai usar de fato**, e
esse nem sempre é o que o `java -version` informou:

- `Maven home` é onde o próprio Maven está instalado, `/usr/share/maven` no pacote do Ubuntu.
- `Java version` e `runtime` são o JDK que vai compilar o seu código. O Maven o encontra pela
  variável `JAVA_HOME`, se ela estiver definida, e pelo `java` do seu path, se não estiver.
- `platform encoding: UTF-8` é o padrão com que o JDK leria arquivos-fonte. O projeto desta aula
  declara a codificação no pom, então uma máquina configurada com outra constrói do mesmo jeito.
- `OS name` e `arch` são a máquina. A sua vai mostrar outra versão de kernel.

Quando os três respondem com 25 e o caminho do runtime termina em `java-25-openjdk-amd64` (ou
`arm64`), a máquina está pronta.
