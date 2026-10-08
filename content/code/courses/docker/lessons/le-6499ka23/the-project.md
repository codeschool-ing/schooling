---
title: Ana's project, written out
version: 1
---

**Every image from here to lesson 26 is built from one program, `shelf`**, the bookshop's catalogue
lesson 1 introduced. It is small on purpose: six files, which you create once, now. What is worth
reading in it is not the Go but how it behaves inside a container. It takes its configuration from
the environment, writes its log where Docker collects it, and stops cleanly when it is told to. You
do not need to know Go to follow the course, and you do not need Go on your machine; the compiler
is in the `golang:1.25` image, as lesson 1 showed.

The project lives in a directory of its own:

```sh
mkdir ~/shelf && cd ~/shelf
```

Create each file below with an editor, `nano main.go` for instance, and paste it in. The copy
button on an annotated file hands over the whole file without the notes.

## The program

`go.mod` names the module, the version of Go it is written for, and its dependencies: pgx, the
PostgreSQL driver, and the four modules pgx itself needs.

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

`main.go` is the service: three routes, a store of books, and the start and stop.

```schooling-example
{"language": "go", "file": "main.go", "parts": [{"code": "// shelf serves a bookshop's catalogue over HTTP. It is the program the docker\n// course packages, lesson after lesson, so it is small on purpose: what is\n// worth reading in it is how it behaves inside a container — it takes its\n// configuration from the environment, logs to standard output, and stops\n// cleanly when it is sent SIGTERM.\npackage main\n\nimport (\n\t\"context\"\n\t\"encoding/json\"\n\t\"errors\"\n\t\"log\"\n\t\"net/http\"\n\t\"os\"\n\t\"os/signal\"\n\t\"syscall\"\n\t\"time\"\n)\n\n", "note": "What the program is for, in its own words, and only Go's standard library: the one dependency is used in `postgres.go`."}, {"code": "// version is stamped at build time with -ldflags \"-X main.version=...\".\nvar version = \"dev\"\n\n", "note": "`dev` until a build replaces it. This lesson's `ARG VERSION`, two sections on, passes `-ldflags \"-X main.version=1.0.0\"`, and `/version` then says which build is running."}, {"code": "type book struct {\n\tID     int    `json:\"id\"`\n\tTitle  string `json:\"title\"`\n\tAuthor string `json:\"author\"`\n}\n\n// The catalogue a shelf with no database serves.\nvar builtIn = []book{\n\t{1, \"The Left Hand of Darkness\", \"Ursula K. Le Guin\"},\n\t{2, \"Dom Casmurro\", \"Machado de Assis\"},\n\t{3, \"The Remains of the Day\", \"Kazuo Ishiguro\"},\n}\n\n", "note": "Three books built in, so the program answers with no database at all, which is how most lessons run it until Compose gives it one in lesson 19."}, {"code": "type store interface {\n\tBooks(ctx context.Context) ([]book, error)\n}\n\ntype memory []book\n\nfunc (m memory) Books(context.Context) ([]book, error) { return m, nil }\n\n", "note": "Two sources of books behind one interface: the list above, or PostgreSQL."}, {"code": "func routes(s store) http.Handler {\n\tmux := http.NewServeMux()\n\tmux.HandleFunc(\"GET /health\", func(w http.ResponseWriter, r *http.Request) {\n\t\tw.Write([]byte(\"ok\\n\"))\n\t})\n\tmux.HandleFunc(\"GET /version\", func(w http.ResponseWriter, r *http.Request) {\n\t\tw.Write([]byte(version + \"\\n\"))\n\t})\n\tmux.HandleFunc(\"GET /books\", func(w http.ResponseWriter, r *http.Request) {\n\t\tbooks, err := s.Books(r.Context())\n\t\tif err != nil {\n\t\t\tlog.Printf(\"books: %v\", err)\n\t\t\thttp.Error(w, \"the catalogue is unavailable\", http.StatusServiceUnavailable)\n\t\t\treturn\n\t\t}\n\t\tw.Header().Set(\"Content-Type\", \"application/json\")\n\t\tjson.NewEncoder(w).Encode(books)\n\t})\n\treturn mux\n}\n\n", "note": "Three routes. `/health` is what lesson 18's health check asks; `/version` names the build; `/books` answers 503 when the database cannot be read, and says why in the log."}, {"code": "func main() {\n\tlog.SetFlags(log.Ldate | log.Ltime | log.LUTC)\n\tport := os.Getenv(\"PORT\")\n\tif port == \"\" {\n\t\tport = \"8080\"\n\t}\n\n", "note": "Configuration comes from the environment, the way `docker run -e` and Compose hand it over: `PORT`, 8080 unless set."}, {"code": "\tvar s store = memory(builtIn)\n\tif url := os.Getenv(\"DATABASE_URL\"); url != \"\" {\n\t\tdb, err := openPostgres(context.Background(), url)\n\t\tif err != nil {\n\t\t\tlog.Fatalf(\"database: %v\", err)\n\t\t}\n\t\tdefer db.Close()\n\t\ts = db\n\t\tlog.Printf(\"catalogue: postgres\")\n\t} else {\n\t\tlog.Printf(\"catalogue: built in, %d books\", len(builtIn))\n\t}\n\n", "note": "With `DATABASE_URL` set, the books come from PostgreSQL. A database it cannot reach stops the program at start, with the reason as its last log line."}, {"code": "\tsrv := &http.Server{Addr: \":\" + port, Handler: routes(s)}\n\tstop := make(chan os.Signal, 1)\n\tsignal.Notify(stop, syscall.SIGTERM, syscall.SIGINT)\n\tgo func() {\n\t\tsig := <-stop\n\t\tlog.Printf(\"received %v, shutting down\", sig)\n\t\tctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)\n\t\tdefer cancel()\n\t\tsrv.Shutdown(ctx)\n\t}()\n\n", "note": "`docker stop` sends SIGTERM. The program stops taking requests, finishes the ones it has, and exits within five seconds. Later in this lesson that is the difference between a stop that takes a fifth of a second and one that takes ten."}, {"code": "\tlog.Printf(\"shelf %s listening on :%s\", version, port)\n\tif err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {\n\t\tlog.Fatal(err)\n\t}\n\tlog.Printf(\"stopped\")\n}\n", "note": "Each log line goes to standard error, and `docker logs` shows it together with standard output, which is all the comment at the top means."}]}
```

`postgres.go` is the other store, the one used when there is a database.

```schooling-example
{"language": "go", "file": "postgres.go", "parts": [{"code": "package main\n\nimport (\n\t\"context\"\n\t\"fmt\"\n\n\t\"github.com/jackc/pgx/v5/pgxpool\"\n)\n\ntype postgres struct{ pool *pgxpool.Pool }\n\n", "note": "The driver, pgx, is the one package that does not come with Go, and the reason `vendor/` exists."}, {"code": "// openPostgres connects, and creates and fills the one table on first use, so\n// a fresh database container is a working catalogue with nothing run by hand.\nfunc openPostgres(ctx context.Context, url string) (*postgres, error) {\n\tpool, err := pgxpool.New(ctx, url)\n\tif err != nil {\n\t\treturn nil, err\n\t}\n\tif err := pool.Ping(ctx); err != nil {\n\t\tpool.Close()\n\t\treturn nil, err\n\t}\n\t_, err = pool.Exec(ctx, `CREATE TABLE IF NOT EXISTS books (\n\t\tid serial PRIMARY KEY, title text NOT NULL, author text NOT NULL)`)\n\tif err != nil {\n\t\tpool.Close()\n\t\treturn nil, fmt.Errorf(\"creating the table: %w\", err)\n\t}\n\tvar n int\n\tif err := pool.QueryRow(ctx, `SELECT count(*) FROM books`).Scan(&n); err != nil {\n\t\tpool.Close()\n\t\treturn nil, err\n\t}\n\tif n == 0 {\n\t\tfor _, b := range builtIn {\n\t\t\tif _, err := pool.Exec(ctx, `INSERT INTO books (title, author) VALUES ($1, $2)`, b.Title, b.Author); err != nil {\n\t\t\t\tpool.Close()\n\t\t\t\treturn nil, fmt.Errorf(\"seeding: %w\", err)\n\t\t\t}\n\t\t}\n\t}\n\treturn &postgres{pool}, nil\n}\n\n", "note": "The table is created and filled on first use, so a fresh database container needs nothing run by hand."}, {"code": "func (p *postgres) Books(ctx context.Context) ([]book, error) {\n\trows, err := p.pool.Query(ctx, `SELECT id, title, author FROM books ORDER BY id`)\n\tif err != nil {\n\t\treturn nil, err\n\t}\n\tdefer rows.Close()\n\tvar books []book\n\tfor rows.Next() {\n\t\tvar b book\n\t\tif err := rows.Scan(&b.ID, &b.Title, &b.Author); err != nil {\n\t\t\treturn nil, err\n\t\t}\n\t\tbooks = append(books, b)\n\t}\n\treturn books, rows.Err()\n}\n\nfunc (p *postgres) Close() { p.pool.Close() }\n", "note": "One query, in id order. Errors go back to the route, which turns them into a 503."}]}
```

## Its tests

Two files of tests, which lesson 25 runs inside containers, exactly as a pipeline would. You do not
run them before then.

```schooling-example
{"language": "go", "file": "main_test.go", "parts": [{"code": "package main\n\nimport (\n\t\"encoding/json\"\n\t\"net/http\"\n\t\"net/http/httptest\"\n\t\"testing\"\n)\n\nfunc TestBooksAnswersWithTheCatalogue(t *testing.T) {\n\trec := httptest.NewRecorder()\n\troutes(memory(builtIn)).ServeHTTP(rec, httptest.NewRequest(\"GET\", \"/books\", nil))\n\tif rec.Code != http.StatusOK {\n\t\tt.Fatalf(\"status %d, want 200\", rec.Code)\n\t}\n\tvar got []book\n\tif err := json.NewDecoder(rec.Body).Decode(&got); err != nil {\n\t\tt.Fatal(err)\n\t}\n\tif len(got) != len(builtIn) {\n\t\tt.Fatalf(\"%d books, want %d\", len(got), len(builtIn))\n\t}\n}\n\nfunc TestHealthIsOK(t *testing.T) {\n\trec := httptest.NewRecorder()\n\troutes(memory(nil)).ServeHTTP(rec, httptest.NewRequest(\"GET\", \"/health\", nil))\n\tif rec.Code != http.StatusOK || rec.Body.String() != \"ok\\n\" {\n\t\tt.Fatalf(\"got %d %q\", rec.Code, rec.Body.String())\n\t}\n}\n", "note": "Ordinary tests: they need nothing but the code, and lesson 25 runs them in a build stage."}]}
```

```schooling-example
{"language": "go", "file": "postgres_test.go", "parts": [{"code": "//go:build integration\n\npackage main\n\nimport (\n\t\"context\"\n\t\"os\"\n\t\"testing\"\n)\n\n// Run against a real Postgres: DATABASE_URL names it, and the table is\n// created and seeded by openPostgres exactly as it is in production.\nfunc TestPostgresServesTheSeededCatalogue(t *testing.T) {\n\turl := os.Getenv(\"DATABASE_URL\")\n\tif url == \"\" {\n\t\tt.Fatal(\"DATABASE_URL is not set: this test needs a database\")\n\t}\n\tdb, err := openPostgres(context.Background(), url)\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tdefer db.Close()\n\tbooks, err := db.Books(context.Background())\n\tif err != nil {\n\t\tt.Fatal(err)\n\t}\n\tif len(books) < len(builtIn) {\n\t\tt.Fatalf(\"%d books, want at least %d\", len(books), len(builtIn))\n\t}\n}\n", "note": "The build tag keeps this file out of `go test` unless `-tags integration` is given, because it needs a real PostgreSQL. Lesson 25 runs it against one."}]}
```

## Its dependency

`go.sum` holds the checksums Go checks every download against. It is generated rather than written,
and this is the copy that matches the `go.mod` above, so paste it as it is:

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

Last, the dependency's own source goes into the project, in `vendor/`, so that a build needs no
network. The command runs Go from the `golang:1.25` image, the way lesson 10 runs any tool. It runs
as your user, so that the files are yours, and keeps Go's cache in `/tmp`, because that user has no
home in the container:

```sh
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/src -w /src -e GOCACHE=/tmp/gocache golang:1.25 go mod vendor
```

It prints a `go: downloading` line for each module it fetches, and leaves a `vendor/` directory of
about 10 MB. **On the lab it ran only with the modules handed to it from outside**, because the lab's
containers cannot reach the internet, as lesson 5's last section showed; the `vendor/` it made is
the same, file for file.

## A first commit

Later lessons read the project's history and add to it, so it goes into Git now. Put your own name
and address in place of Ana's:

```
ana@vm:~/shelf$ git init -q -b main && git add -A && git -c user.name=Ana -c user.email=ana@example.com commit -qm "shelf: the catalogue over HTTP" && git log --format="%an <%ae>: %s"
Ana <ana@example.com>: shelf: the catalogue over HTTP
```

That is the whole project. The next section packages it.
