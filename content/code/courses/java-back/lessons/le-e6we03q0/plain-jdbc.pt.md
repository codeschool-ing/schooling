---
title: JDBC à mão
version: 1
---

O **JDBC**, Java Database Connectivity, é a parte do JDK que conversa com bancos relacionais. Ele é
um conjunto de interfaces em `java.sql` (`Connection`, `PreparedStatement`, `ResultSet` e mais
algumas) e nada que conheça um banco em particular. Esse conhecimento mora num **driver**, um jar
que os autores de cada banco publicam, que implementa essas interfaces para o servidor deles.

Essa divisão é o motivo de valer a pena ver o JDBC sem nada na frente. O Hibernate da aula 10, o
Spring Data da aula 11 e todas as bibliotecas que a aula 12 compara abrem as conexões e rodam o SQL
delas por essas mesmas interfaces. Quando uma delas falha, a exceção lá embaixo é do JDBC, e se lê do
mesmo jeito que aqui.

## O driver

A livraria vai depender do driver do PostgreSQL na versão que o Spring Boot 4.1.1 gerencia, a
42.7.13. Para um programa fora de qualquer projeto, peça ao Maven que traga esse jar para o seu
repositório local:

```
ana@vm:~$ mvn -q dependency:get -Dartifact=org.postgresql:postgresql:42.7.13
ana@vm:~$ ls ~/.m2/repository/org/postgresql/postgresql/42.7.13/
_remote.repositories
postgresql-42.7.13.jar
postgresql-42.7.13.jar.sha1
postgresql-42.7.13.pom
postgresql-42.7.13.pom.sha1
```

O `-q` deixa o Maven calado a não ser que algo falhe, e o `dependency:get` não precisa de
`pom.xml`: as coordenadas na linha de comando são o pedido inteiro. O jar agora está no caminho que o
`ls` listou, o mesmo lugar onde o build da livraria vai encontrá-lo.

## Um programa que faz uma pergunta

Salve isto como `~/Jdbc.java`. Ele recebe o nome de um autor e imprime os livros desse autor da
tabela que você preencheu na seção anterior:

```schooling-example
{"language": "java", "file": "Jdbc.java", "parts": [{"code": "import java.sql.Connection;\nimport java.sql.DriverManager;\nimport java.sql.PreparedStatement;\nimport java.sql.ResultSet;\nimport java.sql.SQLException;\n", "note": "Tudo aqui é `java.sql`, que vem com o JDK. Nenhum destes nomes é do PostgreSQL: são interfaces, e o jar do driver fornece as classes por trás delas."}, {"code": "public class Jdbc {\n\n    public static void main(String[] args) throws SQLException {\n        String url = \"jdbc:postgresql://localhost:5432/bookshop\";\n        String author = args[0];\n", "note": "A URL nomeia o driver depois de `jdbc:`, e então o host, a porta e o banco. `SQLException` é verificada, então o `main` a declara em vez de capturar o que não sabe consertar."}, {"code": "        try (Connection connection = DriverManager.getConnection(url, \"bookshop\", \"bookshop\");\n             PreparedStatement statement = connection.prepareStatement(\n                     \"SELECT id, title, price_cents FROM book WHERE author = ? ORDER BY title\")) {\n", "note": "O `DriverManager` pergunta a cada driver no class path se ele entende a URL, e o do PostgreSQL abre uma conexão TCP e faz login. O `?` é um **parâmetro**: um lugar para um valor, que não faz parte do texto do SQL."}, {"code": "            statement.setString(1, author);\n", "note": "Os parâmetros são numerados a partir de 1, na ordem em que os `?` aparecem. `setString`, `setLong`, `setInt` dizem de que tipo Java é o valor."}, {"code": "            try (ResultSet rows = statement.executeQuery()) {\n                while (rows.next()) {\n                    long id = rows.getLong(\"id\");\n                    String title = rows.getString(\"title\");\n                    int cents = rows.getInt(\"price_cents\");\n                    System.out.printf(\"%d  %-22s %d.%02d%n\", id, title, cents / 100, cents % 100);\n                }\n            }", "note": "Um `ResultSet` é um cursor que começa antes da primeira linha. `next()` o avança e responde `false` depois da última, e cada getter lê uma coluna da linha atual, pelo nome."}, {"code": "        }\n    }\n}", "note": "Sair do `try` fecha o result set, depois o statement, depois a conexão: o inverso da ordem em que foram abertos, e também quando uma exceção está saindo."}]}
```

O Java 25 roda um único arquivo-fonte direto, sem build, e o `-cp` põe o driver no class path dele.
Sem `-cp`, nada no JDK sabe o que `jdbc:postgresql:` quer dizer:

```
ana@vm:~$ java Jdbc.java 'H. G. Wells' 2>&1 | head -n 3
Exception in thread "main" java.sql.SQLException: No suitable driver found for jdbc:postgresql://localhost:5432/bookshop
	at java.sql/java.sql.DriverManager.getConnection(DriverManager.java:638)
	at java.sql/java.sql.DriverManager.getConnection(DriverManager.java:199)
```

**`No suitable driver` é um problema de class path, nunca de rede.** O `DriverManager` perguntou a
cada driver que tinha carregado se aceitava a URL, não havia nenhum, e nada chegou a ser enviado ao
servidor. O `head -n 3` fica com as três primeiras linhas do stack trace. Com o jar:

```
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Jdbc.java 'H. G. Wells'
2  The Time Machine       29.50
3  The War of the Worlds  32.00
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Jdbc.java "Flannery O'Connor"
4  Wise Blood             41.00
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Jdbc.java 'Mary Shelley'
```

Duas linhas, uma linha, e nenhuma. O livro de Mary Shelley foi o que o `CHECK` recusou, então a
consulta não achou nada, o `next()` respondeu `false` logo da primeira vez, e o programa não imprimiu
nada e terminou normalmente. **Um resultado vazio é uma resposta, não um erro.** O preço saiu como
`29.50` a partir do inteiro 2950 por divisão e resto, então nenhum número de ponto flutuante chegou a
guardar o dinheiro.

Repare no que o programa não precisou fazer com o segundo nome. O apóstrofo entrou como é, sem ser
dobrado e sem caso especial, e a linha certa voltou. A próxima seção mostra por quê, e o que
acontece com um programa que monta o SQL do outro jeito.

## O que cada conexão custa

Cada execução do `Jdbc.java` abriu uma conexão, usou-a para uma consulta e a fechou. Abrir uma não
sai barato: uma conexão TCP, uma sessão criptografada, um login conferido contra o hash de uma senha,
e um processo novo no servidor para atendê-la. Para um programa que roda uma vez isso não importa.
Para uma aplicação web que responde a muitas requisições por segundo, seria a maior parte do
trabalho, e as próximas seções mostram o que o Spring Boot faz a respeito.
