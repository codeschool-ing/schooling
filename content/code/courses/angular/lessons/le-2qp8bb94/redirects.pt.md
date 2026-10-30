---
title: Redirecionamentos, para endereços que mudaram
version: 1
---

**Um redirecionamento é uma rota sem componente: ele manda o router para outro endereço.** Dois
motivos para ter um. Um endereço que as pessoas já usam, em favoritos ou em links de outros lugares,
deve continuar funcionando depois que a página mudou. E dois endereços para uma página, como `/` e
`/week`, são mais gentis do que um deles ser um 404.

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week },
  {
    path: 'courses/:courseId',
    component: CoursePage,
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession },
    ],
  },
  { path: 'week', redirectTo: '' },
  { path: 'course/:courseId', redirectTo: 'courses/:courseId' },
  { path: '**', component: NotFound },
];
```

O `redirectTo` pode usar os parâmetros do endereço com que casou, então `course/:courseId` vira
`courses/` com o mesmo id. Os dois vão antes do `**`, como tudo.

```
ana@dev:~/planner$ look http://localhost:4200/week --url --text h2
[vite] connecting...
[vite] connected.
Angular is running in development mode.
url: /
This week
```

```
ana@dev:~/planner$ look http://localhost:4200/course/git --url --text h2
[vite] connecting...
[vite] connected.
Angular is running in development mode.
url: /courses/git
Git
```

O endereço mudou no navegador, não só a tela: o `--url` imprimiu onde a página terminou. Isso importa
pelo mesmo motivo de o redirecionamento existir. Uma pessoa que copia o endereço agora copia o que vai
continuar funcionando.

Um redirecionamento também pode ser uma função, que recebe a rota e retorna um caminho ou uma
`UrlTree`, para uma mudança que precisa de uma decisão: um id numérico antigo que precisa ser
procurado, por exemplo. Os dois daqui não precisam de nenhuma.
