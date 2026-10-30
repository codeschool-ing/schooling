---
title: Um Observable é uma função que ainda não foi chamada
version: 1
---

**Um Observable é a descrição de valores que vão chegar ao longo do tempo, e nada acontece até alguém
assiná-lo.** A aula 12 encontrou um sem se deter nele: o `http.patch` retornou um Observable, e o
pedido só saiu quando o `subscribe` foi chamado. O RxJS, a biblioteca que o Angular usa para eles,
vem instalado em todo projeto Angular; o `rxjs` está no `package.json` desde a aula 2.

Três coisas distinguem um Observable, e um bench mostra as três. Fazer um à mão mostra o que ele é:
uma função que recebe um **subscriber** e chama `next` nele com cada valor, e `complete` no fim.

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { Observable } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  template: '',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  constructor() {", "note": "`Observable` vem do `rxjs`, não do Angular."},
 {"code": "    const numbers = new Observable<number>((subscriber) => {\n      console.log('subscribed');\n      subscriber.next(1);\n      subscriber.next(2);\n      setTimeout(() => {\n        subscriber.next(3);\n        subscriber.complete();\n      }, 100);\n    });", "note": "A função lá dentro roda uma vez por assinante. Dois valores na hora, um terceiro um décimo de segundo depois, e depois o fim."},
 {"code": "    console.log('before subscribe');\n    numbers.subscribe({ next: (n) => console.log('got', n), complete: () => console.log('done') });\n    console.log('after subscribe');", "note": "O `subscribe` recebe um objeto com um callback para cada tipo de evento: um valor, um erro, o fim."},
 {"code": "    const planner = inject(HttpClient).get<PlannerData>('/api/planner');\n    planner.subscribe();\n    planner.subscribe();\n  }\n}", "note": "Um pedido descrito, e assinado duas vezes."}
]}
```

O bench entra no `App` ao lado das duas telas:

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
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --network --wait 1000
[vite] connecting...
[vite] connected.
before subscribe
subscribed
got 1
got 2
after subscribe
Angular is running in development mode.
net  GET /api/planner  200
net  GET /api/planner  200
net  GET /api/planner  200
got 3
done
```

**Ele é preguiçoso.** O `subscribed` vem depois do `before subscribe`: criar o Observable não rodou
nada, e a função lá dentro rodou quando o `subscribe` foi chamado. **Ele pode ser síncrono,
assíncrono ou os dois.** O `got 1` e o `got 2` chegaram antes de o `subscribe` sequer retornar, e o
`got 3` um instante depois, depois de todo o resto da página. **Ele é frio.** Três pedidos de
`/api/planner`, o do store e mais dois: cada `subscribe` rodou a função de novo, e num Observable do
`HttpClient` essa função manda um pedido. Dois assinantes são dois pedidos, o que é certo para um
pedido e surpreende na primeira vez que custa um segundo.

## Comparado com o que você já conhece

| | dá | quando começa | quantos valores | tem um valor atual |
|---|---|---|---|---|
| uma `Promise` | um valor, ou um erro | na hora, quando é criada | um | não |
| um `signal` | o valor de agora | sempre tem um | um por vez, cada um trocando o anterior | sim |
| um `Observable` | valores conforme acontecem, um erro, um fim | na assinatura, uma vez por assinante | nenhum, um, ou qualquer número | não |

Um signal responde "o que é agora". Um Observable responde "o que acontece, e quando". Os dados do
planner são o primeiro tipo de pergunta, e é por isso que as aulas 6 a 12 precisaram de tão pouco do
RxJS. O resto desta aula é o segundo tipo.
