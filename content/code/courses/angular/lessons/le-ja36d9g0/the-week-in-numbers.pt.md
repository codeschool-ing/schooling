---
title: A semana, em números
version: 1
---

**De volta ao planner, com o que a bancada ensinou.** O resumo da semana recebe os dois números da
aula 1, 165 minutos planejados e 90 feitos, e uma barra de progresso desenhada com um property
binding. Os números estão escritos na classe por enquanto; a aula 6 os calcula a partir dos dados.

```typescript
// src/app/week-summary/week-summary.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly planned = 165;
  protected readonly done = 90;
}
```

`readonly`, porque nada no componente deve mudá-los: o template os lê e nada os escreve. A aula 1
prometeu que o código Angular poria `protected` e `readonly` em quase todo campo que um template lê, e
aqui está o primeiro par.

```html
<!-- src/app/week-summary/week-summary.html -->
<p>{{ planned }} minutes planned, {{ done }} done.</p>
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done" [max]="planned"></progress>
```

Um elemento `<progress>` é a barra de progresso do próprio navegador, com o papel que um leitor de
tela anuncia como tal, e o rótulo dela vem do `<label>` ao lado. A bancada não é mais necessária.
Apague a pasta dela, e tire-a do `App` de novo:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<app-week />
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
(nothing on the page matches main)
```

O `look --a11y main` não achou nenhum `main`, e diz isso. A página ainda não tem marco: quem chega
aqui com um leitor de tela não tem como saltar para o conteúdo, que é uma das primeiras coisas que uma
verificação de acessibilidade aponta. Envolva a semana num:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
</main>
<router-outlet />
```

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y main
[vite] connecting...
[vite] connected.
Angular is running in development mode.
- main
  - heading "This week" [level=2]
  - paragraph
    - text: 165 minutes planned, 90 done.
  - LabelText
    - text: Done this week
  - progressbar "Done this week": 90
```

O `<label>` virou o nome da barra de progresso, `Done this week`, e o valor dela é 90, que um leitor de
tela anuncia em relação ao máximo que o binding definiu, 165. Os testes continuam passando, e o planner
vai para um commit:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Bindings: the week's numbers and its progress bar"
```
