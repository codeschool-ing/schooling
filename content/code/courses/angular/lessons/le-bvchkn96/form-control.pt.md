---
title: Um controle de formulário, e onde o valor dele fica
version: 1
---

**Num formulário reativo o formulário é um objeto na classe do componente, e o template só aponta
para ele.** Um `FormControl` guarda o valor de um campo, sabe se ele foi tocado ou mudado, e, mais
adiante nesta aula e na próxima, se ele é válido. O `<input>` no template é ligado a ele e mantido em
sincronia com ele nos dois sentidos: digitar muda o controle, e definir o controle muda o que o input
mostra. Como o modelo é código, ele pode ser lido, testado e tipado sem template nenhum.

O formulário do planner vai acrescentar sessões a um curso, então ele é um componente próprio, ao
lado da lista na página do curso:

```
ana@dev:~/planner$ npx ng generate component add-session --inline-template --inline-style --skip-tests
CREATE src/app/add-session/add-session.ts (286 bytes)
```

Uma primeira versão com um controle, para os minutos, e uma linha embaixo que diz o que o controle
guarda:

```schooling-example
{"language": "typescript", "file": "src/app/add-session/add-session.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component } from '@angular/core';\nimport { FormControl, ReactiveFormsModule } from '@angular/forms';\n\n@Component({\n  selector: 'app-add-session',\n  imports: [ReactiveFormsModule],", "note": "As diretivas de formulário reativo, o `[formControl]` entre elas, vêm do `ReactiveFormsModule`, importado como um componente."},
 {"code": "  template: `\n    <label for=\"minutes\">Minutes</label>\n    <input id=\"minutes\" type=\"number\" [formControl]=\"minutes\" />\n    <p>The value is {{ minutes.value }}, of type {{ typeOfValue() }}.</p>\n  `,\n  styles: `\n    :host {\n      display: grid;\n      gap: 0.5rem;\n      max-width: 20rem;\n    }\n  `,\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class AddSession {", "note": "O `[formControl]` liga o input ao controle na classe. Não há handler `(input)`: a diretiva escuta por você."},
 {"code": "  protected readonly minutes = new FormControl(30);\n\n  protected typeOfValue(): string {\n    return typeof this.minutes.value;\n  }\n}", "note": "O tipo do controle vem do primeiro valor dele: `FormControl<number | null>`."}
]}
```

A página do curso o põe embaixo da lista:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { AddSession } from '../add-session/add-session';
import { PlannerStore } from '../planner-store';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList, AddSession],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```

```html
<!-- src/app/course-page/course-page.html -->
@if (store.isLoading()) {
  <p>Loading the course…</p>
} @else if (store.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  @if (store.saveError(); as message) {
    <p role="alert">{{ message }}</p>
  }
  <app-session-list [sessions]="sessions()" (toggled)="store.toggle($event.id, $event.done)" />
  <app-add-session />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

Digite um número no campo, e depois esvazie-o:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = 45'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
Minutes

The value is 45, of type number.
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = '
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 
Minutes

The value is , of type object.
```

**Um campo numérico dá ao controle um `number`, e um vazio dá `null`**, que o `typeof` chama de
`object`. É por isso que o tipo do controle é `FormControl<number | null>` e não
`FormControl<number>`: o Angular não pode descartar o campo vazio, nem o `reset()`, que por padrão
devolve um controle a `null`. `new FormControl(30, { nonNullable: true })` faz o `reset()` voltar a
30 e tira o `null` do tipo. O campo vazio ainda pode pôr um `null` ali em tempo de execução; o
`Validators.required` da aula 15 é o que o recusa.
