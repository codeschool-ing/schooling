---
title: Formato, contado à parte
version: 2
---

As três primeiras verificações da aula 1, `json`, `fields` e `labels`, são a métrica de formato.
Elas perguntam se um programa consegue usar a resposta, antes de alguém perguntar se ela está certa.

```
ana@lab:~/triage$ pl check runs/v6-all.jsonl --failures | grep json
json         69     1
t38    json      not a JSON object
```

Uma em setenta falha no formato, o `t38`, o ebook cujo resumo quebrou num apóstrofo na aula 3. **Uma
falha de formato não é uma resposta errada, e uma métrica que mistura as duas manda você consertar a
coisa errada.** A aula 3 consertou o `t38` com o modo de schema da API do Ollama; um rótulo errado se
conserta com uma definição mais clara das categorias. Nenhuma das correções toca no outro problema.

É por isso que a matriz de confusão dá às falhas de formato uma coluna própria, `(bad)`, em vez de
contar o `t38` como uma mensagem de returns classificada como outra coisa. No `pl check` a mesma
separação é a ordem das verificações: as 25 respostas que falham em `category` são a que nunca foi
JSON válido e 24 que eram e escolheram o rótulo errado.

## Relate-o como uma taxa própria

O formato é a métrica mais fácil de afirmar com exatidão: 69 de 70 respostas são JSON válido, cabem
nos campos e usam as listas. **É também a única que um sistema em funcionamento consegue verificar
em toda resposta**, já que não precisa do rótulo de uma pessoa, então uma taxa de formato pode ser
medida em produção além de num conjunto de teste. Um rótulo errado num JSON válido é invisível ali;
uma resposta que não é JSON válido não é.

Mantenha-a separada mesmo quando for alta. Uma taxa de formato que escorrega de 69 de 70 para 66 de
70 depois de uma mudança é uma regressão, e dentro de uma nota combinada pareceria um erro de
arredondamento.
