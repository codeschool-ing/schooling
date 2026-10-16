---
title: Limites e uma linha de base para o back-end
version: 1
---

Um orçamento de página não diz nada sobre o servidor por trás dela. O back-end ganha o seu portão
do k6, que a aula 5 apresentou. **Um threshold (limite) é uma condição de passa ou reprova sobre
uma métrica, conferida no fim da execução, e um limite reprovado faz o k6 sair com um código
diferente de zero.** Esse código de saída é o contrato inteiro com um pipeline.

Há dois tipos de limite que vale pôr num threshold, e eles pegam coisas diferentes.

- **O requisito.** A aula 1 escreveu `GET /shows/{id}` abaixo de 200 ms no percentil 95. Ele é
  absoluto, e vale seja o que for que a última versão fez.
- **A linha de base.** O percentil 95 que a última versão aceita alcançou, com uma tolerância. Ela
  pega uma mudança que deixa um endpoint várias vezes mais lento enquanto ele ainda está bem
  abaixo de 200 ms, o que o requisito deixaria passar por meses, uma entrega de cada vez.

## O script

O `perf/api.js` confere os dois:

```schooling-example
{"language": "javascript", "file": "boxoffice/perf/api.js", "parts": [{"code": "// boxoffice/perf/api.js\n// The back end's half of the gate: 20 requests a second for 15 seconds on\n// GET /shows/{id}, judged against the requirement and against the baseline,\n// the 95th percentile of the last version somebody accepted.\nimport http from \"k6/http\";\n", "note": "O mesmo módulo `k6/http` que a aula 5 usou. A carga é pequena de propósito: o portão roda em cada pull request, e o trabalho dele é perceber uma mudança, não achar o ponto de ruptura."}, {"code": "const TOLERANCE = 0.5;          // 50% slower than the baseline fails...\nconst SLACK_MS = 5;             // ...plus 5 ms, the noise of a fast endpoint\nconst thresholds = [\"p(95)<200\"];\ntry {\n  const baseline = JSON.parse(open(\"./baseline.json\"));\n  const limit = baseline.p95_ms * (1 + TOLERANCE) + SLACK_MS;\n  thresholds.push(`p(95)<${limit.toFixed(1)}`);\n} catch (e) {\n  console.warn(\"no baseline.json yet: judging against the requirement alone\");\n}\n", "note": "Dois limites no percentil 95. `p(95)<200` é o requisito, e ele não muda. O segundo vem do `baseline.json`: o percentil 95 da linha de base, mais 50%, mais 5 ms. Sem linha de base o script avisa e fica só com o requisito, que é como a primeira linha de base é gravada."}, {"code": "export const options = {\n  scenarios: {\n    shows: { executor: \"constant-arrival-rate\", rate: 20, timeUnit: \"1s\",\n             duration: \"15s\", preAllocatedVUs: 10 },\n  },\n  thresholds: {\n    http_req_failed: [\"rate<0.01\"],\n    http_req_duration: thresholds,\n  },\n};\n", "note": "Uma taxa de chegada constante, para toda execução mandar as mesmas 300 requisições, faça o servidor o que fizer, e `thresholds` guarda as duas listas. Quando qualquer limite falha no fim da execução, o k6 sai com o código 99."}, {"code": "export default function () {\n  const id = 981 + Math.floor(Math.random() * 20);\n  http.get(`http://127.0.0.1:8000/shows/${id}`);\n}", "note": "Cada iteração pede um dos vinte espetáculos à venda, ao acaso, para o teste contar as reservas dos vinte e não as de um só."}]}
```

## Uma bilheteria mais rápida para começar

**Uma linha de base só interessa numa versão que vale a pena manter.** A aula 9 rastreou o tempo do
`GET /shows/{id}` até o banco, que conta as reservas de um espetáculo entre quase trezentas mil
linhas sem índice, então esta aula começa da correção óbvia: um índice em `bookings.show_id`. Ela
muda o banco, não o `app.py`: rode `python3 seed.py` de novo sempre que quiser o original de
volta.

```
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=12.7, pay;dur=0.0, total;dur=13.1
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "CREATE INDEX bookings_show ON bookings(show_id)"
ana@nft:~/boxoffice$ curl -si localhost:8000/shows/990 | grep Server-Timing
Server-Timing: db;dur=0.2, pay;dur=0.0, total;dur=0.5
```

A parte do banco na requisição, o `db` do `Server-Timing`, caiu de 12.7 ms para 0.2 ms.

## A primeira execução, e a linha de base

Sem `baseline.json`, o script avisa e julga só pelo requisito:

```
ana@nft:~/boxoffice$ k6 run --quiet perf/api.js; echo "exit $?"
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:36-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console
time="2026-10-10T16:41:51-03:00" level=warning msg="no baseline.json yet: judging against the requirement alone" source=console


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=1.19ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=841.88µs min=562.81µs med=780.16µs max=4.66ms p(90)=1ms   p(95)=1.19ms
      { expected_response:true }...: avg=841.88µs min=562.81µs med=780.16µs max=4.66ms p(90)=1ms   p(95)=1.19ms
    http_req_failed................: 0.00% 0 out of 301
    http_reqs......................: 301   20.064104/s

    EXECUTION
    iteration_duration.............: avg=1ms      min=691.38µs med=930.22µs max=4.78ms p(90)=1.2ms p(95)=1.7ms 
    iterations.....................: 301   20.064104/s
    vus............................: 0     min=0        max=0 
    vus_max........................: 10    min=10       max=10

    NETWORK
    data_received..................: 96 kB 6.4 kB/s
    data_sent......................: 24 kB 1.6 kB/s



