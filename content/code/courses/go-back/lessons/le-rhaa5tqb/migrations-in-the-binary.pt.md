---
title: Migrações que viajam com o binário
version: 1
---

O comando goose é uma ferramenta no seu notebook. Um servidor em produção não o tem, e não deveria
precisar de uma pessoa rodando-o antes de cada deploy. **O outro jeito é compilar os arquivos de
migração dentro do próprio boxoffice e aplicá-los quando ele inicia.** O pacote `embed` do Go, que a aula
24 do `go-concurrency` apresentou, põe arquivos dentro do binário na hora do build:

```go
// boxoffice/migrate.go
package main

import (
	"context"
	"database/sql"
	"embed"
	"fmt"
	"io/fs"
	"log"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/pressly/goose/v3"
	"github.com/pressly/goose/v3/lock"
)

//go:embed migrations/*.sql
var migrationFiles embed.FS

// migrate brings the database up to the newest migration compiled into this binary.
func migrate(ctx context.Context, url string) error {
	db, err := sql.Open("pgx", url)
	if err != nil {
		return err
	}
	defer db.Close()
	dir, err := fs.Sub(migrationFiles, "migrations")
	if err != nil {
		return err
	}
	locker, err := lock.NewPostgresSessionLocker()
	if err != nil {
		return err
	}
	provider, err := goose.NewProvider(goose.DialectPostgres, db, dir, goose.WithSessionLocker(locker))
	if err != nil {
		return err
	}
	results, err := provider.Up(ctx)
	if err != nil {
		return fmt.Errorf("migrating: %w", err)
	}
	for _, r := range results {
		log.Printf("migration %s applied in %s", r.Source.Path, r.Duration)
	}
	return nil
}
```

- **`//go:embed migrations/*.sql`** faz de `migrationFiles` um sistema de arquivos somente leitura com
  esses arquivos, compilados dentro. O binário não precisa de diretório nenhum ao lado, e a aula 16
  depende disso.
- **A biblioteca do goose fala `database/sql`**, então o `migrate` abre um `sql.DB` de vida curta pelo
  driver do pgx, aula 6 seção 05, e o fecha ao terminar.
- **O session locker** pega um advisory lock do PostgreSQL durante o processo. Se três cópias do
  boxoffice iniciam ao mesmo tempo, uma aplica as migrações e as outras duas esperam por ela, em vez de
  as três tentarem criar a mesma tabela.
- O `provider.Up` aplica o que estiver pendente e devolve o que fez, que vai para o log.

O `main` o chama antes de qualquer outra coisa tocar no banco, e também monta o pool com duas
configurações próprias, que a seção 07 explica:

```go
// boxoffice/main.go
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	tokens := map[string]string{}
	for role, name := range map[string]string{
		"manager": "BOXOFFICE_MANAGER_TOKEN",
		"door":    "BOXOFFICE_DOOR_TOKEN",
	} {
		if t := os.Getenv(name); t != "" {
			tokens[t] = role
		}
	}
	if len(tokens) == 0 {
		log.Fatal("no staff tokens: set BOXOFFICE_MANAGER_TOKEN")
	}

	url := os.Getenv("DATABASE_URL")
	if url == "" {
		log.Fatal("no database: set DATABASE_URL")
	}
	ctx := context.Background()
	if err := migrate(ctx, url); err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg, err := pgxpool.ParseConfig(url)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	cfg.MaxConns = 10
	cfg.MaxConnIdleTime = 5 * time.Minute
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("database: %v", err)
	}

	srv := &http.Server{
		Addr:              "localhost:8080",
		Handler:           routes(&pgStore{pool: pool}, tokens),
		ReadHeaderTimeout: 2 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}
	log.Printf("boxoffice listening on %s", srv.Addr)
	log.Fatal(srv.ListenAndServe())
}
```

Contra um banco vazio, as primeiras linhas do servidor são as migrações:

```
ana@vm:~/boxoffice$ go vet ./...
ana@vm:~/boxoffice$ dropdb boxoffice && createdb boxoffice
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 20:18:43 migration 00001_events.sql applied in 4.584833ms
2026/10/16 20:18:43 migration 00002_tickets.sql applied in 5.055343ms
2026/10/16 20:18:43 boxoffice listening on localhost:8080
```

**E iniciado uma segunda vez, ele não aplica nada**, porque o banco já está na versão 2:

```
ana@vm:~/boxoffice$ cat .server.log
2026/10/16 20:18:47 boxoffice listening on localhost:8080
```

## Na inicialização, ou como um passo à parte

Migrar na inicialização é simples e combina com o boxoffice, com uma instância e mudanças que levam
milissegundos. Tem dois custos que vale conhecer:

- **Uma migração lenta atrasa a inicialização.** Acrescentar um índice a uma tabela de cem milhões de
  linhas pode levar minutos, e um servidor que não responde às verificações de saúde por minutos parece
  morto para quem o executa.
- **O código novo e o schema novo chegam no mesmo instante.** Se cópias antigas do programa ainda
  estão servindo enquanto as novas iniciam, o código antigo encontra o schema novo. Mudanças com que as
  duas versões convivem, acrescentar uma coluna antes de usá-la, remover uma só depois que nada a lê,
  evitam isso.

Serviços maiores rodam as migrações como um passo separado do deploy, com os mesmos arquivos e o comando
goose ou um job dedicado, antes de o código novo iniciar. Como os arquivos e a biblioteca são os mesmos,
**passar de um jeito para o outro é uma mudança no deploy, não nas migrações.**
