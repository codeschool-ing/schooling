---
title: FormArray, para uma lista cujo tamanho a pessoa decide
version: 1
---

**Um `FormArray` é uma lista de controles cujo tamanho pode mudar com o formulário na tela.** Um
grupo tem um conjunto fixo de nomes; um array tem posições, e controles podem entrar e sair. O planner
usa um para uma coisa que é cansativa de outro jeito: planejar a mesma duração de sessão em vários
dias de uma vez. Uma data para começar, um botão para outra, e um botão ao lado de cada data para
tirá-la.

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "import { HttpErrorResponse } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';\nimport { NonNullableFormBuilder, ReactiveFormsModule } from '@angular/forms';\nimport { concatMap, from } from 'rxjs';\nimport { PlannerStore } from '../planner-store';\n\n@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],", "note": "`concatMap` e `from`, da aula 13: um pedido por data, um depois do outro."},
 {"code": "  template: `\n    <form [formGroup]=\"form\" (ngSubmit)=\"submit()\">\n      <h3>Add sessions</h3>\n      <div formArrayName=\"dates\">\n        @for (date of form.controls.dates.controls; track date; let i = $index) {\n          <label [for]=\"'date-' + i\">Date {{ i + 1 }}</label>\n          <input [id]=\"'date-' + i\" type=\"date\" [formControlName]=\"i\" />\n          @if (form.controls.dates.length > 1) {\n            <button type=\"button\" (click)=\"form.controls.dates.removeAt(i)\">Remove date {{ i + 1 }}</button>\n          }\n        }\n      </div>\n      <button type=\"button\" (click)=\"addDate()\">Another date</button>\n      <label for=\"minutes\">Minutes</label>\n      <input id=\"minutes\" type=\"number\" formControlName=\"minutes\" />\n      <button type=\"submit\">Add</button>\n      @if (error(); as message) {\n        <p role=\"alert\">{{ message }}</p>\n      }\n    </form>\n  `,\n  styles: `\n    form,\n    div {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {\n  readonly courseId = input.required<string>();\n  private readonly store = inject(PlannerStore);\n  private readonly fb = inject(NonNullableFormBuilder);\n  protected readonly error = signal<string | null>(null);", "note": "O `formArrayName` aponta para o array, e lá dentro o `[formControlName]` recebe uma posição em vez de um nome. Cada data ganha um label e um id próprios, numerados, para um leitor de tela distingui-las."},
 {"code": "  protected readonly form = this.fb.group({\n    dates: this.fb.array([this.fb.control('')]),\n    minutes: 30,\n  });\n\n  protected addDate(): void {\n    this.form.controls.dates.push(this.fb.control(''));\n  }", "note": "Um array de controles de data, começando com um, dentro do grupo."},
 {"code": "  protected submit(): void {\n    this.error.set(null);\n    const { dates, minutes } = this.form.getRawValue();\n    from(dates)\n      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))\n      .subscribe({\n        complete: () => this.startAgain(),\n        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),\n      });\n  }", "note": "Um `POST` por data, em ordem, e o formulário só volta ao começo quando todos tiverem respondido. Um erro para o resto e diz por quê."},
 {"code": "  private startAgain(): void {\n    this.form.controls.dates.clear();\n    this.addDate();\n    this.form.reset();\n  }\n}", "note": "O `reset()` reinicia valores, não estrutura: deixaria três datas vazias onde havia três. Então o array volta a um controle antes."}
]}
```

O `track date` acompanha cada objeto de controle em si, que continua o mesmo para uma data quando
outra data acima dela é removida. Então, quando uma data sai, é o input daquela data que sai da
página, e os inputs depois dele mantêm o que o navegador guarda neles, o foco incluído. Duas datas, de
meia hora cada:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-course-page --do 'fill Date 1 = 2026-10-27' --do 'click Another date' --do 'fill Date 2 = 2026-10-29' --do 'fill Minutes = 30' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date 1 = 2026-10-27
-- click Another date
-- fill Date 2 = 2026-10-29
-- fill Minutes = 30
-- click Add
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 40 minutes
 2026-10-27, 30 minutes
 2026-10-29, 30 minutes
Add sessions
Date 1
Another date
Minutes
Add
```

Duas sessões acrescentadas, e o formulário de volta a uma data vazia. O `concatMap` mandou o segundo
`POST` só depois de o primeiro ser respondido, o que mantém os ids na ordem em que as datas foram
digitadas. O `forkJoin` os teria mandado de uma vez; para duas sessões a diferença é invisível, e para
vinte, a ordem em que o servidor os viu seria a de chegada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Duas colunas unidas por linhas. À esquerda, o modelo do formulário na classe: um FormGroup chamado form, com um FormArray chamado dates, que tem FormControls nas posições 0 e 1, e um FormControl chamado minutes. À direita, o template: o elemento form com [formGroup]=&quot;form&quot;, um div com formArrayName=&quot;dates&quot;, dois inputs de data com [formControlName] valendo 0 e 1, e um input numérico com formControlName=&quot;minutes&quot;. Cada linha une uma parte do modelo ao elemento ligado a ela.\"><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">na classe</text><text x=\"530\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">no template</text><rect x=\"40\" y=\"36\" width=\"220\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"50\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">form: FormGroup</text><rect x=\"70\" y=\"92\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dates: FormArray</text><rect x=\"100\" y=\"148\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[0]: FormControl</text><rect x=\"100\" y=\"196\" width=\"160\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">[1]: FormControl</text><rect x=\"70\" y=\"244\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">minutes: FormControl</text><rect x=\"400\" y=\"36\" width=\"260\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;form [formGroup]=\"form\"&gt;</text><rect x=\"420\" y=\"92\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;div formArrayName=\"dates\"&gt;</text><rect x=\"440\" y=\"148\" width=\"220\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;input [formControlName]=\"0\"&gt;</text><rect x=\"440\" y=\"196\" width=\"220\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;input [formControlName]=\"1\"&gt;</text><rect x=\"420\" y=\"244\" width=\"240\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;input formControlName=\"minutes\"&gt;</text><line x1=\"260\" y1=\"52\" x2=\"400\" y2=\"52\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"108\" x2=\"420\" y2=\"108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"164\" x2=\"440\" y2=\"164\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"212\" x2=\"440\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><line x1=\"260\" y1=\"260\" x2=\"420\" y2=\"260\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><path d=\"M 55 68 L 55 108 L 70 108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M 55 108 L 55 260 L 70 260\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M 85 124 L 85 164 L 100 164\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><path d=\"M 85 164 L 85 212 L 100 212\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path></svg>", "caption": "O modelo é uma árvore na classe; o template nomeia cada parte dele no elemento que a mostra."}
```
