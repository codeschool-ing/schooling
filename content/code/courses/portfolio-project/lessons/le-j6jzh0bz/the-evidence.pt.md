---
title: A evidência, do histórico
version: 1
---

Uma retrospectiva escrita de memória é uma história; uma escrita a partir do histórico é um relatório. O
repositório já guarda a maior parte do que ela precisa. Primeiro, quando cada marco foi alcançado:

```
ana@laptop:~/loanbook$ git log --tags --no-walk --format='%ad %d' --date=short
2026-07-06  (HEAD -> main, tag: v1.0.0)
2026-06-29  (tag: v0.3.0)
2026-06-15  (tag: v0.2.0)
2026-06-05  (tag: v0.1.0)
```

Cinco semanas, dentro das seis do filtro da aula 3, e as datas são as do próprio plano. Depois um marco em detalhe, o
que tem o ponto do projeto:

```
ana@laptop:~/loanbook$ git log --reverse --format='%ad %s' --date=short v0.1.0..v0.2.0
2026-06-09 Refuse to lend an item that is already out
2026-06-10 Test the loan rules
2026-06-11 Answer every error as JSON
2026-06-12 Say what to do when there is nothing to lend
2026-06-15 Mark a loan overdue the day after it is due
```

A lista de tarefas da aula 5 estimou as duas regras em **três dias e meio**: dois para a recusa, um e meio
para os atrasos. O marco foi do dia 9 ao dia 15, **cinco dias úteis**, e o log diz por quê: dois dos seus
cinco commits, *Answer every error as JSON* e *Say what to do when there is nothing to lend*, não estavam na
estimativa. Eram itens de *deveria* que se mostraram necessários antes que as regras pudessem ser mostradas.
A estimativa das regras chegou perto; a estimativa do marco deixou de fora um terço do trabalho.

Por fim, o tamanho do que foi construído:

```
ana@laptop:~/loanbook$ git rev-list --count HEAD
20
ana@laptop:~/loanbook$ git diff --shortstat $(git rev-list --max-parents=0 HEAD) HEAD
 13 files changed, 473 insertions(+), 3 deletions(-)
ana@laptop:~/loanbook$ wc -l app.py static/app.js test_app.py
  166 app.py
   72 static/app.js
   56 test_app.py
  294 total
```

Vinte commits, menos de quinhentas linhas acrescentadas em treze arquivos, das quais o programa em si tem
menos de trezentas. Números assim valem uma linha numa retrospectiva, não mais: dão a quem lê uma ideia de
escala, e são verdadeiros, porque vieram do repositório e não da memória.
