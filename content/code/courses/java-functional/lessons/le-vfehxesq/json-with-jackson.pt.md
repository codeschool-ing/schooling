---
title: JSON com Jackson
version: 1
---

**JSON é texto que não dá nome a classe nenhuma: objetos entre chaves, listas entre colchetes, strings,
números, `true`, `false` e `null`.** Toda linguagem o lê, uma pessoa consegue lê-lo, e quem lê decide
sozinho que classe cada objeto vira. O JDK não tem biblioteca de JSON, então esta é a primeira dependência
do curso, e o seu primeiro projeto Maven. O **Jackson** é a biblioteca que a maior parte do código Java usa
para isso, incluindo o Spring, sobre o qual o `java-back` é construído.

O projeto segue a estrutura que o `java` decidiu na aula 18 seção 04: crie um diretório `~/catalogue` e
salve isto como `pom.xml` dentro dele.

```schooling-example
{
  "language": "xml",
  "file": "pom.xml",
  "parts": [
    {
      "code": "<project xmlns=\"http://maven.apache.org/POM/4.0.0\"\n         xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n         xsi:schemaLocation=\"http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd\">\n  <modelVersion>4.0.0</modelVersion>",
      "note": "**A abertura que todo `pom.xml` tem**, como na aula 18 seção 04 do `java`."
    },
    {
      "code": "\n  <groupId>com.example</groupId>\n  <artifactId>catalogue</artifactId>\n  <version>1.0-SNAPSHOT</version>",
      "note": "**As coordenadas.** O `artifactId` é o nome deste projeto, então o pacote é `com.example.catalogue`, a regra que o curso `java` fixou."
    },
    {
      "code": "\n  <properties>\n    <maven.compiler.release>25</maven.compiler.release>\n    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>\n    <exec.mainClass>com.example.catalogue.App</exec.mainClass>\n  </properties>",
      "note": "**Os dois ajustes do `java`, e mais um.** O `exec.mainClass` é lido pelo plugin que roda o programa, para o `mvn exec:java` saber que `main` chamar."
    },
    {
      "code": "\n  <dependencies>\n    <dependency>\n      <groupId>tools.jackson.core</groupId>\n      <artifactId>jackson-databind</artifactId>\n      <version>3.2.3</version>\n    </dependency>\n  </dependencies>",
      "note": "**A primeira dependência deste curso.** O Maven baixa a biblioteca nomeada por estas três coordenadas, e as bibliotecas de que ela precisa por sua vez, para `~/.m2/repository`, e as põe no class path quando compila e quando roda. O Jackson 3 fica sob `tools.jackson`; o Jackson 2, mais antigo, usava `com.fasterxml.jackson`."
    },
    {
      "code": "\n  <build>\n    <pluginManagement>\n      <plugins>\n        <plugin>\n          <artifactId>maven-clean-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-resources-plugin</artifactId>\n          <version>3.5.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-compiler-plugin</artifactId>\n          <version>3.15.0</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-surefire-plugin</artifactId>\n          <version>3.5.6</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-jar-plugin</artifactId>\n          <version>3.5.1</version>\n        </plugin>\n        <plugin>\n          <artifactId>maven-install-plugin</artifactId>\n          <version>3.2.0</version>\n        </plugin>",
      "note": "**Os plugins do `java`, fixados nas mesmas versões**, para quem montou o projeto daquele curso não baixar nada de novo para eles."
    },
    {
      "code": "\n        <plugin>\n          <groupId>org.codehaus.mojo</groupId>\n          <artifactId>exec-maven-plugin</artifactId>\n          <version>3.6.4</version>\n        </plugin>\n      </plugins>\n    </pluginManagement>\n  </build>\n</project>\n",
      "note": "**Um plugin novo, fixado como os outros.** O `exec-maven-plugin` roda a `main` de uma classe com o class path do projeto, dependências incluídas."
    }
  ]
}
```

O record que o JSON vai guardar fica em `src/main/java/com/example/catalogue/Book.java`:

```java
// src/main/java/com/example/catalogue/Book.java
package com.example.catalogue;

public record Book(String title, String author, int year) {}
```

e o programa em `src/main/java/com/example/catalogue/App.java`:

```java
// src/main/java/com/example/catalogue/App.java
package com.example.catalogue;

import java.util.List;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

public class App {
    public static void main(String[] args) {
        JsonMapper mapper = JsonMapper.builder().build();
        List<Book> books = List.of(new Book("Dune", "Frank Herbert", 1965), new Book("Emma", "Jane Austen", 1815));

        String json = mapper.writerWithDefaultPrettyPrinter().writeValueAsString(books);
        System.out.println(json);

        List<Book> back = mapper.readValue(json, new TypeReference<List<Book>>() {});
        System.out.println("read back, equal: " + back.equals(books));
        System.out.println(mapper.writeValueAsString(books.get(0)));
    }
}
```

O `mvn -q` imprime só o que o programa imprime, e `compile exec:java` compila e roda num comando só:

```
ana@vm:~/catalogue$ mvn -q compile exec:java
WARNING: A terminally deprecated method in sun.misc.Unsafe has been called
WARNING: sun.misc.Unsafe::objectFieldOffset has been called by com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper (file:/usr/share/maven/lib/guava.jar)
WARNING: Please consider reporting this to the maintainers of class com.google.common.util.concurrent.AbstractFuture$UnsafeAtomicHelper
WARNING: sun.misc.Unsafe::objectFieldOffset will be removed in a future release
[ {
  "title" : "Dune",
  "author" : "Frank Herbert",
  "year" : 1965
}, {
  "title" : "Emma",
  "author" : "Jane Austen",
  "year" : 1815
} ]
read back, equal: true
{"title":"Dune","author":"Frank Herbert","year":1965}
```

## O que o Jackson fez

As quatro linhas de `WARNING` são do próprio Maven, da cópia dele do Guava, e aparecem em todo comando
`mvn`; a aula 18 seção 04 do `java` as explica, e elas não dizem nada sobre este projeto. Depois delas,
**a lista virou um array JSON de dois objetos**, cada componente do record um campo com o próprio nome, e o
mesmo texto lido de volta deu uma lista igual à primeira. A última linha é o mesmo livro sem o pretty
printer, a forma que um programa envia.

O Jackson achou os campos sozinho. Um record diz quais são os seus componentes, e o Jackson grava um campo
por componente e, ao ler, chama o construtor canônico do record com os valores que achou. **Nenhuma
anotação, nenhum setter, nenhum construtor vazio**, e é por isso que records e JSON combinam: a classe é
uma descrição dos dados, e o construtor é a única porta de entrada.

| parte | faz |
|---|---|
| `JsonMapper.builder().build()` | um mapper com os ajustes padrão; faça um e compartilhe, ele é thread-safe |
| `writeValueAsString(value)` | de um objeto para texto JSON |
| `readValue(text, Book.class)` | de texto JSON para um objeto daquela classe |
| `new TypeReference<List<Book>>() {}` | o tipo a ler quando é genérico, já que `List<Book>.class` não existe |

O `TypeReference` é a única linha estranha. Tipos genéricos são apagados em tempo de execução (aula 35 do
`java`), então `readValue(json, List.class)` daria uma lista de mapas; uma subclasse anônima de
`TypeReference` guarda o tipo completo na sua declaração, onde o Jackson consegue lê-lo.

**O que quem lê decide aqui é a classe**: `Book`, escrita no código. O JSON escolheu só os valores. Essa é
a diferença em relação às duas últimas seções, e é por isso que o JSON é o formato para trocar dados.
