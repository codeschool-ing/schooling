---
title: Medindo, com honestidade
version: 1
---

Os dois prompts, nos setenta casos, os quarenta do conjunto de desenvolvimento e os trinta mais
difíceis guardados à parte:

```
ana@lab:~/triage$ wc -l cases/all.jsonl
70 cases/all.jsonl
ana@lab:~/triage$ pl run prompts/v8-rules.txt cases/all.jsonl --out runs/rules.jsonl
70 calls, prompt 65da61bb, written to runs/rules.jsonl
ana@lab:~/triage$ pl run prompts/v8-guide.txt cases/all.jsonl --out runs/guide.jsonl
70 calls, prompt d0591569, written to runs/guide.jsonl
ana@lab:~/triage$ pl check runs/rules.jsonl
check      pass  fail
json         65     5
fields       65     5
labels       65     5
category     54    16
urgency      45    25
all          45    25
ana@lab:~/triage$ pl check runs/guide.jsonl
check      pass  fail
json         64     6
fields       64     6
labels       64     6
category     53    17
urgency      43    27
all          43    27
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl
runs/rules.jsonl         passes 45/70
runs/guide.jsonl         passes 43/70
fixed 3, broken 5, still passing 40, still failing 22
broken: t05 t06 t21 t32 t36
sign test on the 8 that changed: p = 0.727
ana@lab:~/triage$ pl compare runs/rules.jsonl runs/guide.jsonl --answers
70 cases, same answer 70, different answer 0
```

As regras passam em 45 e o guia em 43. Oito mensagens mudaram, três para um lado e cinco para o
outro, e o teste do sinal diz que uma divisão assim aparece por acaso cerca de três vezes em quatro
(p = 0.727). As categorias são idênticas nas setenta. **Por todos os números daqui, os dois prompts
são o mesmo prompt**, e a diferença de duas mensagens são os hábitos de embrulho, embaralhados em
outras respostas como a aula 2 mostrou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Setenta mensagens, um quadrado cada, comparadas entre o prompt de treze regras e o prompt que explica as categorias. 40 passam com os dois e 22 falham com os dois, e essas 62 não dizem nada sobre qual prompt é melhor. 3 passam só com o prompt explicado e 5 só com as regras. Só essas 8 são evidência, e elas se dividem em 3 a 5.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">70 mensagens, regras contra guia</text><rect x=\"20\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"46\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"72\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"98\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"124\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"150\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"176\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"202\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"228\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"254\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"280\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"306\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"332\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"358\" y=\"40\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"20\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"46\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"72\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"98\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"124\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"150\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"176\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"202\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"228\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"254\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"280\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"306\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"332\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"358\" y=\"66\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"20\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"46\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"72\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"98\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"124\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"150\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"176\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"202\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"228\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"254\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"280\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"306\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"332\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"358\" y=\"92\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"46\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"72\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"98\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"124\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"150\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"176\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"202\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"228\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"254\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"280\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"306\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"332\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"358\" y=\"118\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"46\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"72\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"98\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"124\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"150\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"176\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"202\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"228\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"254\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"280\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"306\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"332\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"358\" y=\"144\" width=\"22\" height=\"22\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"408\" y=\"46\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"428\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">passam com os dois</text><rect x=\"408\" y=\"74\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"428\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">falham com os dois</text><rect x=\"408\" y=\"102\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"428\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">passam só com o guia</text><rect x=\"408\" y=\"130\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"428\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">passam só com as regras</text><text x=\"408\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">evidência: 8 de 70</text></svg>", "caption": "Sessenta e duas mensagens saíram iguais com os dois prompts e não trazem evidência para lado nenhum. As oito que mudaram se dividem em três a cinco, o que uma moeda honesta faz cerca de três vezes em quatro."}
```

## Por que o substituto não distingue os dois

Esse resultado diz mais sobre o substituto do que sobre explicações. **O substituto não lê
significado.** Ele classifica por palavras-chave, julga a urgência por uma lista curta de
expressões e só aproveita de um prompt um punhado de palavras que procura, como as listas de
rótulos, JSON ou uma instrução para ser breve ou minucioso. Um motivo não está entre elas. Estas
regras também não:

```
ana@lab:~/triage$ pl show runs/rules.jsonl t22
│ {
│   "category": "billing",
│   "urgency": "low",
│   "summary": "Asks: can I pay with a gift card and a credit card on the same order?"
│ }
stop: end, tokens in 208, out 42
```

`t22` voltou low com as regras, o que está certo, e não porque o substituto pesou a linha 12 contra
a 13. Ele responde low a mensagens que começam com *Can I*, de uma lista de aberturas que ele trata
como perguntas que podem esperar. O holdout tem as mensagens para as quais a frase de urgência do
guia foi escrita, e o substituto erra nelas com os dois prompts:

```
ana@lab:~/triage$ grep h03 cases/all.jsonl
{"id": "h03", "message": "My account shows an order I never placed and my card has been charged for it.", "expect": {"category": "billing", "urgency": "high"}}
ana@lab:~/triage$ pl check runs/guide.jsonl --failures | grep -e h03 -e h22
h03    urgency   normal, expected high
h22    urgency   normal, expected high
```

Ser cobrado por um pedido que nunca fez é estar no prejuízo, o que o guia diz ser high. O substituto
não tem expressão para isso, então disse normal, com o guia como com as regras.

## Para que serve a medição

Num modelo real, esta comparação é o experimento que responde à pergunta: os mesmos setenta casos,
os dois prompts, comparados mensagem por mensagem, com `h03` e `h22` entre as primeiras mensagens a
ler. **Este curso não tem um número para o resultado**, e ninguém tem um para o seu modelo e as suas
mensagens até rodar. Afirmar que explicações vencem regras por alguma porcentagem, sem a execução, é
afirmar algo sobre o modelo de outra pessoa e o conjunto de teste de outra pessoa.

O que o laboratório consegue mostrar é a disciplina. Uma mudança em que você acredita mediu como
ruído aqui, e o relato certo disso é *nenhuma diferença detectada em setenta casos*, não *o guia é
melhor* e não *o guia não funciona*. A aula 11 trata de montar um conjunto de teste grande e
direcionado o bastante para detectar as diferenças que importam para você.
