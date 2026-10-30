---
title: O servidor confere de novo, e tem a última palavra
version: 1
---

**Tudo o que o formulário confere, o servidor confere de novo, porque o formulário não é a única
entrada.** O navegador roda código que a pessoa controla. Qualquer um pode abrir as ferramentas de
desenvolvedor e mandar um `POST` que o formulário nunca mandaria, ou usar o `curl`, que não precisa de
formulário nenhum:

```
ana@dev:~/planner$ curl -s -X POST http://localhost:3000/api/sessions -d '{"courseId":"javascript","date":"2026-10-26","minutes":-5}'; echo
{"error":"minutes must be a whole number above 0"}
```

**Validação no cliente é para a pessoa; validação no servidor é para os dados.** As conferências do
formulário tornam os erros baratos de corrigir, com uma mensagem onde o erro está, antes de uma ida e
volta. As do servidor são as que decidem o que é guardado, e a mensagem `role="alert"` do formulário
continua lá para uma recusa que o formulário não previu. As duas são escritas duas vezes de propósito,
e as do servidor não são opcionais.

A conferência assíncrona tem o mesmo limite, pelo outro lado. Ela disse que o dia 24 estava ocupado
quando perguntou; uma sessão acrescentada em outro lugar um segundo depois só seria pega quando o
servidor visse o `POST`. O servidor do planner não recusa uma segunda sessão num mesmo dia, então a
conferência é um aviso para a pessoa e não uma regra que os dados mantêm; uma regra que os dados
precisam manter fica no servidor, onde é conferida no momento de escrever.

Uma última mudança. O `startAgain` da aula 14 limpava o array e acrescentava um controle novo, então
depois de todo envio bem-sucedido o único input de data da página era destruído e feito de novo.
Manter o primeiro controle e remover o resto deixa esse input onde está:

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
    const { dates } = this.form.controls;
    while (dates.length > 1) dates.removeAt(1);
    this.form.reset();
  }
}
```

Duas datas, as duas livres, as duas depois de hoje:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-course-page --network --do 'fill Date 1 = 2026-10-26' --do 'click Another date' --do 'fill Date 2 = 2026-10-28' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- fill Date 1 = 2026-10-26
-- click Another date
net  GET /api/planner  200
-- fill Date 2 = 2026-10-28
-- click Add
net  GET /api/planner  200
net  POST /api/sessions  201
net  POST /api/sessions  201
JavaScript
 2026-10-13, 45 minutes
 2026-10-20, 60 minutes
 2026-10-24, 50 minutes
 2026-10-26, 30 minutes
 2026-10-28, 30 minutes
Add sessions
Date 1
Another date
Minutes
Add
```

Uma conferência por data conforme cada campo era deixado, depois os dois `POST`s, e o formulário
voltou a uma data vazia e 30 minutos.

```
ana@dev:~/planner$ git add -A && git commit -q -m "Validators: messages, a day that has gone, repeats, and the server's own check"
```
