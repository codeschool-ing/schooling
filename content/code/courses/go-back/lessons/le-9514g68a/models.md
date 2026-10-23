---
title: Models, and the tables GORM makes from them
version: 1
---

A GORM model is an ordinary struct. GORM reads its name, its fields and its tags, and from them decides
the table, the columns and the keys. **Most of that is done by naming convention**, so the shortest
model is the one that follows the conventions exactly:

```go
// gormlab/models/models.go
package models

import (
	"log"
	"os"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// Event is one show, as GORM maps it.
type Event struct {
	ID      uint   `gorm:"primaryKey"`
	Name    string `gorm:"size:100;not null;uniqueIndex"`
	Seats   int    `gorm:"not null"`
	Sold    int    `gorm:"not null;default:0"`
	Tickets []Ticket
}

// Ticket is one sale of one or more seats.
type Ticket struct {
	gorm.Model
	EventID  uint   `gorm:"not null"`
	Event    Event
	Email    string `gorm:"not null"`
	Quantity int    `gorm:"not null"`
}

// Open connects to DATABASE_URL and prints every statement GORM sends.
func Open() *gorm.DB {
	db, err := gorm.Open(postgres.Open(os.Getenv("DATABASE_URL")), &gorm.Config{
		Logger: logger.New(log.New(os.Stdout, "", 0), logger.Config{
			LogLevel:      logger.Info,
			Colorful:      false,
			SlowThreshold: time.Second,
		}),
	})
	if err != nil {
		log.Fatal(err)
	}
	return db
}
```

What GORM reads from those types:

- **The table is the struct's name, in snake case and plural**: `Event` is `events`, `Ticket` is
  `tickets`.
- **A field called `ID` is the primary key**; the `primaryKey` tag only says so out loud.
- **`EventID uint` plus `Event Event` is a "belongs to"**: a ticket belongs to an event, through the
  column `event_id`. **`Tickets []Ticket` on `Event` is the other side**, a "has many".
- **`gorm.Model` embedded** adds four fields every row of `tickets` gets: `ID`, `CreatedAt`,
  `UpdatedAt` and `DeletedAt`. GORM fills the two timestamps itself, and the third changes what
  `Delete` means, which section 07 shows.
- **The tags** add what Go types cannot say: `size:100`, `not null`, a unique index, a default.

`Open` connects through the driver, and sets **GORM's logger to print every statement it sends**, with
the file and line that caused it. That logger is what makes this lesson possible: it is the only way to
see the SQL an ORM wrote.

## AutoMigrate

The first program asks GORM to make the tables:

```go
// gormlab/cmd/migrate/main.go
package main

import (
	"log"

	"example.com/gormlab/models"
)

func main() {
	db := models.Open()
	if err := db.AutoMigrate(&models.Event{}, &models.Ticket{}); err != nil {
		log.Fatal(err)
	}
}
```

```
ana@vm:~/gormlab$ DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql' go run ./cmd/migrate
/home/ana/gormlab/cmd/migrate/main.go:12
[2.435ms] [rows:1] SELECT count(*) FROM information_schema.tables WHERE table_schema = CURRENT_SCHEMA() AND table_name = 'events' AND table_type = 'BASE TABLE'
/home/ana/gormlab/cmd/migrate/main.go:12
[3.113ms] [rows:0] CREATE TABLE "events" ("id" bigserial,"name" varchar(100) NOT NULL,"seats" bigint NOT NULL,"sold" bigint NOT NULL DEFAULT 0,PRIMARY KEY ("id"))
/home/ana/gormlab/cmd/migrate/main.go:12
[0.868ms] [rows:0] CREATE UNIQUE INDEX IF NOT EXISTS "idx_events_name" ON "events" ("name")
/home/ana/gormlab/cmd/migrate/main.go:12
[0.501ms] [rows:1] SELECT count(*) FROM information_schema.tables WHERE table_schema = CURRENT_SCHEMA() AND table_name = 'tickets' AND table_type = 'BASE TABLE'
/home/ana/gormlab/cmd/migrate/main.go:12
[2.865ms] [rows:0] CREATE TABLE "tickets" ("id" bigserial,"created_at" timestamptz,"updated_at" timestamptz,"deleted_at" timestamptz,"event_id" bigint NOT NULL,"email" text NOT NULL,"quantity" bigint NOT NULL,PRIMARY KEY ("id"),CONSTRAINT "fk_events_tickets" FOREIGN KEY ("event_id") REFERENCES "events"("id"))
/home/ana/gormlab/cmd/migrate/main.go:12
[0.912ms] [rows:0] CREATE INDEX IF NOT EXISTS "idx_tickets_deleted_at" ON "tickets" ("deleted_at")
ana@vm:~/gormlab$ psql gormlab -c "\d tickets"
                                       Table "public.tickets"
   Column   |           Type           | Collation | Nullable |               Default               
------------+--------------------------+-----------+----------+-------------------------------------
 id         | bigint                   |           | not null | nextval('tickets_id_seq'::regclass)
 created_at | timestamp with time zone |           |          | 
 updated_at | timestamp with time zone |           |          | 
 deleted_at | timestamp with time zone |           |          | 
 event_id   | bigint                   |           | not null | 
 email      | text                     |           | not null | 
 quantity   | bigint                   |           | not null | 
Indexes:
    "tickets_pkey" PRIMARY KEY, btree (id)
    "idx_tickets_deleted_at" btree (deleted_at)
Foreign-key constraints:
    "fk_events_tickets" FOREIGN KEY (event_id) REFERENCES events(id)
```

**Six statements, all written by GORM.** It asked whether each table existed, created it, and created the
indexes: a unique one on `name` from the tag, and one on `deleted_at`, because every query on tickets
will filter on it. The foreign key `fk_events_tickets` came from the relationship, with no tag asking for
it. `int` became `bigint` and the `uint` id became a `bigserial`.

Compare it with lesson 6's `schema.sql`. **Two rules are missing**: nothing says `seats > 0`, and nothing
says `sold` may not exceed `seats`, the rule that kept boxoffice from overselling. The struct had no way
to say them, so the table does not enforce them. They can be added with `check` tags, and the point
stands: **a schema generated from structs knows what the structs know**, and the database's own rules
have to be asked for one by one.

AutoMigrate is also cautious in one direction only. It creates what is missing and widens some
columns whose size changed, and it never drops a column the struct no longer has, because that could
destroy data. **That makes it fine for a prototype and wrong for a
database with real sales in it**, where every change to the schema should be a reviewed, versioned
step. Lesson 9 is about exactly those steps.
