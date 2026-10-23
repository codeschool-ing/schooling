---
title: Escolhendo com @switch, e o case que ninguém escreveu
version: 1
---

**`@switch (valor)` desenha o único `@case` cujo valor combina, ou o `@default` quando nenhum
combina.** É o `@if` para um valor com várias possibilidades conhecidas, e o planner tem um: uma
sessão está feita, perdida ou ainda planejada. Ponha um status na bancada:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

type Status = 'done' | 'missed' | 'planned';

@Component({
  selector: 'app-bench',
  imports: [],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected status: Status = 'missed';
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
@switch (status) {
  @case ('done') {
    <p>Done.</p>
  }
  @case ('missed') {
    <p>Missed: the date has passed.</p>
  }
  @default {
    <p>Planned.</p>
  }
}
<button type="button" (click)="status = 'done'">Mark done</button>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Mark done'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Mark done
Bench

Done.

Mark done
```

A comparação usa `===`, então `@case ('Done')` nunca combinaria com `'done'`, e não há passagem de um
case para o seguinte: exatamente um bloco é desenhado.

## Quando o default não deveria existir

O `@default` pega um valor para o qual ninguém escreveu um case. Isso é uma rede de segurança, e
também um lugar onde um status novo pode se esconder. Acrescente `'skipped'` ao `Status` no mês que
vem, e o `@default` desenha "Planned." para toda sessão pulada sem dizer nada. O Angular 21 pode
transformar isso num erro de build. Troque o default por `@default never;`, e acrescente o quarto
status que o tipo permite sem um case para ele:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
@switch (status) {
  @case ('done') {
    <p>Done.</p>
  }
  @case ('missed') {
    <p>Missed: the date has passed.</p>
  }
  @default never;
}
<button type="button" (click)="status = 'done'">Mark done</button>
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep ERROR
✘ [ERROR] TS2322: Type '"planned"' is not assignable to type 'never'. [plugin angular-compiler]
```

`never` é o tipo do TypeScript para "nenhum valor pode estar aqui", e o compilador conferiu que todo
valor que o tipo permite tem um case. `'planned'` não tinha, e o build o apontou. **Use
`@default never;` quando o tipo lista todas as possibilidades**, para que a próxima pessoa a
acrescentar uma fique sabendo onde desenhá-la.
