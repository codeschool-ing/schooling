---
title: Escolher o limite a partir de uma medida
version: 1
---

Um limite pega a resposta que dispara, e só faz esse trabalho se as respostas comuns nunca chegam a
ele. Então **o ponto de partida é a resposta comum mais longa, medida**:

```
ana@lab:~/triage$ pl run prompts/v4-only-json.txt cases/all.jsonl --out runs/v4-all.jsonl
70 calls, prompt 651820d7, written to runs/v4-all.jsonl
ana@lab:~/triage$ pl latency runs/v4-all.jsonl
calls 70
p50 1159 ms   p95 1390 ms   max 1473 ms
output tokens: mean 38.0, max 50
```

Nas setenta mensagens, o conjunto de desenvolvimento e o de reserva juntos, a resposta mais longa
teve 50 tokens e a média foi 38,0. Um limite de 50 passaria todas hoje. **Um limite exatamente no
máximo medido não tem folga**, e o prompt não vai ficar igual. A versão da aula 21 pede um quarto
campo, uma nota de confiança, e aqui ela roda sob um limite de 50:

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set max_tokens=50 --out runs/v9-50.jsonl
40 calls, prompt c31bed19, written to runs/v9-50.jsonl
ana@lab:~/triage$ pl check runs/v9-50.jsonl --failures
check      pass  fail
json         38     2
fields       38     2
labels       38     2
category     38     2
urgency      36     4
all          36     4

t14    urgency   normal, expected low
t24    json      cut off at max_tokens
t28    urgency   normal, expected low
t37    json      cut off at max_tokens
ana@lab:~/triage$ pl show runs/v9-50.jsonl t37
│ {"category": "billing", "urgency": "normal", "summary": "The book they ordered says 'in stock' but their order still says 'awaiting dispatch' after a week.", "confidence":
stop: max_tokens, tokens in 287, out 50
ana@lab:~/triage$ pl show runs/v9-50.jsonl t24
│ {"category": "delivery", "urgency": "low", "summary": "Asks: is it possible to change the delivery address on an order I placed an hour ago?", "confidence": 0.97
stop: max_tokens, tokens in 282, out 50
```

Duas respostas foram cortadas. Agora olhe a linha `all`: 36, e mais abaixo, com o limite em 100, é
36 de novo. As duas respostas cortadas já estavam erradas por outro motivo, `t37` na categoria e
`t24` na urgência, então **o total não se mexeu e o corte ficou escondido dentro dele**. Só a linha
`json` e os motivos de parada mostram o corte. No dia em que alguém consertar a regra de urgência,
`t24` passa a estar certa e continua reprovada, e o conserto parece menor do que foi.

```
ana@lab:~/triage$ pl run prompts/v9-confidence.txt cases/dev.jsonl --set max_tokens=100 --out runs/v9-100.jsonl
40 calls, prompt c31bed19, written to runs/v9-100.jsonl
ana@lab:~/triage$ pl check runs/v9-100.jsonl
check      pass  fail
json         40     0
fields       40     0
labels       40     0
category     39     1
urgency      36     4
all          36     4
ana@lab:~/triage$ pl latency runs/v9-100.jsonl
calls 40
p50 1413 ms   p95 1532 ms   max 1591 ms
output tokens: mean 45.4, max 54
```

Com limite de 100 nada é cortado, e a resposta mais longa agora tem 54 tokens. Um campo a mais levou
o máximo de 50 para 54, e quem acrescenta um campo não pensa em conferir o limite. O dobro do máximo
medido, aqui 100, é um hábito deste curso, e não uma lei. Não custa nada numa resposta que para antes
dele, porque o que o provedor cobra são os tokens escritos, e o `pl cost` soma a mesma coisa. A regra
por trás do hábito: o limite fica tão acima de toda resposta que você mediu que **só uma resposta que
deu errado consegue alcançá-lo**, e você mede de novo sempre que o prompt muda.

## Uma resposta cortada é uma falha

`t24` está a uma chave de ser JSON válido. Um leitor que conserta respostas, acrescentando a chave
que falta e analisando o resultado, a aceitaria, e nessa mensagem até teria a resposta inteira. Em
`t37`, cortada depois de `"confidence":`, o mesmo conserto não tem valor para fechar. Numa resposta
cortada no meio do resumo, como `t01` sob o limite de trinta, ele aceitaria uma frase sem o fim, e
nada adiante ficaria sabendo.

O `prompt-engineering` consertou saída inválida na aula 19. Uma resposta cortada é o único caso em
que consertar é a ferramenta errada. **Toda resposta que parou em `max_tokens` é uma falha, analise
ou não o que sobrou dela.** O leitor olha o motivo da parada antes de analisar qualquer coisa,
registra a resposta e a trata como a bancada trata: como uma resposta que não chegou. Contar essas
paradas também é como você descobre que um limite foi parar no meio do tráfego comum, muito antes de
alguém ler um resumo truncado.
