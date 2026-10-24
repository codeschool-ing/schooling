---
title: Regeneração no Nuxt
version: 1
---

**O Nuxt escreve a mesma ideia como uma route rule**: `swr` com um número de segundos guarda cada
página renderizada no servidor por esse tempo, e serve a cópia velha enquanto renderiza uma nova. A
regra vai no `nuxt.config.ts`, ao lado de uma segunda que pré-renderiza a página inicial no build,
então um mesmo site usa dois modos. Substitua o arquivo:

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  app: { head: { title: "Study planner", htmlAttrs: { lang: "en" } } },
  routeRules: {
    "/": { prerender: true },
    "/courses/**": { swr: 10 },
  },
});
```

Desta vez é `npm run build`, não `generate`: as páginas de curso são renderizadas pelo servidor, sob
pedido, e só a página inicial é um arquivo. Ligue o `PORT=3002 node .output/server/index.mjs` no
segundo terminal, e rode as mesmas quatro requisições do Next.js, com um `look` que imprime os
cabeçalhos do Nuxt:

```
ana@dev:~/meta/nuxt$ look() { curl -s -D - -o /tmp/page.html http://localhost:3002/courses/git | grep -iE '^(cache-control|last-modified):'; grep -o '<h1>[^<]*</h1>' /tmp/page.html; }
ana@dev:~/meta/nuxt$ look
last-modified: Fri, 23 Oct 2026 23:16:00 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git</h1>
ana@dev:~/meta/nuxt$ sed -i 's/"title": "Git"/"title": "Git and GitHub"/' courses.json
ana@dev:~/meta/nuxt$ look
last-modified: Fri, 23 Oct 2026 23:16:00 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git</h1>
ana@dev:~/meta/nuxt$ sleep 11; look
last-modified: Fri, 23 Oct 2026 23:16:00 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git</h1>
ana@dev:~/meta/nuxt$ sleep 1; look
last-modified: Fri, 23 Oct 2026 23:16:11 GMT
cache-control: s-maxage=10, stale-while-revalidate
<h1>Git and GitHub</h1>
```

**Os mesmos quatro passos, e a mesma requisição é a que vê a página velha**: a terceira, onze
segundos depois da mudança, recebeu *Git* com o `last-modified` antigo, e a quarta, um segundo depois,
recebeu o título novo com um novo. O Nuxt fala menos disso que o Next.js, sem cabeçalho `HIT` ou `STALE`, então a data
do `last-modified` é como você sabe qual cópia voltou.

O `isr` é a outra regra, com o mesmo significado numa hospedagem que dá suporte a ele, onde as cópias
ficam no próprio cache da hospedagem em vez de no processo Node. Neste computador, com o preset
`node-server`, o `swr` é o que roda. Devolva o título e a configuração da aula 2 depois; a aula 4
precisa de toda página renderizada sob pedido.
