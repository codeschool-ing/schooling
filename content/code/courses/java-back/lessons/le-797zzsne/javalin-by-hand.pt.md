---
title: Um serviço Javalin à mão
version: 1
---

Esta seção constrói o menor serviço que faz parte do trabalho do bookshop: listar os livros e buscar
um pelo id. Ele mora no próprio diretório, `~/javalin-hello`, ao lado do bookshop, e são dois arquivos.
Crie o diretório para o código-fonte:

```sh
mkdir -p ~/javalin-hello/src/main/java/com/example/hello
```

e salve isto como `~/javalin-hello/pom.xml`. Ele deixa uma dependência de fora de propósito, por um
motivo que a primeira execução mostra:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>javalin-hello</artifactId>
  <version>0.1.0</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.javalin</groupId>
      <artifactId>javalin</artifactId>
      <version>7.2.3</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-simple</artifactId>
      <version>2.0.18</version>
    </dependency>
  </dependencies>

  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-clean-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-resources-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>3.15.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>3.5.6</version>
        </plugin>
        <plugin>
          <artifactId>maven-jar-plugin</artifactId>
          <version>3.5.1</version>
        </plugin>
      </plugins>
    </pluginManagement>
    <plugins>
      <plugin>
        <artifactId>maven-shade-plugin</artifactId>
        <version>3.6.2</version>
        <executions>
          <execution>
            <phase>package</phase>
            <goals>
              <goal>shade</goal>
            </goals>
            <configuration>
              <transformers>
                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                  <mainClass>com.example.hello.HelloApp</mainClass>
                </transformer>
              </transformers>
            </configuration>
          </execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
