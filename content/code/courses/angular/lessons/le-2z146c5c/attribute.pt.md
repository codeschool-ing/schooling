---
title: Uma diretiva de atributo, comportamento sem template
version: 1
---

**Uma diretiva é um componente sem template: uma classe que o Angular prende a um elemento que casa
com o seletor dela, para mudar a aparência ou o comportamento desse elemento.** Um componente desenha
algo novo; uma diretiva trabalha sobre algo que já está lá. Todo `routerLink`, todo
`formControlName`, todo `ngModel` deste curso foi uma diretiva.

Uma **diretiva de atributo** é escrita como um atributo e muda o elemento dela. A primeira clássica,
num bench: um destaque que marca um elemento enquanto o ponteiro está sobre ele, ou enquanto ele tem
o foco do teclado, o que importa tanto quanto:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport { ChangeDetectionStrategy, Component, Directive, input, signal } from '@angular/core';\n\n@Directive({\n  selector: '[appHighlight]',", "note": "O seletor entre colchetes casa com um atributo: todo elemento com `appHighlight` ganha uma destas."},
 {"code": "  host: {\n    '[style.background-color]': 'active() ? colour() : null',\n    '(mouseenter)': 'active.set(true)',\n    '(mouseleave)': 'active.set(false)',\n    '(focusin)': 'active.set(true)',\n    '(focusout)': 'active.set(false)',\n  },\n})\nexport class Highlight {", "note": "O `host` liga o elemento em que a diretiva está, como um template liga um elemento: propriedades e atributos entre colchetes, eventos entre parênteses."},
 {"code": "  readonly colour = input('yellow', { alias: 'appHighlight' });\n  protected readonly active = signal(false);\n}", "note": "O input usa o nome da própria diretiva como apelido, então `appHighlight=\"khaki\"` define a cor num atributo só."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Highlight],\n  template: `\n    <p appHighlight>A plain highlight.</p>\n    <button type=\"button\" appHighlight=\"khaki\">A khaki button</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {}"}
]}
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

O `Tab` move o foco de uma coisa que pode recebê-lo para a próxima. O bench vem depois do link da
navegação e dos três links de curso da semana, então o quinto toque chega ao botão dele:

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-bench --do 'press Tab' --do 'press Tab' --do 'press Tab' --do 'press Tab' --do 'press Tab'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- press Tab
-- press Tab
-- press Tab
-- press Tab
-- press Tab
<app-bench><p apphighlight="">A plain highlight.</p><button type="button" apphighlight="khaki" style="background-color: khaki;">A khaki button</button></app-bench>
```

O parágrafo está intocado, e o botão tem o fundo que o atributo dele pediu, porque tem o foco. **O
`host` é como uma diretiva muda o seu elemento.** Código mais antigo escreve o mesmo com decorators em
membros da classe, `@HostBinding('style.background-color')` numa propriedade e
`@HostListener('mouseenter')` num método; o objeto `host` faz o mesmo e mantém toda ligação num lugar
só, que é o que o guia de estilo do Angular agora recomenda.
