---
title: Formato, contado à parte
version: 1
---

As três primeiras verificações da aula 1, `json`, `fields` e `labels`, são a métrica de formato. Elas
perguntam se um programa consegue usar a resposta, antes que alguém pergunte se ela está certa.

```
ana@lab:~/triage$ pl check runs/v6-all.jsonl
check      pass  fail
json         68     2
fields       68     2
labels       68     2
category     56    14
urgency      46    24
all          46    24
ana@lab:~/triage$ pl check runs/v6-all.jsonl --failures | grep json
json         68     2
t26    json      not JSON
t39    json      not JSON
ana@lab:~/triage$ pl show runs/v6-all.jsonl t26
│ ```json
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "They'd like to cancel their subscription to the monthly box before the next payment."
│ }
│ ```
stop: end, tokens in 123, out 48
```

Duas de setenta falham no formato. `t26` tem a categoria certa e a urgência certa, dentro de um bloco
de código Markdown, onde o prompt pediu só um objeto JSON. **Uma falha de formato não é uma resposta
errada, e uma métrica que mistura as duas manda você corrigir a coisa errada.** Um bloco de código se
corrige com um exemplo ou com um formato de saída mais rígido, o assunto da aula 3; um rótulo errado se
corrige com uma definição mais clara das categorias. Nenhuma das correções toca o outro problema.

É por isso que a matriz de confusão dá às falhas de formato uma coluna própria, `(bad)`, em vez de
contar `t26` como uma mensagem de billing classificada como outra coisa. No `pl check` a mesma
separação é a ordem das verificações: as 14 respostas que falham em `category` são as 2 que o parser
rejeitou e as 12 que o parser aceitou e que escolheram o rótulo errado.

## Informe como uma taxa própria

O formato é a métrica mais fácil de afirmar com exatidão: 68 de 70 respostas são JSON válido, cabem
nos campos e usam as listas. **É também a única que um sistema em funcionamento consegue verificar em
toda resposta**, já que não precisa do rótulo de uma pessoa, então uma taxa de formato pode ser medida
em produção além de num conjunto de teste. Um rótulo errado em JSON válido é invisível ali; um bloco
de código não é.

Mantenha-a separada mesmo quando ela for alta. Uma taxa de formato que escorrega de 70 de 70 para 68
de 70 depois de uma mudança é uma regressão, e dentro de uma nota combinada pareceria um erro de
arredondamento.
