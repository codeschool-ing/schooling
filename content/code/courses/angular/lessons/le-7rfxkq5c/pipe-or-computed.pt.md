---
title: Um pipe, um computed, ou um método?
version: 1
---

**Um pipe formata um valor para um template; um `computed` calcula um valor para a classe.** Os dois
são lembrados até as entradas mudarem, o que torna os dois baratos. Um método chamado num template não
é lembrado por nada, e roda em toda conferência do componente, como um pipe impuro.

| o template precisa de | escreva | por quê |
|---|---|---|
| um valor mostrado de um jeito, em vários componentes | um pipe | uma definição, importada onde é usada, testada com `new` |
| um valor derivado do estado, para este componente | um `computed` | rastreado como qualquer signal, e legível na classe também |
| um valor calculado uma vez por conferência, barato | um método | aceitável quando é barato, como o `asText()` da aula 14 |
| estado que é o mesmo em todo lugar | no store | a regra da aula 11: um fato sobre o planner vai para lá |

O planner tem os quatro: o `minutes` é um pipe porque cinco templates dizem durações do mesmo jeito; o
`rows` no `Week` é um `computed` porque é a forma daquela tela; o `shows()` do formulário é um método
porque são duas comparações; o `weekTotals` fica no store porque toda tela concorda com ele.

O bench sai:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M angular.json
 M src/app/course-card/course-card.ts
 M src/app/course-page/course-page.html
 M src/app/course-page/course-page.ts
 M src/app/session-row/session-row.ts
 M src/app/week-summary/week-summary.html
 M src/app/week-summary/week-summary.ts
 M src/app/week/week.html
 M src/app/week/week.spec.ts
 M src/app/week/week.ts
?? src/app/minutes-pipe.spec.ts
?? src/app/minutes-pipe.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Pipes: dates in British English, and durations in words"
```
