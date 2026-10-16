---
title: Parameters, never pasted strings
version: 1
---

`Jdbc.java` never put the author's name into its SQL. It wrote a `?` and handed the name over
with `setString`. The obvious alternative is to build the query as a string, and plenty of code
does. It works on every name you try while writing it, which is why it survives. This section runs
it on the name that breaks it.

This is a **detour**: `Unsafe.java` is the wrong way, kept only long enough to watch it fail.
Save it beside `Jdbc.java`; it differs in one line and in using a plain `Statement`:

```java
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Unsafe {

    public static void main(String[] args) throws SQLException {
        String url = "jdbc:postgresql://localhost:5432/bookshop";
        String sql = "SELECT id, title, price_cents FROM book WHERE author = '" + args[0] + "' ORDER BY title";
        System.out.println(sql);

        try (Connection connection = DriverManager.getConnection(url, "bookshop", "bookshop");
             Statement statement = connection.createStatement();
             ResultSet rows = statement.executeQuery(sql)) {
            while (rows.next()) {
                int cents = rows.getInt("price_cents");
                System.out.printf("%d  %-22s %d.%02d%n", rows.getLong("id"), rows.getString("title"), cents / 100, cents % 100);
            }
        }
    }
}
```

It prints the SQL it built before sending it. For an ordinary name it works, and gives the same
answer as `Jdbc.java`:

```
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Unsafe.java 'H. G. Wells'
SELECT id, title, price_cents FROM book WHERE author = 'H. G. Wells' ORDER BY title
2  The Time Machine       29.50
3  The War of the Worlds  32.00
ana@vm:~$ java -cp ~/.m2/repository/org/postgresql/postgresql/42.7.13/postgresql-42.7.13.jar Unsafe.java "Flannery O'Connor" 2>&1 | head -n 4
SELECT id, title, price_cents FROM book WHERE author = 'Flannery O'Connor' ORDER BY title
Exception in thread "main" org.postgresql.util.PSQLException: Unterminated string literal started at position 73 in SQL SELECT id, title, price_cents FROM book WHERE author = 'Flannery O'Connor' ORDER BY title. Expected  char
	at org.postgresql.core.Parser.checkParsePosition(Parser.java:1459)
	at org.postgresql.core.Parser.parseSql(Parser.java:1366)
```

Read the printed SQL as the database would. The quote after `author = ` opens a string, and the
apostrophe in the name **closes it**, so the string is `'Flannery O'`. Then `Connor` is no longer
data at all; it is a word in the statement. The quote after it opens a new string that never ends,
and the driver, reading the text before sending it, stopped there: position 73 is that last quote.
Nobody typed anything malicious. A real surname turned part of the input into SQL.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 254\" role=\"img\" aria-label=\"Above, the concatenated query: one string in which the author's name, Flannery O'Connor, sits inside the SQL, and its apostrophe ends the quoted text early. Below, the prepared statement: the SQL with a placeholder, $1, is sent first, and the name is sent separately as a value.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Concatenated: the name is pasted into the text of the SQL</text><rect x=\"20\" y=\"30\" width=\"660\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SELECT id, title, price_cents FROM book WHERE author = '<tspan fill=\"var(--amber)\">Flannery O'Connor</tspan>' ORDER BY title</text><text x=\"20\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the apostrophe in the name closes the quoted text, and the rest is read as SQL</text><text x=\"20\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">A parameter: the statement and the value are sent separately</text><rect x=\"20\" y=\"144\" width=\"660\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SELECT id, title, price_cents FROM book WHERE author = $1 ORDER BY title</text><text x=\"668\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">statement</text><rect x=\"20\" y=\"206\" width=\"300\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$1 = <tspan fill=\"var(--amber)\">Flannery O'Connor</tspan></text><text x=\"336\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a value, never read as SQL</text><text x=\"308\" y=\"224\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">value</text></svg>", "caption": "Concatenation sends one string, and the server cannot tell where the data stops. A parameter travels beside the statement and is never read as SQL."}
```

## Why a syntax error is the lucky outcome

Here the result was an exception, because the text that leaked happened not to be valid SQL. **Input
that leaks into a statement and IS valid SQL runs**, and it runs with the bookshop role's
permissions: it can widen a `WHERE` to rows the screen was never meant to show, or end the statement
and start another. That is **SQL injection**, and it has been near the top of every list of web
application weaknesses for twenty years, for one reason: data and code share one channel.

Doubling the apostrophes before concatenating, the way you typed `'Flannery O''Connor'` in `psql`,
fixes this name. It does not fix the method, because every query that builds text must apply the
rule correctly, for every type of value, forever. The fix that holds is to **keep the value out of
the text**. With `?` and `setString`, the PostgreSQL driver sends the statement with a numbered
placeholder, `$1`, and sends the value beside it. The server parses the statement before it ever
sees the value, so there is nothing in the value it could read as SQL.

Two consequences follow, and both come up in real code:

- **A parameter is a value, never a name.** A table, a column or a sort direction cannot be a `?`,
  because the server needs them to understand the statement at all. When a user picks the sort
  column, map their choice onto a fixed list of column names written in the code; never paste their
  text in.
- **`prepareStatement` protects only what goes through `?`.** A string built with `+` or
  `String.format` and then passed to `prepareStatement` is exactly as unsafe as `Unsafe.java`. The
  method's name is not the protection; the placeholder is.

Every query in the rest of this course, including the ones Spring and Hibernate write for you, uses
parameters. Delete `Unsafe.java`; its job is done.
