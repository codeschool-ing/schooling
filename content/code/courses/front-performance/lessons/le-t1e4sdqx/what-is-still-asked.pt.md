---
title: O que ainda é perguntado toda vez
version: 1
---

**Um 304 é barato em bytes e custa uma ida e volta inteira.** Num celular a 300 milissegundos do servidor,
quatro conferências que podem rodar em paralelo ainda custam uma ida e volta, e as fontes e a capa que o
planner confere a cada visita não mudaram desde que foram feitas. Pergunte ao Lighthouse o que ele acha delas:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|insight'
performance 100, throttling simulate
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
```

**O Use efficient cache lifetimes sumiu.** Os scripts são guardados por um ano, e os arquivos mandados com
`no-cache` e um ETag também não estão na lista dele: conferir é uma escolha que o servidor fez de propósito,
e não custa corpo. O que nenhum insight conta é a ida e volta que cada conferência ainda custa a quem volta,
um número que só uma medida da segunda visita mostra, como o `revisit.ts` fez.

## Duas saídas

- **Dar ao arquivo um nome com hash**, e ele cai na primeira regra. O Vite faz isso com tudo o que o código ou
  o CSS importa: uma fonte citada numa folha de estilo com um `url()` relativo é copiada para `dist/assets/`
  com um hash. O planner mantém as fontes em `public/` porque o preload da aula 7 as cita por um endereço fixo;
  um build que também escrevesse o preload deixaria que elas mudassem de lugar.
- **Dar a ele um tempo de vida que combine com a frequência com que muda.** Uma capa redesenhada uma vez por
  ano pode ser guardada por uma semana, `max-age=604800`, com o ETag para depois. O que isso custa é a semana:
  uma capa mudada chega a um visitante que volta com até sete dias de atraso.

**O planner os deixa como estão**, com quatro 304 numa volta, e isso é uma escolha medida e não um descuido:
nesta página eles rodam em paralelo, o custo é uma ida e volta, e a próxima aula acrescenta um cache que os
serve sem perguntar à rede.
