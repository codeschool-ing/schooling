---
title: What an ORM does, and what it hides
version: 1
---

Lesson 6 wrote every SQL statement boxoffice sends, by hand, and scanned every column into a field by
hand. **An ORM, an object-relational mapper, writes those statements for you from your types.** You
describe a struct, and it creates the table, inserts a value of that struct as a row, reads rows back
into values, and follows the relationships between them. GORM is the most widely used one in Go, and
this lesson uses its current release, v1.31.2, with its PostgreSQL driver, which is built on the same
pgx as lesson 6.

The trade is simple to state and easy to underestimate:

| an ORM gives you | and costs you |
|---|---|
| no SQL for the common operations: create, find by id, update a field, delete | the SQL it writes is not in your code, so reading the code does not tell you what the database is asked |
| relationships loaded by name, `Preload("Tickets")` | one innocent loop can send a hundred queries, section 06's subject |
| a schema made from the structs | a schema that knows only what the struct tags say, which is less than the table in lesson 6 said |
| one API for several databases | rules of its own, which section 07 is about |

**Nothing in this lesson changes boxoffice.** GORM gets a project of its own, `gormlab`, with its own
database, so that it can create tables freely and so that the comparison with lesson 6's pgx code is
side by side rather than a rewrite. Lesson 8 then shows the opposite approach, and section 08 here
says when GORM is the right one.

## The project

`gormlab` is one module with a package of models and several small programs, each a command under
`cmd/`, each shown whole in the section that runs it:

```localised
gormlab/
  models/models.go        the two models and a function to connect
  cmd/migrate/main.go     section 03
  cmd/crud/main.go        section 04
  cmd/relations/main.go   section 05
  cmd/nplus1/main.go      section 06
  cmd/pitfalls/main.go    section 07
```

It uses its own database, made the way lesson 6 made `boxoffice`. Once the files of section 03 are in
place, `go mod tidy` fetches GORM:

```
ana@vm:~/gormlab$ createdb gormlab
ana@vm:~/gormlab$ export DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql'
ana@vm:~/gormlab$ go mod init example.com/gormlab
go: creating new go.mod: module example.com/gormlab
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/gormlab$ go mod tidy
go: finding module for package gorm.io/driver/postgres
go: finding module for package gorm.io/gorm
go: finding module for package gorm.io/gorm/logger
go: found gorm.io/gorm in gorm.io/gorm v1.31.2
go: found gorm.io/gorm/logger in gorm.io/gorm v1.31.2
go: found gorm.io/driver/postgres in gorm.io/driver/postgres v1.6.3
ana@vm:~/gormlab$ sed -n 1,8p go.mod
module example.com/gormlab

go 1.27.1

require (
	gorm.io/driver/postgres v1.6.3
	gorm.io/gorm v1.31.2
)
```

**Two direct requirements**, GORM and its driver. `go mod tidy` also downloaded the SQLite driver and
`go-sqlite3`, which the PostgreSQL driver's own tests use; they are not in the binary, and they show how
far a module graph reaches beyond what a program calls.