exit 0
```

O aviso aparece doze vezes porque cada usuário virtual roda o nível de cima do script, e o k6 o
roda mais algumas vezes por conta própria enquanto lê as opções. Os dois limites que existem
foram cumpridos, e o código de saída é 0.

**Uma linha de base gravada de uma execução só leva o ruído dela para toda comparação
seguinte**, então esta é a mediana de três. O `jq -s` lê os três resumos num único array:

```
ana@nft:~/boxoffice$ mkdir -p perf/runs
ana@nft:~/boxoffice$ for i in 1 2 3; do k6 run --quiet --summary-export=perf/runs/base-$i.json perf/api.js > /dev/null 2>&1; done
ana@nft:~/boxoffice$ jq -s '{p95_ms: (map(.metrics.http_req_duration["p(95)"]) | sort | .[1])}' perf/runs/base-*.json > perf/baseline.json
ana@nft:~/boxoffice$ cat perf/baseline.json
{
  "p95_ms": 3.177051450000001
}
```

A mediana das três é 3.177 ms; a próxima seção olha quão afastadas elas ficaram. Rode o script de
novo, e o segundo limite aparece ao lado do primeiro, calculado a partir da linha de base:

```
ana@nft:~/boxoffice$ k6 run --quiet perf/api.js; echo "exit $?"


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=1.32ms
    ✓ 'p(95)<9.8' p(95)=1.32ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=844.47µs min=512.13µs med=735.3µs  max=6.37ms p(90)=971.83µs p(95)=1.32ms
      { expected_response:true }...: avg=844.47µs min=512.13µs med=735.3µs  max=6.37ms p(90)=971.83µs p(95)=1.32ms
    http_req_failed................: 0.00% 0 out of 301
    http_reqs......................: 301   20.064601/s

    EXECUTION
    iteration_duration.............: avg=995.35µs min=596.59µs med=862.87µs max=6.47ms p(90)=1.17ms   p(95)=1.85ms
    iterations.....................: 301   20.064601/s
    vus............................: 0     min=0        max=0 
    vus_max........................: 10    min=10       max=10

    NETWORK
    data_received..................: 96 kB 6.4 kB/s
    data_sent......................: 24 kB 1.6 kB/s



exit 0
```

Os 9.8 ms são 3.177 × 1,5 + 5, arredondados para uma casa, e o percentil 95 desta execução, 1.32
ms, fica bem dentro.

## Uma regressão que o requisito deixaria passar

Agora desfaça a correção, como faria uma migração que esqueceu o índice:

```
ana@nft:~/boxoffice$ sqlite3 data/boxoffice.db "DROP INDEX bookings_show"
ana@nft:~/boxoffice$ k6 run --quiet perf/api.js; echo "exit $?"


  █ THRESHOLDS 

    http_req_duration
    ✓ 'p(95)<200' p(95)=33.4ms
    ✗ 'p(95)<9.8' p(95)=33.4ms

    http_req_failed
    ✓ 'rate<0.01' rate=0.00%


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=16.21ms min=7.89ms med=12.55ms max=77.15ms p(90)=27.04ms p(95)=33.4ms 
      { expected_response:true }...: avg=16.21ms min=7.89ms med=12.55ms max=77.15ms p(90)=27.04ms p(95)=33.4ms 
    http_req_failed................: 0.00% 0 out of 301
    http_reqs......................: 301   20.050534/s

    EXECUTION
    iteration_duration.............: avg=16.41ms min=8.05ms med=12.72ms max=77.29ms p(90)=27.36ms p(95)=33.61ms
    iterations.....................: 301   20.050534/s
    vus............................: 0     min=0        max=1 
    vus_max........................: 10    min=10       max=10

    NETWORK
    data_received..................: 97 kB 6.4 kB/s
    data_sent......................: 24 kB 1.6 kB/s



time="2026-10-10T16:43:06-03:00" level=error msg="thresholds on metrics 'http_req_duration' have been crossed"
exit 99
```

O percentil 95 foi para 33.4 ms, cerca de dez vezes a linha de base. O requisito passou e a linha
de base não. **O endpoint ficou muitas vezes mais lento e continuou abaixo de 200 ms, e só a
comparação com a última versão boa percebeu.** O k6 diz qual limite cruzou, no resumo e na linha
de erro embaixo dele, e sai com 99.
