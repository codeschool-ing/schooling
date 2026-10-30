---
title: O que o servidor responde, além da página
version: 1
---

**Uma página renderizada no servidor também é uma resposta HTTP, e o código de status dela é lido por
programas que nunca olham a página.** Um buscador descarta um endereço que responde `404`, um
verificador de links o aponta, um cache guarda um `200`. Só no navegador nada disso importava: o dev
server respondia a todo endereço com o `index.html` e um `200`, e o roteador decidia o que mostrar.
Agora cada endereço é renderizado, então cada um pode responder por si. O `curl` imprime o status e,
num redirecionamento, para onde ele aponta:

```
ana@dev:~/planner$ for p in / /week /course/git /nowhere /courses/nope; do curl -s -o /dev/null -w "$p %{http_code} %{redirect_url}\n" http://localhost:4200$p; done
/ 200 
/week 302 http://localhost:4200/
/course/git 302 http://localhost:4200/course/courses/:courseId
/nowhere 200 
/courses/nope 200 
```

Três dos cinco estão errados.

- `/course/git` é o endereço antigo que a aula 17 manteve funcionando com
  `redirectTo: 'courses/:courseId'`. No navegador o roteador preenche o `:courseId`. No servidor, o
  redirecionamento é respondido com um `302` antes de a aplicação rodar, e o endereço nele é o texto da
  rota, com `:courseId` e tudo, então o link antigo agora leva a uma página que não existe.
- `/nowhere` mostra "Nothing here" com um `200`, o que diz a todo programa que lê a resposta que a
  página existe. Isso se chama soft 404.
- `/courses/nope` é igual: o guard `courseExists` da aula 18 o manda para a mesma página.

O redirecionamento se conserta calculando o endereço em vez de escrevê-lo como padrão. O
`redirectTo` aceita uma função, que recebe os parâmetros da rota:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { courseExists } from './course-exists';
import { courseTitle } from './course-title';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week, title: 'This week · Study planner' },
  {
    path: 'courses/:courseId',
    title: courseTitle,
    canActivate: [courseExists],
    loadChildren: () => import('./courses.routes').then((m) => m.courseRoutes),
  },
  { path: 'week', redirectTo: '' },
  { path: 'course/:courseId', redirectTo: ({ params }) => `/courses/${params['courseId']}` },
  { path: '**', component: NotFound, title: 'Not found · Study planner' },
];
```

No servidor, uma função não pode ser respondida antes de a aplicação rodar, então a aplicação roda,
o roteador segue a função, e o servidor responde com um `302` para onde o roteador foi.

O status de uma página renderizada é definido de dentro da aplicação, por um token, o `RESPONSE_INIT`.
No servidor ele é a resposta sendo preparada; no navegador não há resposta a preparar, e ele é
`null`. O `NotFound` é o único componente que sabe que a resposta é "não encontrado":

```schooling-example
{"language": "typescript", "file": "src/app/not-found/not-found.ts", "parts": [
 {"code": "// src/app/not-found/not-found.ts\nimport { ChangeDetectionStrategy, Component, RESPONSE_INIT, inject } from '@angular/core';\nimport { RouterLink } from '@angular/router';\n\n@Component({\n  selector: 'app-not-found',\n  imports: [RouterLink],\n  template: `\n    <h2>Nothing here</h2>\n    <p>The planner has no page at this address. <a routerLink=\"/\">Back to this week</a>.</p>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})"},
 {"code": "export class NotFound {\n  constructor() {\n    const response = inject(RESPONSE_INIT);\n    if (response) response.status = 404;\n  }\n}", "note": "`null` no navegador, então o `if` é toda a parte do navegador. No servidor, o status definido aqui é o que vai."}
]}
```

```
ana@dev:~/planner$ for p in / /week /course/git /nowhere /courses/nope; do curl -s -o /dev/null -w "$p %{http_code} %{redirect_url}\n" http://localhost:4200$p; done
/ 200 
/week 302 http://localhost:4200/
/course/git 302 http://localhost:4200/courses/git
/nowhere 404 
/courses/nope 404 
```

`/courses/nope` também responde `404`, sem nenhuma mudança própria, porque o guard o manda para o
mesmo componente. Uma pessoa vê exatamente o que via antes:

```
ana@dev:~/planner$ look http://localhost:4200/courses/nope --text main
[error] Failed to load resource: the server responded with a status of 404 (Not Found)
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 2 component(s) and 17 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
Nothing here

The planner has no page at this address. Back to this week.
```

A primeira linha é o navegador contando o `404` da própria página. É o único sinal, e é o certo.
