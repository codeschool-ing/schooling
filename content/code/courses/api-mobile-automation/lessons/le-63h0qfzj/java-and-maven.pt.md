---
title: Java e Maven, instalados
version: 1
---

**O REST Assured é uma biblioteca Java, então os testes desta lição são programas Java.** Para
escrevê-los e rodá-los você precisa de duas coisas. Uma é um kit de desenvolvimento Java, que
compila e executa Java. A outra é uma ferramenta de build, que baixa as bibliotecas que um projeto
cita e roda os testes dele. A ferramenta de build aqui é o Maven. Uma IDE como o IntelliJ IDEA não é
uma das duas. Ela é um lugar confortável para escrever Java, e tudo abaixo funciona a partir de um
terminal e do editor que você já usa.

## Instalando os dois

No Ubuntu 24.04 ou no WSL, os dois vêm dos pacotes do próprio Ubuntu, numa linha só:

```sh
sudo apt-get install -y openjdk-21-jdk-headless maven
```

`openjdk-21` é o Java 21, uma versão com suporte de longo prazo e o JDK padrão do Ubuntu 24.04.
`-jdk` é o kit de desenvolvimento, com o compilador, e não só o ambiente que executa programas
prontos. `-headless` deixa de fora as bibliotecas de desenhar janelas, que um teste de API nunca
abre. O Maven chega na versão que o Ubuntu empacota, mais velha que a última versão do próprio
Maven. Isso importa uma vez, na seção 07, e o projeto da próxima seção é escrito para que não
importe em nenhum outro lugar.

Os dois respondem quando você pergunta a versão:

```
ana@laptop:~$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@laptop:~$ mvn -version
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 21.0.12.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v114", arch: "amd64", family: "unix"
```

Leia duas linhas da segunda resposta. `Apache Maven 3.8.7` é a ferramenta de build, e
`Java version: 21.0.12.1` é **o JDK com que o Maven vai compilar seus testes**. Ele nem sempre é o
que o `java -version` cita. Numa máquina com dois JDKs instalados, o Maven usa aquele para onde o
`JAVA_HOME` aponta, e um teste que compila num terminal e não em outro costuma ser isso.

Num Mac, o Homebrew instala os dois com `brew install openjdk@21 maven`, e os números de versão
vão ser outros. Isso não foi executado para este curso.

## O que o Maven faz por um projeto de testes

Três trabalhos, e cada linha do `pom.xml` da próxima seção serve a um deles.

- Ele busca bibliotecas. Um projeto lista do que depende por três nomes: um grupo, um artefato e uma
  versão, como `io.rest-assured`, `rest-assured`, `6.0.1`. O Maven baixa cada uma do **Maven
  Central**, o repositório público de bibliotecas Java, junto com tudo de que aquela biblioteca
  depende por sua vez. Ele as guarda em `~/.m2/repository`, para que o próximo projeto não as baixe
  de novo.
- Ele sabe onde fica cada coisa. O código de teste mora em `src/test/java`, em diretórios que
  repetem o nome do pacote, e as classes compiladas vão para `target`. Ninguém configura isso; um
  projeto que segue o layout ganha isso de graça, e um que não segue descobre que nada roda.
- Ele roda o build em fases. `mvn test` compila o código, compila os testes e depois os roda,
  parando na primeira fase que falhar. Cada fase é trabalho de um **plugin**: o plugin do compilador
  compila e o plugin Surefire roda os testes. Plugins também são bibliotecas, com versões próprias,
  e a seção 07 mostra por que o projeto cita essas versões em vez de aceitar as do Maven.
