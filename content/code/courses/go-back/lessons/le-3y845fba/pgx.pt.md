---
title: pgx, e o store do boxoffice no PostgreSQL
version: 1
---

O `pgx` tem duas caras. Pelo `database/sql` ele é um driver como qualquer outro, como a seção anterior o
usou. Sozinho, ele é um cliente PostgreSQL completo com interface própria, e é assim que o boxoffice o
usa. **O primeiro passo é uma decisão de formato, não sobre o pgx**: os handlers precisam parar de
falar com o `*memStore` e falar com qualquer coisa que saiba listar, buscar, acrescentar e vender
eventos. A seção 09 escreve isso como uma interface, `Store`, e o `pgStore` abaixo é a segunda coisa que
a satisfaz, depois do store em memória.

```schooling-example
{
  "language": "go",
  "file": "boxoffice/pgstore.go",
  "parts": [
    {
      "code": "// boxoffice/pgstore.go\npackage main\n\nimport (\n\t\"context\"\n\t\"errors\"\n\t\"fmt\"\n\n\t\"github.com/jackc/pgx/v5\"\n\t\"github.com/jackc/pgx/v5/pgconn\"\n\t\"github.com/jackc/pgx/v5/pgxpool\"\n)\n\n// pgStore keeps the events in PostgreSQL.\ntype pgStore struct {\n\tpool *pgxpool.Pool\n}\n\n",
      "note": "**Um `pgxpool.Pool` é o pool do pgx**, a mesma ideia do `sql.DB` da seção anterior: muitas conexões, abertas sob demanda, seguras para compartilhar de toda goroutine. O `pgStore` guarda um, criado uma vez no `main`."
    },
    {
      "code": "func (s *pgStore) List(ctx context.Context) ([]Event, error) {\n\trows, err := s.pool.Query(ctx, `SELECT id, name, seats, sold FROM events ORDER BY id`)\n\tif err != nil {\n\t\treturn nil, fmt.Errorf(\"listing events: %w\", err)\n\t}\n\treturn pgx.CollectRows(rows, pgx.RowToStructByPos[Event])\n}\n\n",
      "note": "O `Query` manda o SQL e devolve linhas; **o `pgx.CollectRows` as percorre, lê cada uma com a função que recebe e as fecha**, de modo que o `rows.Close` e o `rows.Err` da seção anterior não têm como ser esquecidos. O `RowToStructByPos[Event]` preenche os campos da struct a partir das colunas, em ordem, e é por isso que o `SELECT` nomeia as colunas na ordem em que `Event` declara os campos."
    },
    {
      "code": "func (s *pgStore) Get(ctx context.Context, id int) (Event, error) {\n\tvar e Event\n\terr := s.pool.QueryRow(ctx, `SELECT id, name, seats, sold FROM events WHERE id = $1`, id).\n\t\tScan(&e.ID, &e.Name, &e.Seats, &e.Sold)\n\tif errors.Is(err, pgx.ErrNoRows) {\n\t\treturn Event{}, fmt.Errorf(\"event %d: %w\", id, ErrNotFound)\n\t}\n\treturn e, err\n}\n\n",
      "note": "**`$1` é um placeholder**, e o `id` viaja separado do texto SQL; a seção 07 trata de por que isso importa. Nenhuma linha volta como `pgx.ErrNoRows`, que é do pgx, e o store o transforma no próprio `ErrNotFound`, embrulhado com o id, para que o `fail` da aula 3 ainda o reconheça com `errors.Is`."
    },
    {
      "code": "func (s *pgStore) Add(ctx context.Context, name string, seats int) (Event, error) {\n\te := Event{Name: name, Seats: seats}\n\terr := s.pool.QueryRow(ctx,\n\t\t`INSERT INTO events (name, seats) VALUES ($1, $2) RETURNING id`, name, seats).Scan(&e.ID)\n\tvar pgErr *pgconn.PgError\n\tif errors.As(err, &pgErr) && pgErr.Code == \"23505\" {\n\t\treturn Event{}, fmt.Errorf(\"%q: %w\", name, ErrDuplicate)\n\t}\n\treturn e, err\n}\n\n",
      "note": "O `RETURNING id` devolve o número que o banco escolheu, na mesma ida e volta da inserção. Uma violação de unicidade, **SQLSTATE `23505`**, vira `ErrDuplicate`; a seção 08 mostra o erro de onde ela é lida."
    },
    {
      "code": "// Sell takes quantity seats in one statement, so two buyers cannot both get the last one.\nfunc (s *pgStore) Sell(ctx context.Context, id, quantity int) (Event, error) {\n\tvar e Event\n\terr := s.pool.QueryRow(ctx, `\n\t\tUPDATE events SET sold = sold + $2\n\t\tWHERE id = $1 AND seats - sold >= $2\n\t\tRETURNING id, name, seats, sold`, id, quantity).Scan(&e.ID, &e.Name, &e.Seats, &e.Sold)\n\tif errors.Is(err, pgx.ErrNoRows) {\n\t\tif _, err := s.Get(ctx, id); err != nil {\n\t\t\treturn Event{}, err\n\t\t}\n\t\treturn Event{}, fmt.Errorf(\"event %d: %w\", id, ErrSoldOut)\n\t}\n\treturn e, err\n}\n",
      "note": "**A venda inteira é uma instrução só.** O `WHERE` ao mesmo tempo acha o evento e confere os lugares, e o PostgreSQL faz a verificação e a mudança na linha juntas, então dois compradores do último lugar não conseguem passar os dois. Nenhuma linha de volta quer dizer uma de duas coisas, e uma segunda consulta diz qual: o evento não existe, ou está esgotado."
    }
  ]
}
```

Três hábitos desse arquivo valem a pena em todo store que você escrever:

- **Todo método recebe um `context.Context` e o repassa ao pgx.** Quando um cliente desconecta, o
  contexto da requisição é cancelado, e o pgx cancela a consulta no servidor em vez de terminar um
  trabalho que ninguém vai ler.
- **Erros do pgx são embrulhados com o que estava sendo feito** (`listing events: %w`), e os erros
  sentinela do próprio store servem para o que os handlers precisam distinguir. Um handler nunca vê
  um tipo do pgx.
- **Cada instrução SQL é uma string constante com placeholders.** Nada da requisição é colado no
  próprio SQL.

O número de idas e voltas também importa. `List`, `Get` e `Add` fazem uma cada. O `Sell` faz uma quando
dá certo, que é o caso comum, e duas só quando falha. **Uma chamada ao banco é a coisa mais lenta que um
handler faz**: o log da aula 2 media dezenas de microssegundos por requisição contra o mapa, e a seção
09 vai medir milissegundos contra o PostgreSQL.
