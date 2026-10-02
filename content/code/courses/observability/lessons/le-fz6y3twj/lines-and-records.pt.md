---
title: Uma linha para uma pessoa, um registro para uma máquina
version: 1
---

As primeiras linhas de log que alguém escreve são frases: *checkout finished for order 5001 in
11ms*. Leem bem, e são lidas por pessoas exatamente enquanto forem poucas o bastante para ler.
**Depois disso, logs são lidos por programas**, buscando, contando e filtrando, e uma frase é a
pior entrada possível para um programa. O `two_ways.py` escreve os mesmos dois mil checkouts dos dois
jeitos, com durações inventadas:

```python
import json
import random

random.seed(3)
with open("plain.log", "w") as plain, open("json.log", "w") as structured:
    for n in range(1, 2001):
        took = round(random.expovariate(1 / 40))
        order = 5000 + n
        plain.write(f"INFO checkout finished for order {order} in {took}ms (kettle, paid)\n")
        structured.write(json.dumps({"level": "INFO", "message": "checkout finished", "order_id": order,
                                     "sku": "kettle", "outcome": "paid", "duration_ms": took}) + "\n")
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python two_ways.py 2>/dev/null; head -2 scratch/plain.log scratch/json.log
==> scratch/plain.log <==
INFO checkout finished for order 5001 in 11ms (kettle, paid)
INFO checkout finished for order 5002 in 31ms (kettle, paid)

==> scratch/json.log <==
{"level": "INFO", "message": "checkout finished", "order_id": 5001, "sku": "kettle", "outcome": "paid", "duration_ms": 11}
{"level": "INFO", "message": "checkout finished", "order_id": 5002, "sku": "kettle", "outcome": "paid", "duration_ms": 31}
```

Agora a pergunta que uma investigação de fato faz: *que checkouts levaram 150 milissegundos ou
mais?* Contra as frases, é uma expressão regular que precisa saber onde o número fica, que ele vem
seguido de `ms`, e como dizer *um número de pelo menos 150* um dígito por vez. Contra os registros,
é um campo e uma comparação:

```
ana@obs:~/shop$ grep -cE 'in (1[5-9][0-9]|[2-9][0-9]{2}|[0-9]{4,})ms' scratch/plain.log
49
ana@obs:~/shop$ jq -c 'select(.duration_ms >= 150)' scratch/json.log | wc -l
49
```

**Quarenta e nove dos dois jeitos**, então a expressão regular está certa, desta vez. Ela também
erra no dia em que alguém mudar a frase para *in 0.217 s*, não casa nada se uma linha disser *in
1200 ms* com espaço, e não pode ser lida pela próxima pessoa sem um minuto de reflexão. O campo
sobrevive a tudo isso, e se compõe: a pergunta seguinte, *os lentos que foram pagos, com o id do
pedido*, é mais uma condição:

```
ana@obs:~/shop$ jq -c 'select(.duration_ms >= 150 and .outcome == "paid") | {order_id, duration_ms}' scratch/json.log | head -3
{"order_id":5011,"duration_ms":217}
{"order_id":5054,"duration_ms":188}
{"order_id":5068,"duration_ms":183}
```

Esse é o argumento inteiro do log estruturado, e o resto desta aula trata de fazê-lo bem: **uma linha
de log é um registro com campos nomeados, e a frase é só um dos campos**.
