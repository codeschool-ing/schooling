---
title: O que foi instalado, e o Java que você não pediu
version: 1
---

O `apt` pôs o JDK num diretório e disse ao shell onde encontrá-lo. Vale conhecer as duas metades
antes de algo dar errado, porque **a maioria das instalações de Java quebradas é uma máquina com dois
JDKs e um shell que escolheu o outro**. A máquina da Ana já tem dois, e ela instalou um.

## Todo JDK mora em `/usr/lib/jvm`

```
ana@vm:~$ ls -l /usr/lib/jvm
total 12
lrwxrwxrwx 1 root root   25 Oct  4  2023 default-java -> java-1.21.0-openjdk-amd64
lrwxrwxrwx 1 root root   21 Sep  4 03:14 java-1.21.0-openjdk-amd64 -> java-21-openjdk-amd64
lrwxrwxrwx 1 root root   21 Sep  4 03:24 java-1.25.0-openjdk-amd64 -> java-25-openjdk-amd64
drwxr-xr-x 7 root root 4096 Oct 16 19:30 java-21-openjdk-amd64
drwxr-xr-x 9 root root 4096 Oct 16 19:30 java-25-openjdk-amd64
drwxr-xr-x 2 root root 4096 Oct 16 19:30 openjdk-25
```

Dois diretórios de verdade, `java-25-openjdk-amd64` e `java-21-openjdk-amd64`, e links apontando
para eles. O 25 é o que a Ana pediu. **O 21 veio com o Maven.** O pacote `maven` do Ubuntu precisa de
*algum* runtime Java para rodar, e pede o padrão do arquivo:

```
ana@vm:~$ apt-cache depends default-jre-headless | head -2
default-jre-headless
  Depends: openjdk-21-jre-headless
```

No Ubuntu 24.04 o padrão é o 21, escolhido quando a versão foi lançada, em 2024, antes de o 25
existir. Então o Maven trouxe um **runtime** Java 21, sem compilador, e o link `default-java` aponta
para ele. Nada está errado ainda. É só a máquina que você tem, e a seção 04 mostra o único jeito em
que isso morde.

## Qual `java` é executado

Quando você digita `java`, o shell executa `/usr/bin/java`, e no Ubuntu esse arquivo é um link
gerenciado por um programa pequeno chamado `update-alternatives`. Cada JDK instalado se registra com
uma prioridade, e no modo automático vence a maior:

```
ana@vm:~$ update-alternatives --display java | head -3
java - auto mode
  link best version is /usr/lib/jvm/java-25-openjdk-amd64/bin/java
  link currently points to /usr/lib/jvm/java-25-openjdk-amd64/bin/java
```

**Modo automático, apontando para o 25.** Mais abaixo na mesma saída, que não aparece aqui, as duas
prioridades são 2511 e 2111, e o 25 vence porque o número dele é maior. `sudo update-alternatives
--config java` deixa você escolher à mão, e o curso nunca precisa disso.

## Trinta programas

O diretório do próprio JDK guarda os programas, e `/usr/bin` aponta para eles:

```
ana@vm:~$ ls -C -T 0 /usr/lib/jvm/java-25-openjdk-amd64/bin
jar        javadoc   jdb        jhsdb   jmap         jps         jstat       rmiregistry
jarsigner  javap     jdeprscan  jimage  jmod         jrunscript  jstatd      serialver
java       jcmd      jdeps      jinfo   jnativescan  jshell      jwebserver
javac      jconsole  jfr        jlink   jpackage     jstack      keytool
ana@vm:~$ du -sh /usr/lib/jvm/java-25-openjdk-amd64 /usr/lib/jvm/java-21-openjdk-amd64
331M	/usr/lib/jvm/java-25-openjdk-amd64
194M	/usr/lib/jvm/java-21-openjdk-amd64
```

Trinta programas em 331 MB. **Este curso usa mais ou menos um terço deles**, e cada um chega na lição
que precisa dele:

| programa | o que faz | primeiro uso |
|---|---|---|
| `javac` | compila código `.java` em arquivos `.class` | seção 05 desta lição |
| `java` | inicia uma JVM e executa um programa nela | seção 05 desta lição |
| `javap` | imprime o que há dentro de um arquivo `.class` | seção 05 desta lição |
| `jshell` | executa Java uma linha por vez, para experimentar | lição 3 |
| `jps`, `jcmd` | listam as JVMs em execução e fazem perguntas a uma delas | lição 2 |
| `javadoc` | transforma comentários de documentação em páginas web | lição 3 |
| `jar` | empacota classes num arquivo só | lição 18 |
| `jdeps`, `jlink` | descobrem do que um programa precisa, e montam um runtime só com isso | lição 40 |

O diretório do Java 21 é menor porque é só um runtime: tem o `java` e mais alguns, e nenhum `javac`.
Essa diferença é a segunda falha da seção 04.

O `jshell` também responde a versão, e na primeiríssima vez em que roda ele diz outra coisa antes:

```
ana@vm:~$ jshell --version
Oct 16, 2026 7:30:57 PM java.util.prefs.FileSystemPreferences setupUserRoot
INFO: Created user preferences directory.
jshell 25.0.4.1
ana@vm:~$ jshell --version
jshell 25.0.4.1
```

As duas linhas `INFO` não são erro. O Java guarda um pequeno depósito de preferências do usuário no
seu diretório pessoal, e o primeiro programa que precisa dele o cria e avisa que criou. A segunda
execução o encontra lá e fica quieta. **Uma linha que diz `INFO` ou `WARNING` é a JVM lhe contando
alguma coisa; só um status de saída diferente de 0 diz que o programa falhou**, e a lição 2 é sobre
esse número.
