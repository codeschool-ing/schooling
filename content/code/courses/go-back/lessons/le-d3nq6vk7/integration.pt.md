---
title: Contra um PostgreSQL de verdade
version: 1
---

O `pgStore` é código que só tem sentido com um banco por trás: o `Sell` dele é uma transação, um `UPDATE`
condicional e um `INSERT`, e a correção dele é o comportamento do banco sob concorrência. **Testá-lo contra
uma imitação testaria a imitação.** Estes testes criam um banco de verdade só deles:

```go
// boxoffice/pgstore_test.go
package main

import (
	"context"
	"crypto/rand"
	"errors"
	"net/url"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// testDB makes a database for one test, migrates it, and drops it when the
// test ends. BOXOFFICE_TEST_DATABASE_URL names the server to make it on.
func testDB(t *testing.T) *pgxpool.Pool {
	t.Helper()
	base := os.Getenv("BOXOFFICE_TEST_DATABASE_URL")
	if base == "" {
		t.Skip("BOXOFFICE_TEST_DATABASE_URL is not set")
	}
	ctx := context.Background()
	admin, err := pgx.Connect(ctx, base)
	if err != nil {
		t.Fatal(err)
	}
	name := "boxoffice_test_" + strings.ToLower(rand.Text()[:10])
	if _, err := admin.Exec(ctx, "CREATE DATABASE "+name); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if _, err := admin.Exec(ctx, "DROP DATABASE "+name+" WITH (FORCE)"); err != nil {
			t.Errorf("dropping %s: %v", name, err)
		}
		admin.Close(ctx)
	})

	u, err := url.Parse(base)
	if err != nil {
		t.Fatal(err)
	}
	u.Path = "/" + name
	if err := migrate(ctx, u.String()); err != nil {
		t.Fatal(err)
	}
	pool, err := pgxpool.New(ctx, u.String())
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

func TestPgStoreSellsNoMoreThanItHas(t *testing.T) {
	pool := testDB(t)
	store := &pgStore{pool: pool}
	ctx := context.Background()
	e, err := store.Add(ctx, "Small Room", 10)
	if err != nil {
		t.Fatal(err)
	}

	var wg sync.WaitGroup
	var mu sync.Mutex
	results := map[string]int{}
	for range 30 {
		wg.Go(func() {
			_, err := store.Sell(ctx, e.ID, 1, "fan@example.com")
			mu.Lock()
			defer mu.Unlock()
			switch {
			case err == nil:
				results["sold"]++
			case errors.Is(err, ErrSoldOut):
				results["sold out"]++
			default:
				results[err.Error()]++
			}
		})
	}
	wg.Wait()

	if results["sold"] != 10 || results["sold out"] != 20 || len(results) != 2 {
		t.Errorf("results %v, want 10 sold and 20 sold out", results)
	}
	var sold, tickets int
	pool.QueryRow(ctx, "SELECT sold FROM events WHERE id = $1", e.ID).Scan(&sold)
	pool.QueryRow(ctx, "SELECT count(*) FROM tickets WHERE event_id = $1", e.ID).Scan(&tickets)
	if sold != 10 || tickets != 10 {
		t.Errorf("sold %d and %d tickets, want 10 and 10", sold, tickets)
	}
}

func TestASaleReachesTheHub(t *testing.T) {
	pool := testDB(t)
	store := &pgStore{pool: pool}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	h := newHub()
	ch, unsubscribe := h.subscribe(1)
	defer unsubscribe()
	go listen(ctx, pool, h)
	// A sale made before listen has run LISTEN would never be heard, so wait for it.
	for i := 0; ; i++ {
		var n int
		pool.QueryRow(ctx, `SELECT count(*) FROM pg_stat_activity
			WHERE datname = current_database() AND query = 'LISTEN availability'`).Scan(&n)
		if n > 0 {
			break
		}
		if i == 200 {
			t.Fatal("listen did not run LISTEN within 2s")
		}
		time.Sleep(10 * time.Millisecond)
	}

	if _, err := store.Sell(ctx, 1, 3, "fan@example.com"); err != nil {
		t.Fatal(err)
	}
	select {
	case n := <-ch:
		if n != 117 {
			t.Errorf("availability %d, want 117", n)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("no notification within 2s of the sale")
	}
}
```

## Um banco por teste

