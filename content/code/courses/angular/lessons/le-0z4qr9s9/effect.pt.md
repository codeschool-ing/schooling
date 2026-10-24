---
title: effect, para o que um signal faz com o mundo de fora
version: 1
---

**`effect(() => …)` roda uma função sempre que os signals que ela leu da última vez mudam, e serve para
o único trabalho que um `computed` não faz: agir sobre algo fora do Angular.** Gravar no
`localStorage`, definir o título da página, registrar em log, desenhar num canvas. Se a função
*devolve* um valor de que alguém precisa, é um `computed`; um effect não devolve nada.

Um effect pertence a algo que tem um tempo de vida, então ele é criado num componente, nos campos da
classe ou no construtor dela, e para quando o componente é destruído. Dê ao resumo da semana um effect
que registra os números, para vê-lo rodar:

```typescript
// src/app/week-summary/week-summary.ts
import { Component, effect, signal } from '@angular/core';

@Component({
  selector: 'app-week-summary',
  imports: [],
  templateUrl: './week-summary.html',
  styleUrl: './week-summary.css',
})
export class WeekSummary {
  protected readonly planned = signal(165);
  protected readonly done = signal(90);

  constructor() {
    effect(() => {
      console.log(`effect: ${this.done()} of ${this.planned()} minutes done`);
    });
  }

  protected markOne(): void {
    this.done.update((d) => d + 15);
  }
}
```

O template lê os signals com parênteses agora, e ganha um botão para mudar um deles:

```html
<!-- src/app/week-summary/week-summary.html -->
@let left = planned() - done();
<p>{{ planned() }} minutes planned, {{ done() }} done.</p>
@if (left <= 0) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ left }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done()" [max]="planned()"></progress>
<button type="button" (click)="markOne()">Mark 15 minutes done</button>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary --do 'click Mark 15 minutes done' --do 'click Mark 15 minutes done'
[vite] connecting...
[vite] connected.
effect: 90 of 165 minutes done
Angular is running in development mode.
-- click Mark 15 minutes done
effect: 105 of 165 minutes done
-- click Mark 15 minutes done
effect: 120 of 165 minutes done
165 minutes planned, 120 done.

45 minutes to go.

Done this weekMark 15 minutes done
```

O effect rodou uma vez quando o componente foi criado, e uma vez depois de cada clique. **Ele não roda
no momento da mudança.** O Angular agenda os effects e os roda juntos, depois da mudança e antes de a
página ser desenhada, então duas mudanças seguidas produzem uma execução, com as duas aplicadas.

## Para o que um effect não serve

O erro a evitar é um effect que define outro signal:

```typescript
effect(() => {
  this.left.set(this.planned() - this.done());
});
```

Funciona, de certo modo: `left` fica errado entre a mudança e a execução do effect, e o valor passa a
ter duas fontes de verdade, os signals e o effect que os copia. `computed(() => this.planned() -
this.done())` é a mesma coisa, sempre certa, sem nada para agendar. **Se você está escrevendo num signal
dentro de um effect, procure o computed que você queria.**

O effect de log e o botão eram para observar; a próxima seção troca os dois. Os effects que ficam neste
curso são poucos: um na aula 22 salva uma preferência no `localStorage`, que é exatamente o mundo de fora
para o qual um effect existe.
