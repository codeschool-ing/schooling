---
title: Um título para cada página, e um resolver para uma delas
version: 1
---

**Toda rota pode definir o título do documento, e deve, porque o título é o que um leitor de tela
anuncia depois de uma navegação e é o nome de uma aba e de um favorito.** Uma aplicação de página
única que nunca muda o título diz "Planner" em toda página, e uma pessoa que não vê a tela ouve que
nada mudou.

Um título fixo é uma string na rota. O título da página do curso depende do curso, então é um
**resolver**: uma função que o router chama antes de ativar a rota, que pode retornar um valor ou um
Observable, e a rota espera a resposta dele. O `courseTitle` espera o store terminar de carregar,
para o nome ser conhecido, e então o acha:

```typescript
// src/app/course-title.ts
import { inject } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { ResolveFn } from '@angular/router';
import { filter, map, take } from 'rxjs';
import { PlannerStore } from './planner-store';

export const courseTitle: ResolveFn<string> = (route) => {
  const store = inject(PlannerStore);
  return toObservable(store.isLoading).pipe(
    filter((loading) => !loading),
    take(1),
    map(() => {
      const course = store.courses().find((c) => c.id === route.paramMap.get('courseId'));
      return `${course?.name ?? 'No such course'} · Study planner`;
    }),
  );
};
```

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { courseTitle } from './course-title';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week, title: 'This week · Study planner' },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    title: courseTitle,
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
ana@dev:~/planner$ look http://localhost:4200/ --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>This week · Study planner</title>
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>Git · Study planner</title>
```

```
ana@dev:~/planner$ look http://localhost:4200/nowhere --html title
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<title>Not found · Study planner</title>
```

**Um resolver faz a navegação esperar**, e esse é o propósito e o custo dele. Aqui ele espera dados
que o store carrega uma vez, então a demora é o primeiro carregamento e nada depois. Um resolver que
buscasse o curso a cada navegação seguraria a página velha na tela, sem responder, pelo tempo que o
pedido levasse. É por isso que a própria página do curso não usa um: ela mostra o próprio
carregamento, o que é melhor do que uma página que parece não ter ouvido o clique. Um resolver é para
aquilo sem o que a rota não pode ser ativada, e um título é uma dessas coisas.

```
ana@dev:~/planner$ git add -A && git commit -q -m "Router: a page per address, links, child routes, redirects and titles"
```
