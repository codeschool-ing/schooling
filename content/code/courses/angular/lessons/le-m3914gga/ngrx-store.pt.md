---
title: NgRx Store, a mesma ideia com mais cerimônia
version: 1
---

**O NgRx é a biblioteca de estado que a maioria das grandes aplicações Angular usa, e o Store dele é o
padrão da primeira seção com cada parte explícita.** O estado é um objeto para a aplicação inteira. Um
componente nunca chama um método que o muda: ele **despacha uma action**, um objeto simples que diz o
que aconteceu. Um **reducer**, uma função pura, recebe o estado e a action e retorna o próximo estado.
**Seletores** leem dele. Efeitos colaterais, como pedidos, moram num quarto tipo de coisa, os effects
do próprio NgRx, fora desta visão geral.

A biblioteca é um pacote como o Material, numa versão exata que combina com o Angular 21. Instalado
para um bench, para vê-lo rodar:

```
ana@dev:~/planner$ npm install @ngrx/store@21.1.1

added 1 package, and audited 478 packages in 794ms

2 vulnerabilities (1 moderate, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O `npm` menciona dois avisos, e eles não são do NgRx. O `npm audit` diz quais são:

```
ana@dev:~/planner$ npm audit 2>&1 | head -13
# npm audit report

undici  7.0.0 - 7.30.0
Severity: high
undici vulnerable to Denial of Service via unbounded memory in the EventSource parser - https://github.com/advisories/GHSA-4qv8-2p9j-2685
undici vulnerable to Subresource Integrity bypass via non-lowercase algorithm tokens - https://github.com/advisories/GHSA-f72v-6w45-q472
undici vulnerable to Denial of Service via unhandled error on excessive content-encodings - https://github.com/advisories/GHSA-xjj6-f33q-929c
fix available via `npm audit fix --force`
Will install @angular/build@20.3.41, which is a breaking change
node_modules/undici
  @angular/build  21.0.0-next.0 - 21.2.28
  Depends on vulnerable versions of undici
  node_modules/@angular/build
```

Os dois vêm do `undici`, uma biblioteca HTTP que o `@angular/build` usa no seu computador, que nunca
chega ao navegador, e a correção oferecida com `--force` é voltar ao `@angular/build` 20, uma versão
maior abaixo. Ler um relatório desses e decidir é um trabalho à parte; aqui a resposta é esperar um
patch da ferramenta de build, não aceitar um rebaixamento.

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { Store, createAction, createFeatureSelector, createReducer, createSelector, on, props } from '@ngrx/store';\n\nexport const minutesAdded = createAction('[Bench] Minutes added', props<{ minutes: number }>());\nexport const cleared = createAction('[Bench] Cleared');", "note": "Actions: um tipo, por convenção `[Origem] Evento`, e o que veio com ele. Elas dizem o que aconteceu, não o que fazer a respeito."},
 {"code": "export const minutesReducer = createReducer(\n  [] as number[],\n  on(minutesAdded, (state, { minutes }) => [...state, minutes]),\n  on(cleared, () => []),\n);", "note": "O reducer: dado o estado e uma action, o próximo estado. Ele é puro, então pode ser testado com uma chamada, e nunca muda o estado que recebeu."},
 {"code": "const selectMinutes = createFeatureSelector<number[]>('minutes');\nconst selectTotal = createSelector(selectMinutes, (minutes) => minutes.reduce((sum, m) => sum + m, 0));", "note": "Seletores leem o estado, e lembram a última resposta, como um `computed` faz."},
 {"code": "@Component({\n  selector: 'app-bench',\n  template: `\n    <p>{{ minutes().join(' + ') || 'nothing' }} = {{ total() }}</p>\n    <button type=\"button\" (click)=\"add(30)\">Add 30</button>\n    <button type=\"button\" (click)=\"clear()\">Clear</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  private readonly store = inject(Store);\n  protected readonly minutes = this.store.selectSignal(selectMinutes);\n  protected readonly total = this.store.selectSignal(selectTotal);\n\n  protected add(minutes: number): void {\n    this.store.dispatch(minutesAdded({ minutes }));\n  }\n\n  protected clear(): void {\n    this.store.dispatch(cleared());\n  }\n}", "note": "O `selectSignal` entrega um seletor ao template como signal; o `dispatch` é a única entrada."}
]}
```

O store é fornecido para a aplicação inteira, com cada reducer sob a chave onde o estado dele mora. É
o `provideStore` que a tabela da aula 3 mencionou:

```typescript
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import {
  PreloadAllModules,
  provideRouter,
  withComponentInputBinding,
  withPreloading,
  withRouterConfig,
} from '@angular/router';
import { provideStore } from '@ngrx/store';

import { routes } from './app.routes';
import { minutesReducer } from './bench/bench';
import { requestedBy } from './requested-by';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(
      routes,
      withComponentInputBinding(),
      withRouterConfig({ paramsInheritanceStrategy: 'always' }),
      withPreloading(PreloadAllModules),
    ),
    provideHttpClient(withInterceptors([requestedBy])),
    provideStore({ minutes: minutesReducer }),
  ]
};
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
ana@dev:~/planner$ look http://localhost:4200/ --text 'app-bench p' --do 'click Add 30' --do 'click Add 30' --do 'click Clear' --do 'click Add 30'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add 30
-- click Add 30
-- click Clear
-- click Add 30
30 = 30
```

A mesma aritmética que o `PlannerStore` faria com um signal e um método, escrita como duas actions, um
reducer, dois seletores e um provider. **Essa cerimônia é o produto, não um defeito**: toda mudança no
estado é um objeto action, então todas podem ser registradas, reproduzidas e inspecionadas numa
extensão do navegador que mostra o estado antes e depois de cada uma, e uma equipe de quarenta pessoas
lê qualquer funcionalidade do mesmo jeito. Para uma pessoa e um planner, é mais código que o problema.

O bench, o provider dele e o pacote saem:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts src/app/app.config.ts
```

```
ana@dev:~/planner$ npm uninstall @ngrx/store

removed 1 package, and audited 477 packages in 791ms

2 vulnerabilities (1 moderate, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```
