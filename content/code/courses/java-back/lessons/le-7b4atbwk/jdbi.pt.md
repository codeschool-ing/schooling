---
title: O JDBI contra o bookshop, e como escolher
version: 1
---

O **JDBI** é a biblioteca mais fina desta aula: JDBC sem a cerimônia. Ele abre e fecha conexões para
você, liga parâmetros com nome e mapeia linhas para objetos, e é só. Não há entidades, nem código
gerado, nem nada lembrado entre uma chamada e a seguinte. Ele fica perto do `JdbcClient` da aula 9, e a
diferença que importa é que o JDBI não precisa do Spring para rodar.

Esta seção o roda contra o banco `bookshop` do jeito que a aula 11 o deixou, com os autores e livros
que o `data.sql` põe lá. O bookshop em si não precisa estar rodando; o PostgreSQL precisa.

## Um projeto só dele

O JDBI ganha um projeto pequeno ao lado do bookshop, para que nada em `~/bookshop` mude. Crie os
diretórios dele:

TRANSCRIPT-MKDIR

`~/jdbi-look/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>jdbi-look</artifactId>
  <version>0.1.0</version>

  <properties>
    <maven.compiler.release>25</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.jdbi</groupId>
      <artifactId>jdbi3-core</artifactId>
      <version>3.55.0</version>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <version>42.7.13</version>
      <scope>runtime</scope>
    </dependency>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-nop</artifactId>
      <version>2.0.17</version>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <artifactId>maven-resources-plugin</artifactId>
        <version>3.5.0</version>
      </plugin>
      <plugin>
        <artifactId>maven-compiler-plugin</artifactId>
        <version>3.15.0</version>
      </plugin>
      <plugin>
        <artifactId>maven-dependency-plugin</artifactId>
        <version>3.10.0</version>
      </plugin>
    </plugins>
  </build>
</project>
```

Três dependências, e as duas últimas estão ali para rodar, não para compilar contra elas, que é o que
o escopo `runtime` diz. `jdbi3-core` é a biblioteca. O driver é o driver JDBC do PostgreSQL, na versão
que o parent do bookshop escolhe. E `slf4j-nop` é uma decisão sobre log: o JDBI registra log pelo
SLF4J, a fachada de que trata a aula 16, e sem nenhuma biblioteca de log por trás o SLF4J imprime três
linhas de aviso a cada execução. O `slf4j-nop` manda descartar o log de propósito. Os três plugins têm
versão fixada pelo motivo que a aula 1 deu.

`~/jdbi-look/src/main/java/com/example/look/Titles.java`, os títulos e preços dos livros de um autor:

```schooling-example
{
 "language": "java",
 "file": "Titles.java",
 "parts": [
  {
   "code": "package com.example.look;\n\nimport java.util.List;\n\nimport org.jdbi.v3.core.Jdbi;\nimport org.jdbi.v3.core.mapper.reflect.ConstructorMapper;\n\npublic class Titles {\n",
   "note": "Duas classes do núcleo do JDBI: `Jdbi`, por onde tudo começa, e um mapper que monta um objeto pelo construtor."
  },
  {
   "code": "    public record TitleAndPrice(String title, int priceCents) {\n    }\n",
   "note": "O formato de uma linha. A aula 11 declarou `TitleAndPrice` como uma projeção em interface; aqui é um record simples."
  },
  {
   "code": "    public static void main(String[] args) {\n        Jdbi jdbi = Jdbi.create(\"jdbc:postgresql://localhost:5432/bookshop\", \"bookshop\", \"bookshop\");\n",
   "note": "A URL, o usuário e a senha do `application.properties` do bookshop. Criar um `Jdbi` ainda não abre conexão nenhuma."
  },
  {
   "code": "        List<TitleAndPrice> books = jdbi.withHandle(handle -> handle\n                .createQuery(\"\"\"\n                        SELECT b.title, b.price_cents\n                        FROM book b JOIN author a ON a.id = b.author_id\n                        WHERE a.name = :name\n                        ORDER BY b.title\"\"\")",
   "note": "`withHandle` abre uma conexão, a embrulha num **handle**, roda a lambda e a fecha aconteça o que acontecer. O SQL é um text block, exatamente o que o PostgreSQL vai receber, com um parâmetro com nome, `:name`."
  },
  {
   "code": "                .bind(\"name\", args[0])",
   "note": "O primeiro argumento da linha de comando preenche `:name`. Ele viaja como parâmetro ligado, separado do SQL, como o `?` do `PreparedStatement` da aula 9."
  },
  {
   "code": "                .map(ConstructorMapper.of(TitleAndPrice.class))\n                .list());\n",
   "note": "As colunas são casadas com os componentes do record pelo nome, e `price_cents` é lido como `priceCents`. `list()` roda a consulta e junta todas as linhas."
  },
  {
   "code": "        books.forEach(System.out::println);\n    }\n}",
   "note": "Um record imprime os próprios componentes, e é só disso que esta olhada precisa."
  }
 ]
}
```

