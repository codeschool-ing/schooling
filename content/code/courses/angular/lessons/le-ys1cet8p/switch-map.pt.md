---
title: Uma caixa de busca, e para que serve o switchMap
version: 1
---

**Uma caixa de busca é o problema em que o RxJS é melhor: um fluxo de teclas, cada uma podendo
começar um pedido, onde só a resposta à última importa.** Signals guardam bem o valor mais recente,
e não têm nada a dizer sobre o tempo: quanto esperar, o que fazer com um pedido que já está a caminho
quando chega a próxima tecla.

O bench ganha um campo para achar um curso pelo nome. A busca é um signal, como qualquer estado; o
`toObservable` a transforma num Observable dos valores dela, e o `toSignal` transforma a ponta da
cadeia de volta num signal que o template pode ler. Os dois vêm do `@angular/core/rxjs-interop`, a
ponte do Angular entre os dois:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';\nimport { toObservable, toSignal } from '@angular/core/rxjs-interop';\nimport { map, switchMap } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  template: `\n    <label for=\"find\">Find a course</label>\n    <input id=\"find\" [value]=\"query()\" (input)=\"query.set($any($event.target).value)\" />\n    <p>{{ found()?.join(', ') ?? 'nothing yet' }}</p>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  private readonly http = inject(HttpClient);\n  protected readonly query = signal('');", "note": "O `$any` diz ao compilador de templates para aceitar o `$event.target` sem o tipo dele: é um input, e esse é o jeito mais curto de dizer isso num template."},
 {"code": "  protected readonly found = toSignal(\n    toObservable(this.query).pipe(\n      switchMap((q) =>\n        this.http.get<PlannerData>('/api/planner').pipe(\n          map((data) => data.courses.filter((c) => c.name.toLowerCase().includes(q.toLowerCase())).map((c) => c.name)),\n        ),\n      ),\n    ),\n  );\n}", "note": "Todo valor da busca vira um pedido, e toda resposta vira os nomes que batem. O `toSignal` assina, e cancela quando o bench é destruído; até a primeira resposta, o valor dele é `undefined`."}
]}
```

O `--wait 100` deixa passar um décimo de segundo entre as ações, mais ou menos a velocidade de quem
digita. O `fill` põe um `J` na caixa, e o `press` digita mais duas letras:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --network --wait 100 --do 'fill Find a course = J' --do 'press a' --do 'press v'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
net  GET /api/planner  200
-- fill Find a course = J
net  GET /api/planner  200
-- press a
net  GET /api/planner  200
-- press v
net  GET /api/planner  200
Find a course

JavaScript
```

Um pedido para cada valor que a busca teve, o vazio do começo incluído, para uma resposta de que só o
último precisava. Uma API de verdade buscando num catálogo de verdade faria o trabalho quatro vezes.

## Esperando uma pausa

O `debounceTime(300)` segura cada valor por 300 milissegundos e só o repassa se nenhum outro valor
tiver chegado nesse meio-tempo. Um operador, antes do `switchMap`:

```typescript
// src/app/bench/bench.ts
import { HttpClient } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, signal } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { debounceTime, map, switchMap } from 'rxjs';
import { PlannerData } from '../planner';

@Component({
  selector: 'app-bench',
  template: `
    <label for="find">Find a course</label>
    <input id="find" [value]="query()" (input)="query.set($any($event.target).value)" />
    <p>{{ found()?.join(', ') ?? 'nothing yet' }}</p>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly http = inject(HttpClient);
  protected readonly query = signal('');
  protected readonly found = toSignal(
    toObservable(this.query).pipe(
      debounceTime(300),
      switchMap((q) =>
        this.http.get<PlannerData>('/api/planner').pipe(
          map((data) => data.courses.filter((c) => c.name.toLowerCase().includes(q.toLowerCase())).map((c) => c.name)),
        ),
      ),
    ),
  );
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --network --wait 100 --do 'fill Find a course = J' --do 'press a' --do 'press v' --do 'wait 600'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- fill Find a course = J
-- press a
-- press v
-- wait 600
net  GET /api/planner  200
Find a course

JavaScript
```

Um pedido, fora o do store, mandado 300 milissegundos depois da última tecla.

## Por que switchMap e não um dos primos

Cada um dos quatro operadores `...Map` transforma um valor num Observable interno, aqui um pedido.
Eles diferem no que fazem quando chega um valor novo enquanto o último pedido ainda está em andamento:

| operador | um valor novo com um pedido em andamento | certo para |
|---|---|---|
| `switchMap` | cancela o pedido velho e começa o novo | uma busca, onde uma resposta velha é uma resposta errada |
| `mergeMap` | começa o novo e mantém os dois | trabalho independente, onde toda resposta conta |
| `concatMap` | espera o velho terminar, depois começa o novo | escritas que precisam acontecer em ordem |
| `exhaustMap` | ignora o valor novo até o velho terminar | um botão de enviar apertado duas vezes |

A API local responde em milissegundos, então nada acima chegou a ser ultrapassado. Numa rede de
verdade isso acontece: o pedido para `Ja` é lento, o para `Jav` é rápido, e com `mergeMap` a resposta
lenta chega por último e a tela mostra os resultados de `Ja` sob uma caixa que diz `Jav`. O
`switchMap` torna isso impossível, porque o pedido para `Ja` foi cancelado quando o `Jav` chegou.
