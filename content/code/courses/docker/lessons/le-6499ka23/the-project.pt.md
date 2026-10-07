---
title: O projeto da Ana, por extenso
version: 1
---

**Toda imagem daqui até a aula 26 é construída a partir de um programa, o `shelf`**, o catálogo da
livraria que a aula 1 apresentou. Ele é pequeno de propósito: seis arquivos, que você cria uma vez,
agora. O que vale a pena ler nele não é o Go, e sim como ele se comporta dentro de um container. Ele
recebe a configuração do ambiente, escreve o log onde o Docker o recolhe e para de forma limpa quando
mandam. Você não precisa saber Go para acompanhar o curso, nem precisa de Go na sua máquina; o
compilador está na imagem `golang:1.25`, como a aula 1 mostrou.

O projeto mora num diretório só dele:

```sh
mkdir ~/shelf && cd ~/shelf
```

Crie cada arquivo abaixo com um editor, `nano main.go` por exemplo, e cole o conteúdo. O botão de
copiar de um arquivo anotado entrega o arquivo inteiro, sem as notas.

## O programa

O `go.mod` nomeia o módulo, a versão do Go para a qual ele foi escrito e as dependências: o pgx, o
driver de PostgreSQL, e os quatro módulos de que o próprio pgx precisa.

```
module example.com/shelf

go 1.25.0

require github.com/jackc/pgx/v5 v5.11.0

require (
	github.com/jackc/pgpassfile v1.0.0 // indirect
	github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 // indirect
	github.com/jackc/puddle/v2 v2.2.2 // indirect
	golang.org/x/sync v0.17.0 // indirect
	golang.org/x/text v0.29.0 // indirect
)
```

O `main.go` é o serviço: três rotas, um estoque de livros, a partida e a parada.

