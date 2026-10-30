---
title: Limpando quando um componente sai
version: 1
---

**Quando um componente é destruído, tudo o que ele iniciou fora do Angular continua andando, a não ser
que ele o pare: um timer, um ouvinte no `window`, uma conexão.** O `@if` que removeu o `Life` na primeira
seção destruiu o componente; ele não parou os timers nem os ouvintes que o componente tinha iniciado,
porque o Angular não sabe deles. Um componente que inicia um relógio mostra o vazamento:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';

@Component({
  selector: 'app-clock',
  template: '<p>clock: {{ ticks() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Clock {
  protected readonly ticks = signal(0);

  constructor() {
    setInterval(() => {
      this.ticks.update((t) => t + 1);
      console.log('tick', this.ticks());
    }, 200);
  }
}

@Component({
  selector: 'app-bench',
  imports: [Clock],
  template: `
    <h2>Bench</h2>
    <button type="button" (click)="shown.set(false)">Remove</button>
    @if (shown()) {
      <app-clock />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly shown = signal(true);
}
```

O `--do 'wait 500'` deixa passar meio segundo entre as ações:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'wait 500' --do 'click Remove' --do 'wait 500'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
tick 1
tick 2
-- wait 500
tick 3
tick 4
tick 5
tick 6
tick 7
-- click Remove
tick 8
tick 9
tick 10
-- wait 500
tick 11
tick 12
tick 13
tick 14
tick 15
Bench
Remove
```

O relógio saiu da página, e o intervalo dele continuou batendo para um componente que não existe mais,
mantendo-o na memória para que nunca possa ser recolhido. Faça isso num componente mostrado numa lista,
e toda vez que a lista mudar outro intervalo começa e nenhum para.

## DestroyRef

O `inject(DestroyRef)` dá ao componente o objeto que o Angular chama quando ele é destruído, e o
`onDestroy` registra o que rodar então:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, DestroyRef, inject, signal } from '@angular/core';

@Component({
  selector: 'app-clock',
  template: '<p>clock: {{ ticks() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Clock {
  protected readonly ticks = signal(0);

  constructor() {
    const id = setInterval(() => {
      this.ticks.update((t) => t + 1);
      console.log('tick', this.ticks());
    }, 200);
    inject(DestroyRef).onDestroy(() => {
      clearInterval(id);
      console.log('clock stopped');
    });
  }
}

@Component({
  selector: 'app-bench',
  imports: [Clock],
  template: `
    <h2>Bench</h2>
    <button type="button" (click)="shown.set(false)">Remove</button>
    @if (shown()) {
      <app-clock />
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly shown = signal(true);
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'wait 500' --do 'click Remove' --do 'wait 500'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
tick 1
tick 2
-- wait 500
tick 3
tick 4
tick 5
tick 6
tick 7
-- click Remove
clock stopped
-- wait 500
Bench
Remove
```

A limpeza fica escrita ao lado do que ela limpa, no construtor, o que é mais fácil de manter certo do que
um início no `ngOnInit` e uma parada num método `ngOnDestroy` separado. O `inject` é o assunto da aula
10; aqui basta saber que ele entrega ao componente coisas que o Angular guarda para ele. **O que o Angular
iniciou, o Angular para**: effects, requisições de `resource` e as assinaturas do pipe `async` terminam
junto com o componente sozinhas. O que você iniciou com uma API do navegador é seu.
