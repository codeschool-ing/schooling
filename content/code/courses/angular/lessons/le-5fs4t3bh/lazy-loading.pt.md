---
title: Lazy loading, uma parte da aplicação buscada quando é preciso
version: 1
---

**Tudo o que as rotas importam diretamente vai para o primeiro arquivo que o navegador baixa.** A
página do curso, as sessões, o formulário com os validadores: uma pessoa que abre o planner para
olhar a semana baixa tudo isso, e pode nunca abrir um curso. Um build de produção diz de que tamanho
isso é:

```
ana@dev:~/planner$ npx ng build 2>&1 | sed -n '/Initial chunk/,/Output location/p'
Initial chunk files | Names         |  Raw size | Estimated transfer size
main-LXR6UEY3.js    | main          | 318.31 kB |                83.90 kB
styles-5INURTSO.css | styles        |   0 bytes |                 0 bytes

                    | Initial total | 318.31 kB |                83.90 kB

Application bundle generation complete. [4.507 seconds] - 2026-10-29T23:50:55.332Z

Output location: /home/ana/planner/dist/planner
```

Um arquivo, o `main`, com tudo dentro. O `loadChildren` recebe uma função que importa uma lista de
rotas, e o build põe o que só essas rotas usam num arquivo próprio, buscado na primeira vez que
alguém navega para lá. As rotas do curso vão para um arquivo só delas:

```typescript
// src/app/courses.routes.ts
import { Routes } from '@angular/router';
import { AddSession } from './add-session/add-session';
import { CoursePage } from './course-page/course-page';
import { CourseSessions } from './course-sessions/course-sessions';
import { unsavedWork } from './unsaved-work';

export const courseRoutes: Routes = [
  {
    path: '',
    component: CoursePage,
    children: [
      { path: '', component: CourseSessions },
      { path: 'add', component: AddSession, canDeactivate: [unsavedWork] },
    ],
  },
];
```

E a rota do curso fica com o que decide se ela é aberta, o título e o guard, e carrega o resto:

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
  { path: 'course/:courseId', redirectTo: 'courses/:courseId' },
  { path: '**', component: NotFound, title: 'Not found · Study planner' },
];
```

O import é uma chamada de função, `import('./courses.routes')`, não um `import` no alto do arquivo.
Esse é o truque inteiro: nada no `app.routes.ts` cita mais o `CoursePage`, então o build fica livre
para deixá-lo fora do `main`.

```
ana@dev:~/planner$ npx ng build 2>&1 | sed -n '/Initial chunk/,/Output location/p'
Initial chunk files | Names          |  Raw size | Estimated transfer size
chunk-ZAJKZMGB.js   | -              | 270.05 kB |                73.92 kB
main-DZVPXVFB.js    | main           |   5.68 kB |                 2.04 kB
styles-5INURTSO.css | styles         |   0 bytes |                 0 bytes

                    | Initial total  | 275.74 kB |                75.96 kB

Lazy chunk files    | Names          |  Raw size | Estimated transfer size
chunk-AQS5JCV2.js   | courses-routes |  44.05 kB |                10.15 kB

Application bundle generation complete. [2.728 seconds] - 2026-10-29T23:51:01.786Z

Output location: /home/ana/planner/dist/planner
```

O `main` agora tem poucos kilobytes, um chunk guarda o código que as duas metades compartilham, o
próprio Angular entre ele, e o `courses-routes` é um chunk lazy: no servidor, e não baixado até um
curso ser aberto. O `--scripts` lista os arquivos de script da aplicação que uma página carregou, em
ordem:

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text h2 --do 'click Git'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Git
scripts: /main.js /chunk-KGABQYFU.js /chunk-5ODBP7SE.js
Git
```

A semana carregou dois arquivos. O clique em Git buscou o terceiro, e então desenhou o curso. Os
chunks do servidor de desenvolvimento têm nomes diferentes dos do build, mas se dividem do mesmo
jeito.
