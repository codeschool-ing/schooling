---
title: Um projeto Karate, e a cola que ele dispensa
version: 1
---

**O Karate é uma ferramenta de testes cujos testes são escritos como cenários, em texto simples, e
executados por uma biblioteca Java.** Você precisa do JDK e do Maven que a lição 7 instalou, e
escreve quase nada de Java: um arquivo curto, e depois disso todo teste é um arquivo `.feature`.
Esta seção monta o projeto, e diz primeiro o que torna o Karate diferente da ferramenta de onde veio
a sua sintaxe.

## A cola que o Karate dispensa

A sintaxe dos cenários é o **Gherkin**, a linguagem do Cucumber, uma ferramenta para descrever
comportamento em passos que uma pessoa consegue ler: `Given`, `When`, `Then`, `And`. No Cucumber, um
passo como `When the customer asks for the list of shows` não significa nada sozinho. Alguém escreve
um método Java com essa frase numa anotação. O método manda a requisição, guarda a resposta num
campo e deixa o método do passo seguinte conferi-la. Esses métodos são o **código de cola**, e numa
suíte Cucumber existe um para cada frase distinta, muitas vezes mais código que os próprios
cenários.

Os passos do Karate não são frases livres. `url`, `path`, `method`, `status`, `header` e `match` são
palavras-chave que o Karate já sabe executar, então `When method get` manda uma requisição sem
nenhum método seu por trás. O cenário é o teste. O que você perde é a liberdade de escrever um passo
nas palavras do negócio. Um cenário do Karate se lê como HTTP, porque é isso que ele descreve.

## O projeto

Os testes moram em `~/boxoffice/karate`, ao lado do `restassured` da lição 7:

```sh
cd ~/boxoffice
mkdir -p karate/src/test/java/boxoffice
```

Salve como `karate/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>boxoffice</groupId>
  <artifactId>boxoffice-karate</artifactId>
  <version>1.0</version>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>io.karatelabs</groupId>
      <artifactId>karate-junit6</artifactId>
      <version>2.1.2</version>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>6.1.3</version>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <testResources>
      <testResource>
        <directory>src/test/java</directory>
        <excludes>
          <exclude>**/*.java</exclude>
        </excludes>
      </testResource>
    </testResources>
    <plugins>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.15.0</version>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <version>3.6.0</version>
      </plugin>
    </plugins>
  </build>
</project>
```

Ele tem a forma do da lição 7, com três diferenças:

- as dependências são o Karate e o JUnit. `io.karatelabs:karate-junit6` é o Karate com a sua ponte
  para o JUnit 6. Ele declara o JUnit como algo que o projeto fornece, e não algo que ele traz,
  então o `pom.xml` cita o `junit-jupiter` por conta própria, na mesma versão que a lição 7 usou.
  Sem ele o único arquivo Java não compila, porque nada traz a anotação `@TestFactory` que ele usa.
  O grupo é `io.karatelabs`. Artigos mais antigos mostram `com.intuit.karate`, o grupo com que o
  Karate era publicado antes de se mudar, e o Karate 2 só existe no novo.
- `testResources`, que diz ao Maven para copiar para o classpath tudo o que não é Java em
  `src/test/java`. A convenção do Karate é manter cada arquivo `.feature` ao lado do runner que o
  inicia. Sem esse bloco, o Maven os deixaria para trás e o Karate não acharia nada.
- os plugins têm versão fixa pelo mesmo motivo da seção 07 da lição 7.

| o quê | versão | o que faz aqui |
|---|---|---|
| `io.karatelabs:karate-junit6` | 2.1.2 | o próprio Karate, e a ponte dele para o JUnit 6 |
| `org.junit.jupiter:junit-jupiter` | 6.1.3 | roda o que o Karate lhe entrega |
| `maven-compiler-plugin` | 3.15.0 | compila o único arquivo Java |
| `maven-surefire-plugin` | 3.6.0 | o roda, e assim roda as features |

O Karate 2 é feito para o Java 21, que é o que a lição 7 instalou. A 2.1.3 saiu no fim de setembro
de 2026, duas semanas antes da gravação, e não foi testada.

## O runner e a configuração

Salve como `karate/src/test/java/boxoffice/BoxofficeTest.java`:

```java
package boxoffice;

import io.karatelabs.junit6.Karate;
import org.junit.jupiter.api.TestFactory;

// The one Java file of the project: it hands every .feature file
// in this directory to Karate, and JUnit reports what Karate ran.
class BoxofficeTest {

    @TestFactory
    Karate features() {
        return Karate.run().relativeTo(getClass());
    }
}
```

Esse é todo o Java. `@TestFactory` marca um método que não testa nada sozinho, mas devolve testes
para o JUnit rodar. `Karate.run().relativeTo(getClass())` devolve um para cada cenário de cada
arquivo `.feature` no mesmo diretório da classe. O nome da classe termina em `Test` para que o
Surefire a encontre, como a lição 7 descobriu do jeito difícil.

O Karate lê mais um arquivo antes de qualquer feature: `karate-config.js`, na raiz do classpath de
teste, cuja função devolve as variáveis que toda feature pode usar. Salve como `karate/src/test/java/karate-config.js`:

```js
function fn() {
  return {
    baseUrl: karate.properties['boxoffice.url'] || 'http://localhost:8080'
  };
}
```

Ele faz o que o `Api.BASE` da lição 7 fazia: `baseUrl` é `http://localhost:8080`, a não ser que a
linha de comando diga `-Dboxoffice.url=…`. O arquivo é JavaScript, e o Karate o roda com um motor
próprio.
