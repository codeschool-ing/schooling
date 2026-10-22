---
title: A consulta N+1
version: 1
---

O problema de desempenho mais comum com um ORM tem nome: **consultas N+1.** Uma consulta busca uma
lista de N coisas, e depois o código percorre a lista e roda mais uma consulta para cada uma, para
carregar algo relacionado. Em Go isso se lê com naturalidade e é invisível no código, porque cada
consulta é uma linha inocente. Este programa faz isso de propósito, e conta:

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

Ele silencia o logger, porque o ponto aqui é um número e não vinte comandos, e registra um
**callback**, uma função que o GORM chama antes de toda consulta, para contá-las. Ele cria vinte
eventos com dois ingressos cada, e depois soma os lugares vendidos duas vezes:

```
ana@vm:~/gormlab$ DATABASE_URL='postgres:///gormlab?host=/var/run/postgresql' go run ./cmd/nplus1
one query per event: 20 events, 60 seats sold, 21 queries
with Preload:        20 events, 60 seats sold, 2 queries
```

**A mesma resposta com 21 consultas e com 2.** O laço rodou uma consulta para os eventos e mais uma
para cada um dos vinte; o `Preload` rodou uma para os eventos e uma para todos os ingressos de uma vez,
com `WHERE event_id IN (...)`. Nesta máquina cada consulta leva uma fração de milissegundo, e a
diferença é invisível. Pela rede até um servidor de banco, a um milissegundo ou mais cada, vinte
consultas são vinte idas e voltas; com mil eventos, mil e uma. **O N+1 cresce com os dados, e é por
isso que ninguém o nota no desenvolvimento e todo mundo o encontra em produção.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 200\" role=\"img\" aria-label=\"Duas fileiras de blocos pequenos, um bloco por consulta. A primeira fileira, o laço, tem um bloco para os eventos seguido de vinte blocos, um para os ingressos de cada evento: vinte e um ao todo. A segunda fileira, com Preload, tem um bloco para os eventos e um para todos os ingressos: dois ao todo.\"><defs><marker id=\"gb-l7-n1-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"15\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma consulta por evento</text><rect x=\"15\" y=\"45\" width=\"44\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"37\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">events</text><rect x=\"66\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"93\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"120\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"147\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"174\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"201\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"228\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"255\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"282\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"309\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"336\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"363\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"417\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"444\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"471\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"498\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"525\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"552\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><rect x=\"579\" y=\"45\" width=\"22\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"615\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">21 consultas</text><text x=\"15\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">com Preload</text><rect x=\"15\" y=\"135\" width=\"44\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"37\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">events</text><rect x=\"66\" y=\"135\" width=\"535\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"333\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tickets WHERE event_id IN (...)</text><text x=\"615\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 consultas</text></svg>", "caption": "Os mesmos 60 lugares contados duas vezes. Cada bloco é uma ida e volta ao banco."}
```

## Encontrando

O sintoma é um handler cujo tempo cresce com o tamanho do que ele devolve, e a ferramenta é a que esta
aula usou o tempo todo: **o log de consultas, com uma contagem**. Um teste que confere quantas
consultas um endpoint manda, como este programa as conta, pega o problema no dia em que ele é escrito.

## E a resposta melhor

O `Preload` consertou a contagem de consultas, e ainda trouxe cada linha de ingresso para o Go para
somar dois números. **O próprio banco faz a soma** e devolve um número por evento:

```sql
SELECT e.name, coalesce(sum(t.quantity), 0) AS sold
FROM events e LEFT JOIN tickets t ON t.event_id = e.id AND t.deleted_at IS NULL
GROUP BY e.id ORDER BY e.id;
```

Um ORM deixa as duas primeiras versões fáceis de escrever e a terceira desajeitada, e esse é um resumo
justo de onde os ORMs ajudam e onde atrapalham. A aula 6 do `sql-databases` trata de agregações como
esta, e a aula 8 mostra uma ferramenta que começa pelo SQL.
