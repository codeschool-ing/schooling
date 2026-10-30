---
title: FormBuilder, a grafia mais curta
version: 1
---

**O `FormBuilder` faz os mesmos controles, grupos e arrays com menos para digitar.** Todo controle até
aqui foi `new FormControl(valor, { nonNullable: true })`; num formulário de dez campos, são dez
repetições da opção. O `NonNullableFormBuilder` é um serviço que constrói todo controle como não
nulável, então a opção sai:

```typescript
// src/app/add-session/add-session.ts
import { HttpErrorResponse } from '@angular/common/http';
import { ChangeDetectionStrategy, Component, inject, input, signal } from '@angular/core';
import { NonNullableFormBuilder, ReactiveFormsModule } from '@angular/forms';
import { PlannerStore } from '../planner-store';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form" (ngSubmit)="submit()">
      <h3>Add a session</h3>
      <label for="date">Date</label>
      <input id="date" type="date" formControlName="date" />
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
      <button type="submit">Add</button>
      @if (error(); as message) {
        <p role="alert">{{ message }}</p>
      }
    </form>
  `,
  styles: `
    form {
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
    date: '',
    minutes: 30,
  });

  protected submit(): void {
    this.error.set(null);
    this.store.add({ courseId: this.courseId(), ...this.form.getRawValue() }).subscribe({
      next: () => this.form.reset(),
      error: (error: HttpErrorResponse) => this.error.set(`Not added: ${error.error?.error ?? error.statusText}`),
    });
  }
}
```

O `fb.group({ date: '', minutes: 30 })` faz um controle de cada valor simples, e o tipo do grupo é o
mesmo de antes: `date` uma string, `minutes` um número, nenhum dos dois nulável. O build não acha
erro nenhum, que é a conferência que importa numa reescrita como esta:

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'ERROR|bundle generation'
Application bundle generation complete. [2.663 seconds] - 2026-10-29T23:48:03.386Z
```

| escrito com `new` | escrito com o builder |
|---|---|
| `new FormControl('', { nonNullable: true })` | `fb.control('')`, ou `''` dentro de um grupo |
| `new FormGroup({ ... })` | `fb.group({ ... })` |
| `new FormArray([ ... ])` | `fb.array([ ... ])` |

O `FormBuilder` sem o `NonNullable` faz controles nuláveis, como o `new FormControl` faz por padrão,
e `inject(FormBuilder).nonNullable` é o mesmo que o `NonNullableFormBuilder`. O código que você vai
ler usa as três grafias; elas constroem os mesmos objetos.
