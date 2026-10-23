---
title: Quando a instalação falha
version: 1
---

Uma instalação que falha raramente diz "sua instalação falhou". Ela diz algo sobre um pacote, um
comando ou a versão de um arquivo de classe, e a tentação é remover tudo e começar de novo. **Cada
falha abaixo tem uma causa, e a mensagem a nomeia** se você a ler até o fim. As quatro foram
produzidas de propósito, numa cópia nova do mesmo Ubuntu 24.04.

## `Unable to locate package openjdk-25-jdk`

O `apt` instala a partir de uma lista de pacotes que guarda no disco, e essa lista é tão recente
quanto o último `apt update`. Uma máquina que nunca rodou um, o que descreve muita máquina virtual
recém-criada, não conhece pacote nenhum:

```
ana@vm:~$ sudo apt install -y openjdk-25-jdk 2>&1 | tail -3; echo $?
Reading package lists...
Building dependency tree...
E: Unable to locate package openjdk-25-jdk
0
ana@vm:~$ sudo apt update 2>&1 | tail -1
151 packages can be upgraded. Run 'apt list --upgradable' to see them.
ana@vm:~$ apt-cache policy openjdk-25-jdk | head -3
openjdk-25-jdk:
  Installed: (none)
  Candidate: 25.0.4.1+1-1~24.04.4
```

**Rode `sudo apt update` e tente de novo.** Depois dele, o `apt-cache policy` mostra uma versão
candidata, e a instalação funciona. Se o candidato continuar `(none)`, o pacote não está em nenhum
arquivo que a máquina lê. O Ubuntu 24.04 traz o `openjdk-25-jdk` em `noble-updates`, no componente
`universe`, e um sistema configurado sem um dos dois não o enxerga.

O `0` merece um segundo olhar. O `echo $?` imprimiu o status de saída do **último** comando do pipe,
que é o `tail`, e o `tail` deu certo. O `apt` falhou e o pipe escondeu. As palavras na tela estavam
certas, e só o número mentiu: um script que conferisse o status depois daquela linha teria seguido
em frente.

## `javac: command not found`, com o `java` funcionando

O JDK é o runtime mais as ferramentas de construção. Instale só o runtime e você consegue executar
programas Java, mas não compilar nenhum:

```
ana@vm:~$ sudo apt install -y openjdk-25-jre-headless >/dev/null 2>&1; java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version; echo $?
bash: line 1: javac: command not found
127
```

**O status de saída 127 é o número do próprio shell para "comando inexistente"**, então a mensagem
vem do `bash` e não do Java. Os nomes dos pacotes carregam a diferença: um pacote `-jre` é um runtime
e um pacote `-jdk` é o kit de desenvolvimento. `-headless` quer dizer sem as bibliotecas de janelas e
gráficos, de que um servidor não precisa. A correção é a linha da seção 02, que instala o
`openjdk-25-jdk` e puxa todas as outras peças junto.

## `UnsupportedClassVersionError`

Esta precisa da máquina da seção 03, com os seus dois Javas, e do `Hello.class` que a seção 05
compila. Execute-o com o Java 21 que veio com o Maven, em vez do 25 que o compilou:

```
ana@vm:~/jvm$ /usr/lib/jvm/java-21-openjdk-amd64/bin/java Hello; echo $?
Error: LinkageError occurred while loading main class Hello
	java.lang.UnsupportedClassVersionError: Hello has been compiled by a more recent version of the Java Runtime (class file version 69.0), this version of the Java Runtime only recognizes class file versions up to 65.0
1
```

**Todo arquivo de classe registra a versão do Java para a qual foi compilado**, como um número que a
seção 05 lê de dentro do arquivo: 69 é o Java 25 e 65 é o Java 21. Uma JVM executa toda versão até a
dela e recusa qualquer uma mais nova, porque um arquivo de classe mais novo pode usar instruções de
que ela nunca ouviu falar. Na prática a mensagem quer dizer uma de duas coisas. Ou rodou o `java`
errado, ou o código foi compilado para uma versão mais nova que a da máquina onde ele tem de rodar. A
seção 06 mostra a segunda correção, o `--release`.

## O Maven no Java errado

O Maven roda em qualquer Java que encontre, e olha a variável `JAVA_HOME` antes de tudo. Muito guia
de instalação na web manda defini-la, e o valor óbvio no Ubuntu é `/usr/lib/jvm/default-java`, o
link que a seção 03 encontrou. Defina esse valor e veja qual Java o Maven escolhe:

```
ana@vm:~/jvm$ JAVA_HOME=/usr/lib/jvm/default-java mvn -v | grep "Java version"
Java version: 21.0.12.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
ana@vm:~/jvm$ mvn -v | grep "Java version"
Java version: 25.0.4.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-25-openjdk-amd64
```

**Com o `default-java`, o Maven roda no 21, e nada diz isso a menos que você pergunte.** Funciona até
o primeiro projeto pedir o Java 25, e aí o compilador recusa com uma mensagem que a lição 18
reproduz. O curso deixa o `JAVA_HOME` sem valor, e o segundo comando mostra o que isso lhe dá: o
Maven segue o `/usr/bin/java` até o 25. Se um guia ou um `~/.profile` antigo o define,
`echo $JAVA_HOME` mostra o valor e `unset JAVA_HOME` o tira do shell atual.

**O que quer que tenha dado errado, os três primeiros comandos são os mesmos**: `java -version`,
`javac -version` e `mvn -v`. Quando os três dizem 25, o laboratório está certo.
