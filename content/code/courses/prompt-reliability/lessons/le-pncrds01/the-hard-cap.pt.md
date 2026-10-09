---
title: O que um limite faz com o JSON
version: 2
---

O `num_predict`, que a maioria das APIs chama de `max_tokens`, parece um pedido de resposta curta.
**É o ponto em que a escrita para, onde quer que a escrita esteja.** O modelo escreve até terminar
ou até o limite chegar, e o limite não espera uma frase, um texto entre aspas ou uma chave fechar.

Primeiro o prompt sem limite, depois o mesmo prompt com um, de 25, definido com `--set`:

```
ana@lab:~/triage$ pl check runs/v4.jsonl
check      pass  fail
json         39     1
fields       39     1
labels       39     1
category     31     9
urgency      20    20
all          20    20
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --set num_predict=25 --out runs/cap25.jsonl
40 calls, prompt 651820d7, llama3.2:3b, written to runs/cap25.jsonl
ana@lab:~/triage$ pl check runs/cap25.jsonl
check      pass  fail
json         10    30
fields       10    30
labels       10    30
category      9    31
urgency       4    36
all           4    36
```

O id do prompt, `651820d7`, é o mesmo nas duas execuções, então a única diferença é o limite. Sem
ele, 20 respostas passaram em tudo. Com ele, **quatro passam**, e só dez são sequer JSON válido. O
`--failures` lista cada falha com o motivo, e o `grep -c` conta as linhas que dão este:

```
ana@lab:~/triage$ pl check runs/cap25.jsonl --failures | grep -c 'cut off at num_predict'
29
ana@lab:~/triage$ pl show runs/cap25.jsonl t01
│ {"category": "billing", "urgency": "high", "summary": "Refund duplicate payment for order 447
stop: length, tokens in 123, out 25, 3.3 s
```

Vinte e nove das trinta falhas de `json` foram cortadas; a trigésima é o `t38`, que quebra no
apóstrofo com ou sem limite. O `t01` para no meio do número do pedido, `447`, e as aspas e a chave
de fechamento nunca foram escritas. Tudo na resposta até ali está certo, e **a resposta não é JSON**,
então um programa que a lê recebe uma exceção e mais nada. O limite não deixou nada mais curto.
Tirou o fim de tudo o que era mais longo, e as respostas passam de 25:

```
ana@lab:~/triage$ python3 stats.py runs/v4.jsonl
runs/v4.jsonl, 40 calls
  tokens in    mean  121.2   total   4846
  tokens out   mean   28.8   total   1153   max 38
  seconds      p50   3.5   p95   4.4   total  143.1
```

Média de 28,8 tokens e a mais longa com 38, contra um limite de 25: a maioria das respostas ia ser
cortada de qualquer jeito.

## O motivo da parada

Toda resposta volta com o motivo pelo qual parou, e o `pl show` o imprime na última linha. `stop`
quer dizer que o modelo terminou sozinho; `length` quer dizer que o limite o terminou. As APIs
hospedadas informam a mesma coisa com nomes próprios: na Messages API da Anthropic é um
`stop_reason` igual a `max_tokens`, e na Chat Completions API da OpenAI um `finish_reason` igual a
`length`. **O motivo da parada é o único campo que diz se uma resposta está completa**, e lê-lo não
custa nada. A `judge()` do `pl.py` o lê, e é assim que consegue dizer *cut off* em vez de *not a
JSON object*.

## Para que serve um limite

**Um limite é uma proteção contra saída descontrolada, nunca um jeito de pedir brevidade.**
Respostas que se repetem ou continuam escrevendo depois do formato são uma falha conhecida na
prática, e um limite para uma delas antes que encha um log ou uma conta. Uma proteção que dispara no
tráfego comum está no lugar errado, e 25, aqui, disparou em vinte e nove mensagens de quarenta.
Pedir uma resposta mais curta é outra ferramenta, e é a próxima seção.
