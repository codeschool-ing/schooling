---
title: Health, liveness e readiness
version: 1
---

O `/actuator/health` responde uma pergunta, **esta aplicação está em condições de trabalhar?**, com uma
palavra e um status HTTP. Por baixo da palavra há uma lista de **health indicators**, um para cada
coisa que o Boot achou que valia verificar, e o status geral é o pior entre os deles. `UP` vem com
`200`; `DOWN` e `OUT_OF_SERVICE` vêm com `503`, e assim um load balancer ou uma sonda de monitoramento
que só lê o status HTTP ainda acerta o veredito.

## O que ele verifica

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/health | python3 -m json.tool
{
    "components": {
        "db": {
            "details": {
                "database": "PostgreSQL",
                "validationQuery": "isValid()"
            },
            "status": "UP"
        },
        "diskSpace": {
            "details": {
                "total": 270553174016,
                "free": 24556486656,
                "threshold": 10485760,
                "path": "/home/ana/bookshop/.",
                "exists": true
            },
            "status": "UP"
        },
        "livenessState": {
            "status": "UP"
        },
        "ping": {
            "status": "UP"
        },
        "readinessState": {
            "status": "UP"
        },
        "ssl": {
            "details": {
                "expiringChains": [],
                "invalidChains": [],
                "validChains": []
            },
            "status": "UP"
        }
    },
    "groups": [
        "liveness",
        "readiness"
    ],
    "status": "UP"
}
```

Ninguém escreveu nenhuma dessas verificações; cada uma chegou com uma dependência. O **`db`** veio com
o datasource: ele pega uma conexão emprestada do pool e pergunta ao driver se ela ainda é válida, que
é o que `isValid()` quer dizer. O **`diskSpace`** informa `DOWN` quando o espaço livre no diretório de
trabalho cai abaixo de `threshold`, dez megabytes, porque uma aplicação que não consegue escrever os
próprios logs está prestes a falhar de jeitos mais estranhos. O `ping` está sempre `UP`; só prova que
alguma coisa respondeu. O `ssl` vigia certificados que a própria aplicação serve, e a livraria não
serve nenhum, então as três listas dele estão vazias. Os dois indicadores `State` pertencem aos grupos
do fim desta seção.

Os detalhes aparecem por causa do `show-details=always`. Eles ajudam quem os lê, e também contam a um
estranho qual banco você usa e quanto disco sobra, e é por isso que o padrão é `never`. Numa porta que
só a máquina alcança, `always` não custa nada. Se os endpoints dividissem a porta pública,
`when-authorized` mostraria os detalhes só para quem estivesse autenticado.

## Tirando o banco

O jeito de confiar num health check é vê-lo falhar. O PostgreSQL tem de continuar rodando para todo o
resto da máquina, então, em vez de pará-lo, proíba o role `bookshop` de fazer login e feche as
conexões que ele já tem. No segundo comando, o `pg_stat_activity` lista os processos do servidor e o
`pg_terminate_backend` encerra um deles.

```
ana@vm:~/bookshop$ sudo -u postgres psql -c 'ALTER ROLE bookshop NOLOGIN'
ALTER ROLE
ana@vm:~/bookshop$ sudo -u postgres psql -c "SELECT count(pg_terminate_backend(pid)) FROM pg_stat_activity WHERE usename = 'bookshop'"
 count 
-------
    10
