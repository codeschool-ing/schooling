---
title: Criar, ler, atualizar
version: 1
---

As quatro operações do dia a dia, uma linha de GORM cada:

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

Leia cada linha de Go contra o SQL embaixo dela:

- **`db.Create(&jazz)`** inseriu as três colunas e pediu o id de volta com `RETURNING`, e depois o
  escreveu em `jazz.ID`. É por isso que a struct é passada por ponteiro: o GORM a preenche.
- **`db.First(&e, jazz.ID)`** leu uma linha pela chave primária e acrescentou sozinho
  `ORDER BY "events"."id" LIMIT 1`. "First" quer dizer o primeiro pela chave primária, qualquer que
  seja a consulta, e numa tabela grande essa ordem custa uma ordenação quando a condição não está na
  chave.
- **`db.Model(&e).Update("sold", 2)`** escreveu uma coluna da linha para a qual `e` aponta, usando a
  chave primária dela no `WHERE`.
- **`db.Where("seats - sold > ?", 100).Find(&big)`** mostra a saída de emergência do GORM: a condição é
  o seu SQL, com `?` para cada valor, e o GORM transforma cada `?` num placeholder do tipo do banco.

## O log mostra valores, o banco recebe placeholders

A linha de log diz `WHERE seats - sold > 100`, com o número dentro do SQL. **Isso é o logger sendo
prestativo, não a consulta sendo colada.** O GORM manda o comando com `$1` e o valor separados,
exatamente como pediu a seção 07 da aula 6, e o logger imprime os dois juntos para uma pessoa ler. O
mesmo vale para o `INSERT`, onde o nome do evento aparece entre aspas. Copiar um comando deste log para
o `psql` funciona; não é prova de que valores foram colados no SQL.

**Nada aqui está errado, e nada aqui aparece no código Go.** O `ORDER BY` do `First`, o `RETURNING` do
`Create`, a chave usada pelo `Update`: cada um é uma decisão que o GORM tomou, e que você só vê lendo o
log ou a documentação dele. Esse é o preço que a primeira tabela da seção 02 citou.
