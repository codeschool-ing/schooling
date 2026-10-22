---
title: Relationships, and loading them
version: 1
---

The models declared a relationship in both directions: an `Event` has many `Tickets`, and a `Ticket`
belongs to an `Event`. **GORM uses those declarations when it writes and when it reads**, and both are
worth watching:

```go
// gormlab/cmd/relations/main.go
package main

import (
	"fmt"

	"example.com/gormlab/models"
)

func main() {
	db := models.Open()

	choir := models.Event{Name: "Chamber Choir", Seats: 80, Tickets: []models.Ticket{
		{Email: "ana@example.com", Quantity: 2},
		{Email: "rui@example.com", Quantity: 4},
	}}
	db.Create(&choir)

	var loaded models.Event
	db.Preload("Tickets").First(&loaded, choir.ID)
	for _, t := range loaded.Tickets {
		fmt.Printf("%s bought %d for %s\n", t.Email, t.Quantity, loaded.Name)
	}

	var ticket models.Ticket
	db.Joins("Event").First(&ticket, "email = ?", "rui@example.com")
	fmt.Printf("ticket %d belongs to %s\n", ticket.ID, ticket.Event.Name)
}
```

```
ana@vm:~/gormlab$ DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql' go run ./cmd/relations
/home/ana/gormlab/cmd/relations/main.go:17
[0.934ms] [rows:2] INSERT INTO "tickets" ("created_at","updated_at","deleted_at","event_id","email","quantity") VALUES ('2026-10-16 20:01:29.755','2026-10-16 20:01:29.755',NULL,2,'ana@example.com',2),('2026-10-16 20:01:29.755','2026-10-16 20:01:29.755',NULL,2,'rui@example.com',4) ON CONFLICT ("id") DO UPDATE SET "event_id"="excluded"."event_id" RETURNING "id"
/home/ana/gormlab/cmd/relations/main.go:17
[3.024ms] [rows:1] INSERT INTO "events" ("name","seats","sold") VALUES ('Chamber Choir',80,0) RETURNING "id"
/home/ana/gormlab/cmd/relations/main.go:20
[0.249ms] [rows:2] SELECT * FROM "tickets" WHERE "tickets"."event_id" = 2 AND "tickets"."deleted_at" IS NULL
/home/ana/gormlab/cmd/relations/main.go:20
[0.693ms] [rows:1] SELECT * FROM "events" WHERE "events"."id" = 2 ORDER BY "events"."id" LIMIT 1
ana@example.com bought 2 for Chamber Choir
rui@example.com bought 4 for Chamber Choir
/home/ana/gormlab/cmd/relations/main.go:26
[0.505ms] [rows:1] SELECT "tickets"."id","tickets"."created_at","tickets"."updated_at","tickets"."deleted_at","tickets"."event_id","tickets"."email","tickets"."quantity","Event"."id" AS "Event__id","Event"."name" AS "Event__name","Event"."seats" AS "Event__seats","Event"."sold" AS "Event__sold" FROM "tickets" LEFT JOIN "events" "Event" ON "tickets"."event_id" = "Event"."id" WHERE email = 'rui@example.com' AND "tickets"."deleted_at" IS NULL ORDER BY "tickets"."id" LIMIT 1
ticket 2 belongs to Chamber Choir
```

## Writing: the children come along

`db.Create(&choir)` was given an event with two tickets inside it, and it saved all three: the event,
then both tickets in one multi-row `INSERT`, each carrying the new event's id, 2. **The log prints the
tickets' insert first** because GORM logs a statement when its whole operation finishes, and the event's
`Create` finished only after its tickets were saved; the `event_id` of 2 in the tickets' values is the
proof that the event row came first. GORM also filled in `created_at` and `updated_at` itself, from
`gorm.Model`.

## Reading: Preload or Joins

A plain `First(&loaded, id)` would have left `loaded.Tickets` empty. **Relationships are loaded only
when asked for**, and there are two ways to ask:

| | `Preload("Tickets")` | `Joins("Event")` |
|---|---|---|
| queries | two: the event, then the tickets `WHERE event_id = 2` | one, with a `LEFT JOIN` |
| fits | has many: one event, many tickets | belongs to: one ticket, one event |
| the SQL | simple, one table each | every column of both tables, each renamed, like `"Event"."name" AS "Event__name"` |

`Preload` with many events sends one second query with `WHERE event_id IN (...)` for all of them, not
one per event. **The difference between that and a loop is the next section.** Notice also that the
tickets query added `"tickets"."deleted_at" IS NULL` without being asked; section 07 explains why.
