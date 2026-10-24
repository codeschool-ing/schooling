---
title: Angular
version: 1
---

**O Angular é uma plataforma inteira, um framework, sua própria ferramenta de linha de comando, um
roteador, formulários e uma configuração de testes, e os componentes dele são classes TypeScript com um
template ao lado.** Desde o Angular 17 os templates dele têm o próprio controle de fluxo, `@for` e `@if`,
e a reatividade dele, desde que os signals chegaram no Angular 16, é cada vez mais feita de **signals**,
parentes próximos dos refs do Vue. O gerador de projetos dele é o Angular CLI, rodado numa versão fixa:

```
ana@dev:~/vue/compare$ npx --yes @angular/cli@22.2.4 new angular --defaults --skip-git --skip-install --ssr=false
CREATE angular/.prettierrc (161 bytes)
CREATE angular/README.md (1460 bytes)
CREATE angular/.editorconfig (314 bytes)
CREATE angular/.gitignore (622 bytes)
CREATE angular/angular.json (1906 bytes)
CREATE angular/package.json (782 bytes)
CREATE angular/tsconfig.json (908 bytes)
CREATE angular/tsconfig.app.json (398 bytes)
CREATE angular/tsconfig.spec.json (409 bytes)
CREATE angular/.vscode/extensions.json (130 bytes)
CREATE angular/.vscode/launch.json (470 bytes)
CREATE angular/.vscode/tasks.json (978 bytes)
CREATE angular/src/main.ts (222 bytes)
CREATE angular/src/index.html (293 bytes)
CREATE angular/src/styles.css (80 bytes)
CREATE angular/src/app/app.css (0 bytes)
CREATE angular/src/app/app.spec.ts (681 bytes)
CREATE angular/src/app/app.ts (290 bytes)
CREATE angular/src/app/app.html (20144 bytes)
CREATE angular/src/app/app.config.ts (312 bytes)
CREATE angular/src/app/app.routes.ts (77 bytes)
CREATE angular/public/favicon.ico (15086 bytes)
```

O `--defaults` aceita a resposta padrão de cada pergunta que o CLI faria, e o `--ssr=false` deixa de fora
a renderização no servidor, que o Angular sabe fazer como o Nuxt faz. Instale, e fixe os pacotes do
framework:

```
ana@dev:~/vue/compare/angular$ npm install

added 281 packages, and audited 282 packages in 13s

84 packages are looking for funding
  run `npm fund` for details

2 vulnerabilities (1 low, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/vue/compare/angular$ npm install --save-exact @angular/common@22.2.3 @angular/compiler@22.2.3 @angular/core@22.2.3 @angular/forms@22.2.3 @angular/platform-browser@22.2.3 @angular/router@22.2.3

added 7 packages, and audited 289 packages in 1s

86 packages are looking for funding
  run `npm fund` for details

2 vulnerabilities (1 low, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## Duas vulnerabilidades, e uma delas importa

Desta vez a auditoria vale mais do que o minuto que a aula 18 deu a ela:

```
ana@dev:~/vue/compare/angular$ npm audit
# npm audit report

vite  8.3.0 - 8.3.2
Severity: high
launch-editor: escapeCmdArgs() omits % escaping on Windows - https://github.com/advisories/GHSA-698v-4r3x-3vcv
launch-editor: Editor CLI flag misinterpretation causing arbitrary command execution for some editors - https://github.com/advisories/GHSA-r825-w8mm-5pxw
launch-editor: `fs.existsSync()` existence check can be bypassed on Windows - https://github.com/advisories/GHSA-587h-7wmj-h5pm
Vite: Cross origin script execution through Vite custom middleware - https://github.com/advisories/GHSA-9jrq-w75r-8gcw
Vite: Files outside `server.fs.allow` could be served when project paths match system paths on non-Windows machine - https://github.com/advisories/GHSA-rq7h-c2jc-7f22
Vite: First 4 bytes of files outside of `server.fs` setting is exposed by `?vite-wasm-instance` - https://github.com/advisories/GHSA-vfpm-58rq-9qcg
fix available via `npm audit fix --force`
Will install @angular/build@22.1.9, which is a breaking change
node_modules/@angular/build/node_modules/vite
  @angular/build  22.2.0-next.0 - 22.3.0-next.1
  Depends on vulnerable versions of vite
  node_modules/@angular/build

2 vulnerabilities (1 low, 1 high)

To address all issues (including breaking changes), run:
  npm audit fix --force
