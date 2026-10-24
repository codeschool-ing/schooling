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
tick 11
tick 12
tick 13
tick 14
tick 15
tick 16
tick 17
tick 18
tick 19
tick 20
tick 21
tick 22
tick 23
tick 24
tick 25
tick 26
tick 27
tick 28
tick 29
tick 30
tick 31
tick 32
tick 33
tick 34
tick 35
tick 36
tick 37
tick 38
tick 39
tick 40
tick 41
tick 42
tick 43
tick 44
tick 45
tick 46
tick 47
tick 48
tick 49
tick 50
tick 51
tick 52
tick 53
tick 54
tick 55
tick 56
tick 57
tick 58
tick 59
tick 60
tick 61
tick 62
tick 63
tick 64
tick 65
tick 66
tick 67
tick 68
tick 69
tick 70
tick 71
tick 72
tick 73
tick 74
tick 75
tick 76
tick 77
tick 78
tick 79
tick 80
tick 81
tick 82
tick 83
tick 84
tick 85
tick 86
tick 87
tick 88
tick 89
tick 90
tick 91
tick 92
tick 93
tick 94
tick 95
tick 96
tick 97
tick 98
tick 99
tick 100
tick 101
tick 102
tick 103
tick 104
tick 105
tick 106
tick 107
tick 108
tick 109
tick 110
tick 111
tick 112
tick 113
tick 114
tick 115
tick 116
tick 117
tick 118
tick 119
tick 120
tick 121
tick 122
tick 123
tick 124
tick 125
tick 126
tick 127
tick 128
tick 129
tick 130
tick 131
tick 132
tick 133
tick 134
tick 135
tick 136
tick 137
tick 138
tick 139
tick 140
tick 141
tick 142
tick 143
tick 144
tick 145
tick 146
tick 147
tick 148
tick 149
tick 150
tick 151
tick 152
tick 153
tick 154
tick 155
tick 156
tick 157
node:internal/modules/run_main:123
    triggerUncaughtException(
    ^

locator.click: Timeout 30000ms exceeded.
Call log:
  - waiting for getByRole('button', { name: 'Remove', exact: true }).or(getByRole('link', { name: 'Remove', exact: true })).first()
    - locator resolved to <button type="button">Remove</button>
  - attempting click action
    2 × waiting for element to be visible, enabled and stable
      - element is visible, enabled and stable
      - scrolling into view if needed
      - done scrolling
      - <vite-error-overlay></vite-error-overlay> intercepts pointer events
    - retrying click action
    - waiting 20ms
    2 × waiting for element to be visible, enabled and stable
      - element is visible, enabled and stable
      - scrolling into view if needed
      - done scrolling
      - <vite-error-overlay></vite-error-overlay> intercepts pointer events
    - retrying click action
      - waiting 100ms
    58 × waiting for element to be visible, enabled and stable
       - element is visible, enabled and stable
       - scrolling into view if needed
       - done scrolling
       - <vite-error-overlay></vite-error-overlay> intercepts pointer events
     - retrying click action
       - waiting 500ms

    at /home/ana/js-tools/look.mjs:133:69 {
  name: 'TimeoutError'
}

Node.js v22.22.0
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
