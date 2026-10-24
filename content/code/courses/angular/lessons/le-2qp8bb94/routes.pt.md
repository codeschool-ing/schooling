---
title: Rotas, e o outlet que elas preenchem
version: 1
---

**O router liga um endereço a um componente, e desenha esse componente onde a aplicação tem um
`<router-outlet>`.** Até aqui o `App` punha as duas telas numa página, uma em cima da outra, com o
curso fixo em `javascript`. Um planner de verdade mostra uma tela por vez e deixa o endereço dizer
qual: `/` para a semana, `/courses/git` para um curso. O router lê o endereço quando a página carrega,
desenha o componente que casa com ele, e muda o endereço, e o componente, quando alguém segue um link.

O router está no projeto desde a aula 2: o `app.routes.ts` com uma lista vazia, e o
`provideRouter(routes)` no `app.config.ts`. Um componente para um endereço que ninguém previu vem
primeiro:

```
ana@dev:~/planner$ npx ng generate component not-found --inline-template --inline-style --skip-tests
CREATE src/app/not-found/not-found.ts (280 bytes)
```

```typescript
// src/app/not-found/not-found.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-not-found',
  imports: [RouterLink],
  template: `
    <h2>Nothing here</h2>
    <p>The planner has no page at this address. <a routerLink="/">Back to this week</a>.</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotFound {}
```

As rotas, na ordem em que o router as tenta:

```typescript
// src/app/app.routes.ts
import { Routes } from '@angular/router';
import { CoursePage } from './course-page/course-page';
import { NotFound } from './not-found/not-found';
import { Week } from './week/week';

export const routes: Routes = [
  { path: '', component: Week },
  { path: 'courses/:courseId', component: CoursePage },
  { path: '**', component: NotFound },
];
```

**O router fica com a primeira rota que casa**, então a ordem faz parte do significado. `''` casa só
com o caminho vazio, aqui `/`. `courses/:courseId` casa com `courses/` seguido de um segmento, e o
`:courseId` dá a esse segmento o nome de parâmetro. `**` casa com qualquer coisa, e é por isso que vai
por último: posto primeiro, responderia todo endereço com "não encontrado".

O `withComponentInputBinding()` é a linha que une o router aos inputs da aula 8: um parâmetro de rota
chamado `courseId` é definido no input do componente de mesmo nome. O `CoursePage` já tem esse input,
`input.required<string>()`, então não precisa de mudança nenhuma.

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter, withComponentInputBinding } from '@angular/router';

import { routes } from './app.routes';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes, withComponentInputBinding()),
    provideHttpClient(withInterceptors([requestedBy])),
  ]
};
```

O `App` mantém o título e entrega o resto da página ao outlet:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <router-outlet />
</main>
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
This week

2026-10-19 to 2026-10-25

165 minutes planned, 90 done.

75 minutes to go.

Done this week
Courses
HTML and CSS: 30 minutes
JavaScript: 110 minutes
Git: 25 minutes
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Git
 2026-10-22, 25 minutes
Add sessions
Date 1
Another date
Minutes
Add
```

```
ana@dev:~/planner$ look http://localhost:4200/nowhere --text main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Nothing here

The planner has no page at this address. Back to this week.
```

Três endereços, três telas, uma aplicação. O último funciona por causa de algo que a aula 2 mostrou:
o servidor de desenvolvimento responde um endereço sem arquivo por trás com o `index.html`, então a
aplicação inicia, e aí o router decide. O `curl` vê a mesma resposta para um curso:

```
ana@dev:~/planner$ curl -si http://localhost:4200/courses/git | head -1
HTTP/1.1 200 OK
```

Um 200 e a página da aplicação, para um endereço que não é um arquivo. O que quer que entregue a
aplicação construída em produção precisa fazer o mesmo, senão todo endereço fora o `/` vira um 404 ao
recarregar.
