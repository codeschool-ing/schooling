---
title: Um grupo de controles, tipados juntos
version: 1
---

**Um `FormGroup` é um conjunto de controles com nome que se comporta como um só: um valor, feito dos
deles, e um status.** Uma sessão precisa de uma data além dos minutos, então o formulário vira um
grupo de dois. No template, o `[formGroup]` liga o `<form>` ao grupo, e o `formControlName` liga cada
input a um controle dentro dele pelo nome:

```typescript
// src/app/add-session/add-session.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form">
      <h3>Add a session</h3>
      <label for="date">Date</label>
      <input id="date" type="date" formControlName="date" />
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
    </form>
    <p>{{ asText() }}</p>
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
  protected readonly form = new FormGroup({
    date: new FormControl('', { nonNullable: true }),
    minutes: new FormControl(30, { nonNullable: true }),
  });

  protected asText(): string {
    return JSON.stringify(this.form.value);
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-add-session --do 'fill Date = 2026-10-26' --do 'fill Minutes = 40'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Date = 2026-10-26
-- fill Minutes = 40
Add a session
Date
Minutes

{"date":"2026-10-26","minutes":40}
```

O valor de um input de data é uma string no formato `YYYY-MM-DD`, seja o que for que o navegador
mostre na tela, que é o formato que a API quer.

## O que os tipos sabem

O tipo do grupo é deduzido dos controles: `FormGroup<{ date: FormControl<string>; minutes:
FormControl<number> }>`. Então o compilador sabe que `form.controls.minutes` existe e guarda um
número, e recusa `form.controls.minuts` como recusa qualquer propriedade escrita errado. Ele também
sabe algo menos óbvio, que um método que soma dez minutos mostra:

```typescript
// src/app/add-session/add-session.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-add-session',
  imports: [ReactiveFormsModule],
  template: `
    <form [formGroup]="form">
      <h3>Add a session</h3>
      <label for="date">Date</label>
      <input id="date" type="date" formControlName="date" />
      <label for="minutes">Minutes</label>
      <input id="minutes" type="number" formControlName="minutes" />
    </form>
    <p>{{ asText() }}</p>
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
  protected readonly form = new FormGroup({
    date: new FormControl('', { nonNullable: true }),
    minutes: new FormControl(30, { nonNullable: true }),
  });

  protected asText(): string {
    return JSON.stringify(this.form.value);
  }

  protected tenMore(): number {
    return this.form.value.minutes + 10;
  }
}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A4 ERROR
✘ [ERROR] TS2532: Object is possibly 'undefined'. [plugin angular-compiler]

    src/app/add-session/add-session.ts:38:11:
      38 │     return this.form.value.minutes + 10;
         ╵            ~~~~~~~~~~~~~~~~~~~~~~~
```

**O `form.value` deixa de fora os controles desabilitados**, então todo campo no tipo dele é opcional:
um controle poderia estar desabilitado no momento da leitura, e o valor dele faltaria. O
`getRawValue()` inclui todo controle, desabilitado ou não, então o tipo dele tem todos os campos:
`this.form.getRawValue().minutes + 10` compila. É esse que se manda a um servidor, e a próxima seção
faz isso. O método só estava ali para dar de cara com o erro; ele sai, e o `add-session.ts` volta a
ser a versão de antes dele.
