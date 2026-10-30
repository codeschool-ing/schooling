---
title: Um validador assíncrono, e o pending
version: 1
---

**Algumas regras só podem ser conferidas perguntando a outra pessoa.** Se o curso já tem uma sessão
num dia é uma pergunta para o servidor: o store tem uma cópia, mas outra aba, ou outra pessoa usando o
mesmo planner, pode ter acrescentado uma desde que a cópia foi carregada. Um **validador assíncrono**
retorna um Observable da resposta em vez da resposta, e enquanto ele espera o status do controle é
`PENDING`.

Duas coisas vêm junto. O Angular roda primeiro os validadores síncronos de um controle e os
assíncronos só se esses passarem, então uma data vazia ou passada nunca custa um pedido. E um
validador assíncrono roda a cada mudança do valor, o que, num campo que muda a cada tecla, seria um
pedido por tecla. O `updateOn: 'blur'` muda quando o controle recebe o valor do input: ao sair do
campo em vez de a cada tecla, então o servidor é perguntado uma vez por data. Um envio também pega os
valores de todo campo, então apertar Enter num campo ainda manda o que ele tem.

```typescript
// src/app/add-session/add-session.ts
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';
import { AbstractControl, AsyncValidatorFn, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { concatMap, filter, from, map, take } from 'rxjs';
import { PlannerData, isoDay } from '../planner';
import { PlannerStore } from '../planner-store';
import { TODAY } from '../today';
import { distinctDates, notBefore } from '../validators';

const MESSAGES: Record<string, string> = {
  required: 'This is needed.',
  min: 'At least 5 minutes.',
  max: 'At most 480 minutes.',
  past: 'That day has already gone.',
  taken: 'This course already has a session that day.',
};

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      <h3>Add sessions</h3>
      <div formArrayName="dates">
        @for (date of form.controls.dates.controls; track date; let i = $index) {
          <label [for]="'date-' + i">Date {{ i + 1 }}</label>
          <input
            [id]="'date-' + i"
            type="date"
            [formControlName]="i"
            [aria-invalid]="shows(date)"
            [aria-describedby]="shows(date) ? 'date-' + i + '-error' : null"
          />
          @if (shows(date)) {
            <p [id]="'date-' + i + '-error'">{{ messageFor(date) }}</p>
          }
          @if (form.controls.dates.length > 1) {
            <button type="button" (click)="form.controls.dates.removeAt(i)">Remove date {{ i + 1 }}</button>
          }
        }
        @if (shows(form.controls.dates) && form.controls.dates.hasError('repeated')) {
          <p>Two of the dates are the same day.</p>
        }
      </div>
      <button type="button" (click)="addDate()">Another date</button>
      <label for="minutes">Minutes</label>
      <input
        id="minutes"
        type="number"
        formControlName="minutes"
        [aria-invalid]="shows(form.controls.minutes)"
        [aria-describedby]="shows(form.controls.minutes) ? 'minutes-error' : null"
      />
      @if (shows(form.controls.minutes)) {
        <p id="minutes-error">{{ messageFor(form.controls.minutes) }}</p>
      }
      <button type="submit">Add</button>
      @if (error(); as message) {
        <p role="alert">{{ message }}</p>
      }
    </form>
  `,
  styles: `
    form,
    div {
      display: grid;
      gap: 0.5rem;
      max-width: 20rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AddSession {
  readonly courseId = input.required<string>();
  private readonly store = inject(PlannerStore);
  private readonly http = inject(HttpClient);
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);
  private readonly today = isoDay(inject(TODAY));
  protected readonly error = signal<string | null>(null);
  protected readonly submitted = signal(false);

  private readonly freeDay: AsyncValidatorFn = (control) =>
    this.http
      .get<PlannerData>('/api/planner')
      .pipe(
        map((data) =>
          data.sessions.some((s) => s.courseId === this.courseId() && s.date === control.value) ? { taken: true } : null,
        ),
      );

  protected readonly form = this.fb.group({
    dates: this.fb.array([this.dateControl()], { validators: distinctDates }),
    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),
  });

  protected shows(control: AbstractControl): boolean {
    return control.invalid && (control.touched || this.submitted());
  }

  protected messageFor(control: AbstractControl): string {
    const first = Object.keys(control.errors ?? {})[0];
    return MESSAGES[first] ?? first;
  }

  protected addDate(): void {
    this.form.controls.dates.push(this.dateControl());
  }

  protected submit(): void {
    this.submitted.set(true);
    if (this.form.pending) {
      this.form.statusChanges.pipe(filter((status) => status !== 'PENDING'), take(1)).subscribe(() => this.submit());
      return;
    }
    if (this.form.invalid) {
      this.focusFirstProblem();
      return;
    }
    this.error.set(null);
    const { dates, minutes } = this.form.getRawValue();
    from(dates)
      .pipe(concatMap((date) => this.store.add({ courseId: this.courseId(), date, minutes })))
      .subscribe({
        complete: () => this.startAgain(),
        error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),
      });
  }

  private dateControl() {
    return this.fb.control('', {
      validators: [Validators.required, notBefore(this.today)],
      asyncValidators: this.freeDay,
      updateOn: 'blur',
    });
  }

  private focusFirstProblem(): void {
    const { dates, minutes } = this.form.controls;
    const i = dates.controls.findIndex((date) => date.invalid);
    const id = i >= 0 ? `date-${i}` : dates.invalid ? 'date-0' : minutes.invalid ? 'minutes' : null;
    if (id) this.host.nativeElement.querySelector<HTMLElement>(`#${id}`)?.focus();
  }

  private startAgain(): void {
    this.submitted.set(false);
    this.form.controls.dates.clear();
    this.addDate();
    this.form.reset();
  }
}
```

O `submit` precisa esperar uma conferência ainda em andamento. Clicar no botão deixa o campo de data,
o blur define o valor, o validador assíncrono começa, e o `submit` roda no mesmo instante com o
formulário `PENDING`, nem válido nem inválido. Então o `submit` espera o primeiro status que não for
`PENDING` e roda de novo nessa hora. O sábado, dia 24, já tem a sessão de JavaScript:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y app-add-session --network --do 'fill Date 1 = 2026-10-24' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- fill Date 1 = 2026-10-24
-- click Add
net  GET /api/planner  200
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [invalid] [focused]: 2026-10-24 (description: This course already has a session that day.)
  - paragraph
    - text: This course already has a session that day.
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes": 30
  - button "Add"
```

Dois pedidos do planner: o do store quando a página carregou, e o do validador quando o campo de data
foi deixado. A resposta disse que o dia estava ocupado, o `submit` rodou de novo com o status novo, e
o foco foi para a data.
