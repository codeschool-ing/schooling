---
title: zone.js, e conferir tudo depois de tudo
version: 1
---

**Durante os primeiros oito anos, o Angular respondeu o "quando" com uma biblioteca chamada zone.js:
ela envolvia toda coisa assíncrona que o navegador sabe fazer, e depois que qualquer uma terminava, o
Angular percorria a árvore inteira.** Um clique, um timer, a resposta de um servidor, uma promise
resolvida: o zone.js sabia, porque tinha trocado o `setTimeout`, o `addEventListener`, o `fetch` e o
resto por versões que avisam o Angular quando o callback delas rodou. Ninguém precisava dizer que algo
mudou, porque o Angular supunha que algo podia ter mudado, toda vez.

A maioria das aplicações Angular em produção ainda funciona assim, então vale ver. O planner não usa
zone.js, e acrescentá-lo são três mudanças. Primeiro, a bancada, agora com três pequenos componentes,
cada um com um contador que um timer muda de 0 para 1:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component, signal } from '@angular/core';\n\n@Component({\n  selector: 'app-tick',\n  template: '<p>default, plain field: {{ count }}</p>',\n})\nexport class Tick {\n  protected count = 0;\n  constructor() {\n    setTimeout(() => (this.count = 1), 300);\n  }\n}", "note": "Um componente como se escrevia antes dos signals: um campo comum, definido por um timer depois de 300 milissegundos."},
 {"code": "@Component({\n  selector: 'app-tick-onpush',\n  template: '<p>OnPush, plain field: {{ count }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class TickOnPush {\n  protected count = 0;\n  constructor() {\n    setTimeout(() => (this.count = 1), 300);\n  }\n}", "note": "O mesmo componente, com `changeDetection: ChangeDetectionStrategy.OnPush`, que a próxima seção explica."},
 {"code": "@Component({\n  selector: 'app-tick-signal',\n  template: '<p>OnPush, signal: {{ count() }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class TickSignal {\n  protected readonly count = signal(0);\n  constructor() {\n    setTimeout(() => this.count.set(1), 100);\n  }\n}", "note": "OnPush também, com o contador num signal, definido mais cedo, aos 100 milissegundos."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Tick, TickOnPush, TickSignal],\n  template: '<h2>Bench</h2><app-tick /><app-tick-onpush /><app-tick-signal />',\n})\nexport class Bench {}", "note": "A bancada mostra os três."}
]}
```

Faça o commit, para o próximo passo poder ser desfeito com exatidão:

```
ana@dev:~/planner$ git add -A && git commit -q -m "A bench for change detection"
```

Depois o próprio zone.js, na versão que o Angular 21 aceita:

```
ana@dev:~/planner$ npm install zone.js@0.16.3

added 1 package, and audited 476 packages in 897ms

2 moderate severity vulnerabilities

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O npm acrescentou o pacote, e depois informou duas vulnerabilidades que a instalação da aula 2 não
informou. Elas não estão no zone.js. O `npm audit` diz onde:

```
ana@dev:~/planner$ npm audit 2>&1 | head -12
# npm audit report

undici  7.0.0 - 7.30.0
Severity: moderate
undici vulnerable to Denial of Service via unbounded memory in the EventSource parser - https://github.com/advisories/GHSA-4qv8-2p9j-2685
undici vulnerable to Subresource Integrity bypass via non-lowercase algorithm tokens - https://github.com/advisories/GHSA-f72v-6w45-q472
fix available via `npm audit fix --force`
Will install @angular/build@20.3.41, which is a breaking change
node_modules/undici
  @angular/build  21.0.0-next.0 - 21.2.28
  Depends on vulnerable versions of undici
  node_modules/@angular/build
```

O `undici` é uma biblioteca de HTTP que o sistema de build da CLI usa, e um alerta contra ela foi
publicado depois que a aula 2 foi gravada: a base que o `npm audit` lê muda todo dia, e um projeto que
estava limpo ontem não está limpo hoje sem nenhuma linha dele mudar. Leia o conserto oferecido antes de
rodar qualquer coisa: o `--force` instalaria o `@angular/build` 20, um major inteiro para trás, para
trocar uma biblioteca que só roda no seu computador enquanto você faz o build. A resposta proporcional
é anotar e pegar o `@angular/build` 21 corrigido quando for publicado, com o `ng update` da aula 2. O
`front-quality` é o curso sobre ler esses relatórios.

Ele precisa ser carregado antes de qualquer outra coisa, então vai na primeira linha do `main.ts`, onde
troca as funções assíncronas do navegador antes de o código do Angular rodar:

```typescript
// src/main.ts
import 'zone.js';
import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';

bootstrapApplication(App, appConfig)
  .catch((err) => console.error(err));
```

e a aplicação é instruída a usá-lo, na sua configuração:

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideBrowserGlobalErrorListeners, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';

import { routes } from './app.routes';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes)
  ]
};
```

O `--wait 1000` deixa a página rodar por um segundo depois de carregar, tempo suficiente para os dois
timers:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --wait 1000
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

default, plain field: 1

OnPush, plain field: 0

OnPush, signal: 1
```

**O campo comum do componente padrão mostrou 1.** O timer dele era o timer do zone.js; quando o
callback terminou, o zone.js avisou o Angular, e o Angular percorreu a árvore e achou o `count` mudado.
Essa é a conveniência que o zone.js comprava: atribua a qualquer campo, de qualquer lugar assíncrono, e
a página acompanha.

Isso também custava algo em toda página. O zone.js é código que o navegador baixa e roda antes de a
aplicação começar, e uma passada pela árvore inteira depois de todo timer, todo movimento de mouse que
um ouvinte vê e toda promise resolvida é trabalho feito, tenha algo mudado ou não. E a linha do meio já
mostra o problema: o componente OnPush manteve o 0, por um motivo que a próxima seção dá.
