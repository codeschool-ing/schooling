---
title: A linguagem de consulta, perguntada a três linhas
version: 1
---

**Uma consulta do Cloud Logging é um filtro sobre entradas: campos, comparações e palavras booleanas, sem
`SELECT` e sem `FROM`.** É o que o Logs Explorer lê, o que um sink usa para selecionar, o que uma exclusão
descarta e o que uma métrica baseada em log conta (lição 10), então a mesma expressão é escrita em quatro
lugares. Nenhum deles roda no seu computador. Abaixo, cada consulta é escrita como o Cloud Logging a recebe,
seguida da mesma pergunta feita às linhas do `logdemo.py` com `jq`; **o `jq` não é o Cloud Logging**, e o
único propósito dele é mostrar que entradas o filtro seleciona.

## Severidade, e a comparação que ela permite

```localised
severity>=WARNING
```

As severidades são ordenadas, então `>=` significa "isto ou pior". O equivalente em `jq` precisa listá-las,
porque para o `jq` elas são só strings:

```
ana@laptop:~/gcp$ python3 logdemo.py | jq -c -R 'fromjson?' | jq -c 'select(.severity == "WARNING" or .severity == "ERROR") | {severity, message, order_id}'
{"severity":"WARNING","message":"payment retried","order_id":"o-1002"}
```

Uma entrada. A terceira linha do programa, a que diz `level=error`, não está lá: ela não tem severidade. É o
aviso da seção anterior, visto do lado da consulta.

## Campos, e a entrada a que pertencem

```localised
resource.type="cloud_run_revision"
resource.labels.service_name="shop-api"
httpRequest.status>=200
```

Linhas escritas uma embaixo da outra são unidas por `AND`. `resource` é de onde a entrada veio, definido pela
plataforma em vez do seu código, o que o torna a coisa mais barata para filtrar. `httpRequest.status` só existe
em entradas que carregam uma requisição HTTP, e uma entrada sem o campo não casa, seja qual for a comparação:

```
ana@laptop:~/gcp$ python3 logdemo.py | jq -c -R 'fromjson?' | jq -r 'select(.httpRequest.status >= 200) | ."logging.googleapis.com/trace"'
projects/planner-dev/traces/4bf92f3577b34da6a3ce929d0e0e4736
```

A única entrada com requisição, e o trace dela: o valor que a lição 11 usa para abrir o trace daquele pedido.

## O resto da linguagem, em resumo

| expressão | seleciona |
|---|---|
| `jsonPayload.order_id="o-1002"` | entradas cujo campo do payload é igual ao valor |
| `jsonPayload.message:"retried"` | `:` é "contém", para texto |
| `textPayload=~"stock .* failed"` | `=~` é uma expressão regular |
| `NOT severity=DEFAULT` | `NOT`, `AND` e `OR` combinam; `OR` precisa ser escrito |
| `timestamp>="2026-10-30T12:00:00Z"` | um horário, embora o seletor de tempo do Explorer seja o jeito comum |

**Filtre por `resource` e `severity` primeiro, campos do payload por último.** Os dois primeiros são indexados e
estreitam a busca rápido; uma consulta que começa com `jsonPayload.message:"…"` sobre um mês de logs lê todos
eles.
