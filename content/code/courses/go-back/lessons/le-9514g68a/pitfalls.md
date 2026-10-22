---
title: Four pitfalls
version: 1
---

GORM's rules are documented, and each is reasonable on its own. **Together they are a second language
inside Go, and the mistakes come from forgetting that you are speaking it.** This program walks into
four of them, one after the other, against the rows the earlier programs left:

```go
// gormlab/cmd/pitfalls/main.go
package main

import (
	"errors"
	"fmt"

	"example.com/gormlab/models"
	"gorm.io/gorm"
)

func main() {
	db := models.Open()

	var e models.Event
	db.First(&e, "name = ?", "Jazz at the Docks")
	fmt.Println("before:", e.Sold, "sold")
	db.Model(&e).Updates(models.Event{Sold: 0})
	db.First(&e, e.ID)
	fmt.Println("after Updates with Sold: 0:", e.Sold, "sold")

	var t models.Ticket
	db.First(&t, "email = ?", "rui@example.com")
	db.Delete(&t)
	var left, all int64
	db.Model(&models.Ticket{}).Where("email = ?", "rui@example.com").Count(&left)
	db.Unscoped().Model(&models.Ticket{}).Where("email = ?", "rui@example.com").Count(&all)
	fmt.Println("rui's tickets after Delete:", left, "visible,", all, "in the table")

	err := db.Delete(&models.Event{}).Error
	fmt.Println("delete with no condition:", err)

	var none models.Event
	err = db.First(&none, "name = ?", "Nobody").Error
	fmt.Println("First, no row:", err, errors.Is(err, gorm.ErrRecordNotFound))
	var nones []models.Event
	err = db.Find(&nones, "name = ?", "Nobody").Error
	fmt.Println("Find, no row:", err, len(nones))
}
```

```
ana@vm:~/gormlab$ DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql' go run ./cmd/pitfalls
/home/ana/gormlab/cmd/pitfalls/main.go:16
[1.487ms] [rows:1] SELECT * FROM "events" WHERE name = 'Jazz at the Docks' ORDER BY "events"."id" LIMIT 1
before: 2 sold
/home/ana/gormlab/cmd/pitfalls/main.go:19
[0.362ms] [rows:1] SELECT * FROM "events" WHERE "events"."id" = 1 AND "events"."id" = 1 ORDER BY "events"."id" LIMIT 1
after Updates with Sold: 0: 2 sold
/home/ana/gormlab/cmd/pitfalls/main.go:23
[0.460ms] [rows:1] SELECT * FROM "tickets" WHERE email = 'rui@example.com' AND "tickets"."deleted_at" IS NULL ORDER BY "tickets"."id" LIMIT 1
/home/ana/gormlab/cmd/pitfalls/main.go:24
[1.979ms] [rows:1] UPDATE "tickets" SET "deleted_at"='2026-10-16 20:01:30.245' WHERE "tickets"."id" = 2 AND "tickets"."deleted_at" IS NULL
/home/ana/gormlab/cmd/pitfalls/main.go:26
[0.433ms] [rows:1] SELECT count(*) FROM "tickets" WHERE email = 'rui@example.com' AND "tickets"."deleted_at" IS NULL
/home/ana/gormlab/cmd/pitfalls/main.go:27
[0.190ms] [rows:1] SELECT count(*) FROM "tickets" WHERE email = 'rui@example.com'
rui's tickets after Delete: 0 visible, 1 in the table
/home/ana/gormlab/cmd/pitfalls/main.go:30 WHERE conditions required
[0.125ms] [rows:0] DELETE FROM "events"
delete with no condition: WHERE conditions required
/home/ana/gormlab/cmd/pitfalls/main.go:34 record not found
[0.147ms] [rows:0] SELECT * FROM "events" WHERE name = 'Nobody' ORDER BY "events"."id" LIMIT 1
First, no row: record not found true
/home/ana/gormlab/cmd/pitfalls/main.go:37
[0.189ms] [rows:0] SELECT * FROM "events" WHERE name = 'Nobody'
Find, no row: <nil> 0
ana@vm:~/gormlab$ psql gormlab -c "SELECT id, email, deleted_at FROM tickets WHERE email = 'rui@example.com'"
 id |      email      |          deleted_at           
----+-----------------+-------------------------------
  2 | rui@example.com | 2026-10-16 23:01:30.245469+00
(1 row)
```

## 1. A zero value is not an update

`db.Model(&e).Updates(models.Event{Sold: 0})` was meant to reset the jazz event's sales. **GORM sent no
`UPDATE` at all**: the log goes straight from the first `SELECT` to the second, and `sold` is still 2.
When `Updates` is given a struct, it writes only the fields that are not their zero value, because it
cannot tell "set this to zero" from "I did not mention this field". `0`, `""` and `false` are all
skipped. **To write a zero, name the column**: `Update("sold", 0)`, a `map[string]any`, or `Select("sold")`
before `Updates`. Lesson 3 section 04 met the same ambiguity in JSON.

## 2. Delete does not delete

`db.Delete(&t)` on a ticket sent an `UPDATE ... SET "deleted_at"=...`. **A model that embeds `gorm.Model`
is soft-deleted**: the row stays, stamped with the time, and every later query GORM writes adds
`"deleted_at" IS NULL`, so the row seems gone. The count with `Unscoped()` found it, and so does `psql`,
which knows nothing of GORM's convention (it prints the stamp in UTC, the database server's time zone,
where GORM logged São Paulo time).

That is useful when deleted data must be kept, and costly when it is forgotten:

- **another program reading the table sees the row as alive**, because the rule lives in GORM and not
  in the database;
- a **unique index still counts the soft-deleted row**, so a deleted ticket's unique value cannot be
  used again;
- the table only grows.

`db.Unscoped().Delete(&t)` deletes for real. Leaving `gorm.Model` out of a struct, as `Event` does, means
`Delete` is a real `DELETE`.

## 3. A delete with no condition is refused

`db.Delete(&models.Event{})` names no row, and would delete every event. **GORM refused it** with `WHERE
conditions required`; the log shows the statement it built and did not send, with `rows:0`. It is a
guard against exactly the mistake of a missing condition, and the same guard applies to `Update`. To mean
"all rows", the code has to say so, with `Where("1 = 1")` or a session setting.

## 4. First fails, Find does not

`First` with no row returned `record not found`, which is `gorm.ErrRecordNotFound`; **`Find` with no row
returned no error and an empty slice.** Both are right for what they mean, one row expected against a
list that may be empty, and code that uses one with the expectations of the other either reports a
missing row as a failure or misses it entirely. In a handler, `First` and an `errors.Is` check are the
404 of lesson 3.
