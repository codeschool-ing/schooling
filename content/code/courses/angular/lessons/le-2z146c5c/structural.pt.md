---
title: Uma diretiva estrutural, e a estrela
version: 1
---

**Uma diretiva estrutural decide se, ou quantas vezes, um pedaço de template é desenhado.** Antes do
`@if` e do `@for` da aula 5 havia o `*ngIf` e o `*ngFor`, e o código antigo está cheio deles. A estrela
é uma abreviação: o Angular embrulha o elemento num `<ng-template>`, um pedaço de template que não é
desenhado sozinho, e o entrega à diretiva, que o desenha quantas vezes decidir.

```html
<p *ngIf="late">Overdue</p>

<!-- is short for -->
<ng-template [ngIf]="late">
  <p>Overdue</p>
</ng-template>
```

Uma diretiva desse tipo recebe o template como um `TemplateRef`, e o lugar da página onde ele vai como
um `ViewContainerRef`, e desenha um no outro. A segunda diretiva do bench é o oposto do `*ngIf`,
desenhada quando a condição é falsa:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "// src/app/bench/bench.ts\nimport {\n  ChangeDetectionStrategy,\n  Component,\n  Directive,\n  TemplateRef,\n  ViewContainerRef,\n  effect,\n  inject,\n  input,\n  signal,\n} from '@angular/core';\n\n@Directive({\n  selector: '[appHighlight]',\n  host: {\n    '[style.background-color]': 'active() ? colour() : null',\n    '(mouseenter)': 'active.set(true)',\n    '(mouseleave)': 'active.set(false)',\n    '(focusin)': 'active.set(true)',\n    '(focusout)': 'active.set(false)',\n  },\n})\nexport class Highlight {\n  readonly colour = input('yellow', { alias: 'appHighlight' });\n  protected readonly active = signal(false);\n}"},
 {"code": "@Directive({\n  selector: '[appUnless]',\n})\nexport class Unless {\n  readonly appUnless = input.required<boolean>();\n  private readonly template = inject(TemplateRef);\n  private readonly place = inject(ViewContainerRef);\n\n  constructor() {\n    effect(() => {\n      if (this.appUnless()) {\n        this.place.clear();\n      } else if (this.place.length === 0) {\n        this.place.createEmbeddedView(this.template);\n      }\n    });\n  }\n}", "note": "O template a desenhar e o lugar onde desenhá-lo, os dois injetados. Um effect redesenha quando a condição muda, e desenha no máximo uma cópia."},
 {"code": "@Component({\n  selector: 'app-bench',\n  imports: [Highlight, Unless],\n  template: `\n    <p appHighlight>A plain highlight.</p>\n    <button type=\"button\" appHighlight=\"khaki\">A khaki button</button>\n    <p *appUnless=\"done()\">Still to do.</p>\n    <button type=\"button\" (click)=\"done.set(true)\">Mark done</button>\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  protected readonly done = signal(false);\n}", "note": "O `*appUnless=\"done()\"` desenha o parágrafo enquanto o `done()` for falso."}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Mark done'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Mark done
A plain highlight.

A khaki buttonMark done
```

O parágrafo estava lá, e o clique o tirou. **Código novo raramente precisa disso**, porque o fluxo de
controle embutido cobre os casos comuns e é mais rápido: o `@if` e o `@for` fazem parte da linguagem
de template, compilados direto na view, enquanto uma diretiva estrutural é uma classe que depende de
dois serviços. O que sobra para diretivas estruturais é um template que uma biblioteca lhe entrega
para desenhar, como uma linha de tabela que um data grid desenha uma vez por linha, e ler o código de
antes do Angular 17.
