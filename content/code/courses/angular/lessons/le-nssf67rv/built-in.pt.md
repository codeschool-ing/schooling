---
title: Os validadores que vêm com o Angular
version: 1
---

**Um validador é uma função que olha um controle e responde `null`, para válido, ou um objeto dizendo
o que está errado.** O Angular roda os validadores de um controle toda vez que o valor dele muda, e o
`status` do controle decorre das respostas: `VALID`, `INVALID`, ou `PENDING` enquanto um assíncrono
ainda trabalha. Um grupo é inválido se qualquer controle dentro dele for. O formulário da aula 14
mandava uma data vazia ao servidor e deixava o servidor recusá-la; o mesmo formulário com validadores
sabe antes de mandar qualquer coisa.

O `Validators` guarda os comuns: `required`, `min` e `max` para números, `minLength` e `maxLength`
para strings, `email`, e `pattern` para uma expressão regular. Um controle os recebe como segundo
argumento, sozinhos ou numa lista. O controle de data agora é feito por um pequeno método, já que o
`addDate` faz o mesmo controle que o grupo faz, e uma linha embaixo do formulário relata o que os
validadores dizem:

```typescript
// src/app/add-session/add-session.ts
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { concatMap, from } from 'rxjs';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      <h3>Add sessions</h3>
      <div formArrayName="dates">
        @for (date of form.controls.dates.controls; track date; let i = $index) {
          <label [for]="'date-' + i">Date {{ i + 1 }}</label>
          <input [id]="'date-' + i" type="date" [formControlName]="i" />
          @if (form.controls.dates.length > 1) {
            <button type="button" (click)="form.controls.dates.removeAt(i)">Remove date {{ i + 1 }}</button>
          }
        }
      </div>
      <button type="button" (click)="addDate()">Another date</button>
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
      <button type="submit">Add</button>
      @if (error(); as message) {
        <p role="alert">{{ message }}</p>
      }
    </form>
    <p>{{ report() }}</p>
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
  protected readonly error = signal<string | null>(null);

  protected readonly form = this.fb.group({
    dates: this.fb.array([this.dateControl()]),
    minutes: this.fb.control(30, { validators: [Validators.required, Validators.min(5), Validators.max(480)] }),
  });

  protected report(): string {
    return `${this.form.status}; minutes: ${JSON.stringify(this.form.controls.minutes.errors)}`;
  }

  protected addDate(): void {
    this.form.controls.dates.push(this.dateControl());
  }

  protected submit(): void {
    if (this.form.invalid) return;
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

  private startAgain(): void {
    this.form.controls.dates.clear();
    this.addDate();
    this.form.reset();
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = 2'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 2
Add sessions
Date 1
Another date
Minutes
Add

INVALID; minutes: {"min":{"min":5,"actual":2}}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Minutes = '
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 
Add sessions
Date 1
Another date
Minutes
Add

INVALID; minutes: {"required":true}
```

**Cada validador que falha acrescenta a própria chave ao `errors`.** O `min` diz qual era o mínimo e
qual era o valor, o `required` só diz `true`. O grupo continua `INVALID` nos dois casos, e
continuaria com minutos bons também, porque a data ainda está vazia e também é `required`. O `submit`
agora para aí, então uma data vazia nunca mais chega ao servidor.

Isso é melhor para o servidor e pior para a pessoa: o botão não faz nada, e nada na página diz por
quê. Os números no `errors` são para código ler. A próxima seção os transforma em frases, e põe cada
uma onde uma pessoa, e um leitor de tela, vão achá-la.

O Angular também acrescenta `novalidate` a todo formulário que gerencia, o que desliga os balões de
validação do próprio navegador. Eles não podem ser estilizados, dizem coisas diferentes em cada
navegador, e não são anunciados do mesmo jeito por todo leitor de tela, então o formulário mostra as
próprias mensagens no lugar.
