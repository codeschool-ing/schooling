---
title: Subindo o servidor e perguntando a ele
version: 1
---

Dois programas conversam com o servidor nesta seção: o `curl`, que manda um pedido a partir do terminal,
e o `jq`, que lê o JSON que volta. No Ubuntu, e no WSL, confira que os dois estão lá:

```sh
curl --version | head -1
jq --version
```

Se algum disser `command not found`, instale com `sudo apt install curl jq`. No macOS o `curl` vem com o
sistema e o `jq` é `brew install jq`.

O servidor precisa de um terminal só para ele, porque fica rodando até ser parado. Abra um segundo
terminal, que o `~/.bashrc` coloca no ambiente do curso, e suba o servidor lá:

```sh
cd ~/ml
uvicorn app:app
```

`app:app` quer dizer *o objeto chamado `app` no arquivo `app.py`*. O Uvicorn responde em
`http://127.0.0.1:8000`, que é esta máquina e nada fora dela, e imprime uma linha para cada pedido que
recebe. Deixe-o rodando e volte ao primeiro terminal.

Para perguntar sobre um assinante de verdade, o pedido precisa de uma linha do `churn_2026.csv` em JSON,
sem as duas colunas que a API não recebe. Salve isto como `row.py`:

```python
# row.py
import sys

import pandas as pd

rows = pd.read_csv("data/churn_2026.csv")
row = rows[(rows["customer_id"] == sys.argv[1]) & (rows["snapshot"] == sys.argv[2])]
print(row.drop(columns=["snapshot", "days_since_last_order"]).iloc[0].to_json(force_ascii=False))
```

Depois pergunte ao servidor sobre dois assinantes de março de 2026:

```
ana@lab:~/ml$ curl -s localhost:8000/health | jq -c
{"model":"churn-2025-12","trained_to":"2025-12-01","cut":0.2778}
ana@lab:~/ml$ python row.py C00007 2026-03-01 > c00007.json
ana@lab:~/ml$ cat c00007.json
{"customer_id":"C00007","city":"São Paulo","age":18,"app_user":1,"payment":"pix","plan":"weekly","box":"large","channel":"ads","tenure_months":5,"price_month":757.12,"orders_90d":11,"skips_90d":1,"late_90d":2,"complaints_90d":0,"support_calls_90d":1,"rating_90d":3.58,"days_since_login":5.0}
ana@lab:~/ml$ curl -s localhost:8000/score -H 'content-type: application/json' -d @c00007.json | jq -c
{"customer_id":"C00007","chance":0.6449,"credit":true,"model":"churn-2025-12"}
ana@lab:~/ml$ python row.py C00035 2026-03-01 | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c
{"customer_id":"C00035","chance":0.0795,"credit":false,"model":"churn-2025-12"}
```

`-d @c00007.json` manda o arquivo como corpo do pedido, e `-d @-` manda o que chegar pelo pipe. `jq -c`
imprime a resposta numa linha.

**C00007 recebe crédito**: 18 anos, cinco meses de casa, duas entregas atrasadas e nota 3,58, que é o
formato de insatisfeito da aula 14. **C00035 não recebe**, e é o pedido mais interessante: no plano
mensal, sem app e sem nota, então `rating_90d` e `days_since_login` chegaram os dois como `null`, e o
imputador do pipeline os preencheu como faz em todo lote.

Agora três pedidos que não deveriam receber uma chance:

```
ana@lab:~/ml$ jq '.age = "forty"' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c '.detail[] | [.loc[1], .msg]'
["age","Input should be a valid integer, unable to parse string as an integer"]
ana@lab:~/ml$ jq 'del(.rating_90d)' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c '.detail[] | [.loc[1], .msg]'
["rating_90d","Field required"]
ana@lab:~/ml$ jq '.plan = "daily"' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c
{"customer_id":"C00007","chance":0.3843,"credit":true,"model":"churn-2025-12"}
```

Os dois primeiros são recusados, com **status 422** e uma frase que nomeia o campo. Uma idade `"forty"`
não é um número, e um pedido sem `rating_90d` não é a mesma coisa que uma nota `null`. Nenhum dos dois
chegou ao modelo.

O terceiro não foi recusado, e esse é o custo da primeira escolha da seção anterior. **Um plano chamado
`daily` não existe**, e foi pontuado: o codificador deu zeros a ele, e a chance foi de 0,6449 para 0,3843,
ainda um crédito. Uma API com uma lista de planos o teria recusado, e teria recusado também o plano mensal
em fevereiro. Uma saída é uma lista guardada ao lado da ficha, atualizada quando o negócio cria um plano;
a outra é aceitar os desconhecidos e contá-los, que é o que a aula 22 faz. As duas são decisões, e a que
não é decisão é nunca olhar.

O segundo terminal mostra o que o servidor viu:

```
ana@lab:~$ cd ~/ml
ana@lab:~/ml$ uvicorn app:app
INFO:     Started server process [12128]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     127.0.0.1:45186 - "GET /health HTTP/1.1" 200 OK
INFO:     127.0.0.1:45188 - "POST /score HTTP/1.1" 200 OK
INFO:     127.0.0.1:45198 - "POST /score HTTP/1.1" 200 OK
INFO:     127.0.0.1:45206 - "POST /score HTTP/1.1" 422 Unprocessable Entity
INFO:     127.0.0.1:45214 - "POST /score HTTP/1.1" 422 Unprocessable Entity
INFO:     127.0.0.1:45226 - "POST /score HTTP/1.1" 200 OK
```

Uma linha por pedido, com o status. As duas recusas estão lá como **422**, então um cliente mandando dados
ruins aparece no log do servidor mesmo quando ninguém lê o do cliente. E toda resposta que o servidor deu
está em `scores.jsonl`:

```
ana@lab:~/ml$ cat scores.jsonl
{"at": "2026-10-16T01:33:34", "customer_id": "C00007", "chance": 0.6449, "credit": true, "model": "churn-2025-12"}
{"at": "2026-10-16T01:33:35", "customer_id": "C00035", "chance": 0.0795, "credit": false, "model": "churn-2025-12"}
{"at": "2026-10-16T01:33:35", "customer_id": "C00007", "chance": 0.3843, "credit": true, "model": "churn-2025-12"}
```
