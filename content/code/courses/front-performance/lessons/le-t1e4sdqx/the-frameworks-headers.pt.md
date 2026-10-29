---
title: O que os frameworks mandam
version: 1
---

**Cada um dos quatro frameworks da aula 2 manda cabeçalhos de cache próprios**, e o jeito mais rápido de saber
quais é perguntar. O `tools/heads.ts` busca uma página, acha o primeiro script que ela cita e imprime o
`Cache-Control` dos dois. Salve-o em `tools/`:

```typescript
// tools/heads.ts: for each address, the cache-control of the page and of the first
// script the page names, which is what a browser will keep and for how long.
//
//   node tools/heads.ts URL...
for (const url of process.argv.slice(2)) {
  const page = await fetch(url);
  const html = await page.text();
  // A script element, or a modulepreload for one; and the page's <base>, which relative addresses start from.
  const src = html.match(/<script[^>]+src="([^"]+)"/)?.[1] ?? html.match(/href="([^"]+\.js)"/)?.[1];
  const base = new URL(html.match(/<base href="([^"]+)"/)?.[1] ?? url, url);
  const script = src ? await fetch(new URL(src, base)) : null;
  console.log(url);
  console.log(`  page    ${page.headers.get("cache-control") ?? "(none)"}`);
  console.log(`  script  ${script?.headers.get("cache-control") ?? "(none)"}`);
}
```

Inicie os quatro servidores de produção da aula 2, cada um na sua porta, como a aula 4 fez por último, e
pergunte aos cinco servidores, o do planner primeiro:

```
ana@dev:~/planner$ node tools/heads.ts http://localhost:3000/courses/git http://localhost:3001/courses/git http://localhost:3002/courses/git http://localhost:3003/courses/git http://localhost:3004/courses/git
http://localhost:3000/courses/git
  page    max-age=0, s-maxage=10
  script  public, max-age=31536000, immutable
http://localhost:3001/courses/git
  page    s-maxage=3600, stale-while-revalidate=82800
  script  public, max-age=31536000, immutable
http://localhost:3002/courses/git
  page    (none)
  script  public, max-age=31536000, immutable
http://localhost:3003/courses/git
  page    (none)
  script  public,max-age=31536000,immutable
http://localhost:3004/courses/git
  page    (none)
  script  public, max-age=31536000
```

**Todo framework guarda os scripts por um ano**, porque todos dão aos arquivos do build nomes com hash, como o
Vite faz. Três deles acrescentam `immutable`; o servidor do Angular manda o ano sem ele, o que custa uma
conferência quando a pessoa recarrega a página, nos navegadores que conferem.

**As páginas diferem.** O Nuxt, o SvelteKit e o Angular não mandam nada para uma página desenhada no servidor,
o que deixa o navegador estimar, como a seção "O que um cache economiza" descreveu; para uma página que é a
mesma para todo mundo, um cabeçalho como o do planner é uma linha da configuração deles. **O Next.js manda
`s-maxage=3600, stale-while-revalidate=82800`** para a página de curso, cuja versão da aula 3 se regenera a
cada hora e vence depois de um dia: uma CDN pode guardá-la uma hora, e servi-la vencida pelo resto do dia
enquanto busca uma nova. É a regeneração incremental escrita como cabeçalho, que qualquer CDN entende.

Pare os quatro servidores quando terminar.