## Rodando

Um programa com dependências precisa delas no classpath, e a aula 1 mostrou como pedir um ao Maven.
`compile` compila a classe, e `dependency:build-classpath` escreve em `cp.txt` o caminho de cada jar de
que ela precisa. A primeira execução baixa o JDBI; o `-q` a deixa em silêncio.

TRANSCRIPT-RUN

O classpath é a medida de quão fino o JDBI é. Fora o driver e a dupla de log, ele é o `jdbi3-core` e
dois jars pequenos de que depende. **O programa é JDBC com o encanamento feito para você**: uma
conexão, um comando preparado com um parâmetro ligado, linhas transformadas em records, tudo fechado.

## Um erro, e quando ele aparece

O SQL é uma string, e vale ver o que isso custa. Como desvio, troque `b.price_cents` por `b.price` na
linha do `SELECT` em `Titles.java`, e compile e rode de novo:

TRANSCRIPT-TYPO

A compilação não imprimiu nada, porque para o javac uma string SQL é uma string como qualquer outra. O
erro apareceu quando o PostgreSQL leu o comando, em tempo de execução, o que numa aplicação de verdade
quer dizer na frente de quem fez a requisição. O `head -n 3` cortou o stack trace que vem abaixo.
Ponha `b.price_cents` de volta antes de seguir.

É assim para toda biblioteca cujo SQL é texto: `JdbcClient`, JDBI e MyBatis. As outras colunas da
figura desta aula pegam o erro mais cedo. **O jOOQ e os query beans do EBean o pegam na compilação**,
porque a coluna ou a propriedade é um campo de uma classe gerada. O Spring Data JPA fica entre os dois:
ele confere o JPQL de cada `@Query` e os nomes de propriedade de cada consulta derivada quando a
aplicação sobe, então um erro de digitação ali impede a partida em vez de uma requisição. Uma consulta
nativa é SQL puro, e o Spring Data a repassa sem conferir.

## Como escolher

| o que a equipe quer | onde olhar |
|---|---|
| objetos, mudanças acompanhadas e o maior ecossistema | JPA com Hibernate, pelo Spring Data JPA (aulas 10 e 11) |
| um ORM, sem um contexto de persistência com prazo de validade | EBean |
| o SQL completo do banco, conferido pelo compilador | jOOQ |
| SQL mantido como texto, separado do Java, montado dinamicamente | MyBatis |
| uma camada fina sobre o JDBC, dentro do Spring | `JdbcClient` (aula 9), ou Spring Data JDBC |
| uma camada fina sobre o JDBC, sem Spring | JDBI |

**A escolha não é exclusiva.** Todas terminam nas mesmas chamadas JDBC, então uma única aplicação
Spring Boot pode manter o Spring Data JPA para as entidades e escrever o único relatório pesado com
`JdbcClient` ou jOOQ ao lado. Os dois usam o mesmo `DataSource` e entram nas mesmas transações, que a
aula 14 examina de perto. Trocar o JPA porque uma consulta fica desajeitada nele troca um custo que a
equipe conhece por um que ela não conhece; acrescentar uma segunda ferramenta para essa consulta, não.
