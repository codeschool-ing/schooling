---
title: Create, read, update
version: 1
---

The four everyday operations, each one line of GORM:

```go
// gormlab/cmd/crud/main.go
package main

import (
	"fmt"

	"example.com/gormlab/models"
)

func main() {
	db := models.Open()

	jazz := models.Event{Name: "Jazz at the Docks", Seats: 120}
	db.Create(&jazz)
	fmt.Println("created event", jazz.ID)

	var e models.Event
	db.First(&e, jazz.ID)
	fmt.Printf("read back: %s, %d seats\n", e.Name, e.Seats)

	db.Model(&e).Update("sold", 2)

	var big []models.Event
	db.Where("seats - sold > ?", 100).Find(&big)
	fmt.Println("events with more than 100 seats left:", len(big))
}
```

```
ana@vm:~/gormlab$ DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql' go run ./cmd/crud
/home/ana/gormlab/cmd/crud/main.go:14
[2.388ms] [rows:1] INSERT INTO "events" ("name","seats","sold") VALUES ('Jazz at the Docks',120,0) RETURNING "id"
created event 1
/home/ana/gormlab/cmd/crud/main.go:18
[0.620ms] [rows:1] SELECT * FROM "events" WHERE "events"."id" = 1 ORDER BY "events"."id" LIMIT 1
read back: Jazz at the Docks, 120 seats
/home/ana/gormlab/cmd/crud/main.go:21
[0.891ms] [rows:1] UPDATE "events" SET "sold"=2 WHERE "id" = 1
/home/ana/gormlab/cmd/crud/main.go:24
[0.316ms] [rows:1] SELECT * FROM "events" WHERE seats - sold > 100
events with more than 100 seats left: 1
```

Read each Go line against the SQL under it:

- **`db.Create(&jazz)`** inserted the three columns and asked for the id back with `RETURNING`, then
  wrote it into `jazz.ID`. That is why the struct is passed by pointer: GORM fills it in.
- **`db.First(&e, jazz.ID)`** read one row by primary key and added `ORDER BY "events"."id" LIMIT 1` on
  its own. "First" means first by primary key, whatever the query, and on a large table that order
  costs a sort when the condition is not on the key.
- **`db.Model(&e).Update("sold", 2)`** wrote one column of the row `e` points at, using its primary
  key for the `WHERE`.
- **`db.Where("seats - sold > ?", 100).Find(&big)`** shows GORM's escape hatch: the condition is your
  SQL, with `?` for each value, and GORM turns each `?` into a placeholder of the database's kind.

## The log shows values, the database receives placeholders

The log line reads `WHERE seats - sold > 100`, with the number in the SQL. **That is the logger being
helpful, not the query being glued together.** GORM sends the statement with `$1` and the value apart,
exactly as lesson 6 section 07 asked, and the logger prints the two merged so a person can read them.
The same is true of the `INSERT`, where the event's name appears in quotes. Copying a statement from
this log into `psql` works; it is not evidence that values were pasted into SQL.

**Nothing here is wrong, and nothing here is visible in the Go code.** The `ORDER BY` on `First`, the
`RETURNING` on `Create`, the key used by `Update`: each is a decision GORM made, which you can only see
by reading its log or its documentation. That is the price the first table of section 02 named.
