---
title: Uma segunda tarefa, outro vencedor
version: 1
---

A aula 4 seção 04 disse que um modelo pode passar numa tarefa e falhar em outra, e que é por isso que
cada tarefa é avaliada sozinha. A tarefa de extração, nos mesmos quarenta e-mails, com o
`prompts/extract.txt`:

```
ana@desk:~/desk$ python lab/evalkit.py run extract runs/extract.jsonl 0 standin-large standin-small standin-local
```

```
ana@desk:~/desk$ python lab/evalkit.py report runs/extract.jsonl
model           strict   loose     loose, 95%  p50 s  $ per 1k
standin-large    40/40   40/40     91% to 100%   0.87    0.2946
standin-small    35/40   39/40     87% to 100%   0.27    0.0256
standin-local    37/40   37/40     80% to  97%   1.40    0.0000
```

O standin-large acerta os quarenta. O standin-small acha o número de pedido certo 39 vezes e **só
escreve JSON válido 35 vezes**; o standin-local acerta 37, todos limpos. Na classificação, o
standin-small venceu o standin-local na nota tolerante. Na extração, o programa que chama
`json.loads` prefere os 37 do standin-local.

As falhas dizem por quê:

```
ana@desk:~/desk$ python lab/evalkit.py errors runs/extract.jsonl
standin-small  c03 loose ok  expected LB-20452        got 'Here is the JSON you asked for: {"order": "LB-20452"}'
standin-small  c11 loose ok  expected LB-20329        got 'Here is the JSON you asked for: {"order": "LB-20329"}'
standin-small  c18 loose ok  expected LB-20493        got 'Here is the JSON you asked for: {"order": "LB-20493"}'
standin-small  c27 loose ok  expected LB-20497        got 'Here is the JSON you asked for: {"order": "LB-20497"}'
standin-small  c37 wrong     expected None            got '{"order": "LB-unknown"}'
standin-local  c10 wrong     expected LB-20377        got '{"order": "20377"}'
standin-local  c21 wrong     expected LB-20440        got '{"order": "LB-20404"}'
standin-local  c40 wrong     expected LB-20474        got '{"order": null}'
```

**O standin-small embrulha o JSON numa frase** quatro vezes. O número lá dentro está certo, e o
programa quebra. É uma falha de formato, e tem conserto de formato: um recurso de saída estruturada
que prende a resposta a um esquema (a coluna `S` da aula 4), ou uma etapa de arrumação que extrai o
`{...}`. Com qualquer um dos dois, a nota estrita do standin-small viraria a tolerante.

**O c37 é o interessante.** Ele pede para mudar o endereço de uma assinatura e não cita pedido
nenhum. A resposta certa é `null`; o standin-small inventou `LB-unknown`. Um programa que procure
isso não acha nada, que é o jeito seguro de falhar, mas um valor inventado que por acaso parecesse um
número de pedido real não seria nada seguro. **Casos cuja resposta certa é "não há nenhum" são onde a
invenção aparece**, e a seção 03 guardou quinze deles por esse motivo.

**Os três do standin-local são erros de conteúdo**: `20377` sem o prefixo, `LB-20404` para um pedido
escrito `LB-20440`, e `null` para um e-mail que cita o pedido com todas as letras. Nenhum recurso de
formato conserta isso. Os dígitos trocados são o tipo perigoso: JSON válido, um número plausível, o
cliente errado.

## Por tarefa, então

| | classificação, tolerante | extração, estrita | erros perigosos de extração |
|---|---|---|---|
| standin-large | 38 | 40 | 0 |
| standin-small | 34 | 35 | 0, se os marcadores inventados forem pegos |
| standin-local | 32 | 37 | 1, um número de pedido trocado |

A pergunta para cada linha não é mais "qual é o melhor", e sim **"com que erros a loja consegue
conviver, a que preço"**. A seção 10 responde.
