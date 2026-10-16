---
title: The N+1 query
version: 1
---

The most common performance problem with an ORM has a name: **N+1 queries.** One query fetches a list of
N things, and then the code loops over the list and runs one more query for each, to load something
related. It reads naturally in Go and it is invisible in the code, because each query is one innocent
line. This program does it on purpose, and counts:

```go
// gormlab/cmd/nplus1/main.go
package main

import (
	"fmt"

	"example.com/gormlab/models"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func main() {
	db := models.Open()
	db.Logger = db.Logger.LogMode(logger.Silent) // this program counts instead

	queries := 0
	db.Callback().Query().Before("gorm:query").Register("count", func(*gorm.DB) { queries++ })

	for i := 1; i <= 20; i++ {
		e := models.Event{Name: fmt.Sprintf("Recital %02d", i), Seats: 50, Tickets: []models.Ticket{
			{Email: "bea@example.com", Quantity: 1},
			{Email: "caio@example.com", Quantity: 2},
		}}
		db.Create(&e)
	}

	queries = 0
	var events []models.Event
	db.Where("name LIKE ?", "Recital%").Find(&events)
	seats := 0
	for _, e := range events {
		var tickets []models.Ticket
		db.Where("event_id = ?", e.ID).Find(&tickets)
		for _, t := range tickets {
			seats += t.Quantity
		}
	}
	fmt.Printf("one query per event: %d events, %d seats sold, %d queries\n", len(events), seats, queries)

	queries = 0
	events = nil
	db.Preload("Tickets").Where("name LIKE ?", "Recital%").Find(&events)
	seats = 0
	for _, e := range events {
		for _, t := range e.Tickets {
			seats += t.Quantity
		}
	}
	fmt.Printf("with Preload:        %d events, %d seats sold, %d queries\n", len(events), seats, queries)
}
```

It silences the logger, because the point here is a number and not twenty statements, and it registers
a **callback**, a function GORM calls before every query, to count them. It creates twenty events with two
tickets each, and then sums the seats sold twice:

```
ana@vm:~/gormlab$ DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql' go run ./cmd/nplus1
one query per event: 20 events, 60 seats sold, 21 queries
with Preload:        20 events, 60 seats sold, 2 queries
```

**The same answer from 21 queries and from 2.** The loop ran one query for the events and one more for
each of the twenty; `Preload` ran one for the events and one for all of their tickets at once, with
`WHERE event_id IN (...)`. On this machine each query is a fraction of a millisecond, and the difference
is invisible. Across a network to a database server, at a millisecond or more each, twenty queries are
twenty round trips; at a thousand events, a thousand and one. **N+1 grows with the data, which is why it
is never noticed in development and always found in production.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Two rows of small blocks, one block per query. The first row, the loop, has one block for the events followed by twenty blocks, one per event's tickets: twenty-one in all. The second row, with Preload, has one block for the events and one for all the tickets: two in all.\"><defs><marker id=\"gb-l7-n1-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"15\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a query per event</text><rect x=\"15\" y=\"45\" width=\"44\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"37\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">events</text><rect x=\"66\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"93\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"147\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"174\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"201\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"255\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"309\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"336\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"363\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"417\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"444\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"471\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"498\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"525\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"552\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"579\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"615\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21 queries</text><text x=\"15\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">with Preload</text><rect x=\"15\" y=\"135\" width=\"44\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"37\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">events</text><rect x=\"66\" y=\"135\" width=\"535\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"333\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tickets WHERE event_id IN (...)</text><text x=\"615\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 queries</text></svg>", "caption": "The same 60 seats counted twice. Each block is a round trip to the database."}
```

## Finding it

The symptom is a handler whose time grows with the size of what it returns, and the tool is the one this
lesson has used throughout: **the query log, with a count**. A test that asserts how many queries an
endpoint sends, as this program counts them, catches the problem the day it is written.

## And the better answer

`Preload` fixed the query count, and still brought every ticket row into Go to add up two numbers. **The
database can do the sum itself** and return one number per event:

```sql
SELECT e.name, coalesce(sum(t.quantity), 0) AS sold
FROM events e LEFT JOIN tickets t ON t.event_id = e.id AND t.deleted_at IS NULL
GROUP BY e.id ORDER BY e.id;
```

An ORM makes the first two versions easy to write and the third one awkward, and that is a fair summary
of where ORMs help and where they get in the way. `sql-databases` lesson 6 is about aggregations like
this one, and lesson 8 shows a tool that starts from the SQL instead.
