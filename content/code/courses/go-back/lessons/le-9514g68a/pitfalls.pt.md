---
title: Quatro armadilhas
version: 1
---

As regras do GORM estão documentadas, e cada uma é razoável sozinha. **Juntas elas são uma segunda
língua dentro do Go, e os erros vêm de esquecer que você está falando nela.** Este programa cai em
quatro delas, uma depois da outra, contra as linhas que os programas anteriores deixaram:

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

## 1. Um valor zero não é uma atualização

O `db.Model(&e).Updates(models.Event{Sold: 0})` deveria zerar as vendas do evento de jazz. **O GORM não
mandou `UPDATE` nenhum**: o log pula direto do primeiro `SELECT` para o segundo, e `sold` continua 2.
Quando o `Updates` recebe uma struct, ele escreve só os campos que não estão no valor zero, porque não
consegue distinguir "ponha isto em zero" de "não falei deste campo". `0`, `""` e `false` são todos
ignorados. **Para escrever um zero, nomeie a coluna**: `Update("sold", 0)`, um `map[string]any`, ou
`Select("sold")` antes do `Updates`. A seção 04 da aula 3 encontrou a mesma ambiguidade em JSON.

## 2. Delete não apaga

O `db.Delete(&t)` num ingresso mandou um `UPDATE ... SET "deleted_at"=...`. **Um modelo que embute
`gorm.Model` sofre soft delete**: a linha fica, carimbada com a hora, e toda consulta que o GORM escreve
depois acrescenta `"deleted_at" IS NULL`, então a linha parece ter sumido. A contagem com `Unscoped()` a
encontrou, e o `psql` também, que não sabe nada da convenção do GORM (ele imprime o carimbo em UTC, o
fuso do servidor de banco, onde o GORM registrou a hora de São Paulo).

Isso é útil quando dados apagados precisam ser guardados, e caro quando é esquecido:

- **outro programa que lê a tabela vê a linha como viva**, porque a regra mora no GORM e não no banco;
- um **índice único continua contando a linha apagada**, então o valor único de um ingresso apagado
  não volta a ser usado;
- a tabela só cresce.

O `db.Unscoped().Delete(&t)` apaga de verdade. Deixar o `gorm.Model` fora de uma struct, como `Event`
faz, faz do `Delete` um `DELETE` de verdade.

## 3. Um delete sem condição é recusado

O `db.Delete(&models.Event{})` não nomeia linha nenhuma, e apagaria todos os eventos. **O GORM
recusou** com `WHERE conditions required`; o log mostra o comando que ele montou e não mandou, com
`rows:0`. É uma proteção contra exatamente o erro de uma condição esquecida, e a mesma proteção vale
para o `Update`. Para dizer "todas as linhas", o código precisa dizer isso, com `Where("1 = 1")` ou uma
configuração de sessão.

## 4. First falha, Find não

O `First` sem linha devolveu `record not found`, que é o `gorm.ErrRecordNotFound`; **o `Find` sem linha
não devolveu erro e sim uma slice vazia.** Os dois estão certos para o que querem dizer, uma linha
esperada contra uma lista que pode estar vazia, e um código que usa um com as expectativas do outro ou
reporta uma linha ausente como falha, ou não a percebe. Num handler, o `First` com uma verificação de
`errors.Is` é o 404 da aula 3.
