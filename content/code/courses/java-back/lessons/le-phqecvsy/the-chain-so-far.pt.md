---
title: O JDK e o Maven, como o curso anterior os deixou
version: 1
---

Este curso é o terceiro de uma sequência, e a aula 1 de `java` instalou as ferramentas dele. Se
você veio por ela, **já tem tudo e não instala nada duas vezes**: pule os dois comandos abaixo e
continue a partir dos avisos. Se chegou direto aqui, a instalação são dois comandos na máquina
Ubuntu da seção anterior.

```sh
sudo apt update
sudo apt install -y openjdk-25-jdk maven
```

`openjdk-25-jdk` é o **JDK**, o Java Development Kit: o lançador `java`, que roda programas, e o
`javac`, o compilador, que um runtime sozinho não tem. `maven` é o Maven 3.8.7 empacotado pelo
Ubuntu, que põe o comando `mvn` no seu path. O `apt` imprime uma tela de progresso enquanto baixa e
instala os dois.

## Quatro linhas de aviso, e a linha que as cala

A aula 18 de `java` construiu um primeiro projeto Maven e deixou quatro linhas `WARNING:` no topo
de todo build. Qualquer execução do Maven que faz trabalho de verdade as imprime, mesmo uma que
falha logo de cara, e o `-q`, que nos outros casos esconde tudo menos os erros, não as esconde.
Aqui o Maven recebe o pedido de conferir um projeto na sua pasta pessoal, onde não há nenhum:

```
ana@vm:~$ mvn -q validate
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
[ERROR] The goal you specified requires a project to execute but there is no POM in this directory (/home/ana). Please verify you invoked Maven from the correct directory. -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MissingProjectException
```

O erro no fim é o esperado; não existe `pom.xml` em `~`. As quatro linhas acima dele são um aviso
só, e **ele não é sobre o seu código**: ele cita o `guava.jar` em `/usr/share/maven/lib`, uma
biblioteca com que o próprio Maven é feito, chamando uma parte do JDK que o Java 25 diz que será
removida. Você não tem como mudar o Guava do Maven 3.8.7, e o JDK imprime o aviso em toda execução,
então todo build seu abriria com quatro linhas sobre o código de outra pessoa.

Uma opção do JDK diz que esse acesso é permitido, e o `~/.mavenrc` é um arquivo de onde o comando
`mvn` lê opções antes de iniciar o Java. Acrescente a linha a ele e pergunte de novo:

```
ana@vm:~$ echo 'MAVEN_OPTS="--sun-misc-unsafe-memory-access=allow"' >> ~/.mavenrc
ana@vm:~$ mvn -q validate
[ERROR] The goal you specified requires a project to execute but there is no POM in this directory (/home/ana). Please verify you invoked Maven from the correct directory. -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MissingProjectException
```

O erro continua ali, porque continua não havendo projeto, e o aviso sumiu. A linha chega ao Maven e
a mais nada: um programa que você roda com `java` não é iniciado pelo `mvn` e nunca lê esse
arquivo.
