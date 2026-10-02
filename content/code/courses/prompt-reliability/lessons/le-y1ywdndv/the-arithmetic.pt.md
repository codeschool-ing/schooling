---
title: A aritmética
version: 1
---

O cache tem dois preços próprios no `prices.json`:

```
ana@lab:~/triage$ grep cache prices.json
  "cache_read": 30,
  "cache_write": 375,
```

A entrada comum custa 300 centavos o milhão de tokens. **Ler do cache custa um décimo disso, e gravar
nele custa um quarto a mais.** As proporções são do curso; a forma, uma leitura barata e uma gravação
cara, é a que os provedores descrevem, e cada um dá os próprios números na documentação.

## Quanto o cache economizou

Para saber quanto o cache economizou você precisa do mesmo prompt sem ele. O `v17-static-first.txt`
é o `v8-guide.txt` com um cabeçalho de duas linhas, o que o `diff` confirma não imprimindo nada além
do `echo`:

```
ana@lab:~/triage$ diff <(tail -n +3 prompts/v17-static-first.txt) prompts/v8-guide.txt && echo same template
same template
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/plain.jsonl
40 calls, prompt d0591569, written to runs/plain.jsonl
ana@lab:~/triage$ pl cost runs/plain.jsonl
tokens          count   per call
input           10139      253.5
cache_read          0        0.0
cache_write         0        0.0
output           1536       38.4

cost of these 40 calls: 5.3457 cents
cost of a million calls like them: 133,643 cents
```

Sem o cache, os 10139 tokens de entrada foram todos entrada comum. Com ele, os mesmos 10139 se
dividiram em 827, 8736 e 576: **o cache não muda quantos tokens são lidos, só quanto cada um custa**.
Em milionésimos de centavo:

| | sem o cache | com ele |
|---|---|---|
| entrada | 10139 × 300 = 3.041.700 | 827 × 300 = 248.100 |
| leitura do cache | | 8736 × 30 = 262.080 |
| gravação no cache | | 576 × 375 = 216.000 |
| saída | 1536 × 1500 = 2.304.000 | 1536 × 1500 = 2.304.000 |
| total | 5.345.700 | 3.030.180 |

Esses são os `5.3457` e `3.0302` centavos que o `pl cost` imprimiu. O lado da entrada caiu de
3.041.700 para 726.180, mais de três quartos, e a conta inteira 43%: 133.643 centavos por milhão de
chamadas contra 75.755. A saída não mexeu, porque um cache só mexe no prompt.

## Quando o cache custa mais

O `v17-message-first` pagou `6.0216` centavos, mais do que as mesmas chamadas pagariam sem cache
nenhum: pela mesma aritmética, (827 + 9312) × 300 + 1521 × 1500 = 5.323.200 milionésimos, ou 5,3232
centavos. Os 9312 tokens dele que passaram pelo cache foram todos gravações, cada uma 75 centavos por
milhão mais cara que a entrada comum, e nenhum foi lido de volta. São 9312 × 75 = 698.400
milionésimos de centavo gastos guardando blocos que ninguém usou. **Um prefixo usado uma vez custa mais com cache do
que sem.** Com estes preços, um bloco gravado uma vez e lido uma vez custa 375 + 30 = 405 contra 600
para lê-lo duas vezes como entrada comum, então um bloco se paga a partir do segundo uso. Um prefixo que se repete
em poucas chamadas por dia, e expira entre elas, pode nunca chegar ao segundo uso.

## E o tempo

O relógio do substituto também cobra menos de um token em cache:

```
ana@lab:~/triage$ grep -n "^LATENCY" promptlab/model.py
23:LATENCY = {"per_call": 300, "per_input": 0.4, "per_cached": 0.04, "per_output": 20.0, "jitter": 150}
ana@lab:~/triage$ pl latency runs/plain.jsonl
calls 40
p50 1238 ms   p95 1450 ms   max 1503 ms
output tokens: mean 38.4, max 50
ana@lab:~/triage$ pl latency runs/static.jsonl
calls 40
p50 1157 ms   p95 1369 ms   max 1423 ms
output tokens: mean 38.4, max 50
```

Um token em cache custa 0,04 ms contra 0,4, então os 218,4 tokens por chamada lidos do cache
economizaram uns 79 ms cada, perto dos 81 ms entre as duas medianas. Ao lado dos 20 ms por token de
saída da aula 16 é um ganho modesto, e o dinheiro é o motivo maior para usar o cache.
