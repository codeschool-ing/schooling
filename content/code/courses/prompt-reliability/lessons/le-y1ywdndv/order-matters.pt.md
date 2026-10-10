---
title: A ordem importa
version: 2
---

Este prompt diz exatamente o que o `v8-guide.txt` diz, em outra ordem: a mensagem primeiro e o guia
depois. Salve-o como `prompts/v17-message-first.txt`:

```
<message>
{{message|xml}}
</message>

You sort customer messages for Folio, an online bookshop, so that the right
person answers each one and the urgent ones are answered first.

Answer with only a JSON object with three fields:
- "category": one of billing, delivery, returns, account, other
- "urgency": one of low, normal, high
- "summary": one sentence saying what the customer needs

What the categories mean, because two people answer them:
- billing goes to the accounts desk: money taken, owed or charged wrongly.
- delivery goes to the warehouse: an order on its way, late or lost.
- returns also goes to the warehouse: a book coming back, or a refund for one.
- account goes to whoever runs the website: signing in, settings, personal data.
- other is for anything that needs neither.

Urgency is about harm, not tone. A customer out of pocket, or unable to
reach their account, is high however politely they ask. A question that
can wait a day is low.

The summary is read instead of the message by somebody choosing what to do
next, so it says what the customer needs, without their name.
```

As mesmas cinco mensagens:

```
ana@lab:~/triage$ head -n 4 prompts/v17-message-first.txt
<message>
{{message|xml}}
</message>

ana@lab:~/triage$ python3 timing.py prompts/v17-message-first.txt cases/dev.jsonl 5
case  read tokens  read ms  wrote tokens  write ms
t01           287     4833            29      3113
t02           288     4627            34      3705
t03           288     4542            28      3066
t04           284     4530            33      3634
t05           285     4507            29      3137
```

**Toda chamada leu por uns quatro segundos e meio.** Este prompt começa com `<message>` e depois as
palavras do próprio cliente, então duas chamadas não têm em comum mais que essa tag, e o cache só
consegue reaproveitar um começo. O guia atrás da mensagem é o mesmo em toda chamada, e o cache não
alcança uma palavra dele.

Sobre as quarenta mensagens do dev:

```
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/dev.jsonl --out runs/static.jsonl
40 calls, prompt d0591569, llama3.2:3b, written to runs/static.jsonl
ana@lab:~/triage$ pl run prompts/v17-message-first.txt cases/dev.jsonl --out runs/first.jsonl
40 calls, prompt 327661b0, llama3.2:3b, written to runs/first.jsonl
ana@lab:~/triage$ python3 stats.py runs/static.jsonl runs/first.jsonl
runs/static.jsonl, 40 calls
  tokens in    mean  285.1   total  11406
  tokens out   mean   28.7   total   1148   max 38
  seconds      p50   3.8   p95   4.6   total  152.7
runs/first.jsonl, 40 calls
  tokens in    mean  285.1   total  11406
  tokens out   mean   30.1   total   1205   max 44
  seconds      p50   7.6   p95   8.4   total  286.0
```

Os mesmos tokens de entrada, 285,1 por chamada, e quase os mesmos de saída. A chamada mediana levou
3,8 segundos com o guia primeiro e 7,6 com a mensagem primeiro: **o dobro, para ler as mesmas palavras
em outra ordem**. Em quarenta chamadas são 152,7 segundos contra 286,0, e num dia mais cheio é a
diferença entre uma fila que acompanha e uma que não.

O cache não esquece um prompt no momento em que chega o próximo, porém. Aqui estão as mesmas cinco
chamadas com a mensagem primeiro, de novo:

```
ana@lab:~/triage$ python3 timing.py prompts/v17-message-first.txt cases/dev.jsonl 5
case  read tokens  read ms  wrote tokens  write ms
t01           287      191            29      3250
t02           288      205            34      3666
t03           288      186            28      3049
t04           284      202            33      3306
t05           285      153            29      2780
```

Lidas em menos de um quarto de segundo cada. Esses cinco prompts exatos tinham sido lidos alguns
minutos antes, e o cache ainda os tinha, então o começo guardado mais longo era o prompt inteiro.
**Um prompt repetido sai quase de graça para ler; uma mensagem nova na frente nunca se repete.** Em
produção toda mensagem é nova, e é por isso que a primeira execução é a honesta.

A regra sai direto daí: **ponha o que é igual em toda chamada no começo, e o que varia no fim**.
Instruções, o guia, exemplos e qualquer texto de referência fixo vêm primeiro; a mensagem do cliente,
e qualquer outra coisa que muda por chamada, vem por último.
