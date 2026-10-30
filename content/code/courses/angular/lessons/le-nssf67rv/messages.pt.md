---
title: Mensagens de erro que uma pessoa encontra
version: 1
---

**Uma mensagem de erro é mostrada quando pode ajudar, ligada ao seu campo para um leitor de tela ler
os dois juntos, e o primeiro campo que precisa de atenção recebe o foco.** Três decisões, cada uma das
quais o formulário toma em poucas linhas:

- **Quando.** Uma mensagem que aparece enquanto alguém ainda digita o primeiro dígito é ruído. A regra
  aqui é a comum: mostrar a mensagem de um campo depois que o campo foi deixado (`touched`), ou depois
  que alguém tentou enviar, o que vier primeiro.
- **Onde.** Embaixo do campo, num parágrafo com id, e o `aria-describedby` do campo nomeia esse id,
  para um leitor de tela ler o label e depois a mensagem. O `aria-invalid` diz que o campo está
  errado, o que um leitor de tela também anuncia.
- **O que acontece no envio.** Nada é mandado, toda mensagem aparece, e o foco vai para o primeiro
  campo que tem uma. Uma pessoa que apertou Enter no último campo e não ouviu nada teria, senão, de
  sair procurando.

```typescript
// src/app/add-session/add-session.ts
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, ElementRef, inject, input, signal } from '@angular/core';
import { AbstractControl, NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { concatMap, from } from 'rxjs';
import { PlannerStore } from '../planner-store';

const MESSAGES: Record<string, string> = {
  required: 'This is needed.',
  min: 'At least 5 minutes.',
  max: 'At most 480 minutes.',
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
  private readonly fb = inject(NonNullableFormBuilder);
  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);
  protected readonly error = signal<string | null>(null);
  protected readonly submitted = signal(false);

  protected readonly form = this.fb.group({
    dates: this.fb.array([this.dateControl()]),
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
    return this.fb.control('', { validators: Validators.required });
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

As mensagens ficam num objeto com as chaves dos nomes que os validadores usam, então um validador
acrescentado depois ganha a frase dele num lugar só. O `focusFirstProblem` acha o primeiro controle
inválido pela posição e foca o input com o id correspondente. Ele lê os controles em vez da página,
porque a página é desenhada depois que o `submit` retorna, então as classes dela ainda descrevem o
momento antes do clique.

O `--a11y` mostra o formulário como um leitor de tela o tem: o nome, o estado e a descrição para onde
o `aria-describedby` de cada campo aponta. Um formulário vazio, enviado:

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-add-session --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [invalid] [focused] (description: This is needed.)
  - paragraph
    - text: This is needed.
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes": 30
  - button "Add"
```

A data está `invalid`, tem o foco, e é descrita pela mensagem dela. O campo de minutos não tem
mensagem, porque 30 está certo. Agora uma data, e minutos de menos:

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-add-session --network --do 'fill Date 1 = 2026-10-26' --do 'fill Minutes = 2' --do 'click Add'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- fill Date 1 = 2026-10-26
-- fill Minutes = 2
-- click Add
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1": 2026-10-26
  - button "Another date"
  - LabelText
    - text: Minutes
  - spinbutton "Minutes" [invalid] [focused]: 2 (description: At least 5 minutes.)
  - paragraph
    - text: At least 5 minutes.
  - button "Add"
```

O foco passou pela data, que agora é válida, e foi para os minutos. O único pedido é o do store,
quando a página carregou: nenhum `POST` foi mandado.
