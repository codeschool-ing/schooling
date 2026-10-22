---
title: Relacionamentos, e como carregá-los
version: 1
---

Os modelos declararam um relacionamento nos dois sentidos: um `Event` tem muitos `Tickets`, e um
`Ticket` pertence a um `Event`. **O GORM usa essas declarações quando escreve e quando lê**, e vale
observar os dois:

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

## Escrevendo: os filhos vêm junto

O `db.Create(&choir)` recebeu um evento com dois ingressos dentro, e salvou os três: o evento, depois
os dois ingressos num `INSERT` de várias linhas, cada um levando o id do novo evento, 2. **O log
imprime primeiro o insert dos ingressos** porque o GORM registra um comando quando a operação inteira
termina, e o `Create` do evento só terminou depois de os ingressos serem salvos; o `event_id` 2 nos
valores dos ingressos é a prova de que a linha do evento veio antes. O GORM também preencheu
`created_at` e `updated_at` sozinho, por causa do `gorm.Model`.

## Lendo: Preload ou Joins

Um simples `First(&loaded, id)` teria deixado `loaded.Tickets` vazio. **Relacionamentos só são
carregados quando pedidos**, e há dois jeitos de pedir:

| | `Preload("Tickets")` | `Joins("Event")` |
|---|---|---|
| consultas | duas: o evento, depois os ingressos `WHERE event_id = 2` | uma, com um `LEFT JOIN` |
| serve para | has many: um evento, muitos ingressos | belongs to: um ingresso, um evento |
| o SQL | simples, uma tabela por vez | todas as colunas das duas tabelas, cada uma renomeada, como `"Event"."name" AS "Event__name"` |

O `Preload` com muitos eventos manda uma segunda consulta com `WHERE event_id IN (...)` para todos
eles, e não uma por evento. **A diferença entre isso e um laço é a próxima seção.** Note também que a
consulta de ingressos acrescentou `"tickets"."deleted_at" IS NULL` sem ninguém pedir; a seção 07 explica
por quê.
