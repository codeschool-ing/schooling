---
title: Depois que o DOM é desenhado
version: 1
---

**O `afterNextRender` roda uma função uma vez, depois que o Angular escrever o DOM da próxima vez, e é
o lugar do código que precisa dos elementos existindo e dispostos: medir, focar, entregar um elemento a
uma biblioteca que desenha nele.** O `afterEveryRender` roda depois de cada escrita dessas. Os dois
substituem a maior parte dos usos do `ngAfterViewInit`, e os dois só rodam no navegador, o que importa na
aula 23, em que a página é desenhada primeiro num servidor que não tem layout nem foco.

```typescript
// src/app/bench/bench.ts
import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  afterNextRender,
  viewChild,
} from '@angular/core';

@Component({
  selector: 'app-bench',
  template: `
    <h2>Bench</h2>
    <p #para>A paragraph to measure.</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly para = viewChild.required<ElementRef<HTMLElement>>('para');

  constructor() {
    console.log('constructor: the paragraph exists?', document.querySelector('app-bench p') !== null);
    afterNextRender(() => {
      console.log('after render: it is', this.para().nativeElement.offsetHeight, 'pixels tall');
    });
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
constructor: the paragraph exists? false
after render: it is 18 pixels tall
Angular is running in development mode.
Bench

A paragraph to measure.
```

No construtor o parágrafo ainda não existe; depois da próxima renderização ele existe, disposto, com uma
altura que o navegador calculou. Ler o `offsetHeight` pede ao navegador que disponha a página, então faça
isso no `afterNextRender` e não num computed ou num template, onde rodaria durante uma conferência.

O `afterNextRender` também recebe fases, `earlyRead`, `write`, `mixedReadWrite` e `read`, para que código
que só lê o layout rode depois do código que o muda, e o navegador disponha a página uma vez e não uma
vez por componente. Você vai precisar delas quando dois componentes se medirem e se redimensionarem, e
não antes.
