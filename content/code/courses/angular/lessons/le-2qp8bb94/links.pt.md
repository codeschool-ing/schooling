---
title: Links que o router segue
version: 1
---

**O `routerLink` faz um link que o router segue sem recarregar a página.** Ele continua sendo um `<a>`
com `href`, então pode ser aberto numa aba nova, copiado, e lido como link por um leitor de tela. Um
clique nele muda o endereço e troca o componente no outlet; nada é buscado de novo, e os dados do
store continuam lá.

Cada curso da semana vira um link para a página dele. O `['/courses', course().id]` monta o caminho
pelos segmentos, o que é mais seguro do que colar strings quando um id pode ter um caractere que uma
URL precisa escapar:

```typescript
// src/app/course-card/course-card.ts
import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { RouterLink } from '@angular/router';
import { Course } from '../planner';

@Component({
  selector: 'app-course-card',
  imports: [RouterLink],
  template: `<a class="name" [routerLink]="['/courses', course().id]">{{ course().name }}</a>: {{ minutes() }} minutes`,
  styles: `
    .name {
      font-weight: 600;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseCard {
  readonly course = input.required<Course>();
  readonly minutes = input(0);
}
```

E o `App` ganha um caminho de volta. O `routerLinkActive` acrescenta uma classe enquanto o endereço do
link é o atual, `exact: true` para o `/` não ficar ativo em toda página, e o `ariaCurrentWhenActive`
define `aria-current="page"`, que um leitor de tela anuncia como "página atual":

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<nav aria-label="Planner">
  <a routerLink="/" routerLinkActive="current" [routerLinkActiveOptions]="{ exact: true }" ariaCurrentWhenActive="page">This week</a>
</nav>
<main>
  <router-outlet />
</main>
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```css
/* src/app/app.css */
nav {
  display: flex;
  gap: 1rem;
}
```

O `--url` imprime o endereço em que a página terminou. Um clique num curso:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text main --do 'click JavaScript' --url
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click JavaScript
url: /courses/javascript
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
Add sessions
Date 1
Another date
Minutes
Add
```

E o HTML da navegação na semana, onde o link dela é a página atual:

```
ana@dev:~/planner$ look http://localhost:4200/ --html 'app-root nav'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<nav aria-label="Planner"><a routerlink="/" routerlinkactive="current" ariacurrentwhenactive="page" href="/" class="current" aria-current="page">This week</a></nav>
```

## Os testes percebem

Os testes que o CLI gerou, e o da aula 10, não rodaram desde que o router chegou:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|^ERROR|Tests '
ERROR ɵNotFound: NG0201: No provider found for `ActivatedRoute`. Source: DynamicTestModule. Find more at https://v21.angular.dev/errors/NG0201
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 3 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/app.spec.ts > App > should create the app
 FAIL  |planner| src/app/app.spec.ts > App > should render the heading
 FAIL  |planner| src/app/week/week.spec.ts > Week > counts the week that holds today
      Tests  3 failed | 2 passed (5)
```

`NG0201` de novo, o erro da aula 10: o `routerLink` injeta o `ActivatedRoute`, e um teste constrói os
componentes por um injetor próprio, a que ninguém deu um router. O `App` tem um link, e todo
`CourseCard` que a semana desenha também. O `provideRouter([])` dá a cada teste um router sem rotas,
que é tudo de que um link precisa para ser desenhado:

```typescript
// src/app/app.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { App } from './app';

describe('App', () => {
  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [App],
      providers: [provideRouter([])],
    }).compileComponents();
  });

  it('should create the app', () => {
    const fixture = TestBed.createComponent(App);
    const app = fixture.componentInstance;
    expect(app).toBeTruthy();
  });

  it('should render the heading', async () => {
    const fixture = TestBed.createComponent(App);
    await fixture.whenStable();
    const compiled = fixture.nativeElement as HTMLElement;
    expect(compiled.querySelector('h1')?.textContent).toBe('Study planner');
  });
});
```

```typescript
// src/app/week/week.spec.ts
import { TestBed } from '@angular/core/testing';
import { provideRouter } from '@angular/router';
import { TODAY } from '../today';
import { Week } from './week';

describe('Week', () => {
  it('counts the week that holds today', async () => {
    TestBed.configureTestingModule({
      imports: [Week],
      providers: [provideRouter([]), { provide: TODAY, useValue: new Date('2026-10-28T09:00:00') }],
    });
    const fixture = TestBed.createComponent(Week);
    await fixture.whenStable();
    const text = (fixture.nativeElement as HTMLElement).textContent;
    expect(text).toContain('2026-10-26 to 2026-11-01');
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|^ERROR|Tests '
      Tests  5 passed (5)
```
