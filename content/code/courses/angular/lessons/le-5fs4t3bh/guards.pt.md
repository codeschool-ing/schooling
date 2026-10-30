---
title: Guards, e o que eles não são
version: 1
---

**Um guard é uma função que o router pergunta antes de seguir com uma navegação: esta rota pode ser
usada, aberta, deixada?** Ele responde `true` para deixar a navegação passar, `false` para pará-la, ou
um redirecionamento para mandá-la a outro lugar, e pode levar o seu tempo, retornando uma Promise ou
um Observable, como o resolver da aula 17 fez.

| guard | perguntado | a pergunta de costume |
|---|---|---|
| `canMatch` | antes de a rota sequer ser considerada, e antes de uma parte lazy ser carregada | esta rota deve existir para esta pessoa? |
| `canActivate` | antes de o componente da rota ser desenhado | esta página pode ser aberta? |
| `canActivateChild` | antes de qualquer filho da rota ser desenhado | algo aqui embaixo pode ser aberto? |
| `canDeactivate` | antes de a página ser deixada | tudo bem sair? |

A página do curso tem uma pergunta para o `canActivate`. Desde a aula 17, `/courses/rust` desenha a
página do curso, que então diz que não tem esse curso. Um guard pode decidir antes de a página ser
desenhada, e mostrar a página de não encontrado no lugar, com o título dela, sob o endereço que a
pessoa digitou:

```typescript
// src/app/course-exists.ts
import { inject } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { CanActivateFn, RedirectCommand, Router } from '@angular/router';
import { filter, map, take } from 'rxjs';
import { PlannerStore } from './planner-store';

export const courseExists: CanActivateFn = (route) => {
  const store = inject(PlannerStore);
  const router = inject(Router);
  return toObservable(store.isLoading).pipe(
    filter((loading) => !loading),
    take(1),
    map(() => {
      const id = route.paramMap.get('courseId');
      if (store.error() || store.courses().some((c) => c.id === id)) return true;
      return new RedirectCommand(router.parseUrl('/not-found'), { skipLocationChange: true });
    }),
  );
};
```

Ele espera o store, como o `courseTitle` fez. Se os dados não puderam ser carregados, ele deixa a
página passar, porque a página diz isso melhor do que "não encontrado" diria. Senão ele responde
`true`, ou um `RedirectCommand` para um endereço com que só a rota `**` casa, com `skipLocationChange`
para a barra de endereço manter o que foi digitado.

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { courseExists } from './course-exists';
import { courseTitle } from './course-title';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week, title: 'This week · Study planner' },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    title: courseTitle,
    canActivate: [courseExists],
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession },
    ],
  },
  { path: 'week', redirectTo: '' },
  { path: 'course/:courseId', redirectTo: 'courses/:courseId' },
  { path: '**', component: NotFound, title: 'Not found · Study planner' },
];
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/rust --url --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
url: /courses/rust
Nothing here

The planner has no page at this address. Back to this week.
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/rust --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>Not found · Study planner</title>
```

## O que um guard não é

**Um guard decide o que a interface mostra; ele não protege nada.** Ele roda no navegador, em código
que a pessoa tem e pode mudar, e os dados que uma página guardada mostraria continuam vindo de uma API
que qualquer um pode chamar com o `curl`, como a aula 15 fez. Um guard que afasta de uma página quem
não entrou é uma cortesia que poupa essa pessoa de uma página de erros. O que mantém os dados longe
dela é o servidor recusando o pedido, toda vez, faça o navegador o que fizer antes. Um guard sem isso
é uma porta trancada numa parede que não existe.
