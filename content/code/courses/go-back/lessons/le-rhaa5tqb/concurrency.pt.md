---
title: Dois compradores ao mesmo tempo
version: 1
---

Uma transação torna um grupo de escritas tudo ou nada. **Ela não impede, sozinha, que duas transações
interfiram uma na outra**, e o quanto elas podem interferir é uma configuração chamada nível de
isolamento. O jeito clássico de perder dinheiro é este: dois compradores leem "sobra um lugar" no mesmo
instante, os dois concluem que há espaço, os dois escrevem "vendido mais um", e o evento fica com um
lugar vendido a mais, ou com uma venda esquecida.

Este programa mede isso. Uma tabela `seats` com uma linha, e quatro jeitos de vender um lugar, cada um
rodado cinquenta vezes ao mesmo tempo por cinquenta goroutines:

```go
// race/main.go
package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"sync"
	"sync/atomic"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

// Each way of selling takes one seat of row 1 of the table seats.

func readThenWrite(ctx context.Context, pool *pgxpool.Pool, iso pgx.TxIsoLevel) error {
	tx, err := pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: iso})
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	var sold int
	if err := tx.QueryRow(ctx, "SELECT sold FROM seats WHERE id = 1").Scan(&sold); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, "UPDATE seats SET sold = $1 WHERE id = 1", sold+1); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func forUpdate(ctx context.Context, pool *pgxpool.Pool) error {
	tx, err := pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)
	var sold int
	if err := tx.QueryRow(ctx, "SELECT sold FROM seats WHERE id = 1 FOR UPDATE").Scan(&sold); err != nil {
		return err
	}
	if _, err := tx.Exec(ctx, "UPDATE seats SET sold = $1 WHERE id = 1", sold+1); err != nil {
		return err
	}
	return tx.Commit(ctx)
}

func oneUpdate(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, "UPDATE seats SET sold = sold + 1 WHERE id = 1")
	return err
}

func main() {
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()
	if _, err := pool.Exec(ctx, "CREATE TABLE IF NOT EXISTS seats (id int PRIMARY KEY, sold int NOT NULL)"); err != nil {
		log.Fatal(err)
	}

	ways := []struct {
		name string
		sell func(context.Context, *pgxpool.Pool) error
	}{
		{"read, then write", func(ctx context.Context, p *pgxpool.Pool) error { return readThenWrite(ctx, p, pgx.ReadCommitted) }},
		{"the same, REPEATABLE READ", func(ctx context.Context, p *pgxpool.Pool) error { return readThenWrite(ctx, p, pgx.RepeatableRead) }},
		{"SELECT ... FOR UPDATE", forUpdate},
		{"one UPDATE", oneUpdate},
	}
	for _, way := range ways {
		if _, err := pool.Exec(ctx, "DELETE FROM seats"); err != nil {
			log.Fatal(err)
		}
		if _, err := pool.Exec(ctx, "INSERT INTO seats VALUES (1, 0)"); err != nil {
			log.Fatal(err)
		}
		var failed atomic.Int32
		var wg sync.WaitGroup
		for range 50 {
			wg.Go(func() {
				if err := way.sell(ctx, pool); err != nil {
					var pgErr *pgconn.PgError
					if errors.As(err, &pgErr) && pgErr.Code == "40001" {
						failed.Add(1)
						return
					}
					log.Print(err)
				}
			})
		}
		wg.Wait()
		var sold int
		if err := pool.QueryRow(ctx, "SELECT sold FROM seats WHERE id = 1").Scan(&sold); err != nil {
			log.Fatal(err)
		}
		fmt.Printf("%-26s 50 sales: sold = %2d, refused with 40001: %2d\n", way.name, sold, failed.Load())
	}
}
```

- **ler, depois escrever**: uma transação lê `sold`, soma um em Go e grava o número novo. É o jeito
  natural de escrever isso, e o errado.
- **o mesmo em `REPEATABLE READ`**, um nível de isolamento mais estrito que o padrão do PostgreSQL,
  `READ COMMITTED`.
- **`SELECT ... FOR UPDATE`**: a leitura pega um lock na linha, então a próxima transação que a quiser
  espera esta terminar.
