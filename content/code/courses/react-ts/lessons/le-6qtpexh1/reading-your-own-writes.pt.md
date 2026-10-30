---
title: Vendo a sua própria mudança
version: 1
---

**Um cache que serve para as mudanças dos outros está errado para as suas.** O `setDone` do planejador,
da aula 16, ainda termina com `refresh()`. Aperte a sessão de quarta no servidor de produção, e olhe dois
segundos depois:

```
ana@dev:~/planner-next$ look 'http://localhost:3000/?week=2026-10-19' --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 2000' | grep -E 'minutes done|Statistics ·'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min"
```

**80 minutos, e o botão não pressionado.** O `PATCH` chegou à API e a sessão está feita lá, então este é
o pior tipo de erro: a cópia otimista mostrou *pressionado*, e quando a Action terminou, a página voltou
do `refresh()` **renderizada a partir do planejador em cache**, que ainda tinha a quarta por fazer. O
`useOptimistic` fez o trabalho dele e mostrou o valor do servidor; o valor do servidor tinha uma hora.
Para o estudante, o clique não fez nada.

A correção é dizer, na Server Function, que a entrada em cache está velha. O **`updateTag('planner')`**
expira na hora toda entrada marcada `planner`, então a página que esta Action renderiza de novo busca o
planejador outra vez. Ele substitui o `refresh()` nas duas funções do `app/actions.ts`:

```
ana@dev:~/planner-next$ sed -i 's/import { refresh } from .next\/cache./import { updateTag } from '\''next\/cache'\''/; s/^  refresh()/  updateTag('\''planner'\'')/' app/actions.ts && grep -n 'updateTag\|refresh' app/actions.ts
3:import { updateTag } from 'next/cache'
20:  updateTag('planner')
46:  updateTag('planner')
ana@dev:~/planner-next$ npm run build > /dev/null && echo built
built
ana@dev:~/planner-next$ look 'http://localhost:3000/?week=2026-10-19' --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 2000' | grep -E 'minutes done|Statistics ·'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 120 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min" [pressed]
ana@dev:~/planner-next$ curl -s http://localhost:3000/courses/statistics | sed 's/<!-- -->//g' | grep -o '[0-9]* of [0-9]* minutes done'
90 of 90 minutes done
```

**120 minutos, e o botão pressionado.** E a página do curso, feita como arquivo estático no build, diz 90
de 90, os 50 de segunda e os 40 de quarta: ela foi feita a partir da entrada marcada, então ficou velha
junto com ela e foi renderizada de novo na requisição seguinte.

O Next.js tem três jeitos de dizer que uma entrada em cache está velha, e eles respondem a perguntas
diferentes:

| chamada | onde | o que o próximo leitor recebe |
|---|---|---|
| `updateTag(tag)` | só numa Server Function | dados novos na hora: para quem acabou de fazer a mudança |
| `revalidateTag(tag, 'max')` | numa Server Function ou num route handler | a entrada antiga mais uma vez, enquanto uma nova é buscada por trás |
| `cacheLife(…)` | dentro da função em cache | o que os limites de tempo disserem, sem chamada nenhuma |

O planejador usa a primeira, porque toda mudança que ele faz é do próprio estudante. Um catálogo que um
editor atualiza para milhares de leitores usaria a segunda, para nenhum leitor esperar a busca. E o
`curl` da seção anterior, uma mudança feita totalmente fora do Next.js, só é coberto pela terceira: para
ele, a hora vale.
