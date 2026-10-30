---
title: Os hooks, na ordem em que o Angular os chama
version: 1
---

**Um hook de ciclo de vida é um método com um nome reservado que o Angular chama num momento específico
da vida de um componente: depois que os inputs são definidos, depois que a view é desenhada, antes de ele
ser destruído.** São oito, mais duas funções que fazem o mesmo trabalho para o desenho. O código Angular
mais antigo se apoia muito neles, e os signals tornaram a maioria desnecessária, então esta aula mostra
cada um disparando, em ordem, e depois os separa nos poucos de que você precisa e nos que você só vai
ler.

Um componente que registra cada hook, e uma bancada que o mostra, o renomeia e o remove:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import {\n  AfterContentChecked,\n  AfterContentInit,\n  AfterViewChecked,\n  AfterViewInit,\n  ChangeDetectionStrategy,\n  Component,\n  DoCheck,\n  OnChanges,\n  OnDestroy,\n  OnInit,\n  SimpleChanges,\n  input,\n  signal,\n} from '@angular/core';\n\n@Component({\n  selector: 'app-life',\n  template: '<p>life: {{ label() }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Life\n  implements OnChanges, OnInit, DoCheck, AfterContentInit, AfterContentChecked, AfterViewInit, AfterViewChecked, OnDestroy\n{\n  readonly label = input('');", "note": "Cada hook tem uma interface com o mesmo nome sem o `ng`. O `implements` é opcional, e faz o compilador conferir o nome e a assinatura de cada método."},
 {"code": "  constructor() {\n    console.log('constructor');\n  }\n  ngOnChanges(changes: SimpleChanges): void {\n    console.log('ngOnChanges:', Object.keys(changes).join(', '));\n  }\n  ngOnInit(): void {\n    console.log('ngOnInit');\n  }\n  ngDoCheck(): void {\n    console.log('ngDoCheck');\n  }\n  ngAfterContentInit(): void {\n    console.log('ngAfterContentInit');\n  }\n  ngAfterContentChecked(): void {\n    console.log('ngAfterContentChecked');\n  }\n  ngAfterViewInit(): void {\n    console.log('ngAfterViewInit');\n  }\n  ngAfterViewChecked(): void {\n    console.log('ngAfterViewChecked');\n  }\n  ngOnDestroy(): void {\n    console.log('ngOnDestroy');\n  }\n}", "note": "Cada hook registra o próprio nome. O `ngOnChanges` também registra quais inputs mudaram."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Life],\n  template: `\n    <h2>Bench</h2>\n    <button type=\"button\" (click)=\"label.set('renamed')\">Rename</button>\n    <button type=\"button\" (click)=\"shown.set(false)\">Remove</button>\n    @if (shown()) {\n      <app-life [label]=\"label()\" />\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  protected readonly label = signal('first');\n  protected readonly shown = signal(true);\n}", "note": "O bench pode renomear o `Life` pelo input dele, e removê-lo com o `@if`."}
]}
```

A bancada entra no `App` do jeito que a da aula 8 entrou:

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

Carregar, renomear, remover:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Rename' --do 'click Remove'
[vite] connecting...
[vite] connected.
constructor
ngOnChanges: label
ngOnInit
ngDoCheck
ngAfterContentInit
ngAfterContentChecked
ngAfterViewInit
ngAfterViewChecked
Angular is running in development mode.
-- click Rename
ngOnChanges: label
ngDoCheck
ngAfterContentChecked
ngAfterViewChecked
-- click Remove
ngOnDestroy
Bench
RenameRemove
```

A ordem é a história de uma vida:

1. **`constructor`**: o objeto existe. Os inputs dele ainda não foram definidos.
2. **`ngOnChanges`**: os inputs foram definidos, aqui o `label`. Ele roda antes do `ngOnInit`, e de novo
   toda vez que um input muda, como o `Rename` mostrou.
3. **`ngOnInit`**: uma vez, depois do primeiro `ngOnChanges`. Os inputs estão lá.
4. **`ngDoCheck`**: a cada conferência do componente, mesmo quando nada mudou.
5. **`ngAfterContentInit`** e **`ngAfterContentChecked`**: o conteúdo projetado da aula 8 está pronto,
   uma vez, depois a cada conferência.
6. **`ngAfterViewInit`** e **`ngAfterViewChecked`**: o próprio template do componente está desenhado,
   uma vez, depois a cada conferência.
7. **`ngOnDestroy`**: uma vez, quando o `@if` o removeu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo da vida de um componente. Uma vez, na criação: constructor, depois ngOnChanges, ngOnInit, ngAfterContentInit e ngAfterViewInit, com o ngDoCheck e os dois hooks Checked no meio. Depois, a cada conferência seguinte: ngOnChanges se um input mudou, ngDoCheck, ngAfterContentChecked e ngAfterViewChecked. No fim, uma vez: ngOnDestroy.\"><line x1=\"20\" y1=\"120\" x2=\"700\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,120.0 692.6,123.1 692.6,116.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"20\" y=\"20\" width=\"300\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">uma vez, na criação</text><text x=\"30.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">constructor</text><text x=\"30.0\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnChanges</text><text x=\"30.0\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnInit</text><text x=\"30.0\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngDoCheck</text><text x=\"180.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterContentInit</text><text x=\"180.0\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterContentChecked</text><text x=\"180.0\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterViewInit</text><text x=\"180.0\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterViewChecked</text><line x1=\"170.0\" y1=\"108\" x2=\"170.0\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><rect x=\"340\" y=\"20\" width=\"220\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">a cada conferência seguinte</text><text x=\"350.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnChanges*</text><text x=\"350.0\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngDoCheck</text><text x=\"350.0\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterContentChecked</text><text x=\"350.0\" y=\"97\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngAfterViewChecked</text><line x1=\"450.0\" y1=\"108\" x2=\"450.0\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"580\" y=\"20\" width=\"120\" height=\"88\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">uma vez, ao sair</text><text x=\"590.0\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ngOnDestroy</text><line x1=\"640.0\" y1=\"108\" x2=\"640.0\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"450\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">* só se um input mudou</text><rect x=\"340\" y=\"170\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">se repete: com que frequência depende</text><text x=\"450\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do OnPush e do zone.js (aula 7)</text></svg>", "caption": "O ngOnInit e os dois hooks Init rodam uma vez; o ngDoCheck e os hooks Checked rodam a cada conferência; o ngOnDestroy roda uma vez, no fim."}
```

Depois do `Rename`, quatro hooks rodaram de novo: o `ngOnChanges` pelo input novo, e então o `ngDoCheck`
e os dois hooks `...Checked`, que rodam em **toda** conferência do componente, qualquer que seja a causa.
Neste componente OnPush numa aplicação zoneless, isso é raro. Num componente padrão de uma aplicação com
zone.js, a passada da aula 7 depois de todo evento, é depois de todo clique e todo timer em qualquer
lugar da página, e esse é o alerta sobre os três: o código neles roda muito mais vezes do que qualquer
coisa muda.
