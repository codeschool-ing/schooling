---
title: As mesmas páginas, pré-renderizadas de quatro jeitos
version: 1
---

**Cada meta-framework faz o que o `prerender.ts` fez, e a prova é a mesma nos quatro: depois do
build, há um arquivo HTML para cada página.** A seção "Modo de renderização, por rota" da aula 2
mostrou onde cada um guarda a chave. Aqui cada projeto de `~/meta` a liga, faz o build e lista os
arquivos. A lista é o que se compara; os logs de build são longos e dizem o mesmo.

## Next.js: nada a mudar

O projeto Next.js já pré-renderizava as suas páginas na aula 2, porque tudo o que elas leem está em
cache. Os seus arquivos HTML ficam dentro de `.next/`, de onde o `next start` os serve:

```
ana@dev:~/meta/next$ npm run build >/dev/null 2>&1; find .next/server/app -name '*.html' | sort
.next/server/app/_global-error.html
.next/server/app/_not-found.html
.next/server/app/courses/[slug].html
.next/server/app/courses/git.html
.next/server/app/courses/html-css.html
.next/server/app/courses/javascript.html
.next/server/app/index.html
```

Um arquivo por curso, um para a página inicial, `_not-found.html` e `_global-error.html` para as
duas páginas que o Next.js sempre tem, e `[slug].html`: a casca da linha `◐`, servida para um slug
que o build não listou enquanto o resto daquela página é renderizado.

## Nuxt: `nuxt generate`

O Nuxt consegue pré-renderizar uma rota com `routeRules`, ou o site inteiro com um comando.
`npm run generate`, que o criador pôs no `package.json`, faz o build do app, liga-o e **o percorre**:
renderiza `/`, segue todo link que acha, e renderiza esses, até não aparecer endereço novo.

```
ana@dev:~/meta/nuxt$ npm run generate >/dev/null 2>&1; find .output/public -name '*.html' | sort
.output/public/200.html
.output/public/404.html
.output/public/courses/git/index.html
.output/public/courses/html-css/index.html
.output/public/courses/javascript/index.html
.output/public/index.html
```

O crawler achou as três páginas de curso seguindo os links da página inicial; nada as listou. Ao
lado de cada página o Nuxt também escreveu um `_payload.json`, os dados a partir dos quais aquela
página foi renderizada, que o navegador busca no lugar da página quando navega até ela com um
clique. O `200.html` é a casca vazia, para uma hospedagem usar como página de reserva de um app que
renderiza no navegador, e o `404.html` é a página para qualquer outro endereço.

**Um crawler só acha o que tem link.** Um curso para o qual ninguém aponta não é gerado, e nada
falha; `nitro.prerender.routes` no `nuxt.config.ts` lista esses endereços à mão.

## SvelteKit: uma linha num layout

`export const prerender = true` num layout vale para toda rota abaixo dele. Salve isto como
`src/routes/+layout.server.ts`; é um arquivo novo, ao lado do `+layout.svelte` que o criador
escreveu:

```typescript
// src/routes/+layout.server.ts: every route below this layout is built at build time.
export const prerender = true;
```

O pré-renderizador do SvelteKit também percorre o site, a partir de `/`:

```
ana@dev:~/meta/svelte$ npm run build >/dev/null 2>&1; find build/prerendered -name '*.html' | sort
build/prerendered/courses/git.html
build/prerendered/courses/html-css.html
build/prerendered/courses/javascript.html
build/prerendered/index.html
```

**As páginas são `git.html`, e não `git/index.html`**, que é o padrão do SvelteKit para um endereço
sem barra no final. O próprio servidor Node dele as acha. Uma hospedagem estática simples pode não
achar: algumas respondem `/courses/git` com `git.html`, algumas só com `git/index.html`, e um
`trailingSlash` num layout muda o SvelteKit para o segundo formato.

## Angular: `RenderMode.Prerender`, com os slugs

O Angular não percorre o site. Uma rota com parâmetro é pré-renderizada exatamente para os valores
que o `getPrerenderParams` devolve, que roda no build, no Node, e por isso pode ler o arquivo
diretamente. Substitua o `src/app/app.routes.server.ts`:

```typescript
// src/app/app.routes.server.ts: how the server renders each address.
import { readFile } from "node:fs/promises";
import { RenderMode, ServerRoute } from "@angular/ssr";
import type { Plan } from "./plan";

export const serverRoutes: ServerRoute[] = [
  { path: "", renderMode: RenderMode.Prerender },
  {
    path: "courses/:slug",
    renderMode: RenderMode.Prerender,
    async getPrerenderParams() {
      const plan: Plan = JSON.parse(await readFile("public/courses.json", "utf8"));
      return plan.courses.map((c) => ({ slug: c.slug }));
    },
  },
  { path: "**", renderMode: RenderMode.Server },
];
```

A última linha mantém todo outro endereço renderizado sob pedido, então um slug que o build não
conhecia ainda é atendido pelo servidor. Faça o build e liste:

```
ana@dev:~/meta/angular$ npm run build 2>&1 | grep Prerendered; find dist/angular/browser -name '*.html' | sort
Prerendered 4 static routes.
dist/angular/browser/courses/git/index.html
dist/angular/browser/courses/html-css/index.html
dist/angular/browser/courses/javascript/index.html
dist/angular/browser/index.csr.html
dist/angular/browser/index.html
```

O `index.csr.html` é a casca vazia, para a qual o servidor recua quando não consegue renderizar,
como fez na aula 2 com o host que recusou.

## Quatro formatos do mesmo resultado

| | como os endereços foram achados | onde ficam os arquivos | uma página de curso é |
|---|---|---|---|
| o seu `prerender.ts` | lidos do `courses.json` | `dist/` | `courses/git/index.html` |
| Next.js | `generateStaticParams` | `.next/server/app/` | `courses/git.html` |
| Nuxt | percorridos a partir de `/` | `.output/public/` | `courses/git/index.html` |
| SvelteKit | percorridos a partir de `/` | `build/prerendered/` | `courses/git.html` |
| Angular | `getPrerenderParams` | `dist/angular/browser/` | `courses/git/index.html` |

**Listar os endereços e percorrer o site atrás deles falham de jeitos diferentes.** Uma lista perde
uma página que alguém esqueceu de pôr nela; um crawler perde uma página para a qual ninguém fez
link. Os dois falham em silêncio, com um build que dá certo, e os dois se conferem do mesmo jeito:
contar os arquivos que o build escreveu contra as páginas que os dados dizem existir.
