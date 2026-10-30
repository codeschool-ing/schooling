---
title: Blocos adiados, lazy loading dentro de um template
version: 1
---

**O `@defer` faz por uma parte de um template o que o `loadChildren` faz por uma parte das rotas**: o
que está dentro do bloco, e os componentes que ele usa, vão para um chunk próprio, buscado quando um
gatilho manda. Uma biblioteca de gráficos que pesa mais que o resto da página, uma seção de
comentários abaixo da dobra, um editor atrás de um botão: nenhum deles precisa estar no primeiro
download.

Um bench com um substituto para algo pesado, num arquivo próprio, como um componente adiado precisa
estar:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```typescript
// src/app/bench/chart.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  selector: 'app-chart',
  template: '<p>The chart is drawn.</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Chart {
  constructor() {
    console.log('the chart code has arrived and runs');
  }
}
```

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { Chart } from './chart';

@Component({
  selector: 'app-bench',
  imports: [Chart],
  template: `
    <button type="button" #show>Show the chart</button>
    @defer (on interaction(show)) {
      <app-chart />
    } @placeholder {
      <p>The chart loads when it is asked for.</p>
    } @loading {
      <p>Loading the chart…</p>
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
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

O `on interaction(show)` busca o chunk quando o botão é clicado ou recebe o foco e um Enter. O
`@placeholder` é o que aparece até lá, o `@loading` enquanto o chunk está a caminho. Outros gatilhos
são `on viewport`, quando o bloco entra na área visível, `on idle`, quando o navegador não tem mais
nada a fazer, `on hover`, `on timer(2s)`, e `when` uma condição fica verdadeira.

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text app-bench
[vite] connecting...
[vite] connected.
NG0751: Angular has detected that this application contains `@defer` blocks and the hot module replacement (HMR) mode is enabled. All `@defer` block dependencies will be loaded eagerly. Find more at https://v21.angular.dev/errors/NG0751
Angular is running in development mode.
scripts: /main.js /chunk-KGABQYFU.js /chunk-5ODBP7SE.js
Show the chart

The chart loads when it is asked for.
```

**O `NG0751` diz que o código do gráfico foi carregado com todo o resto, antes de alguém pedir.** O
servidor de desenvolvimento troca código mudado na página sem recarregar, o que se chama hot module
replacement, e para isso ele carrega o código de todo bloco adiado de uma vez. O build ainda o separa:

```
ana@dev:~/planner$ npx ng build 2>&1 | sed -n '/Lazy chunk/,/^$/p'
Lazy chunk files    | Names          |  Raw size | Estimated transfer size
chunk-OGPL5X64.js   | courses-routes |  44.10 kB |                10.16 kB
chunk-XNMGY5HJ.js   | chart          | 387 bytes |               387 bytes
```

Para ver o `@defer` se comportar no servidor de desenvolvimento, pare o `ng serve` com `Ctrl-C` e
inicie-o com o HMR desligado, `npx ng serve --no-hmr`. Depois, a página antes do clique, e depois:

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
scripts: /main.js /chunk-OZXTPHRX.js /chunk-VUJOFXKG.js /chunk-CEZKWLVC.js
Show the chart

The chart loads when it is asked for.
```

```
ana@dev:~/planner$ look http://localhost:4200/ --scripts --text app-bench --do 'click Show the chart'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Show the chart
the chart code has arrived and runs
scripts: /main.js /chunk-OZXTPHRX.js /chunk-VUJOFXKG.js /chunk-CEZKWLVC.js /chunk-FDXEIX35.js
Show the chart

The chart is drawn.
```

Antes do clique, os arquivos da aplicação, a área do curso entre eles porque é pré-carregada, e o
placeholder. Depois do clique, um arquivo a mais, o chunk do gráfico, e o código do próprio gráfico
rodando pela primeira vez.

O bench sai, e o servidor de desenvolvimento volta ao `npx ng serve` simples:

```
ana@dev:~/planner$ rm -r src/app/bench && git checkout -- src/app/app.html src/app/app.ts
```

```
ana@dev:~/planner$ git status --short
 M src/app/add-session/add-session.ts
 M src/app/app.config.ts
 M src/app/app.routes.ts
?? src/app/course-exists.ts
?? src/app/courses.routes.ts
?? src/app/unsaved-work.ts
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Guards, lazy loading and preloading"
```
