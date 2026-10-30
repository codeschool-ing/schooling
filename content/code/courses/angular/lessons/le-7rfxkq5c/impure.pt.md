---
title: Pipes impuros, e o que eles custam
version: 1
---

**O `pure: false` faz o Angular chamar o `transform` em toda detecção de mudanças do componente,
quaisquer que sejam os argumentos.** É a correção para o total velho, e uma cara. Uma palavra muda no
pipe do bench:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Pipe, PipeTransform } from '@angular/core';

let calls = 0;

@Pipe({ name: 'total', pure: false })
export class TotalPipe implements PipeTransform {
  transform(values: number[]): number {
    calls++;
    console.log(`total ran, call ${calls}`);
    return values.reduce((sum, value) => sum + value, 0);
  }
}

@Component({
  selector: 'app-bench',
  imports: [TotalPipe],
  template: `
    <p>{{ minutes.join(' + ') }} = {{ minutes | total }}</p>
    <button type="button" (click)="push()">Push 10</button>
    <button type="button" (click)="replace()">Replace with 10 more</button>
    <button type="button" (click)="nothing()">Do nothing</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected minutes = [30, 60];

  protected push(): void {
    this.minutes.push(10);
  }

  protected replace(): void {
    this.minutes = [...this.minutes, 10];
  }

  protected nothing(): void {}
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Push 10' --do 'click Do nothing' --do 'click Do nothing'
[vite] connecting...
[vite] connected.
total ran, call 1
Angular is running in development mode.
-- click Push 10
total ran, call 2
-- click Do nothing
total ran, call 3
-- click Do nothing
total ran, call 4
30 + 60 + 10 = 100
```

O push agora é contado. E também todo clique que não mudou nada: o pipe rodou em cada conferência,
porque não tem como saber que nada mudou. Aqui ele soma três números. Um pipe que ordenasse mil
sessões as ordenaria a cada tecla em cada campo da página, e, com zone.js, a cada evento em qualquer
lugar, e é assim que pipes impuros deixam uma aplicação lenta sem ninguém ter escrito uma linha lenta.

**Os pipes impuros do próprio Angular são poucos e deliberados**: o `async`, que precisa procurar um
valor novo no Observable dele, e o `json`, o `slice` e o `keyvalue`, que recebem objetos que podem
mudar no lugar. Um pipe seu quase nunca precisa ser impuro; os dados que ele recebe devem ser
trocados, não mudados.
