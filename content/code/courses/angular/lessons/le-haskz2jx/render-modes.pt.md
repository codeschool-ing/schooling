---
title: Três jeitos de renderizar uma rota
version: 1
---

**O `app.routes.server.ts` diz, rota a rota, onde o HTML de cada página é feito.** A configuração
escreveu uma regra para todas as rotas:

```
ana@dev:~/planner$ cat src/app/app.routes.server.ts
import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  {
    path: '**',
    renderMode: RenderMode.Prerender,
  },
];
```

O `RenderMode` tem três valores:

| modo | o HTML é feito | serve para |
| --- | --- | --- |
| `Prerender` | uma vez, durante o `ng build`, e salvo como arquivo | uma página igual para todo mundo até o próximo deploy |
| `Server` | a cada requisição, pelo servidor rodando | uma página cujo conteúdo muda, ou é diferente por pessoa |
| `Client` | no navegador, como antes desta aula | uma página sem nada que valha mandar antes dos scripts |

Pré-renderizar é o mais rápido dos três, porque o servidor só entrega um arquivo. Mas o build
precisa conhecer todo endereço que vai produzir, e os endereços do planner têm o id de um curso:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'ERROR|Prerendered'
Prerendered 2 static routes.
✘ [ERROR] The 'courses/:courseId' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
✘ [ERROR] The 'courses/:courseId/' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
✘ [ERROR] The 'courses/:courseId/add' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
✘ [ERROR] The 'course/:courseId' route uses prerendering and includes parameters, but 'getPrerenderParams' is missing. Please define 'getPrerenderParams' function for this route in your server routing configuration or specify a different 'renderMode'.
```

O `getPrerenderParams` responderia isso: uma função que lista os ids dos cursos, para o build fazer
`/courses/html-css`, `/courses/javascript` e `/courses/git`. Também estaria errado, por um motivo
que o erro não menciona. **Uma página pré-renderizada guarda os dados como estavam na hora do
build.** A semana diria "1 hour 30 minutes done" até o próximo deploy, fosse o que fosse marcado
nesse meio-tempo. Pré-renderizar é para páginas como uma página "sobre" ou a descrição de um curso.
O planner não tem nenhuma dessas, então toda rota é renderizada por requisição:

```typescript
// src/app/app.routes.server.ts
import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  {
    path: '**',
    renderMode: RenderMode.Server,
  },
];
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'ERROR|Prerendered'
Prerendered 0 static routes.
```

As regras são comparadas com os caminhos do `app.routes.ts`, e para cada endereço vale a regra mais
específica, esteja onde estiver na lista. Então uma lista pode ser mista: uma regra para
`courses/:courseId/add` com `RenderMode.Client`, ao lado do `**`, mandaria a página do formulário
vazia e deixaria todas as outras como estão. O planner mantém essa página no servidor também, porque
os rótulos do formulário e o nome do curso são texto que vale ter antes de os scripts chegarem.
