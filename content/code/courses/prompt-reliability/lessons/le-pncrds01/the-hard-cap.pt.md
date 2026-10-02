---
title: O que um limite faz com JSON
version: 1
---

`max_tokens` parece um pedido de resposta curta. **É o ponto em que a escrita para, onde quer que
ela esteja.** No laboratório, o substituto escreve a resposta inteira e a bancada a corta no limite.
Um modelo hospedado é interrompido do mesmo jeito: escreve até terminar ou até o limite chegar, e o
limite não espera uma frase, uma string ou uma chave se fechar.

Primeiro o prompt sem limite, depois o mesmo prompt com um:

```
ana@lab:~/triage$ pl check runs/v4.jsonl
check      pass  fail
json         37     3
fields       37     3
labels       37     3
category     37     3
urgency      34     6
all          34     6
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/dev.jsonl --set max_tokens=30 --out runs/cap30.jsonl
40 calls, prompt 651820d7, written to runs/cap30.jsonl
ana@lab:~/triage$ pl check runs/cap30.jsonl
check      pass  fail
json          1    39
fields        1    39
labels        1    39
category      1    39
urgency       1    39
all           1    39
ana@lab:~/triage$ pl check runs/cap30.jsonl --failures | grep -c 'cut off at max_tokens'
39
```

`--set` muda um parâmetro numa execução. O id do prompt, `651820d7`, é o mesmo nas duas
execuções, então a única diferença é o limite. Sem ele, 34 respostas passavam em tudo. Com ele,
**passa uma**. `--failures` lista cada falha com o motivo, e `grep -c` conta as linhas que dão este:
as 39 falhas são a mesma, `json`, porque a resposta foi `cut off at max_tokens`.

```
ana@lab:~/triage$ pl show runs/cap30.jsonl t01
│ {
│   "category": "billing",
│   "urgency": "high",
│   "summary": "They were charged twice for order 4471.
stop: max_tokens, tokens in 93, out 30
ana@lab:~/triage$ pl show runs/cap30.jsonl t35
│ {
│   "category": "other",
│   "urgency": "low",
│   "summary": "They love the shop."
│ }
stop: end, tokens in 95, out 29
```

`t01` para depois do ponto final do resumo. As aspas e a chave de fechamento nunca foram escritas.
Tudo na resposta está certo, e **a resposta não é JSON**, então o programa que a lê recebe uma
exceção e mais nada. `t35` sobreviveu por um motivo: o resumo tem quatro palavras, e a resposta
inteira deu 29 tokens, um abaixo do limite. O limite não encurtou nada. Ele arrancou o fim de tudo o
que era mais comprido.

## O motivo da parada

Toda resposta volta com o motivo pelo qual parou, e o `pl show` o mostra na última linha. `end` quer
dizer que o modelo terminou sozinho; `max_tokens`, que o limite terminou por ele. As APIs hospedadas
informam a mesma coisa com nomes próprios: na Messages API da Anthropic é um `stop_reason` igual a
`max_tokens`, e na Chat Completions API da OpenAI um `finish_reason` igual a `length`. **O motivo da
parada é o único campo que diz se uma resposta está completa**, e lê-lo não custa nada.

## Para que serve um limite

**Um limite é uma proteção contra saída descontrolada, nunca um jeito de pedir brevidade.** Respostas
que se repetem ou continuam escrevendo além do formato são uma falha que todo mundo que trabalha com
isso já viu, e um limite interrompe uma delas antes que ela encha um log ou uma fatura. Uma proteção
que dispara no tráfego comum está no lugar errado, e trinta, aqui, disparou em trinta e nove
mensagens de quarenta. Pedir uma resposta mais curta é outra ferramenta, e é a próxima seção.
