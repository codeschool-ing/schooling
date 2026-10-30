---
title: Pipes puros, e o array que mudou no lugar
version: 1
---

**Um pipe é puro por padrão: o Angular só chama o `transform` de novo quando um argumento é um valor
diferente da última vez.** Para uma string ou um número isso quer dizer um valor diferente. Para um
objeto ou um array quer dizer um objeto diferente: o mesmo array com um item empurrado nele é, para o
Angular, o mesmo argumento, e a última resposta do pipe é mostrada de novo sem perguntar. É isso que
torna pipes puros baratos, e é a única armadilha deles.

Um bench com um pipe que soma uma lista, e registra toda vez que roda:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport { ChangeDetectionStrategy, Component, Pipe, PipeTransform } from '@angular/core';\n\nlet calls = 0;\n\n@Pipe({ name: 'total' })\nexport class TotalPipe implements PipeTransform {\n  transform(values: number[]): number {\n    calls++;\n    console.log(`total ran, call ${calls}`);\n    return values.reduce((sum, value) => sum + value, 0);\n  }\n}", "note": "Um pipe pode morar no mesmo arquivo do componente que o usa. Este conta as próprias chamadas."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [TotalPipe],\n  template: `\n    <p>{{ minutes.join(' + ') }} = {{ minutes | total }}</p>\n    <button type=\"button\" (click)=\"push()\">Push 10</button>\n    <button type=\"button\" (click)=\"replace()\">Replace with 10 more</button>\n    <button type=\"button\" (click)=\"nothing()\">Do nothing</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  protected minutes = [30, 60];\n\n  protected push(): void {\n    this.minutes.push(10);\n  }\n\n  protected replace(): void {\n    this.minutes = [...this.minutes, 10];\n  }\n\n  protected nothing(): void {}\n}", "note": "O `minutes` é um array comum de propósito. O `push` o muda no lugar; o `replace` faz um novo."}
]}
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<nav aria-label="Planner">
  <a routerLink="/" routerLinkActive="current" [routerLinkActiveOptions]="{ exact: true }" ariaCurrentWhenActive="page">This week</a>
</nav>
<main>
  <router-outlet />
</main>
<app-bench />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink, RouterLinkActive, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Push 10'
[vite] connecting...
[vite] connected.
total ran, call 1
Angular is running in development mode.
-- click Push 10
30 + 60 + 10 = 90
```

**`30 + 60 + 10 = 90`.** O clique rodou a detecção de mudanças no bench, então o `join` rodou de novo e
mostra três números, e o pipe não, porque o `minutes` era o mesmo array. A página agora se contradiz,
sem erro em lugar nenhum.

```
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Replace with 10 more'
[vite] connecting...
[vite] connected.
total ran, call 1
Angular is running in development mode.
-- click Replace with 10 more
total ran, call 2
30 + 60 + 10 = 100
```

Um array novo, e o pipe rodou de novo: uma vez para o primeiro desenho, uma vez para o array novo.
**Dê a um pipe puro um valor novo quando o valor muda**, que é o que o planner faz desde sempre: os
signals da aula 6, o `update` do store com um espalhamento, o `map` da aula 11 retornando sessões
novas. Código que muda no lugar é o código em que pipes puros ficam velhos.
