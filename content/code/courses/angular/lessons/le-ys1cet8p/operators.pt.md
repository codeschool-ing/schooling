---
title: Operadores, e os poucos que valem a pena
version: 1
---

**Um operador recebe um Observable e retorna um novo, e o `pipe` os encadeia na ordem em que os
valores passam.** O `map` muda cada valor, o `filter` deixa alguns passarem, o `take(3)` termina
depois de três. Nenhum deles muda o Observable que recebeu; cada um o embrulha, e nada roda até a
ponta da cadeia ser assinada.

O `interval(100)` conta 0, 1, 2 e assim por diante, um número a cada décimo de segundo, para sempre.
Uma cadeia que faz dele algo finito, e uma segunda cadeia sobre um pedido, que é de onde vem a maior
parte dos Observables de uma aplicação:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { filter, interval, map, take } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  template: '',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  constructor() {"},
 {"code": "    interval(100)\n      .pipe(\n        map((n) => n * 10),\n        filter((n) => n % 20 === 0),\n        take(3),\n      )\n      .subscribe({ next: (n) => console.log('tick', n), complete: () => console.log('ticks done') });", "note": "Cada operador vê o que o de cima deixou passar. O `take(3)` termina a cadeia inteira, e é isso que para o `interval`."},
 {"code": "    inject(HttpClient)\n      .get<PlannerData>('/api/planner')\n      .pipe(\n        map((data) => data.sessions.filter((s) => !s.done)),\n        map((left) => left.length),\n      )\n      .subscribe((n) => console.log('sessions left to do:', n));\n  }\n}", "note": "Os mesmos operadores sobre um pedido: do planner às sessões não feitas, e a quantas são."}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --wait 1000
[vite] connecting...
[vite] connected.
Angular is running in development mode.
sessions left to do: 3
tick 0
tick 20
tick 40
ticks done
```

O pedido respondeu primeiro, em poucos milissegundos. Os ticks vieram em 0, 20 e 40: o `map` fez 0,
10, 20, 30, 40 dos cinco primeiros números, o `filter` descartou o 10 e o 30, e o `take` parou no
terceiro valor que chegou a ele. Um diagrama de valores ao longo do tempo, uma linha por etapa, é
como o RxJS documenta todo operador, e vale saber lê-lo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um diagrama de bolinhas com quatro linhas, o tempo correndo da esquerda para a direita. interval(100) emite 0, 1, 2, 3 e 4, um a cada décimo de segundo. Depois de map(n =&gt; n * 10): 0, 10, 20, 30, 40, nos mesmos momentos. Depois de filter(n =&gt; n % 20 === 0): 0, 20 e 40; o 10 e o 30 somem. Depois de take(3): 0, 20 e 40, e uma barra onde a cadeia termina, no momento em que o 40 chega.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">interval(100)</text><line x1=\"300\" y1=\"40\" x2=\"670\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,40.0 662.6,43.1 662.6,36.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"316\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"386\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"456\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"526\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"596\" y=\"28\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">map(n =&gt; n * 10)</text><line x1=\"300\" y1=\"92\" x2=\"670\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,92.0 662.6,95.1 662.6,88.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"316\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"386\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10</text><rect x=\"456\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"526\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30</text><rect x=\"596\" y=\"80\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"20\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">filter(n =&gt; n % 20 === 0)</text><line x1=\"300\" y1=\"144\" x2=\"670\" y2=\"144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"670.0,144.0 662.6,147.1 662.6,140.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"316\" y=\"132\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"456\" y=\"132\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"596\" y=\"132\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">take(3)</text><line x1=\"300\" y1=\"196\" x2=\"610\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"628\" y1=\"184\" x2=\"628\" y2=\"208\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><rect x=\"316\" y=\"184\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><rect x=\"456\" y=\"184\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">20</text><rect x=\"596\" y=\"184\" width=\"28\" height=\"24\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"640\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">fim</text><text x=\"470\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo →</text></svg>", "caption": "Cada linha é o que uma etapa deixa passar; o take(3) termina a cadeia no terceiro valor, o que para o interval também."}
```

## Os que vale conhecer

O RxJS tem mais de cem operadores. A maioria das aplicações usa uns dez, e são estes:

| operador | o que faz | onde vale a pena |
|---|---|---|
| `map` | transforma cada valor em outro | moldar uma resposta no que uma tela precisa |
| `filter` | deixa passar os valores que passam num teste | ignorar eventos que não importam |
| `tap` | roda algo para cada valor, e o repassa sem mudar | uma linha de log no meio de uma cadeia |
| `take` | termina depois de um número de valores | uma resposta de algo que continua |
| `debounceTime` | espera uma pausa antes de repassar o último valor | uma caixa de busca, para não mandar um pedido a cada tecla |
| `distinctUntilChanged` | descarta um valor igual ao anterior | não fazer a mesma pergunta duas vezes seguidas |
| `switchMap` | transforma cada valor num Observable novo e fica só com o mais novo | um pedido por busca, onde só a última resposta importa |
| `catchError` | troca um erro por outra coisa | um valor de reserva em vez de uma tela quebrada |
| `retry` | assina de novo depois de um erro | um pedido que pode dar certo na segunda vez |
| `combineLatest` | o último valor de vários, sempre que um muda | uma tela feita de duas fontes |

A próxima seção junta três deles, do jeito que uma caixa de busca faz.