```schooling-example
{"language": "go", "file": "main.go", "parts": [{"code": "// shelf serves a bookshop's catalogue over HTTP. It is the program the docker\n// course packages, lesson after lesson, so it is small on purpose: what is\n// worth reading in it is how it behaves inside a container — it takes its\n// configuration from the environment, logs to standard output, and stops\n// cleanly when it is sent SIGTERM.\npackage main\n\nimport (\n\t\"context\"\n\t\"encoding/json\"\n\t\"errors\"\n\t\"log\"\n\t\"net/http\"\n\t\"os\"\n\t\"os/signal\"\n\t\"syscall\"\n\t\"time\"\n)\n\n", "note": "Para que o programa serve, nas palavras dele, e só a biblioteca padrão do Go: a única dependência é usada no `postgres.go`."}, {"code": "// version is stamped at build time with -ldflags \"-X main.version=...\".\nvar version = \"dev\"\n\n", "note": "`dev` até um build substituí-lo. O `ARG VERSION` desta aula, duas seções adiante, passa `-ldflags \"-X main.version=1.0.0\"`, e o `/version` então diz qual build está rodando."}, {"code": "type book struct {\n\tID     int    `json:\"id\"`\n\tTitle  string `json:\"title\"`\n\tAuthor string `json:\"author\"`\n}\n\n// The catalogue a shelf with no database serves.\nvar builtIn = []book{\n\t{1, \"The Left Hand of Darkness\", \"Ursula K. Le Guin\"},\n\t{2, \"Dom Casmurro\", \"Machado de Assis\"},\n\t{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},\n}\n\n", "note": "Três livros embutidos, para o programa responder sem banco nenhum, que é como a maioria das aulas o roda até o Compose lhe dar um na aula 19."}, {"code": "type store interface {\n\tBooks(ctx context.Context) ([]book, error)\n}\n\ntype memory []book\n\nfunc (m memory) Books(context.Context) ([]book, error) { return m, nil }\n\n", "note": "Duas fontes de livros atrás de uma interface: a lista acima, ou o PostgreSQL."}, {"code": "func routes(s store) http.Handler {\n\tmux := http.NewServeMux()\n\tmux.HandleFunc(\"GET /health\", func(w http.ResponseWriter, r *http.Request) {\n\t\tw.Write([]byte(\"ok\\n\"))\n\t})\n\tmux.HandleFunc(\"GET /version\", func(w http.ResponseWriter, r *http.Request) {\n\t\tw.Write([]byte(version + \"\\n\"))\n\t})\n\tmux.HandleFunc(\"GET /books\", func(w http.ResponseWriter, r *http.Request) {\n\t\tbooks, err := s.Books(r.Context())\n\t\tif err != nil {\n\t\t\tlog.Printf(\"books: %v\", err)\n\t\t\thttp.Error(w, \"the catalogue is unavailable\", http.StatusServiceUnavailable)\n\t\t\treturn\n\t\t}\n\t\tw.Header().Set(\"Content-Type\", \"application/json\")\n\t\tjson.NewEncoder(w).Encode(books)\n\t})\n\treturn mux\n}\n\n", "note": "Três rotas. O `/health` é o que o health check da aula 18 pergunta; o `/version` nomeia o build; o `/books` responde 503 quando o banco não pode ser lido, e diz por quê no log."}, {"code": "func main() {\n\tlog.SetFlags(log.Ldate | log.Ltime | log.LUTC)\n\tport := os.Getenv(\"PORT\")\n\tif port == \"\" {\n\t\tport = \"8080\"\n\t}\n\n", "note": "A configuração vem do ambiente, do jeito que o `docker run -e` e o Compose a entregam: `PORT`, 8080 se não for definida."}, {"code": "\tvar s store = memory(builtIn)\n\tif url := os.Getenv(\"DATABASE_URL\"); url != \"\" {\n\t\tdb, err := openPostgres(context.Background(), url)\n\t\tif err != nil {\n\t\t\tlog.Fatalf(\"database: %v\", err)\n\t\t}\n\t\tdefer db.Close()\n\t\ts = db\n\t\tlog.Printf(\"catalogue: postgres\")\n\t} else {\n\t\tlog.Printf(\"catalogue: built in, %d books\", len(builtIn))\n\t}\n\n", "note": "Com `DATABASE_URL` definida, os livros vêm do PostgreSQL. Um banco que ele não alcança para o programa na partida, com o motivo na última linha do log."}, {"code": "\tsrv := &http.Server{Addr: \":\" + port, Handler: routes(s)}\n\tstop := make(chan os.Signal, 1)\n\tsignal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)\n\tgo func() {\n\t\tsig := <-stop\n\t\tlog.Printf(\"received %v, shutting down\", sig)\n\t\tctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)\n\t\tdefer cancel()\n\t\tsrv.Shutdown(ctx)\n\t}()\n\n", "note": "O `docker stop` manda SIGTERM. O programa para de aceitar pedidos, termina os que tem e sai em até cinco segundos. Mais adiante nesta aula, essa é a diferença entre parar em um quinto de segundo e parar em dez."}, {"code": "\tlog.Printf(\"shelf %s listening on :%s\", version, port)\n\tif err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {\n\t\tlog.Fatal(err)\n\t}\n\tlog.Printf(\"stopped\")\n}\n", "note": "Cada linha de log vai para a saída de erro, e o `docker logs` a mostra junto com a saída padrão, que é tudo o que o comentário do topo quer dizer."}]}
```

O `postgres.go` é o outro estoque, o usado quando há um banco de dados.

```schooling-example
{"language": "go", "file": "postgres.go", "parts": [{"code": "package main\n\nimport (\n\t\"context\"\n\t\"fmt\"\n\n\t\"github.com/jackc/pgx/v5/pgxpool\"\n)\n\ntype postgres struct{ pool *pgxpool.Pool }\n\n", "note": "O driver, pgx, é o único pacote que não vem com o Go, e o motivo de o `vendor/` existir."}, {"code": "// openPostgres connects, and creates and fills the one table on first use, so\n// a fresh database container is a working catalogue with nothing run by hand.\nfunc openPostgres(ctx context.Context, url string) (*postgres, error) {\n\tpool, err := pgxpool.New(ctx, url)\n\tif err != nil {\n\t\treturn nil, err\n\t}\n\tif err := pool.Ping(ctx); err != nil {\n\t\tpool.Close()\n\t\treturn nil, err\n\t}\n\t_, err = pool.Exec(ctx, `CREATE TABLE IF NOT EXISTS books (\n\t\tid serial PRIMARY KEY, title text NOT NULL, author text NOT NULL)`)\n\tif err != nil {\n\t\tpool.Close()\n\t\treturn nil, fmt.Errorf(\"creating the table: %w\", err)\n\t}\n\tvar n int\n\tif err := pool.QueryRow(ctx, `SELECT count(*) FROM books`).Scan(&n); err != nil {\n\t\tpool.Close()\n\t\treturn nil, err\n\t}\n\tif n == 0 {\n\t\tfor _, b := range builtIn {\n\t\t\tif _, err := pool.Exec(ctx, `INSERT INTO books (title, author) VALUES ($1, $2)`, b.Title, b.Author); err != nil {\n\t\t\t\tpool.Close()\n\t\t\t\treturn nil, fmt.Errorf(\"seeding: %w\", err)\n\t\t\t}\n\t\t}\n\t}\n\treturn &postgres{pool}, nil\n}\n\n", "note": "A tabela é criada e preenchida no primeiro uso, então um container de banco novo não precisa de nada rodado à mão."}, {"code": "func (p *postgres) Books(ctx context.Context) ([]book, error) {\n\trows, err := p.pool.Query(ctx, `SELECT id, title, author FROM books ORDER BY id`)\n\tif err != nil {\n\t\treturn nil, err\n\t}\n\tdefer rows.Close()\n\tvar books []book\n\tfor rows.Next() {\n\t\tvar b book\n\t\tif err := rows.Scan(&b.ID, &b.Title, &b.Author); err != nil {\n\t\t\treturn nil, err\n\t\t}\n\t\tbooks = append(books, b)\n\t}\n\treturn books, rows.Err()\n}\n\nfunc (p *postgres) Close() { p.pool.Close() }\n", "note": "Uma consulta, em ordem de id. Os erros voltam para a rota, que os transforma num 503."}]}
```

## Os testes

Dois arquivos de testes, que a aula 25 roda dentro de containers, exatamente como um pipeline faria.
Você não os roda antes disso.

```schooling-example
{"language": "go", "file": "main_test.go", "parts": [{"code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"net/http\"\n\t\"net/http/httptest\"\n\t\"testing\"\n)\n\nfunc TestBooksAnswersWithTheCatalogue(t *testing.T) {\n\trec := httptest.NewRecorder()\n\troutes(memory(builtIn)).ServeHTTP(rec, httptest.NewRequest(\"GET\", \"/books\", nil))\n\tif rec.Code != http.StatusOK {\n\t\tt.Fatalf(\"status %d, want 200\", rec.Code)\n\t}\n\tvar got []book\n\tif err := json.NewDecoder(rec.Body).Decode(&got); err != nil {\n\t\tt.Fatal(err)\n\t}\n\tif len(got) != len(builtIn) {\n\t\tt.Fatalf(\"%d books, want %d\", len(got), len(builtIn))\n\t}\n}\n\nfunc TestHealthIsOK(t *testing.T) {\n\trec := httptest.NewRecorder()\n\troutes(memory(nil)).ServeHTTP(rec, httptest.NewRequest(\"GET\", \"/health\", nil))\n\tif rec.Code != http.StatusOK || rec.Body.String() != \"ok\\n\" {\n\t\tt.Fatalf(\"got %d %q\", rec.Code, rec.Body.String())\n\t}\n}\n", "note": "Testes comuns: só precisam do código, e a aula 25 os roda num estágio do build."}]}
```

```schooling-example
{"language": "go", "file": "postgres_test.go", "parts": [{"code": "//go:build integration\n\npackage main\n\nimport (\n\t\"context\"\n\t\"os\"\n\t\"testing\"\n)\n\n// Run against a real Postgres: DATABASE_URL names it, and the table is\n// created and seeded by openPostgres exactly as it is in production.\nfunc TestPostgresServesTheSeededCatalogue(t *testing.T) {\n\turl := os.Getenv(\"DATABASE_URL\")\n\tif url == \"\" {\n\t\tt.Fatal(\"DATABASE_URL is not set: this test needs a database\")\n\t}\n\tdb, err := openPostgres(context.Background(), url)\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tdefer db.Close()\n\tbooks, err := db.Books(context.Background())\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tif len(books) < len(builtIn) {\n\t\tt.Fatalf(\"%d books, want at least %d\", len(books), len(builtIn))\n\t}\n}\n", "note": "A build tag deixa este arquivo fora do `go test` a menos que se passe `-tags integration`, porque ele precisa de um PostgreSQL de verdade. A aula 25 o roda contra um."}]}
```

## A dependência

O `go.sum` guarda os checksums contra os quais o Go confere cada download. Ele é gerado, não
escrito, e esta é a cópia que bate com o `go.mod` acima, então cole como está:

```
github.com/davecgh/go-spew v1.1.0/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
github.com/davecgh/go-spew v1.1.1 h1:vj9j/u1bqnvCEfJOwUhtlOARqs3+rkHYY13jYWTU97c=
github.com/davecgh/go-spew v1.1.1/go.mod h1:J7Y8YcW2NihsgmVo/mv3lAwl/skON4iLHjSsI+c5H38=
github.com/jackc/pgpassfile v1.0.0 h1:/6Hmqy13Ss2zCq62VdNG8tM1wchn8zjSGOBJ6icpsIM=
github.com/jackc/pgpassfile v1.0.0/go.mod h1:CEx0iS5ambNFdcRtxPj5JhEz+xB6uRky5eyVu/W2HEg=
github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761 h1:iCEnooe7UlwOQYpKFhBabPMi4aNAfoODPEFNiAnClxo=
github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761/go.mod h1:5TJZWKEWniPve33vlWYSoGYefn3gLQRzjfDlhSJ9ZKM=
github.com/jackc/pgx/v5 v5.11.0 h1:IzBBtyK9AHqf98cctWFifYSci2hgQR/cd56wB4p+ogg=
github.com/jackc/pgx/v5 v5.11.0/go.mod h1:mal1tBGAFfLHvZzaYh77YS/eC6IX9OWbRV1QIIM0Jn4=
github.com/jackc/puddle/v2 v2.2.2 h1:PR8nw+E/1w0GLuRFSmiioY6UooMp6KJv0/61nB7icHo=
github.com/jackc/puddle/v2 v2.2.2/go.mod h1:vriiEXHvEE654aYKXXjOvZM39qJ0q+azkZFrfEOc3H4=
github.com/pmezard/go-difflib v1.0.0 h1:4DBwDE0NGyQoBHbLQYPwSUPoCMWR5BEzIk/f1lZbAQM=
github.com/pmezard/go-difflib v1.0.0/go.mod h1:iKH77koFhYxTK1pcRnkKkqfTogsbg7gZNVY4sRDYZ/4=
github.com/stretchr/objx v0.1.0/go.mod h1:HFkY916IF+rwdDfMAkV7OtwuqBVzrE8GR6GFx+wExME=
github.com/stretchr/testify v1.3.0/go.mod h1:M5WIy9Dh21IEIfnGCwXGc5bZfKNJtfHm1UVUgZn+9EI=
github.com/stretchr/testify v1.7.0/go.mod h1:6Fq8oRcR53rry900zMqJjRRixrwX3KX962/h/Wwjteg=
github.com/stretchr/testify v1.11.1 h1:7s2iGBzp5EwR7/aIZr8ao5+dra3wiQyKjjFuvgVKu7U=
github.com/stretchr/testify v1.11.1/go.mod h1:wZwfW3scLgRK+23gO65QZefKpKQRnfz6sD981Nm4B6U=
golang.org/x/sync v0.17.0 h1:l60nONMj9l5drqw6jlhIELNv9I0A4OFgRsG9k2oT9Ug=
golang.org/x/sync v0.17.0/go.mod h1:9KTHXmSnoGruLpwFjVSX0lNNA75CykiMECbovNTZqGI=
golang.org/x/text v0.29.0 h1:1neNs90w9YzJ9BocxfsQNHKuAT4pkghyXc4nhZ6sJvk=
golang.org/x/text v0.29.0/go.mod h1:7MhJOA9CD2qZyOKYazxdYMF85OwPdEr9jTtBpO7ydH4=
gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405/go.mod h1:Co6ibVJAznAaIkqp8huTwlJQCZ016jof/cbN4VW5Yz0=
gopkg.in/yaml.v3 v3.0.0-20200313102051-9f266ea9e77c/go.mod h1:K4uyk7z7BCEPqu6E+C64Yfv1cQ7kz7rIZviUmN+EgEM=
gopkg.in/yaml.v3 v3.0.1 h1:fxVm/GzAzEWqLHuvctI91KS9hhNmmWOoWu0XTYJS7CA=
gopkg.in/yaml.v3 v3.0.1/go.mod h1:K4uyk7z7BCEPqu6E+C64Yfv1cQ7kz7rIZviUmN+EgEM=
```

Por último, o código da própria dependência entra no projeto, em `vendor/`, para que um build não
precise de rede. O comando roda o Go da imagem `golang:1.25`, do jeito que a aula 10 roda qualquer
ferramenta. Ele roda como o seu usuário, para que os arquivos sejam seus, e guarda o cache do Go em
`/tmp`, porque esse usuário não tem home no container:

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -e GOCACHE=/tmp/gocache golang:1.25 go mod vendor
```

Ele imprime uma linha `go: downloading` para cada módulo que busca, e deixa um diretório `vendor/` de
cerca de 8 MB. **No laboratório ele rodou só com os módulos entregues de fora**, porque os
containers do laboratório não alcançam a internet, como mostrou a última seção da aula 5; o
`vendor/` que ele fez é o mesmo, arquivo por arquivo.

## Um primeiro commit

Aulas adiante leem o histórico do projeto e acrescentam a ele, então ele vai para o Git agora.
Ponha o seu nome e o seu endereço no lugar dos da Ana:

```
ana@vm:~/shelf$ git init -q -b main && git add -A && git -c user.name=Ana -c user.email=ana@example.com commit -qm "shelf: the catalogue over HTTP" && git log --format="%an <%ae>: %s"
Ana <ana@example.com>: shelf: the catalogue over HTTP
```

Esse é o projeto inteiro. A próxima seção o empacota.
