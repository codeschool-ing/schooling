---
title: Optional, self, skipSelf e host
version: 1
---

**O `inject` aceita um segundo argumento que muda o caminho da pergunta pela árvore.** Por padrão ela
começa no injetor do próprio componente que pergunta, sobe até o topo, e lança `NG0201` se ninguém
responder. Quatro opções ajustam isso, e código mais antigo escreve cada uma como um decorator num
parâmetro do construtor, `@Optional()`, `@Self()`, `@SkipSelf()` e `@Host()`:

| opção | o que ela muda |
|---|---|
| `optional: true` | ninguém respondendo dá `null` em vez de um erro |
| `self: true` | pergunta só ao injetor do próprio componente |
| `skipSelf: true` | começa um nível acima, no injetor do pai |
| `host: true` | para no componente em cujo template este está |

Duas delas valem ser vistas juntas. O contador mantém o próprio `Tally` e pede um segundo com
`skipSelf`, que pula o próprio injetor, vai até a raiz, e acha o compartilhado. E ele pede uma nota
que ninguém fornece, com `optional`:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component, Injectable, InjectionToken, inject, input, signal } from '@angular/core';\n\nconst NOTE = new InjectionToken<string>('NOTE');\n\n@Injectable({ providedIn: 'root' })\nexport class Tally {\n  readonly count = signal(0);\n}\n\n@Component({\n  selector: 'app-counter',\n  providers: [Tally],\n  template: `\n    <p>{{ name() }}: {{ own.count() }}, all: {{ shared.count() }}, {{ note }}</p>\n    <button type=\"button\" (click)=\"add()\">Add to {{ name() }}</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Counter {\n  readonly name = input.required<string>();", "note": "Um token que ninguém fornece: sem `providedIn`, sem factory, em nenhuma lista."},
 {"code": "  protected readonly own = inject(Tally);\n  protected readonly shared = inject(Tally, { skipSelf: true });", "note": "O primeiro `Tally` vem dos `providers` do próprio contador. A segunda pergunta os pula e acha o da raiz."},
 {"code": "  protected readonly note = inject(NOTE, { optional: true }) ?? 'no note';\n\n  protected add(): void {\n    this.own.count.update((c) => c + 1);\n    this.shared.count.update((c) => c + 1);\n  }\n}", "note": "O `optional` transforma \"ninguém fornece isto\" em `null`, e o `??` dá um padrão."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Counter],\n  template: '<app-counter name=\"first\" /><app-counter name=\"second\" />',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {}"}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add to first' --do 'click Add to second'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add to first
-- click Add to second
first: 1, all: 2, no note

Add to first

second: 1, all: 2, no note

Add to second
```

O tally próprio de cada contador contou o próprio clique, e o compartilhado contou os dois. A nota
era `null`, e a página mostra o padrão.

**O `optional` é para uma dependência que é de fato opcional**, um recurso que pode ou não ter sido
configurado. Usado para calar um `NG0201` que não deveria ter acontecido, ele troca um erro alto no
começo por um `null` em algum lugar mais tarde, que é um lugar pior para descobrir. `self`,
`skipSelf` e `host` importam sobretudo para diretivas, assunto da aula 20, que precisam achar um
componente em particular em volta delas; em componentes, você vai mais é lê-los.