```

Leia-o contra o pom do bookshop. **Não há parent**, então nada gerencia versões: cada dependência
diz a sua, e os plugins são fixados do jeito que a aula 1 os fixou, porque as versões de plugin
embutidas no Maven 3.8.7 são antigas. São duas dependências, o Javalin e o `slf4j-simple`, o backend
mais simples para a fachada SLF4J por onde o Javalin escreve o log (a aula 16 trata desse par). O
**maven-shade-plugin** está ali porque o jar que o Maven monta só tem as suas próprias classes, como a
aula 1 viu quando precisou pôr as dependências no classpath à mão. O shade copia as classes de cada
dependência para um jar só e escreve o `Main-Class` no manifesto dele, então o `java -jar` basta. O
plugin do Spring Boot resolve o mesmo problema de outro jeito, guardando cada biblioteca como um jar
dentro do jar, e a aula 23 abre um.

Depois salve o programa inteiro como `src/main/java/com/example/hello/HelloApp.java`:

```schooling-example
{"language": "java", "file": "src/main/java/com/example/hello/HelloApp.java", "parts": [{"code": "package com.example.hello;\n\nimport java.util.List;\n\nimport io.javalin.Javalin;\nimport io.javalin.http.NotFoundResponse;\n", "note": "Dois imports do Javalin e nenhum de um pacote de anotações: nada neste arquivo é lido por reflexão."}, {"code": "public class HelloApp {\n\n    record Book(long id, String isbn, String title, String author, int priceCents) {\n    }\n\n    static final List<Book> BOOKS = List.of(\n            new Book(1, \"9786500000016\", \"Dom Casmurro\", \"Machado de Assis\", 3990),\n            new Book(2, \"9786500000023\", \"The Time Machine\", \"H. G. Wells\", 2950),\n            new Book(3, \"9786500000030\", \"Frankenstein\", \"Mary Shelley\", 3500));\n", "note": "Os dados com que o serviço responde: os mesmos três livros que o repositório em memória da aula 5 semeia, numa lista. Um `record` dentro da classe mantém o programa num arquivo só."}, {"code": "    public static void main(String[] args) {\n        Javalin.create(config -> {", "note": "O `main` é a aplicação inteira. `Javalin.create` recebe um lambda que preenche a configuração, e no Javalin 7 as rotas fazem parte dela, então todas são conhecidas antes de o servidor iniciar."}, {"code": "            config.routes.get(\"/books\", ctx -> ctx.json(BOOKS));", "note": "Uma rota é um caminho e um lambda. O `ctx` é a requisição e a resposta ao mesmo tempo; `ctx.json` transforma a lista em JSON e define o tipo de conteúdo."}, {"code": "            config.routes.get(\"/books/{id}\", ctx -> {\n                long id = ctx.pathParamAsClass(\"id\", Long.class).get();\n                Book book = BOOKS.stream()\n                        .filter(b -> b.id() == id)\n                        .findFirst()\n                        .orElseThrow(() -> new NotFoundResponse(\"No book with id \" + id));\n                ctx.json(book);\n            });", "note": "`pathParamAsClass` converte o `{id}` e recusa com um 400 um valor que não é número. `NotFoundResponse` é a exceção do Javalin para um 404: lançada de um handler, ela vira a resposta."}, {"code": "        }).start(7070);\n    }\n}", "note": "`start(7070)` abre o Jetty na porta 7070, que o bookshop não usa, então os dois podem rodar ao mesmo tempo."}]}
```

Confira que os dois arquivos estão onde o Maven os espera, depois faça o build. O `-B` é o modo batch
do Maven e o `-q` o deixa calado a menos que algo falhe, então um build que dá certo não imprime nada:

```
ana@vm:~/javalin-hello$ find . -type f | sort
./pom.xml
./src/main/java/com/example/hello/HelloApp.java
```

```
ana@vm:~/javalin-hello$ mvn -B -q package
ana@vm:~/javalin-hello$ ls -l target/*.jar
-rw-r--r-- 1 ana ana 7170648 Oct 22 19:20 target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana    5188 Oct 22 19:20 target/original-javalin-hello-0.1.0.jar
```

Dois jars. O `original-javalin-hello-0.1.0.jar` é o de antes do shade, 5.188 bytes: a sua classe
e os metadados do próprio Maven; o outro é a mesma classe com o Javalin, o Jetty, a biblioteca padrão do Kotlin e o logger
copiados para dentro. Inicie-o num terminal e deixe rodando. De um segundo terminal, peça os livros:

```
ana@vm:~/javalin-hello$ curl -s -o /dev/null -w '%{http_code}\n' localhost:7070/books
500
```

Um 500. O primeiro terminal diz por quê, abaixo do banner que o Javalin imprime ao iniciar:

```
ana@vm:~/javalin-hello$ java -jar target/javalin-hello-0.1.0.jar
[main] INFO io.javalin.Javalin - Starting Javalin ...
[main] INFO org.eclipse.jetty.server.Server - jetty-12.1.12; built: 2026-08-03T22:37:55.389Z; git: 10dd3948f37767b84cc2c62358364f042e51dbbe; jvm 25.0.4.1+1-1-24.04.4-Ubuntu
[main] INFO org.eclipse.jetty.session.DefaultSessionIdManager - Session workerName=node0
[main] INFO org.eclipse.jetty.server.handler.ContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.ee10.servlet.ServletContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.server.AbstractConnector - Started oejs.ServerConnector@59505b48{HTTP/1.1, (http/1.1)}{0.0.0.0:7070}
[main] INFO org.eclipse.jetty.server.Server - Started oejs.Server@48aca48b{STARTING}[12.1.12,sto=0] @611ms
[main] INFO io.javalin.Javalin - 
       __                  ___          _____
      / /___ __   ______ _/ (_)___     /__  /
 __  / / __ `/ | / / __ `/ / / __ \      / /
/ /_/ / /_/ /| |/ / /_/ / / / / / /     / /
\____/\__,_/ |___/\__,_/_/_/_/ /_/     /_/

       https://javalin.io/documentation

[main] INFO io.javalin.Javalin - Javalin started in 2209ms \o/
[main] INFO io.javalin.Javalin - Listening on http://localhost:7070/
[main] INFO io.javalin.Javalin - You are running Javalin 7.2.3 (released August 11, 2026).
[JettyServerThreadPool-33] WARN io.javalin.Javalin - 
#########################################################################
It looks like you don't have an object mapper configured.
The easiest way to fix this is to simply add the 'jackson-databind' dependency:

pom.xml:
<dependency>
    <groupId>com.fasterxml.jackson.core</groupId>
    <artifactId>jackson-databind</artifactId>
    <version>2.22.1</version>
</dependency>

build.gradle or build.gradle.kts:
implementation("com.fasterxml.jackson.core:jackson-databind:2.22.1")

If you're using Kotlin, you will need to add 'jackson-module-kotlin'.

To use a different object mapper, visit https://javalin.io/documentation#configuring-the-json-mapper
#########################################################################
```

O `ctx.json` precisa de algo que transforme um objeto Java em JSON, e o Javalin não traz um. **O
mapper padrão dele usa o Jackson 2 se o Jackson 2 estiver no classpath**; não havia nenhum, e ele disse
isso no log e no corpo do 500. O bookshop nunca passou por isso, porque o `spring-boot-starter-webmvc`
trouxe o Jackson junto e a autoconfiguração da aula 4 o preparou. Com uma biblioteca, escolher o mapper de
JSON é trabalho seu, e esquecer dele é um 500. Repare também quando o erro
apareceu: na primeira requisição que precisou de JSON, e não no início.

Pare o servidor com Ctrl+C no primeiro terminal e troque o bloco `<dependencies>` do pom por este. Ele
acrescenta o `jackson-databind` 2, a versão que a mensagem do Javalin cita, e não o Jackson 3 que o
bookshop usa, porque é para o 2 que o mapper padrão do Javalin foi escrito:

```xml
  <dependencies>
    <dependency>
      <groupId>io.javalin</groupId>
      <artifactId>javalin</artifactId>
      <version>7.2.3</version>
    </dependency>
    <dependency>
      <groupId>com.fasterxml.jackson.core</groupId>
      <artifactId>jackson-databind</artifactId>
      <version>2.22.1</version>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-simple</artifactId>
      <version>2.0.18</version>
    </dependency>
  </dependencies>
```

Faça o build de novo, e o jar cresce com o Jackson:

```
ana@vm:~/javalin-hello$ mvn -B -q package
ana@vm:~/javalin-hello$ ls -l target/javalin-hello-0.1.0.jar
-rw-r--r-- 1 ana ana 9534256 Oct 22 19:20 target/javalin-hello-0.1.0.jar
```

Inicie-o no primeiro terminal:

```
ana@vm:~/javalin-hello$ java -jar target/javalin-hello-0.1.0.jar
[main] INFO io.javalin.Javalin - Starting Javalin ...
[main] INFO org.eclipse.jetty.server.Server - jetty-12.1.12; built: 2026-08-03T22:37:55.389Z; git: 10dd3948f37767b84cc2c62358364f042e51dbbe; jvm 25.0.4.1+1-1-24.04.4-Ubuntu
[main] INFO org.eclipse.jetty.session.DefaultSessionIdManager - Session workerName=node0
[main] INFO org.eclipse.jetty.server.handler.ContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.ee10.servlet.ServletContextHandler - Started oeje10s.ServletContextHandler@611889f4{ROOT,/,b=null,a=AVAILABLE,h=oeje10s.SessionHandler@1da2cb77{STARTED}}
[main] INFO org.eclipse.jetty.server.AbstractConnector - Started oejs.ServerConnector@59505b48{HTTP/1.1, (http/1.1)}{0.0.0.0:7070}
[main] INFO org.eclipse.jetty.server.Server - Started oejs.Server@48aca48b{STARTING}[12.1.12,sto=0] @145ms
[main] INFO io.javalin.Javalin - 
       __                  ___          _____
      / /___ __   ______ _/ (_)___     /__  /
 __  / / __ `/ | / / __ `/ / / __ \      / /
/ /_/ / /_/ /| |/ / /_/ / / / / / /     / /
\____/\__,_/ |___/\__,_/_/_/_/ /_/     /_/

       https://javalin.io/documentation

[main] INFO io.javalin.Javalin - Javalin started in 749ms \o/
[main] INFO io.javalin.Javalin - Listening on http://localhost:7070/
[main] INFO io.javalin.Javalin - You are running Javalin 7.2.3 (released August 11, 2026).
```

`Javalin started in 749ms` é o cronômetro do próprio Javalin; a próxima seção diz por que
esse não é o número a comparar. Agora o segundo terminal:

```
ana@vm:~/javalin-hello$ curl -s localhost:7070/books | python3 -m json.tool
[
    {
        "id": 1,
        "isbn": "9786500000016",
        "title": "Dom Casmurro",
        "author": "Machado de Assis",
        "priceCents": 3990
    },
    {
        "id": 2,
        "isbn": "9786500000023",
        "title": "The Time Machine",
        "author": "H. G. Wells",
        "priceCents": 2950
    },
    {
        "id": 3,
        "isbn": "9786500000030",
        "title": "Frankenstein",
        "author": "Mary Shelley",
        "priceCents": 3500
    }
]
ana@vm:~/javalin-hello$ curl -si -w '\n' localhost:7070/books/2
HTTP/1.1 200 OK
Date: Thu, 22 Oct 2026 22:20:24 GMT
Content-Type: application/json
Content-Length: 99

{"id":2,"isbn":"9786500000023","title":"The Time Machine","author":"H. G. Wells","priceCents":2950}
ana@vm:~/javalin-hello$ curl -si -w '\n' localhost:7070/books/9
HTTP/1.1 404 Not Found
Date: Thu, 22 Oct 2026 22:20:24 GMT
Content-Type: text/plain
Content-Length: 17

No book with id 9
ana@vm:~/javalin-hello$ curl -s localhost:7070/books/two
{"id":[{"message":"TYPE_CONVERSION_FAILED","args":{},"value":"two"}]}
```

O `-w '\n'` pede ao curl uma quebra de linha depois do corpo, já que nenhuma das duas respostas
termina com uma. A lista e o livro avulso são o JSON do bookshop, campo por campo. As outras duas
respostas são onde aparece a diferença em relação à aula 7. Um livro que não existe é um 404 em **texto
puro**, `No book with id 9`. O bookshop responde `application/problem+json` com type, title e detail, e
o Javalin faria isso também depois que você registrasse um exception handler que o escrevesse (o
`config.routes.exception` é onde ele entra). E o `two` é recusado com um 400 no **formato próprio do
Javalin** para uma conversão que falhou, um terceiro formato de erro que nenhum cliente do bookshop sabe
ler.

E uma coisa falta por completo. `BOOKS` é uma lista estática porque não há contêiner para entregar um
repositório a um handler: num serviço Javalin de verdade, o `main` constrói o repositório e o serviço
com `new` e os passa aos lambdas, que é a injeção por construtor da aula 5 escrita à mão, sem nada
conferindo além do compilador.
