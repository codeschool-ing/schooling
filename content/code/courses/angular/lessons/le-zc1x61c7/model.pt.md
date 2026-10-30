---
title: model, quando um valor vai nos dois sentidos
version: 1
---

**O `model()` declara um valor que o pai passa para baixo e o filho pode mudar, e a mudança volta para
o signal do pai.** É um input e um output num só, e o template faz o binding com os dois tipos de
parênteses ao mesmo tempo, `[(value)]="signal"`, que as pessoas chamam de banana na caixa. Ele serve a
um componente que se comporta como um controle de formulário: um stepper, um toggle, um seletor de
data, em que o pai entrega um valor e o quer de volta editado.

O planner ainda não tem um controle assim, então isto é uma bancada, gerada com o template no próprio
arquivo:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, model, signal } from '@angular/core';

@Component({
  selector: 'app-stepper',
  template: `
    <button type="button" (click)="value.update((v) => v - 5)">5 fewer</button>
    {{ value() }} minutes
    <button type="button" (click)="value.update((v) => v + 5)">5 more</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Stepper {
  readonly value = model(30);
}

@Component({
  selector: 'app-bench',
  imports: [Stepper],
  template: `
    <h2>Bench</h2>
    <app-stepper [(value)]="minutes" />
    <p>The bench holds {{ minutes() }}.</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly minutes = signal(45);
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
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click 5 more' --do 'click 5 more'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click 5 more
-- click 5 more
Bench
5 fewer 55 minutes 5 more

The bench holds 55.
```

O `minutes` da bancada começou em 45, que substituiu o padrão de 30 do próprio stepper, e dois cliques
dentro do stepper levaram o signal da bancada a 55. **O filho escreveu, e o valor do pai mudou.**
`[(value)]="minutes"` é abreviação de `[value]="minutes()"` mais `(valueChange)="minutes.set($event)"`:
o `model` declara o output `valueChange` para você.

## Quando não usar

O binding nos dois sentidos esconde quem é dono do valor: o pai guarda o signal, e o filho o muda. Para
um controle, esse é o objetivo. Para as sessões do planner seria errado: uma linha que definisse o
`done` diretamente nos dados do pai passaria por cima do dono, que o output da seção anterior manteve no
comando. **Use o `model` para o valor de um controle, e um input com um output para dados que pertencem a
alguém.**