(1 row)
```

Dez conexões, o `maximum-pool-size` inteiro do pool da aula 14. Agora pergunte de novo:

```
ana@vm:~/bookshop$ curl -s -w "%{http_code} after %{time_total} s\n" -o health.json localhost:8081/actuator/health
503 after 0.015768 s
ana@vm:~/bookshop$ python3 -m json.tool health.json | head -9
{
    "components": {
        "db": {
            "details": {
                "database": "PostgreSQL",
                "validationQuery": "isValid()"
            },
            "status": "DOWN"
        },
ana@vm:~/bookshop$ curl -s -w " %{http_code}\n" localhost:8081/actuator/health/liveness
{"status":"UP"} 200
ana@vm:~/bookshop$ curl -s -w " %{http_code}\n" localhost:8081/actuator/health/readiness
{"status":"UP"} 200
```

O relatório completo virou `DOWN`, e o status, `503`, em 16 milissegundos: a verificação pegou uma
conexão do pool, viu que estava morta e disse isso. Os dois grupos continuam respondendo `UP`, e isso
é de propósito, como a próxima parte explica. A API se saiu pior. O `GET /books` esperou os cinco
segundos de `connection-timeout` do pool por uma conexão que nunca veio, e depois respondeu `401`.
Esse último número é um defeito à parte, e não um veredito sobre o token: a requisição que falhou é
encaminhada para a página `/error` do Spring, que as regras da API não abrem para chamadas anônimas.
As métricas, que a próxima seção lê com calma, viram a requisição antes dessa troca:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code} after %{time_total} s\n" localhost:8080/books
401 after 5.018283 s
```

A primeira linha é a falha: `GET /books`, status `500`, `SERVER_ERROR`, e a exceção que a causou. O
cliente recebeu 401; o timer registrou o que o handler fez. As outras linhas são as requisições
anteriores desta aula, entre elas o 401 anônimo e o 404 com token. O segundo terminal conta a mesma
história por dentro:

```
2026-10-22T20:34:36.781-03:00  WARN 13286 --- [bookshop] [nio-8080-exec-8] [cfd409dc] org.hibernate.orm.jdbc.error             : HHH000247: ErrorCode: 0, SQLState: 28000
2026-10-22T20:34:36.781-03:00  WARN 13286 --- [bookshop] [nio-8080-exec-8] [cfd409dc] org.hibernate.orm.jdbc.error             : bookshop-pool - Connection is not available, request timed out after 5000ms (total=0, active=0, idle=0, waiting=0)
2026-10-22T20:34:36.785-03:00 ERROR 13286 --- [bookshop] [nio-8080-exec-8] [] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: org.springframework.transaction.CannotCreateTransactionException: Could not open JPA EntityManager for transaction] with root cause
```

Devolva o login ao role, e o pool se reconecta na próxima requisição. Um indicador sozinho tem um
caminho próprio:

```
ana@vm:~/bookshop$ sudo -u postgres psql -c 'ALTER ROLE bookshop LOGIN'
ALTER ROLE
ana@vm:~/bookshop$ curl -s -w "\n" localhost:8081/actuator/health/db
{"details":{"database":"PostgreSQL","validationQuery":"isValid()"},"status":"UP"}
```

## Duas perguntas de um orquestrador

Quando outra coisa roda a aplicação, um Kubernetes ou uma plataforma de contêineres, ela faz duas
perguntas diferentes, e o custo de uma resposta errada é diferente para cada uma:

| grupo | a pergunta | o que uma falha faz a plataforma fazer |
|---|---|---|
| `liveness` | este processo quebrou sem conserto? | matá-lo e subir outro |
| `readiness` | devo mandar requisições para cá agora? | parar de rotear tráfego para ele, e deixá-lo rodando |

A ideia errada mais comum é que os dois deveriam informar o banco. Ponha o `db` no **liveness** e uma
queda do banco faz a plataforma reiniciar todas as cópias da livraria ao mesmo tempo. Nenhum reinício
conserta o PostgreSQL, e cada cópia agora paga uma inicialização inteira, com Flyway e Hibernate, e
volta para a mesma falha. Ponha no **readiness** e todas as cópias saem do load balancer juntas, então
um banco lento vira uma queda total, até para requisições que nunca tocam nele. Por isso o Boot
mantém os dois grupos restritos ao estado da própria aplicação, e a falha acima mostrou exatamente
isso: o relatório estava `DOWN`, e nenhum grupo se mexeu. Um grupo pode incluir mais indicadores, com
`management.endpoint.health.group.readiness.include`, e essa é uma decisão a tomar de propósito,
contra o parágrafo acima.

O que mexe no readiness é o ciclo de vida da própria aplicação. Comece num terceiro terminal um laço
que pergunta pelos três, tão rápido quanto o curl consegue, e depois suba a livraria no segundo
terminal:

```
ana@vm:~/bookshop$ for i in $(seq 1500); do echo $(for p in health/liveness health/readiness health; do curl -s -o /dev/null -w '%{http_code} ' localhost:8081/actuator/$p; done); done | uniq -c
    733 000 000 000
      1 200 503 503
    766 200 200 200
```

O `uniq -c` junta linhas iguais, então 1.500 rodadas saíram como três linhas. Nas primeiras 733
rodadas ninguém escutava na 8081, e o `000` do curl quer dizer nenhuma conexão. Depois, uma rodada
respondeu `200 503 503`: o processo estava vivo, e o readiness e o relatório completo diziam que ele
não estava pronto. Toda rodada depois dessa respondeu `200` três vezes. A janela é curta, e um laço
pode perdê-la; se o seu não mostrar nenhum `503`, suba a aplicação de novo. O segundo terminal, subido
com `--logging.level.org.springframework.boot.availability=debug`, diz qual foi a janela:

```
2026-10-22T20:34:48.964-03:00  INFO 14179 --- [bookshop] [           main] [] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 9.799 seconds (process running for 10.494)
2026-10-22T20:34:49.075-03:00 DEBUG 14179 --- [bookshop] [           main] [] o.s.b.a.ApplicationAvailabilityBean      : Application availability state LivenessState changed to CORRECT
2026-10-22T20:34:49.201-03:00  INFO 14179 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
2026-10-22T20:34:49.202-03:00 DEBUG 14179 --- [bookshop] [           main] [] o.s.b.a.ApplicationAvailabilityBean      : Application availability state ReadinessState changed to ACCEPTING_TRAFFIC
```

`Started BookshopApplication` não é o fim de uma inicialização. Logo depois dele, o liveness passa a
`CORRECT`. Então rodam os runners da aplicação, aqui o `CatalogueReport` da aula 5, e só quando o
último retorna é que o readiness passa a `ACCEPTING_TRAFFIC`. Entre os dois, cerca de um quarto de
segundo nesta rodada, o processo está vivo e ainda se preparando, e é para esse momento que o
readiness existe. Os mesmos dois instantes ficam guardados como métricas:

```
ana@vm:~/bookshop$ curl -s localhost:8081/actuator/prometheus | grep -E "^application_(started|ready)_time"
application_ready_time_seconds{main_application_class="com.example.bookshop.BookshopApplication"} 10.038
application_started_time_seconds{main_application_class="com.example.bookshop.BookshopApplication"} 9.799
```

Então o trabalho que tem de terminar antes da primeira requisição, aquecer um cache ou carregar um
arquivo, pertence a um runner: o readiness espera por ele, e uma plataforma que respeita o readiness
não manda nada até ele acabar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 214\" role=\"img\" aria-label=\"Três URLs de health em quatro momentos. Enquanto a livraria sobe, a porta 8081 está fechada e nenhuma responde. Enquanto os runners de inicialização trabalham, o liveness responde 200, e o readiness e o health completo respondem 503. Enquanto ela atende, as três respondem 200. Com o banco recusando a livraria, liveness e readiness ainda respondem 200, e o health completo, 503.\"><text x=\"190.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">subindo</text><text x=\"330.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">runners</text><text x=\"470.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">atendendo</text><text x=\"610.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sem banco</text><text x=\"108\" y=\"63.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">liveness</text><rect x=\"126\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"190.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem resposta</text><rect x=\"266\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"406\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"546\" y=\"40\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UP 200</text><text x=\"108\" y=\"119.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">readiness</text><rect x=\"126\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"190.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem resposta</text><rect x=\"266\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">503</text><rect x=\"406\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"546\" y=\"96\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">UP 200</text><text x=\"108\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">health</text><rect x=\"126\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"190.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem resposta</text><rect x=\"266\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">503</text><rect x=\"406\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">200</text><rect x=\"546\" y=\"152\" width=\"128\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">DOWN 503</text></svg>", "caption": "O readiness espera o trabalho de inicialização terminar. Nenhum dos grupos olha o banco, então perdê-lo muda só o relatório completo.", "same": ["runners"]}
```
