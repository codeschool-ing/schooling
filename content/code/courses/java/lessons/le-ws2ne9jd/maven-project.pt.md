---
title: Um projeto Maven, e o layout que este curso mantém
version: 1
---

`javac -d out` com uma lista de arquivos funciona para duas classes e para de funcionar muito antes
de duzentas. Alguém tem de lembrar quais arquivos compilar, quais bibliotecas pôr no class path e
como empacotar o resultado. **O Maven é o programa que faz isso a partir de uma descrição do
projeto**, um arquivo chamado `pom.xml`, e a maioria dos projetos Java no trabalho é construída por
ele ou pelo Gradle, que faz o mesmo serviço. A lição 1 instalou o Maven 3.8.7 do Ubuntu.

Esta seção decide o layout de todo projeto deste curso e dos dois que vêm depois dele,
`java-functional` e `java-back`, então vale a pena acertá-lo de uma vez.

## O layout

O Maven espera os arquivos em lugares fixos, e em troca precisa ouvir quase nada:

| caminho | o que vai ali |
|---|---|
| `pom.xml` | a descrição do projeto, na raiz |
| `src/main/java` | o código-fonte do programa, em diretórios de pacote |
| `src/main/resources` | arquivos que o programa lê, copiados ao lado das classes |
| `src/test/java` | os testes, nos mesmos pacotes do que testam |
| `target` | tudo o que o Maven produz; apagado pelo `mvn clean`, nunca vai para o repositório |

**As decisões do curso**, que os dois cursos seguintes continuam: o `groupId` é `com.example`, o
`artifactId` é o nome do projeto, e toda classe mora sob o pacote `com.example.<artifactId>`, aqui
`com.example.library`. As classes são compiladas para a versão 25, e todo plugin tem versão fixada.

## O `pom.xml`

Crie um diretório `~/library` e salve isto nele como `pom.xml`:

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>",
      "note": "**O elemento raiz e a versão do modelo.** Todo `pom.xml` começa assim, e ninguém digita isto de memória: copie estas quatro linhas. `4.0.0` é a única versão de modelo que o Maven 3 entende. Não há, de propósito, a linha de declaração `<?xml ...?>`; ela é opcional, e o arquivo é UTF-8 de qualquer jeito."
    },
    {
      "code": "\n  <groupId>com.example</groupId>\n  <artifactId>library</artifactId>\n  <version>1.0-SNAPSHOT</version>",
      "note": "**As coordenadas do projeto, que juntas dão nome ao que ele constrói.** `groupId` é o domínio invertido, como num nome de pacote; `artifactId` é o nome do próprio projeto; `version` termina em `-SNAPSHOT` enquanto o código ainda muda. O jar leva o nome das duas últimas: `library-1.0-SNAPSHOT.jar`."
    },
    {
      "code": "\n  <properties>\n    <maven.compiler.release>25</maven.compiler.release>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n  </properties>",
      "note": "**Duas configurações para todo plugin que as lê.** `maven.compiler.release` é o `--release` da lição 1, entregue ao `javac`, para as classes saírem na versão 69 qualquer que seja o JDK que roda o Maven. A codificação impede que o build dependa do idioma configurado na máquina."
    },
    {
      "code": "\n  <build>\n    <pluginManagement>\n      <plugins>\n        <plugin>\n          <artifactId>maven-clean-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-resources-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-compiler-plugin</artifactId>\n          <version>3.15.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-surefire-plugin</artifactId>\n          <version>3.5.6</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-jar-plugin</artifactId>\n          <version>3.5.1</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-install-plugin</artifactId>\n          <version>3.2.0</version>\n        </plugin>\n      </plugins>\n    </pluginManagement>\n  </build>\n</project>",
      "note": "**Cada plugin que o build usa, fixado numa versão.** O Maven trabalha por meio de plugins, e sem uma versão aqui o Maven 3.8.7 do Ubuntu escolheria os padrões dele, anos mais velhos que estes e antigos demais para sequer conhecer o `maven.compiler.release`. Com elas, este Maven constrói exatamente o que um atual construiria. O `pluginManagement` fixa a versão onde quer que um plugin rode, sem fazê-lo rodar."
    }
  ]
}
```

Depois o programa. `App` vai em `src/main/java/com/example/library/App.java`:

```java
// src/main/java/com/example/library/App.java
package com.example.library;

