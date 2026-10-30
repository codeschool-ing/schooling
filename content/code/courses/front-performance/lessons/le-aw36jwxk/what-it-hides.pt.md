---
title: O que um worker esconde das suas ferramentas
version: 1
---

**Uma página controlada por um worker não consegue mais ver a rede.** Toda requisição que ela faz é respondida
pelo worker, e se o worker respondeu do cache ou foi ao servidor é assunto do worker. O `revisit.ts` da aula 9,
rodado numa página que o worker controla na segunda visita, não consegue dizer o que aconteceu:

```
ana@dev:~/planner$ node tools/revisit.ts http://localhost:3000/courses/git
/courses/git                   undefined, downloaded again
/fonts/plex-400.woff2          undefined, downloaded again
/fonts/plex-700.woff2          undefined, downloaded again
/assets/index-DKDcq93q.js      undefined, downloaded again
/assets/planner-BNdUlffC.js    undefined, downloaded again
/covers/git-800.avif           undefined, downloaded again
```

**O `undefined`, e a palavra *downloaded*, são a ferramenta caindo no último caso dela.** Ela foi escrita para uma
página sem worker: nenhum status atravessou a parte da rede da página, porque o worker respondeu, e a ferramenta
não tem linha para isso. As requisições do próprio worker estão numa lista à parte, a do worker, que as
ferramentas de desenvolvedor mostram sob o worker no painel **Application**, junto com os caches dele e o
conteúdo deles.

## Três consequências

- **Meça com o worker de propósito.** Uma medida de laboratório num navegador novo, como toda ferramenta deste
  curso faz, nunca tem worker instalado, então mede uma primeira visita. Uma visita repetida com worker precisa de
  um teste que o instale antes, como o `offline.ts` faz.
- **Um bug pode morar no worker por muito tempo.** Um worker que serve uma cópia errada continua servindo-a, do
  cache de cada visitante, até uma versão nova substituí-lo. A regra da aula 9 vale aqui também: o próprio
  `/sw.js` vai com `no-cache`, então a conferência diária do navegador vê uma correção no dia do deploy.
- **Há uma saída.** Um servidor pode responder qualquer página com `Clear-Site-Data: "storage"` para o navegador
  descartar os caches e service workers de um site, e uma página pode chamar `unregister()` no seu registro. Um
  site que publica um worker deveria saber qual dos dois vai usar antes de precisar.
