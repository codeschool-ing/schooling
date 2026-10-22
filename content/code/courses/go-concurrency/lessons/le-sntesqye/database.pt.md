---
title: Uma consulta a banco de dados
version: 1
---

**Este curso não tem banco de dados, e esta seção diz isso em vez de fingir.** A biblioteca padrão
define como Go conversa com um, no `database/sql`, e deixa a conversa em si para um driver escrito
por outra pessoa. O `go doc` diz isso com todas as letras:

```
ana@vm:~/cases$ go doc database/sql.DB.Query
package sql // import "database/sql"

func (db *DB) Query(query string, args ...any) (*Rows, error)
    Query executes a query that returns rows, typically a SELECT. The args are
    for any placeholder parameters in the query.

    Query uses context.Background internally; to specify the context, use
    DB.QueryContext.

ana@vm:~/cases$ go doc database/sql.Open | sed -n 8,11p
    Most users will open a database via a driver-specific connection helper
    function that returns a *DB. No database drivers are included in the
    Go standard library. See https://golang.org/s/sqldrivers for a list of
    third-party drivers.
```

A primeira resposta é a que importa aqui. **Todo método do `database/sql` que pode esperar tem um
gêmeo que recebe um contexto**: `QueryContext`, `ExecContext`, `PingContext`, `BeginTx`. O `Query`
simples é o `QueryContext` com `context.Background()`, um contexto que nunca termina, então uma
consulta feita com ele espera o quanto o banco demorar, por menos que a requisição que a pediu
estivesse disposta a esperar.

A forma é a mesma de toda chamada da lição 11. O programa abaixo é essa forma inteira, e ele
compila, passa no `go vet` e roda; é salvo em `~/cases/nodb` como `nodb.go`:

```go
// Command nodb is the shape of a query with a deadline, on a machine with no database.
package main

import (
	"context"
	"database/sql"
	"fmt"
	"time"
)

func orders(ctx context.Context, db *sql.DB, customer string) ([]string, error) {
	ctx, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	rows, err := db.QueryContext(ctx, "SELECT id FROM orders WHERE customer = $1", customer)
	if err != nil {
		return nil, fmt.Errorf("orders of %s: %w", customer, err)
	}
	defer rows.Close()
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func main() {
	db, err := sql.Open("postgres", "postgres://ana@127.0.0.1/shop")
	if err != nil {
		fmt.Println("open:", err)
		return
	}
	defer db.Close()
	ids, err := orders(context.Background(), db, "ana")
	fmt.Println(ids, err)
}
```

```
ana@vm:~/cases$ go vet ./nodb && go run ./nodb
open: sql: unknown driver "postgres" (forgotten import?)
```

Ele falhou onde tinha de falhar: `sql.Open` procurou um driver registrado com o nome `postgres`, não
achou nenhum, e disse isso. Tudo depois dessa linha fica sem exercício nesta máquina, e o curso
diz isso claramente. O que o código ainda mostra é por onde o contexto passa:

- **`orders` recebe `ctx` primeiro e deriva um filho** com um limite próprio de dois segundos. Quem
  chamou com menos tempo sobrando vence, pela regra da lição 11.
- **`QueryContext` recebe o filho.** Se o contexto termina enquanto a consulta roda, a chamada
  devolve o erro do contexto. O driver recebe o mesmo contexto, e o que ele faz com isso é assunto
  do driver.
- **`rows.Close` é adiado com `defer` e `rows.Err()` é devolvido.** Um contexto que termina no meio
  da leitura das linhas aparece ali, depois que `rows.Next()` devolve false, então uma função que
  pula `rows.Err()` pode tomar meio resultado pelo resultado inteiro.

O que um driver faz quando recebe ordem de parar, como o próprio banco cancela o trabalho, e como
isso fica num servidor de verdade são perguntas para um banco de verdade. **O `go-back` se conecta
a um**, e este curso deixa isso para ele.
