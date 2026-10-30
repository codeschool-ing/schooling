---
title: Qual injetor responde
version: 1
---

**Uma aplicação Angular tem uma árvore de injetores, não um, e uma pergunta sobe pela árvore até um
injetor ter uma receita para ela.** Todo componente tem um injetor próprio, feito da sua lista
`providers`; acima de todos fica o injetor raiz, feito do `app.config.ts` e de todo
`providedIn: 'root'`; acima dele, um injetor da plataforma compartilhado pela página inteira, e no
topo um último que responde qualquer coisa lançando `NG0201`. Onde uma receita fica decide quem
compartilha o que ela faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"A árvore de injetores, de cima para baixo. NullInjector, que responde qualquer pergunta lançando NG0201. Abaixo dele o injetor da plataforma, compartilhado pela página. Abaixo, o injetor raiz, feito do app.config.ts e de todo providedIn root. Abaixo, um injetor por componente: App, depois Bench, depois dois Counters, cada um pedindo um Tally. Uma seta tracejada sai de um Counter e sobe: inject(Tally) começa no injetor do próprio Counter, passa por todo injetor sem receita para ele, e o injetor raiz responde.\"><rect x=\"150\" y=\"16\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"300.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">NullInjector</text><text x=\"300.0\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">responde tudo lançando NG0201</text><rect x=\"150\" y=\"82\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">injetor da plataforma</text><text x=\"300.0\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">compartilhado pela página inteira</text><rect x=\"150\" y=\"148\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">injetor raiz</text><text x=\"300.0\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app.config.ts · providedIn: 'root'</text><line x1=\"300.0\" y1=\"82\" x2=\"300.0\" y2=\"62\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,62.0 303.1,69.4 296.9,69.4\" fill=\"var(--wire)\"></polygon><line x1=\"300.0\" y1=\"148\" x2=\"300.0\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,128.0 303.1,135.4 296.9,135.4\" fill=\"var(--wire)\"></polygon><text x=\"210\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">um por componente</text><rect x=\"225\" y=\"214\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"300.0\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os providers dele</text><rect x=\"225\" y=\"270\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"285\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Bench</text><text x=\"300.0\" y=\"301\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os providers dele</text><rect x=\"120\" y=\"326\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"341\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Counter</text><text x=\"205.0\" y=\"357\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pede um Tally</text><rect x=\"310\" y=\"326\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"341\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Counter</text><text x=\"395.0\" y=\"357\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">pede um Tally</text><line x1=\"300.0\" y1=\"212\" x2=\"300.0\" y2=\"194\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,194.0 303.1,201.4 296.9,201.4\" fill=\"var(--wire)\"></polygon><line x1=\"300.0\" y1=\"268\" x2=\"300.0\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,256.0 303.1,263.4 296.9,263.4\" fill=\"var(--wire)\"></polygon><line x1=\"205\" y1=\"324\" x2=\"260\" y2=\"312\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,312.0 253.5,316.6 252.1,310.5\" fill=\"var(--wire)\"></polygon><line x1=\"395\" y1=\"324\" x2=\"340\" y2=\"312\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"340.0,312.0 347.9,310.5 346.5,316.6\" fill=\"var(--wire)\"></polygon><path d=\"M 480 346 L 520 346 L 520 170 L 454 170\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></path><line x1=\"464\" y1=\"170\" x2=\"454\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"454.0,170.0 461.4,166.9 461.4,173.1\" fill=\"var(--amber)\"></polygon><text x=\"532\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">inject(Tally)</text><text x=\"532\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">começa no do próprio Counter,</text><text x=\"532\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passa por todo injetor sem receita,</text><text x=\"532\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e o raiz responde</text></svg>", "caption": "Uma pergunta começa no componente que pergunta e sobe; o primeiro injetor com uma receita responde, e o do topo responde com um erro."}
```

Os greeters estão para sair, então o `app.config.ts` volta primeiro ao que o git tem:

```
ana@dev:~/planner$ git checkout -- src/app/app.config.ts
```

Um contador mostra a árvore funcionando. O `Tally` guarda um número num signal, e o `Counter` mostra
um tally e soma a ele. O bench põe dois contadores lado a lado:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, input, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-counter',
  template: `
    <p>{{ name() }}: {{ tally.count() }}</p>
    <button type="button" (click)="tally.count.set(tally.count() + 1)">Add to {{ name() }}</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Counter {
  readonly name = input.required<string>();
  protected readonly tally = inject(Tally);
}

@Component({
  selector: 'app-bench',
  imports: [Counter],
  template: '<app-counter name="first" /><app-counter name="second" />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add to first'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add to first
first: 1

Add to first

second: 1

Add to second
```

Um clique, e os dois contadores dizem 1. Nem o injetor de um contador nem o do outro tem uma receita
para `Tally`, nem o do bench, então as duas perguntas subiram até a raiz, que fez um `Tally` e o deu
aos dois. É isso que `providedIn: 'root'` quer dizer: uma instância para a aplicação inteira.

## Uma receita mais embaixo

Dê ao `Counter` uma lista `providers` própria e o injetor dele tem a receita, então a pergunta para
ali. Uma linha muda, no decorator do `Counter`:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject, input, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Tally {
  readonly count = signal(0);
}

@Component({
  selector: 'app-counter',
  providers: [Tally],
  template: `
    <p>{{ name() }}: {{ tally.count() }}</p>
    <button type="button" (click)="tally.count.set(tally.count() + 1)">Add to {{ name() }}</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Counter {
  readonly name = input.required<string>();
  protected readonly tally = inject(Tally);
}

@Component({
  selector: 'app-bench',
  imports: [Counter],
  template: '<app-counter name="first" /><app-counter name="second" />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add to first'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add to first
first: 1

Add to first

second: 0

Add to second
```

Agora cada contador tem um `Tally` só dele, feito quando o contador é feito e jogado fora quando ele
é destruído. O `Tally` da raiz ainda existe como receita, e ninguém chega a ele, porque toda pergunta
para um nível abaixo.

| onde a receita fica | quem compartilha uma instância | quanto tempo ela vive |
|---|---|---|
| `providedIn: 'root'`, ou o `app.config.ts` | a aplicação inteira | enquanto a aplicação durar |
| os `providers` de um componente | esse componente e tudo dentro do template dele | enquanto esse componente durar |
| os `providers` de um teste | tudo o que o teste constrói | um teste |

**É nessa decisão que a aula 11 se apoia.** O `Week` e o `CoursePage` carregam cada um os dados do
planner para si, então marcar uma sessão como feita na página do curso deixa o total da semana onde
estava: duas cópias que discordam. Uma instância na raiz, pedida pelas duas, é uma cópia só.
