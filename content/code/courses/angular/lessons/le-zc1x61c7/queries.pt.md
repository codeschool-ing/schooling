---
title: Queries, alcançando um elemento ou um filho
version: 1
---

**Uma query dá a um componente um signal com um elemento ou um componente filho do seu próprio
template.** Na maior parte do tempo, dados e eventos bastam, e uma query é a exceção: para as poucas
coisas que um componente precisa fazer diretamente num elemento, como mover o foco do teclado para
ele. O `viewChild` acha algo no próprio template do componente; o `contentChild` acha algo no conteúdo
projetado nele.

A bancada ganha um campo e um botão que põe o cursor nele:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, ElementRef, viewChild } from '@angular/core';

@Component({
  selector: 'app-bench',
  template: `
    <h2>Bench</h2>
    <label for="bench-note">Note</label>
    <input id="bench-note" #note />
    <button type="button" (click)="write()">Write a note</button>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly note = viewChild.required<ElementRef<HTMLInputElement>>('note');

  protected write(): void {
    this.note().nativeElement.focus();
  }
}
```

O `viewChild.required<…>('note')` acha o elemento com a referência `#note` e devolve um signal com um
`ElementRef`, o invólucro do Angular em volta do elemento do DOM, cujo `nativeElement` é o próprio
input. O `.required` promete que ele existe, então o signal nunca é `undefined`.

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-bench --do 'click Write a note'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Write a note
- heading "Bench" [level=2]
- LabelText
  - text: Note
- textbox "Note" [focused]
- button "Write a note"
```

O campo é o que está marcado como focado. Para quem enxerga e usa mouse, isso é uma conveniência; para
quem usa teclado ou leitor de tela, é a diferença entre ser levado ao campo e ter de procurá-lo, e as
aulas 9 e 21 usam o mesmo movimento quando uma tela muda.

Como os inputs e os outputs, as queries tiveram primeiro uma forma com decorator,
`@ViewChild('note') note!: ElementRef`, preenchida num hook de ciclo de vida que a aula 9 apresenta, e o
`ng generate @angular/core:signal-queries-migration` a reescreve.

## Limpando a bancada, e os testes

Apague a bancada e tire-a do `App`:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error:|Tests '
ERROR RuntimeError: NG0950: Input "planned" is required but no value is available yet. Find more at https://v21.angular.dev/errors/NG0950
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯
 FAIL  |planner| src/app/week-summary/week-summary.spec.ts > WeekSummary > should create
Error: NG0950: Input "planned" is required but no value is available yet. Find more at https://v21.angular.dev/errors/NG0950
      Tests  1 failed | 3 passed (4)
```

O teste gerado do `WeekSummary` cria o componente e nunca define os inputs dele, e um input obrigatório
lido antes de alguém defini-lo é um erro, `NG0950`. Um teste é um pai como qualquer outro e precisa
fornecer o que o componente exige. O `setInput` faz isso, pela referência do componente:

```typescript
// src/app/week-summary/week-summary.spec.ts
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { WeekSummary } from './week-summary';

describe('WeekSummary', () => {
  let component: WeekSummary;
  let fixture: ComponentFixture<WeekSummary>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [WeekSummary],
    }).compileComponents();

    fixture = TestBed.createComponent(WeekSummary);
    fixture.componentRef.setInput('planned', 165);
    fixture.componentRef.setInput('done', 90);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E 'FAIL|Error:|Tests '
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Inputs, outputs and projection: the course page and its sessions"
```