O `testDB` se conecta ao servidor indicado por `BOXOFFICE_TEST_DATABASE_URL`, cria um banco com nome
aleatório, roda nele o `migrate` da aula 9 e devolve um pool. O primeiro `t.Cleanup` dele apaga o banco
quando o teste termina, `WITH (FORCE)` para que conexões ainda abertas não o bloqueiem, e o cleanup do pool,
registrado depois, roda antes, porque os cleanups rodam do último registrado para o primeiro. **Todo teste
começa das três migrações e dos dois eventos da aula 1, e nada que um teste faz é visível a outro**, que é
também o que os deixaria rodar em paralelo. Um banco leva algumas dezenas de milissegundos para ser criado,
barato o bastante para haver um por teste.

Os dois testes são as duas coisas que só o PostgreSQL mostra:

- **O `TestPgStoreSellsNoMoreThanItHas`** é a verificação de concorrência da aula 9, guardada: trinta
  goroutines compram um lugar cada de um evento com dez. Exatamente dez precisam dar certo, as outras vinte
  precisam ouvir que esgotou, e nada mais pode acontecer; depois, a coluna `sold` e a contagem de ingressos
  precisam dizer dez. Desta vez os resultados vão para um mapa sob um mutex, pelo motivo da seção 06.
- **O `TestASaleReachesTheHub`** verifica a cadeia inteira da aula 13: uma venda dispara o gatilho, a
  notificação chega ao `listen`, e o hub entrega 117, os lugares que sobram depois de três de 120. Ele
  espera até o `pg_stat_activity` mostrar que a conexão do `listen` rodou o `LISTEN`, em vez de dormir e
  torcer: uma venda feita antes disso nunca seria ouvida, e o teste falharia numa máquina lenta por um
  motivo que ele não testa.

## Pulado não é aprovado

Sem a variável, os dois testes são pulados:

```
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" -v .
=== RUN   TestPgStoreSellsNoMoreThanItHas
    pgstore_test.go:60: BOXOFFICE_TEST_DATABASE_URL is not set
--- SKIP: TestPgStoreSellsNoMoreThanItHas (0.00s)
=== RUN   TestASaleReachesTheHub
    pgstore_test.go:100: BOXOFFICE_TEST_DATABASE_URL is not set
--- SKIP: TestASaleReachesTheHub (0.00s)
PASS
ok  	example.com/boxoffice	0.006s
```

**A última linha diz `ok`.** Sem `-v`, nada diria que dois testes não rodaram. Isso é conveniente num
laptop sem banco e perigoso em qualquer outro lugar, então a variável precisa estar definida onde quer que
os resultados importem, a CI em primeiro lugar. Aponte-a para o banco `postgres` do seu servidor local, que
os testes só usam para criar e apagar os seus:

```sh
export BOXOFFICE_TEST_DATABASE_URL='postgres:///postgres?host=/var/run/postgresql'
```

```
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" -v .
=== RUN   TestPgStoreSellsNoMoreThanItHas
--- PASS: TestPgStoreSellsNoMoreThanItHas (0.14s)
=== RUN   TestASaleReachesTheHub
--- PASS: TestASaleReachesTheHub (0.09s)
PASS
ok  	example.com/boxoffice	0.236s
```

O `pgstore_test.go:60` e o `:100` da execução pulada são as linhas dos testes que chamaram o `testDB`, não
linhas de dentro dele, que é o `t.Helper()` em ação.

## O cache

```
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" .
ok  	example.com/boxoffice	(cached)
ana@vm:~/boxoffice$ go test -run "TestPgStore|TestASale" .
ok  	example.com/boxoffice	(cached)
ana@vm:~/boxoffice$ go test -count=1 -run "TestPgStore|TestASale" .
ok  	example.com/boxoffice	0.292s
```

A segunda execução idêntica diz **`(cached)`**: o `go test` guarda o resultado de uma execução aprovada e o
repete enquanto o código, as flags e as variáveis de ambiente que o teste leu continuarem os mesmos. O
conteúdo do banco não é nenhum desses, então um teste que depende dele pode ser respondido pelo cache
depois de o banco mudar por baixo. **O `-count=1` desliga o cache** numa execução, e a CI deve sempre
passá-lo. O último comando confirma que a limpeza funcionou: nenhum banco de teste ficou para trás.
