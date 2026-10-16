---
title: JDBC by hand
version: 1
---

**JDBC**, Java Database Connectivity, is the part of the JDK that talks to relational databases. It
is a set of interfaces in `java.sql` (`Connection`, `PreparedStatement`, `ResultSet` and a few
more) and nothing that knows any particular database. That knowledge lives in a **driver**, a jar
each database's makers publish, which implements those interfaces for their server.

That split is why it matters to see JDBC with nothing in front of it. Hibernate in lesson 10, Spring
Data in lesson 11 and every library lesson 12 compares open their connections and run their SQL
through these same interfaces. When one of them fails, the exception underneath is a JDBC one, and
it reads the same as it does here.

## The driver

The bookshop will depend on PostgreSQL's driver at the version Spring Boot 4.1.1 manages, 42.7.13.
For a program outside any project, ask Maven to fetch that jar into your local repository:

```
ana@vm:~$ mvn -q dependency:get -Dartifact=org.postgresql:postgresql:42.7.13
ana@vm:~$ ls ~/.m2/repository/org/postgresql/postgresql/42.7.13/
_remote.repositories
postgresql-42.7.13.jar
postgresql-42.7.13.jar.sha1
postgresql-42.7.13.pom
postgresql-42.7.13.pom.sha1
```

`-q` keeps Maven quiet unless something fails, and `dependency:get` needs no `pom.xml`: the
coordinates on the command line are the whole request. The jar is now at the path `ls` listed, the
same place the bookshop's build will find it.

## A program that asks one question

Save this as `~/Jdbc.java`. It takes an author's name and prints that author's books from the table
you filled in the last section:

```schooling-example
{"language": "java", "file": "Jdbc.java", "parts": [{"code": "import java.sql.Connection;\nimport java.sql.DriverManager;\nimport java.sql.PreparedStatement;\nimport java.sql.ResultSet;\nimport java.sql.SQLException;\n", "note": "Everything here is `java.sql`, which ships with the JDK. None of these names is PostgreSQL's: they are interfaces, and the driver jar supplies the classes behind them."}, {"code": "public class Jdbc {\n\n    public static void main(String[] args) throws SQLException {\n        String url = \"jdbc:postgresql://localhost:5432/bookshop\";\n        String author = args[0];\n", "note": "The URL names the driver after `jdbc:`, then the host, the port and the database. `SQLException` is checked, so `main` declares it rather than catching what it cannot fix."}, {"code": "        try (Connection connection = DriverManager.getConnection(url, \"bookshop\", \"bookshop\");\n             PreparedStatement statement = connection.prepareStatement(\n                     \"SELECT id, title, price_cents FROM book WHERE author = ? ORDER BY title\")) {\n", "note": "`DriverManager` asks every driver on the class path whether it understands the URL, and the PostgreSQL one opens a TCP connection and logs in. The `?` is a **parameter**: a place for a value, which is not part of the SQL text."}, {"code": "            statement.setString(1, author);\n", "note": "Parameters are numbered from 1, in the order the `?` appear. `setString`, `setLong`, `setInt` say which Java type the value is."}, {"code": "            try (ResultSet rows = statement.executeQuery()) {\n                while (rows.next()) {\n                    long id = rows.getLong(\"id\");\n                    String title = rows.getString(\"title\");\n                    int cents = rows.getInt(\"price_cents\");\n                    System.out.printf(\"%d  %-22s %d.%02d%n\", id, title, cents / 100, cents % 100);\n                }\n            }", "note": "A `ResultSet` is a cursor that starts before the first row. `next()` moves it on and answers `false` after the last one, and each getter reads one column of the current row, by name."}, {"code": "        }\n    }\n}", "note": "Leaving the `try` closes the result set, then the statement, then the connection: the reverse of the order they were opened, and also when an exception is on its way out."}]}
```

Java 25 runs a single source file directly, with no build, and `-cp` puts the driver on its class
path. Without `-cp`, nothing in the JDK knows what `jdbc:postgresql:` means:

```
ana@vm:~$ java Jdbc.java 'H. G. Wells' 2>&1 | head -n 3
Exception in thread "main" java.sql.SQLException: No suitable driver found for jdbc:postgresql://localhost:5432/bookshop
	at java.sql/java.sql.DriverManager.getConnection(DriverManager.java:638)
	at java.sql/java.sql.DriverManager.getConnection(DriverManager.java:199)
```

**`No suitable driver` is a class path problem, never a network one.** `DriverManager` asked every
driver it had loaded whether it accepted the URL, there were none, and nothing was ever sent to the
server. `head -n 3` keeps the first three lines of the stack trace. With the jar:

```
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Jdbc.java 'H. G. Wells'
2  The Time Machine       29.50
3  The War of the Worlds  32.00
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Jdbc.java "Flannery O'Connor"
4  Wise Blood             41.00
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Jdbc.java 'Mary Shelley'
```

Two rows, one row, and none. Mary Shelley's book was the one the `CHECK` refused, so the query
matched nothing, `next()` answered `false` the first time, and the program printed nothing and
ended normally. **An empty result is an answer, not an error.** The price came out as `29.50`
from the integer 2950 by dividing and taking the remainder, so no floating-point number ever held
the money.

Notice what the program did not have to do with the second name. The apostrophe went in as it
is, with no doubling and no special case, and the right row came back. The next section shows why,
and what happens to a program that builds its SQL the other way.

## What every connection costs

Each run of `Jdbc.java` opened a connection, used it for one query and closed it. Opening one is
not cheap: a TCP connection, an encrypted session, a login checked against a password hash, and a
new process on the server to serve it. For a program that runs once that does not matter. For a web
application answering many requests a second it would be most of the work, and the next sections
show what Spring Boot does about it.