- **um `UPDATE`**: `sold = sold + 1`, a conta feita pelo banco dentro de um único comando.

Ele roda num banco próprio, `racelab`, duas vezes:

```
ana@vm:~/race$ createdb racelab
ana@vm:~/race$ DATABASE_URL='postgres:///racelab?host=/var/run/postgresql' go run .
read, then write           50 sales: sold = 27, refused with 40001:  0
the same, REPEATABLE READ  50 sales: sold = 16, refused with 40001: 34
SELECT ... FOR UPDATE      50 sales: sold = 50, refused with 40001:  0
one UPDATE                 50 sales: sold = 50, refused with 40001:  0
ana@vm:~/race$ DATABASE_URL='postgres:///racelab?host=/var/run/postgresql' go run .
read, then write           50 sales: sold = 17, refused with 40001:  0
the same, REPEATABLE READ  50 sales: sold = 15, refused with 40001: 35
SELECT ... FOR UPDATE      50 sales: sold = 50, refused with 40001:  0
one UPDATE                 50 sales: sold = 50, refused with 40001:  0
```

**A primeira linha é o bug, e dá um número diferente a cada execução**: 27 e depois 17 lugares
registrados para 50 vendas. Muitas transações leram o mesmo valor, cada uma gravou esse valor mais um, e
as escritas posteriores apagaram as anteriores. Isso se chama **atualização perdida** (lost update). Em
`READ COMMITTED`, uma transação vê o que foi confirmado antes de cada um dos seus comandos, então nada
impede duas delas de lerem o mesmo número.

Em `REPEATABLE READ`, o PostgreSQL percebe o conflito: uma transação que tenta atualizar uma linha que
outra alterou depois que ela começou é recusada com **SQLSTATE `40001`, uma falha de serialização**. As
contas fecham, 16 mais 34 e 15 mais 35, então nenhuma venda se perdeu em silêncio; mas **34 compradores
ouviram um não sem motivo**, e o programa tem de tentar de novo para eles. Código que usa `REPEATABLE
READ` ou `SERIALIZABLE` tem de capturar o `40001` e rodar a transação inteira de novo, o que é correto e
é muita maquinaria.

Os dois últimos são exatos, sempre. **O `FOR UPDATE` põe as transações em fila** pela linha. **Um único
`UPDATE` não precisa de transação nenhuma**: o PostgreSQL trava a linha durante o comando e calcula
`sold + 1` a partir do valor que encontra quando já tem o lock.

## O boxoffice faz o quarto

Olhe de novo o `SellSeats`: `UPDATE events SET sold = sold + $1 WHERE id = $2 AND seats - sold >= $1`.
**A verificação e a mudança são um só comando**, então dois compradores do último lugar fazem fila pela
linha, e o segundo encontra `seats - sold` pequeno demais e não muda nada. Isso valia desde a aula 6,
antes das transações; a transação da seção 05 só acrescenta o ingresso ao mesmo tudo ou nada.

Para ver isso contra o serviço de verdade, este programa manda vinte compras de um ingresso cada, todas
ao mesmo tempo, com um limite de cinco segundos para cada resposta:

```go
// rush/main.go
package main

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

// rush sends 20 purchases of one ticket each, all at once, and counts the answers.
func main() {
	url := "http://localhost:8080/events/" + os.Args[1] + "/tickets"
	client := &http.Client{Timeout: 5 * time.Second}
	var mu sync.Mutex
	statuses := map[int]int{}
	var wg sync.WaitGroup
	for i := range 20 {
		wg.Go(func() {
			body := fmt.Sprintf(`{"quantity": 1, "email": "buyer%02d@example.com"}`, i)
			resp, err := client.Post(url, "application/json", strings.NewReader(body))
			if err != nil {
				mu.Lock()
				statuses[0]++
				mu.Unlock()
				return
			}
			resp.Body.Close()
			mu.Lock()
			statuses[resp.StatusCode]++
			mu.Unlock()
		})
	}
	wg.Wait()
	fmt.Println("201:", statuses[201], " 409:", statuses[409], " no answer in 5s:", statuses[0])
}
```

A seção 07 o roda contra um evento com cinco lugares, e encontra a linha que a seção anterior prometeu.
