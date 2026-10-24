---
title: ngModel, e um formulário que vive no template
version: 1
---

**Um formulário template-driven é construído pelo template: cada `ngModel` num input faz um controle,
e o `<form>` os reúne.** Não há `FormGroup` na classe. A classe guarda valores simples, aqui dois
signals, e o `[(ngModel)]` mantém cada input e o seu valor em sincronia nos dois sentidos. É como os
formulários Angular eram escritos antes de os reativos existirem, continua suportado, e muito código
que você vai encontrar o usa, muitas vezes em formulários pequenos onde ele se lê com naturalidade.

Um bench, para os mesmos dois campos com que a aula 14 começou. Os labels dele dizem `Day` e `Length
in minutes`, para não serem confundidos com os do formulário de verdade na mesma página:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-bench',
  imports: [FormsModule],
  template: `
    <form>
      <label for="t-day">Day</label>
      <input id="t-day" type="date" name="date" [(ngModel)]="date" />
      <label for="t-minutes">Length in minutes</label>
      <input id="t-minutes" type="number" name="minutes" [(ngModel)]="minutes" />
    </form>
    <p>{{ date() }}, {{ minutes() }} minutes</p>
  `,
  styles: `
    form {
      display: grid;
      gap: 0.5rem;
      max-width: 20rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly date = signal('');
  protected readonly minutes = signal(30);
}
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Day = 2026-10-26' --do 'fill Length in minutes = 45'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Day = 2026-10-26
-- fill Length in minutes = 45
Day
Length in minutes

2026-10-26, 45 minutes
```

**O `[( )]` são duas ligações numa só**: `[ngModel]="date()"` define o input a partir do signal, e o
`(ngModelChange)` define o signal a partir do input. Escrito com um signal, o Angular o lê na ida e
chama `set` na volta. Dentro de um `<form>`, todo `ngModel` precisa de um `name`, que é a chave que o
valor dele tem no valor do formulário; deixá-lo de fora é um erro em tempo de execução, a primeira
coisa que todo mundo encontra com esse tipo de formulário.
