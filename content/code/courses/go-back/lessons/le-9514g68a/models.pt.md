---
title: Modelos, e as tabelas que o GORM faz a partir deles
version: 1
---

Um modelo do GORM é uma struct comum. O GORM lê o nome, os campos e as tags dela, e a partir deles
decide a tabela, as colunas e as chaves. **Quase tudo isso sai de convenções de nome**, então o modelo
mais curto é o que segue as convenções à risca:

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

O que o GORM lê desses tipos:

- **A tabela é o nome da struct, em snake case e no plural**: `Event` vira `events`, `Ticket` vira
  `tickets`.
- **Um campo chamado `ID` é a chave primária**; a tag `primaryKey` só diz isso em voz alta.
- **`EventID uint` mais `Event Event` é um "belongs to"**: um ingresso pertence a um evento, pela
  coluna `event_id`. **`Tickets []Ticket` em `Event` é o outro lado**, um "has many".
- **`gorm.Model` embutido** acrescenta quatro campos que toda linha de `tickets` ganha: `ID`,
  `CreatedAt`, `UpdatedAt` e `DeletedAt`. O GORM preenche os dois carimbos de tempo sozinho, e o
  terceiro muda o que `Delete` quer dizer, como a seção 07 mostra.
- **As tags** acrescentam o que os tipos de Go não sabem dizer: `size:100`, `not null`, um índice
  único, um valor padrão.

O `Open` conecta pelo driver e configura **o logger do GORM para imprimir cada comando que ele
manda**, com o arquivo e a linha que o causou. Esse logger é o que torna esta aula possível: é o único
jeito de ver o SQL que um ORM escreveu.

## AutoMigrate

O primeiro programa pede ao GORM que faça as tabelas:

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

**Seis comandos, todos escritos pelo GORM.** Ele perguntou se cada tabela existia, criou-a e criou os
índices: um único em `name`, vindo da tag, e um em `deleted_at`, porque toda consulta em tickets vai
filtrar por ele. A chave estrangeira `fk_events_tickets` veio do relacionamento, sem tag nenhuma
pedindo. `int` virou `bigint` e o id `uint` virou `bigserial`.

Compare com o `schema.sql` da aula 6. **Faltam duas regras**: nada diz `seats > 0`, e nada diz que
`sold` não pode passar de `seats`, a regra que impedia o boxoffice de vender demais. A struct não tinha
como dizê-las, então a tabela não as impõe. Elas podem ser acrescentadas com tags `check`, e o ponto
continua: **um schema gerado a partir de structs sabe o que as structs sabem**, e as regras do próprio
banco precisam ser pedidas uma a uma.

O AutoMigrate também é cauteloso numa direção só. Ele cria o que falta e alarga algumas colunas cujo
tamanho mudou, e nunca apaga uma coluna que a struct deixou de ter, porque isso destruiria dados.
**Isso o torna bom para um protótipo e errado para um banco com vendas de verdade**, onde toda mudança
de schema deveria ser um passo revisado e versionado. A aula 9 trata exatamente desses passos.
