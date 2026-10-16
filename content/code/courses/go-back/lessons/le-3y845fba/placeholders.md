---
title: Values travel apart from the SQL
version: 1
---

Every query boxoffice sends has a fixed text with `$1` and `$2` in it, and the values beside it. **The
alternative, gluing the value into the text, is the most common security flaw in database code**, and
it does not take an attacker to show why. An event can be called *Rock 'n' Roll Night*:

```go
// quote/main.go
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
)

func main() {
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer conn.Close(ctx)

	name := "Rock 'n' Roll Night"
	var n int

	glued := "SELECT count(*) FROM events WHERE name = '" + name + "'"
	fmt.Println("glued:", glued)
	err = conn.QueryRow(ctx, glued).Scan(&n)
	fmt.Println("  ->", n, err)

	err = conn.QueryRow(ctx, "SELECT count(*) FROM events WHERE name = $1", name).Scan(&n)
	fmt.Println("parameter:", n, err)
}
```

`pgx.Connect` opens a single connection, which is all a one-off program needs. The program asks the same
question twice, once with the name glued into the SQL and once with a placeholder:

```
ana@vm:~/quote$ DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql' go run .
glued: SELECT count(*) FROM events WHERE name = 'Rock 'n' Roll Night'
  -> 0 ERROR: syntax error at or near "n" (SQLSTATE 42601)
parameter: 0 <nil>
```

**The glued version is not a query about that name any more.** Its first apostrophe closed the string
PostgreSQL was reading, `n` was read as SQL, and the parser gave up with a syntax error, SQLSTATE
`42601`. A name somebody typed in good faith broke the statement.

Now turn it around. If a value can end the string and continue the SQL, then whoever chooses the value
chooses part of the query, and a value written on purpose can make the statement do something its author
never wrote: read other rows, change them, delete them. That is **SQL injection**, and it has been near
the top of every list of web application flaws for twenty years. The defence is not to clean the value
up, by escaping quotes or refusing certain characters; that has been tried and got wrong in every way
there is. **The defence is never to put a value into the SQL text at all.**

## What a placeholder actually does

With `$1`, pgx sends the statement and the value to PostgreSQL **as two separate parts of the
protocol**. The server parses the statement first, with the placeholder standing in for a value whose
type it already knows, and only then receives the value, which is never parsed as SQL because parsing
is finished. The apostrophes in *Rock 'n' Roll Night* arrive as three characters of a string, and the
count is a correct 0. There is no input for which this goes wrong, which is what makes it a defence and
not a precaution.

## What a placeholder cannot hold

**A placeholder stands for a value, never for a part of the statement**: not a table name, not a column,
not `ASC` or `DESC`. An API that lets a client choose a sort column, `?sort=name`, is tempted to glue
that word into `ORDER BY`. The safe version compares it against a fixed list and uses the list's own
string:

```go
columns := map[string]string{"name": "name", "seats": "seats"}
col, ok := columns[r.URL.Query().Get("sort")]
if !ok {
	col = "id"
}
query := "SELECT id, name, seats, sold FROM events ORDER BY " + col
```

The text glued into the query is always one of three constants from the source code, never the
client's. **Whatever the client sent only chooses among strings you wrote.**