```

**O Vite dentro da ferramenta de build do Angular é o 8.3.0 a 8.3.2, e os alertas são sobre o servidor
de desenvolvimento**: um fala de um script de outra origem executado pelo middleware do servidor, outros
de arquivos servidos de fora das pastas que ele tem permissão de servir. Esse é o servidor que você
deixa rodando no seu computador enquanto navega, então *ele só roda em localhost* não consola aqui. A
correção que a auditoria oferece, `--force`, faria o `@angular/build` voltar para o 22.1.9, uma versão
minor mais antiga que o resto do Angular no projeto. O Vite do próprio planner, 8.3.5, já tem as
correções, e dá para mandar o npm usá-lo em todo este projeto com um **override**:

```
ana@dev:~/vue/compare/angular$ npm pkg set overrides.vite=8.3.5
ana@dev:~/vue/compare/angular$ npm install

removed 1 package, and audited 288 packages in 4s

85 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/angular$ npm ls vite
angular@0.0.0 /home/ana/vue/compare/angular
├─┬ @angular/build@22.2.4
│ ├─┬ @vitejs/plugin-basic-ssl@2.3.0
│ │ └── vite@8.3.5 deduped
│ └── vite@8.3.5 overridden
└─┬ vitest@5.0.5
  ├─┬ @vitest/mocker@5.0.5
  │ └── vite@8.3.5 deduped
  └── vite@8.3.5 deduped
```

**`overridden`, e nenhuma vulnerabilidade**: todo pacote que pedia um Vite agora recebe o 8.3.5. Um
override é uma decisão que você tomou passando por cima de uma dependência, então vale anotar o porquê,
e tirá-lo quando o `@angular/build` publicar a correção ele mesmo; o próximo `npm audit` depois de uma
atualização diz quando.

## O card

```typescript
// src/app/week-card.ts: one course's week, the Angular way.
import { Component, computed, signal } from '@angular/core'

@Component({
  selector: 'app-root',
  template: `
    <section>
      <h2>Spanish</h2>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>
            <label>
              <input type="checkbox" [checked]="s.done" (change)="toggle(s.id)" />
              {{ s.date }}, {{ s.minutes }} minutes
            </label>
          </li>
        }
      </ul>
      <p>{{ done() }} of {{ planned() }} minutes done</p>
    </section>
  `,
})
export class WeekCard {
  readonly sessions = signal([
    { id: 's3', date: '19 October', minutes: 30, done: true },
    { id: 's6', date: '23 October', minutes: 40, done: false },
  ])
  readonly planned = computed(() => this.sessions().reduce((sum, s) => sum + s.minutes, 0))
  readonly done = computed(() =>
    this.sessions()
      .filter((s) => s.done)
      .reduce((sum, s) => sum + s.minutes, 0),
  )

  constructor() {
    console.log('Angular: the constructor runs')
  }

  toggle(id: string) {
    this.sessions.update((list) => list.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }
}
```

A entrada inicia a aplicação com o card como raiz, no `<app-root>` do template:

```typescript
// src/main.ts: the card is the whole application.
import { bootstrapApplication } from '@angular/platform-browser'
import { WeekCard } from './app/week-card'

bootstrapApplication(WeekCard).catch((err) => console.error(err))
```

Em relação ao card do Vue:

- **`signal([...])`** é um `ref`, lido chamando-o, `this.sessions()`, em vez de com `.value`, e mudado
  com `.set` ou `.update`. O update aqui monta uma lista nova, como o do React, porque um signal percebe
  um valor novo e não uma mudança dentro do antigo.
- **`computed(() => ...)`** é o `computed` do Vue, com o mesmo nome, o mesmo cache e o mesmo
  rastreamento automático do que ele leu.
- **`[checked]` e `(change)`** são a sintaxe de binding do Angular: colchetes para um valor que entra
  num elemento, parênteses para um evento que sai dele. `[(ngModel)]` seria a forma de mão dupla, do
  pacote de formulários, e o card passa sem ela.
- **`@for (...; track s.id)`** é o `v-for` com a sua `key`, e o Angular torna o `track` obrigatório.

`npm start` roda o `ng serve`, na porta `4200`:

```
ana@dev:~/vue/compare/angular$ npm start

> angular@0.0.0 start
> ng serve

❯ Building...
✔ Building...
Initial chunk files | Names         | Raw size
main.js             | main          |  5.48 kB | 
styles.css          | styles        | 95 bytes | 

                    | Initial total |  5.57 kB

Application bundle generation complete. [2.022 seconds] - 2026-10-24T01:17:37.717Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
10:17:38 PM [vite] (client) [optimizer] bundling dependencies...
```

```
ana@dev:~/vue/compare/angular$ look http://localhost:4200/ --do 'check text=23 October' --text body
[vite] connecting...
[vite] connected.
Angular: the constructor runs
Angular is running in development mode.
-- check text=23 October
== the text of body
Spanish
 19 October, 30 minutes
 23 October, 40 minutes

70 of 70 minutes done
```

**`[vite] connecting...` numa página Angular**: o `ng serve` é o servidor de desenvolvimento do Vite,
debaixo do build próprio do Angular. E o construtor rodou uma vez, como o setup do Vue; a marcação
redesenhou o que lia os signals.
