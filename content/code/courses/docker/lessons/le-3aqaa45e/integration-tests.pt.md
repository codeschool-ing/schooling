---
title: Testes de integração com um banco de verdade
version: 1
---

**Um teste de unidade confere o programa contra ele mesmo. Um teste de integração o confere contra as
coisas com que ele de fato conversa**, e para o `shelf` isso é o Postgres. O teste dele está no
`postgres_test.go`, atrás da build tag `integration`, então um `go test` simples o pula; ele precisa do
`DATABASE_URL`, e falha, alto, sem ele.

O Compose fornece o banco durante a execução dos testes:

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: shelf
      POSTGRES_PASSWORD: test-only
      POSTGRES_DB: shelf
    tmpfs:
      - /var/lib/postgresql/data
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "shelf", "-d", "shelf"]
      interval: 2s
      retries: 15

  tests:
    image: golang:1.25
    working_dir: /src
    volumes:
      - .:/src
    environment:
      DATABASE_URL: postgres://shelf:test-only@db:5432/shelf
    command: ["go", "test", "-tags", "integration", "-count=1", "-v", "./..."]
    depends_on:
      db:
        condition: service_healthy
```

Três escolhas nele são sobre testes, e não sobre rodar o `shelf`:

- **Os dados moram num `tmpfs`**, em memória: cada execução começa com um banco vazio, nada fica no
  disco, e é mais rápido.
- **A senha é um valor fixo de teste**, no arquivo. Ela não protege nada, já que o banco só existe
  durante a execução e não é publicado em porta nenhuma.
- **O executor de testes é um serviço** na imagem `golang`, com o código montado, e ele espera o banco
  ficar saudável, com o `pg_isready -h` da aula 19.

```
ana@vm:~/shelf$ docker compose -f compose.test.yaml run --rm tests > it.log 2>&1; echo "exit $?"
exit 0
ana@vm:~/shelf$ grep -vE "^ *(Container|Network|Volume) " it.log
=== RUN   TestBooksAnswersWithTheCatalogue
--- PASS: TestBooksAnswersWithTheCatalogue (0.00s)
=== RUN   TestHealthIsOK
--- PASS: TestHealthIsOK (0.00s)
=== RUN   TestPostgresServesTheSeededCatalogue
--- PASS: TestPostgresServesTheSeededCatalogue (0.02s)
PASS
ok  	example.com/shelf	0.021s
?   	example.com/shelf/probe	[no test files]
ana@vm:~/shelf$ docker compose -f compose.test.yaml down 2>&1 | grep -c Removed
2
```

O `docker compose run` inicia o `tests` e aquilo de que ele depende, e **sai com o status dos testes**:
0 aqui, depois de os três passarem, o do Postgres inclusive. Esse status é o que um pipeline lê. O
`down` remove o container do banco e a rede, e o `tmpfs` vai junto.

## Uma falha que chega ao pipeline

A mesma execução com uma senha errada no `DATABASE_URL`:

```
ana@vm:~/shelf$ docker compose -f compose.test.yaml run --rm -e DATABASE_URL=postgres://shelf:wrong@db:5432/shelf tests > it.log 2>&1; echo "exit $?"
exit 1
ana@vm:~/shelf$ grep -E "^(---|FAIL)|password" it.log | head -4
--- PASS: TestBooksAnswersWithTheCatalogue (0.00s)
--- PASS: TestHealthIsOK (0.00s)
        	172.18.0.2:5432 (db): failed SASL auth: FATAL: password authentication failed for user "shelf" (SQLSTATE 28P01)
--- FAIL: TestPostgresServesTheSeededCatalogue (0.01s)
ana@vm:~/shelf$ docker compose -f compose.test.yaml down 2>&1 | grep -c Removed
2
```

**Status 1, e a mensagem do próprio Postgres no log**: `password authentication failed`. Um teste de
unidade não teria achado isso; é um desacordo entre a configuração do `shelf` e o banco, e só um banco
de verdade conseguiria relatá-lo.

O `docker compose up --abort-on-container-exit --exit-code-from tests` faz o mesmo com `up` em vez de
`run`, para arquivos que iniciam vários serviços de uma vez. De um jeito ou de outro, a aula 26 põe
esses comandos num pipeline, sem mudança, que é o que "exatamente como no pipeline" quer dizer: o
pipeline roda o que a Ana roda.
