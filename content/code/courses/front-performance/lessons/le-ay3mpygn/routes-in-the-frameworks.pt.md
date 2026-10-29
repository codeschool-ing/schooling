---
title: Rotas nos frameworks
version: 1
---

**Uma rota é o lugar natural para dividir**, porque uma pessoa está numa página de cada vez. Três dos quatro
frameworks da aula 2 dividem por rota sem ninguém pedir; um precisa ser avisado.

| | por rota | uma parte de uma página |
|---|---|---|
| **Next.js** | toda página e layout em `app/` é um chunk próprio | `next/dynamic`, ou o `lazy` do React com `<Suspense>` |
| **Nuxt** | todo arquivo em `pages/` é um chunk próprio | um componente com o prefixo `Lazy`, `<LazyChart>`, é carregado quando é desenhado pela primeira vez |
| **SvelteKit** | todo `+page` e `+layout` é um chunk próprio, que o build chama de node | `import()` dentro do componente, como nesta aula |
| **Angular** | só rotas escritas com `loadComponent` | `@defer`, o da aula 4, que carrega o código de um bloco num gatilho |

Cada um dos quatro também pode buscar cedo o código da próxima rota, num aviso como o da seção anterior: o
Next.js e o Nuxt quando um link entra na tela, o SvelteKit quando o ponteiro descansa num, que o template
dele pede, e o Angular quando o roteador recebe uma estratégia de preloading. Isso é a leitura desta seção da
documentação deles; a próxima parte foi rodada.

## Avisando o Angular

O projeto Angular da aula 2 cita os dois componentes no `app.routes.ts`, então os dois estão no arquivo que
toda página carrega. O build diz isso:

```
ana@dev:~/meta/angular$ npm run build 2>&1 | sed -n '/Browser bundles/,/Server bundles/p' | grep -E '\.js |Initial total|Lazy chunk'
main-MEAHQ54B.js     | main             | 270.04 kB |                74.41 kB
                     | Initial total    | 270.04 kB |                74.41 kB
```

**Um arquivo inicial, e nenhum lazy.** Troque o `src/app/app.routes.ts` por uma versão em que cada rota
carrega o componente na primeira visita:

```typescript
// src/app/app.routes.ts: which component answers which address. Each is loaded when its
// address is first visited, so each is a chunk of its own.
import { Routes } from "@angular/router";

export const routes: Routes = [
  { path: "", loadComponent: () => import("./home").then((m) => m.Home), title: "Study planner" },
  { path: "courses/:slug", loadComponent: () => import("./course").then((m) => m.Course), title: "Study planner" },
];
```

O import de cada componente saiu do topo do arquivo, e isso importa: um import estático em qualquer lugar
poria o componente de volta no arquivo inicial, diga a rota o que disser.

```
ana@dev:~/meta/angular$ npm run build 2>&1 | sed -n '/Browser bundles/,/Server bundles/p' | grep -E '\.js |Initial total|Lazy chunk'
chunk-IBRQ2R5D.js    | -                | 267.53 kB |                73.83 kB
main-XHWRPD6J.js     | main             | 648 bytes |               648 bytes
                     | Initial total    | 268.17 kB |                74.48 kB
Lazy chunk files     | Names            |  Raw size | Estimated transfer size
chunk-74WP3QX3.js    | course           |   1.02 kB |                 1.02 kB
chunk-XJFROPDD.js    | home             | 903 bytes |               903 bytes
chunk-WYIPRWR6.js    | -                | 846 bytes |               846 bytes
```

**Chunks lazy para `home` e `course`, um terceiro que os dois dividem, e um total inicial que quase não se mexeu.** Os componentes eram a
parte pequena. O que toda página de uma aplicação Angular carrega é o framework, e dividir as suas próprias
rotas não consegue diminuí-lo; impede que ele cresça a cada página acrescentada. O mesmo vale, nas proporções
de cada um, para os outros três, e é o número que a aula 2 mediu quando pesou a mesma página em cada um.
