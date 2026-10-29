---
title: Vencido no edge
version: 1
---

**Uma página pode dizer uma coisa ao navegador e outra a um cache compartilhado.** O `max-age=0` faz todo
navegador conferir, como o `no-cache` fazia; o `s-maxage=10` deixa uma CDN guardar a página por dez segundos
sem perguntar. No `server.ts`, mude a chamada do ramo das páginas para:

```typescript
  send(req, res, "text/html; charset=utf-8", html, "max-age=0, s-maxage=10");
```

Reinicie o `server.ts`, deixe o edge rodando, e peça a página três vezes, a terceira depois de passarem os
dez segundos:

```
ana@dev:~/planner$ for wait in 0 3 8; do sleep $wait; curl -s -o /dev/null -D - http://localhost:8000/courses/git | grep -iE '^(x-cache|age)'; done
x-cache: MISS
age: 3
x-cache: HIT
x-cache: MISS
```

**MISS, HIT com três segundos de idade, e MISS de novo**: a cópia venceu e o edge perguntou à origem. Durante
esses dez segundos, toda requisição de qualquer visitante para aquela página foi respondida pelo edge, e o
servidor foi perguntado uma vez.

## O preço

**Enquanto o edge guarda uma página, uma mudança nela não é vista.** Renomeie o curso de Git no plano que o
servidor lê, a cópia do build em `dist/`, e pergunte pelo edge e direto ao servidor:

```
ana@dev:~/planner$ curl -s localhost:8000/courses/git > /dev/null; sed -i 's/"title": "Git"/"title": "Git and GitHub"/' dist/courses.json
```

```
ana@dev:~/planner$ for host in localhost:8000 localhost:3000; do curl -s $host/courses/git | grep -o '<h1>[^<]*</h1>'; done
<h1>Git</h1>
<h1>Git and GitHub</h1>
```

**O edge ainda diz *Git*; o servidor já diz *Git and GitHub*.** É a página vencida da aula 3 de novo, num cache
desta vez em vez de num build, e é a troca que todo cache compartilhado faz: velocidade para todo mundo,
contra uma mudança que leva até `s-maxage` segundos para chegar. Dez segundos não são nada para o título de um
curso. Para um preço, um estoque ou um cancelamento, o `s-maxage` certo é zero.

## Purgando, e servindo vencido de propósito

**Uma CDN de verdade pode ser mandada descartar uma cópia**, um purge, pela API ou pelo painel dela, que é
como um deploy torna seguro um `s-maxage` longo: o deploy purga o que mudou. E o **`stale-while-revalidate`**
transforma o vencimento num trabalho de segundo plano: quando uma cópia vence, o próximo visitante ainda é
respondido com ela na hora, e a CDN busca uma nova por trás. A regeneração da aula 3 é a ideia desse
cabeçalho, e a próxima seção encontra o Next.js mandando-o.

Ponha o título de volta com o mesmo `sed`, os dois nomes trocados, antes de seguir, e pare o edge com Ctrl-C.
