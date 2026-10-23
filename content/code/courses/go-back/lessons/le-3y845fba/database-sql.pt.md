---
title: database/sql, a interface padrão
version: 1
---

A biblioteca padrão do Go tem um pacote para bancos SQL, o `database/sql`, e, como o `net/http`, ele é
mais uma interface que uma implementação. **Ele define como um programa pede coisas a um banco; um
driver, importado à parte, sabe falar com um banco em particular.** Para o PostgreSQL, o driver usado
aqui vem do `pgx`, a biblioteca PostgreSQL mais completa para Go, que a seção 06 usa por conta própria.

```go
// dbsql/main.go
package main

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"

	_ "github.com/jackc/pgx/v5/stdlib"
)

func main() {
	db, err := sql.Open("pgx", os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()
	ctx := context.Background()

	rows, err := db.QueryContext(ctx, "SELECT id, name, seats - sold FROM events ORDER BY id")
	if err != nil {
		log.Fatal(err)
	}
	defer rows.Close()
	for rows.Next() {
		var id, left int
		var name string
		if err := rows.Scan(&id, &name, &left); err != nil {
			log.Fatal(err)
		}
		fmt.Printf("%d %s: %d left\n", id, name, left)
	}
	if err := rows.Err(); err != nil {
		log.Fatal(err)
	}

	var name string
	err = db.QueryRowContext(ctx, "SELECT name FROM events WHERE id = $1", 9).Scan(&name)
	fmt.Println("event 9:", err, errors.Is(err, sql.ErrNoRows))

	stats := db.Stats()
	fmt.Println("open connections:", stats.OpenConnections, "idle:", stats.Idle)
}
```

O import com sublinhado, `_ "github.com/jackc/pgx/v5/stdlib"`, importa o pacote só pelo que ele faz ao
carregar: registra um driver com o nome `"pgx"`, e o `sql.Open("pgx", url)` o encontra por esse nome.
Depois:

- **`QueryContext` devolve `rows`**, um cursor sobre o resultado. O `rows.Next` o move, o `rows.Scan`
  copia as colunas da linha atual para variáveis, em ordem, e o `rows.Close` devolve a conexão. O
  `defer rows.Close()` importa: **um `rows` que nunca é fechado segura a conexão para sempre**, e
  bastam alguns desses para deixar um pool sem nenhuma.
- **`rows.Err()` depois do laço** informa um erro que terminou o laço antes da hora. Um laço que para
  porque a rede caiu parece igualzinho a um laço que chegou à última linha, e só esta verificação
  distingue os dois.
- **`QueryRowContext` é para uma linha**, e o `Scan` dele devolve `sql.ErrNoRows` quando não havia
  nenhuma.
- Toda chamada recebe um `context.Context`, para que uma consulta pertença a uma requisição e possa
  ser cancelada com ela, que é o uso que a aula 12 do `go-concurrency` citou para um banco.

```
ana@vm:~/dbsql$ export DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql'
ana@vm:~/dbsql$ go mod init example.com/dbsql
go: creating new go.mod: module example.com/dbsql
go: to add module requirements and sums:
	go mod tidy
ana@vm:~/dbsql$ go mod tidy
go: finding module for package github.com/jackc/pgx/v5/stdlib
go: found github.com/jackc/pgx/v5/stdlib in github.com/jackc/pgx/v5 v5.11.0
ana@vm:~/dbsql$ DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql' go run .
1 Jazz at the Docks: 120 left
2 Chamber Choir: 0 left
event 9: sql: no rows in result set true
open connections: 1 idle: 1
```

O `go mod tidy` achou o driver pelo import e baixou o que ele precisa. O programa então listou os dois
eventos, recebeu `sql.ErrNoRows` para o evento 9 e o reconheceu com `errors.Is`, e informou **uma
conexão aberta, ociosa**.

## `sql.DB` é um pool, não uma conexão

O nome engana todo mundo uma vez. **O `sql.Open` não conecta em nada**; ele confere os argumentos e
devolve um `*sql.DB`, que é um pool de conexões abertas sob demanda e reaproveitadas. A primeira
consulta abriu uma, e quando o `rows.Close` a devolveu, ela voltou ao pool como ociosa, que é o que a
última linha mostra. Um programa abre um `sql.DB` no início e o compartilha em todo lugar, de toda
goroutine; ele é seguro para isso, e abrir um por requisição é um jeito clássico de esgotar as
conexões de um banco. A aula 9 dimensiona o pool.

## Por que o boxoffice não o usa

O `database/sql` funciona com qualquer banco que tenha driver, e essa portabilidade é o objetivo dele.
Ela custa recursos próprios do PostgreSQL e um pouco de velocidade: todo valor passa pelas conversões
genéricas do pacote, e coisas como os arrays do PostgreSQL, o `COPY` para carga em massa ou o `LISTEN`
para notificações ficam fora de alcance ou desajeitadas. **Um serviço que só vai falar com o
PostgreSQL não perde nada usando a interface própria do pgx**, e o boxoffice a usa, da próxima seção
em diante. O GORM da aula 7 e o sqlc da aula 8 funcionam sobre qualquer um dos dois.
