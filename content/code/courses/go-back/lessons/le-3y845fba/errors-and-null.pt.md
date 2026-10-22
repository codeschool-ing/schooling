---
title: NULL, linhas que faltam e regras quebradas
version: 1
---

Três coisas voltam de um banco para as quais um programa Go precisa estar pronto: **um valor que não
está lá, uma linha que não está lá e uma regra que o banco se recusou a quebrar.** Este programa
encontra cada uma de propósito:

```go
// nulls/main.go
package main

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func main() {
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
	defer conn.Close(ctx)

	var s string
	err = conn.QueryRow(ctx, "SELECT NULL::text").Scan(&s)
	fmt.Printf("string:      %q %v\n", s, err)

	var p *string
	err = conn.QueryRow(ctx, "SELECT NULL::text").Scan(&p)
	fmt.Printf("*string:     %v %v\n", p, err)

	var t pgtype.Text
	err = conn.QueryRow(ctx, "SELECT NULL::text").Scan(&t)
	fmt.Printf("pgtype.Text: %+v %v\n", t, err)

	_, err = conn.Exec(ctx, "INSERT INTO events (name, seats) VALUES ('Chamber Choir', 10)")
	fmt.Println("duplicate:  ", err)

	_, err = conn.Exec(ctx, "UPDATE events SET sold = 200 WHERE id = 1")
	fmt.Println("too many:   ", err)
}
```

```
ana@vm:~/nulls$ DATABASE_URL='postgres:///boxoffice?host=/var/run/postgresql' go run .
string:      "" can't scan into dest[0] (col: text): cannot scan NULL into *string
*string:     <nil> <nil>
pgtype.Text: {String: Valid:false} <nil>
duplicate:   ERROR: duplicate key value violates unique constraint "events_name_key" (SQLSTATE 23505)
too many:    ERROR: new row for relation "events" violates check constraint "events_check" (SQLSTATE 23514)
```

## Um valor que não está lá

O `NULL` do SQL quer dizer "sem valor", e uma `string` do Go não consegue guardar isso: o valor zero
dela, `""`, é um valor. **O pgx se recusa a ler `NULL` para uma `string`** em vez de transformá-lo
calado numa string vazia, o que faria um telefone ausente parecer um telefone que ninguém digitou. Dois
tipos conseguem guardá-lo:

- **um ponteiro, `*string`**, que fica `nil` para `NULL`. É curto, e a verificação de `nil` é a
  comum do Go; custa uma alocação por valor.
- **`pgtype.Text`**, uma struct com o valor e uma flag `Valid`, `false` para `NULL`. O `database/sql`
  tem a mesma ideia em `sql.NullString`.

As colunas do boxoffice são todas `NOT NULL`, então nada disso o atinge ainda. **A decisão pertence
primeiro ao schema**: uma coluna que precisa ter valor diz `NOT NULL`, e aí o lado Go não precisa de tipo
especial. A seção 04 da aula 3 disse o mesmo sobre JSON, onde um campo ausente e um zero também não se
distinguem.

## Uma linha que não está lá

`QueryRow` sem linha não é um valor zero: é `pgx.ErrNoRows`, como o `sql.ErrNoRows` era para o
`database/sql`. O `pgStore.Get` o transforma em `ErrNotFound`, e o `fail` da aula 3 transforma isso num
404. **O erro troca de vocabulário a cada camada**, do PostgreSQL para o boxoffice e para o HTTP, e
nenhuma camada precisa conhecer as palavras da que está dois passos adiante.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 230\" role=\"img\" aria-label=\"Três falhas, cada uma atravessando três camadas da esquerda para a direita. Uma linha ausente: pgx.ErrNoRows na camada do PostgreSQL vira ErrNotFound no store e 404 no HTTP. Um nome duplicado: SQLSTATE 23505 vira ErrDuplicate e 409. Uma regra quebrada: SQLSTATE 23514 não tem palavra no store, continua um erro embrulhado e vira um 500 com uma linha de log.\"><defs><marker id=\"gb-l6-words-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">PostgreSQL e pgx</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o store</text><text x=\"590\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTP</text><rect x=\"20\" y=\"38\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pgx.ErrNoRows</text><path d=\"M 200 58 L 258 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"260\" y=\"38\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ErrNotFound</text><path d=\"M 440 58 L 498 58\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"500\" y=\"38\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">404 Not Found</text><rect x=\"20\" y=\"100\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SQLSTATE 23505</text><path d=\"M 200 120 L 258 120\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"260\" y=\"100\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ErrDuplicate</text><path d=\"M 440 120 L 498 120\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"500\" y=\"100\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">409 Conflict</text><rect x=\"20\" y=\"162\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">SQLSTATE 23514</text><path d=\"M 200 182 L 258 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"260\" y=\"162\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">embrulhado, sem nome</text><path d=\"M 440 182 L 498 182\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l6-words-ah)\"></path><rect x=\"500\" y=\"162\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">500, e uma linha de log</text><text x=\"229\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">pgStore</text><text x=\"469\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">fail</text></svg>", "caption": "Cada camada fala as próprias palavras. O pgStore traduz as do banco, o fail traduz as do store, e nada num handler vê um tipo do pgx.", "same": ["HTTP"]}
```

## Uma regra que o banco se recusou a quebrar

As duas últimas linhas são as restrições da seção 04 em ação. A inserção quebrou `events_name_key`, a
unicidade dos nomes, e a atualização quebrou `events_check`, a regra de que `sold` fica dentro de
`seats`. Cada erro traz o seu **SQLSTATE**, cinco caracteres que identificam o tipo de falha em toda
versão do PostgreSQL e no driver de toda linguagem:

| SQLSTATE | nome | o que o boxoffice faz |
|---|---|---|
| `23505` | `unique_violation` | `ErrDuplicate`, respondido com 409 |
| `23514` | `check_violation` | nada de especial: quer dizer um bug, e vira um 500 |
| `42601` | `syntax_error` | nada de especial: o bug da seção 07 |
| `3D000` | `invalid_catalog_name` | o banco ausente da seção 03, na partida |

**Comparar pelo código e não pela mensagem** é o que o `pgStore.Add` faz com o `pgconn.PgError`: a
mensagem é texto em inglês que muda entre versões; o código é um contrato. E o boxoffice transforma em
resposta para o cliente só o duplicado, porque é o único que um cliente provoca com uma requisição
válida. Uma violação de check quer dizer que o próprio código do boxoffice tentou vender demais, o que
nenhum cliente deve ouvir e todo operador deve saber, pela linha `unexpected error` do log.

O `problem.go` ganha o erro novo no `fail` dele, na seção 09.