public class App {
    public static void main(String[] args) {
        Book book = new Book("Effective Java");
        System.out.println("The library has " + book.title());
    }
}
```

`App` usa o `Book` da seção 02, agora no mesmo pacote; ele não é mostrado de novo, e uma cópia basta:

```
ana@vm:~/library$ mkdir -p src/main/java/com/example/library && cp ~/pkgs/src/com/example/library/Book.java src/main/java/com/example/library/
ana@vm:~/library$ find . -type f | sort
./pom.xml
./src/main/java/com/example/library/App.java
./src/main/java/com/example/library/Book.java
```

Três arquivos, e o caminho do pacote sob `src/main/java` é o mesmo que era sob `src`.

## O primeiro build baixa o Maven

Um build roda uma sequência fixa de **fases**, e `mvn package` roda cada fase até `package`: copiar os
recursos, compilar, compilar e rodar os testes, e empacotar um jar. Na primeira vez, o Maven não tem
nenhum dos plugins que fazem esse trabalho, então os baixa do Maven Central para `~/.m2/repository`
na sua máquina. A Ana guardou a saída desse primeiro build num arquivo, com `-B`, o modo batch, que
deixa de fora as cores e os contadores de progresso:

```
ana@vm:~/library$ mvn -B clean package > first-build.log; echo $?
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
0
ana@vm:~/library$ grep -c "Downloaded from" first-build.log
158
ana@vm:~/library$ tail -5 first-build.log
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  23.771 s
[INFO] Finished at: 2026-10-16T19:56:58-03:00
[INFO] ------------------------------------------------------------------------
```

**158 downloads**, os plugins fixados e as bibliotecas que eles usam, e o build seguinte não precisa
de nenhum. Apague `~/.m2/repository` e eles voltam no próximo build. O número muda um pouco entre
versões do Maven, e os tempos nas últimas linhas mudam a cada execução.

As quatro linhas `WARNING` foram para a tela e não para o arquivo, porque a JVM as escreve no fluxo
de erro antes de o Maven começar. Elas vêm da cópia que o próprio Maven tem de uma biblioteca chamada
Guava, em `/usr/share/maven/lib/guava.jar`, que usa o `sun.misc.Unsafe`, uma parte interna do JDK
cujos métodos de memória estão sendo aposentados. **Desde o Java 24 a JVM avisa, uma vez por
execução, quando eles são usados.** Elas não dizem nada sobre o seu projeto, aparecem em todo comando
`mvn` deste curso, e nada que você mude no `pom.xml` as tira. A seção 05 mostra o Maven rodando no
Java 21, onde elas não aparecem.

## Todo build depois desse

```
ana@vm:~/library$ mvn clean package
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:library >-------------------------
[INFO] Building library 1.0-SNAPSHOT
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-clean-plugin:3.5.0:clean (default-clean) @ library ---
[INFO] Deleting /home/ana/library/target
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ library ---
[INFO] skip non existing resourceDirectory /home/ana/library/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ library ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 2 source files with javac [debug release 25] to target/classes
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ library ---
[INFO] skip non existing resourceDirectory /home/ana/library/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ library ---
[INFO] No sources to compile
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ library ---
[INFO] No tests to run.
[INFO] 
[INFO] --- maven-jar-plugin:3.5.1:jar (default-jar) @ library ---
[INFO] Building jar: /home/ana/library/target/library-1.0-SNAPSHOT.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.813 s
[INFO] Finished at: 2026-10-16T19:57:02-03:00
[INFO] ------------------------------------------------------------------------
```

Leia de cima para baixo: cada linha `---` nomeia um plugin, a versão dele e o objetivo (goal) que
executou, na ordem das fases. `clean` apagou `target`, `resources` não encontrou `src/main/resources`
e disse isso, `compile` compilou dois arquivos `with javac [debug release 25]`, não havia testes, e
`jar` empacotou o resultado. **`BUILD SUCCESS` e um status de saída 0 são o veredito**; tudo acima
deles é o registro. O que ele produziu:

```
ana@vm:~/library$ find target -name "*.class" -o -name "*.jar" | sort
target/classes/com/example/library/App.class
target/classes/com/example/library/Book.class
target/library-1.0-SNAPSHOT.jar
ana@vm:~/library$ java -cp target/classes com.example.library.App
The library has Effective Java
```

As classes estão em `target/classes`, nos diretórios de pacote da seção 02, então
`java -cp target/classes` as executa como o `-cp out` fazia. O jar são as mesmas classes num arquivo
só, e a seção 05 o torna executável sozinho.
