---
title: Um cartão, do jeito do Angular
version: 1
---

**Esta aula constrói uma pequena parte do planner quatro vezes, em Angular, React, Vue e Svelte, e
põe as quatro lado a lado.** A parte é um cartão: a semana de um curso, as sessões com uma caixa para
marcar, e uma linha que soma os minutos. É pequena o bastante para ler inteira em cada framework, e
tem as três partes que todo framework precisa resolver: **estado** que muda, as sessões; **valores
derivados** que o acompanham, os dois totais; e um **template** que desenha os dois e devolve a
marcação.

Os outros três cursos desta trilha, `react-ts`, `vue` e `svelte`, terminam com a mesma aula do lado
deles, e constroem o mesmo planner. O que vem a seguir é o bastante de cada framework para ler o
cartão, não para aprender o framework: é para isso que aqueles cursos existem.

Cada cartão é um projeto próprio, numa pasta ao lado do planner. Pare qualquer dev server que esteja
rodando, crie a pasta,

```
ana@dev:~$ mkdir compare
```

e comece dentro dela com o framework que este curso conhece. O `--skip-install` porque a instalação é
o passo que a aula 2 precisou contornar, e o contorno é o `.npmrc` do planner:

```
ana@dev:~/compare$ npx @angular/cli@21.2.29 new angular --defaults --skip-git --skip-install --ssr=false
npm warn exec The following package was not found and will be installed: @angular/cli@21.2.29
CREATE angular/.prettierrc (161 bytes)
CREATE angular/README.md (1461 bytes)
CREATE angular/.editorconfig (314 bytes)
CREATE angular/.gitignore (622 bytes)
CREATE angular/angular.json (1906 bytes)
CREATE angular/package.json (784 bytes)
CREATE angular/tsconfig.json (957 bytes)
CREATE angular/tsconfig.app.json (429 bytes)
CREATE angular/tsconfig.spec.json (441 bytes)
CREATE angular/.vscode/extensions.json (130 bytes)
CREATE angular/.vscode/launch.json (470 bytes)
CREATE angular/.vscode/mcp.json (179 bytes)
CREATE angular/.vscode/tasks.json (978 bytes)
CREATE angular/src/main.ts (222 bytes)
CREATE angular/src/index.html (293 bytes)
CREATE angular/src/styles.css (80 bytes)
CREATE angular/src/app/app.css (0 bytes)
CREATE angular/src/app/app.spec.ts (674 bytes)
CREATE angular/src/app/app.ts (289 bytes)
CREATE angular/src/app/app.html (20144 bytes)
CREATE angular/src/app/app.config.ts (313 bytes)
CREATE angular/src/app/app.routes.ts (77 bytes)
CREATE angular/public/favicon.ico (15086 bytes)
```

```
ana@dev:~/compare/angular$ cp ~/planner/.npmrc .
```

Depois as mesmas versões exatas do planner, para o cartão rodar no Angular que este curso usou:

```
ana@dev:~/compare/angular$ npm install --save-exact @angular/common@21.2.25 @angular/compiler@21.2.25 @angular/core@21.2.25 @angular/forms@21.2.25 @angular/platform-browser@21.2.25 @angular/router@21.2.25 rxjs@7.8.2 tslib@2.8.1 @angular/build@21.2.29 @angular/cli@21.2.29 @angular/compiler-cli@21.2.25 jsdom@28.1.0 prettier@3.9.10 typescript@5.9.3 vitest@4.1.12

added 470 packages, and audited 471 packages in 14s

found 0 vulnerabilities
```

Nenhuma vulnerabilidade: o `@angular/build` 21.2.29 é o patch que a aula 2 aplicou. O cartão é a aplicação inteira, então ele é o componente raiz, e nada mais é
necessário:

```
ana@dev:~/compare/angular$ rm src/app/app.html src/app/app.css src/app/app.spec.ts src/app/app.routes.ts
```

```typescript
// src/app/app.ts: one course's week, the Angular way
import { ChangeDetectionStrategy, Component, computed, signal } from '@angular/core';

@Component({
  selector: 'app-root',
  template: `
    <section>
      <h2>JavaScript</h2>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>
            <label>
              <input type="checkbox" [checked]="s.done" (change)="toggle(s.id)" /> {{ s.date }}, {{ s.minutes }} minutes
            </label>
          </li>
        }
      </ul>
      <p>{{ done() }} of {{ planned() }} minutes done</p>
    </section>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {
  protected readonly sessions = signal([
    { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },
    { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },
  ]);
  protected readonly planned = computed(() => this.sessions().reduce((sum, s) => sum + s.minutes, 0));
  protected readonly done = computed(() =>
    this.sessions()
      .filter((s) => s.done)
      .reduce((sum, s) => sum + s.minutes, 0),
  );

  constructor() {
    console.log('Angular: the constructor runs');
  }

  toggle(id: number): void {
    this.sessions.update((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)));
  }
}
```

```typescript
// src/app/app.config.ts: no router, since the card is the whole page
import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';

export const appConfig: ApplicationConfig = {
  providers: [provideBrowserGlobalErrorListeners()],
};
```

Tudo aqui é deste curso: um signal para as sessões, dois `computed`, `@for` com `track`, um binding de
propriedade e um de evento, OnPush. A única linha de que ele não precisa é o `console.log` no
construtor, que diz quando o código do componente roda; a seção de comparação o lê. Inicie o
`npx ng serve`, e marque a segunda sessão:

```
ana@dev:~/compare/angular$ look http://localhost:4200/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
[vite] connected.
Angular: the constructor runs
Angular is running in development mode.
-- check Sat 24 Oct, 50 minutes
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

**110 de 110, e o construtor rodou uma vez**, antes de a página ser desenhada. A marcação chamou o
`toggle`, que trocou a lista do signal; os dois `computed` que a leem ficaram desatualizados, e as
partes do template que leem esses foram desenhadas de novo. Pare o dev server. As próximas três seções
são o mesmo cartão, e a mesma verificação, nos outros três frameworks.
