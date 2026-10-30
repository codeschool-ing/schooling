---
title: Um diálogo para trabalho não salvo
version: 1
---

**O guard da aula 18 perguntava com `confirm()`, que funciona e não pode ser desenhado nem dizer mais
que uma frase.** Um diálogo do Material pode dizer mais, usar os botões da própria aplicação, e ainda
se comportar como um diálogo deve: o foco entra nele, fica lá, e volta para de onde veio.

O diálogo é um componente como qualquer outro, com as diretivas de diálogo do Material para as partes
dele:

```typescript
// src/app/confirm-leave/confirm-leave.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { MatButton } from '@angular/material/button';
import { MatDialogActions, MatDialogClose, MatDialogContent, MatDialogTitle } from '@angular/material/dialog';

@Component({
  selector: 'app-confirm-leave',
  imports: [MatButton, MatDialogActions, MatDialogClose, MatDialogContent, MatDialogTitle],
  template: `
    <h2 mat-dialog-title>Leave this form?</h2>
    <mat-dialog-content>What you typed has not been added.</mat-dialog-content>
    <mat-dialog-actions>
      <button matButton [mat-dialog-close]="false">Stay</button>
      <button matButton="filled" [mat-dialog-close]="true">Leave</button>
    </mat-dialog-actions>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ConfirmLeave {}
```

O `[mat-dialog-close]` fecha o diálogo com um valor: `false` para Stay, `true` para Leave. O guard o
abre e espera esse valor. Um guard roda num contexto de injeção, então pode fazer `inject(MatDialog)`,
e pode retornar um Observable, que o router espera:

```typescript
// src/app/unsaved-work.ts
import { inject } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';
import { CanDeactivateFn } from '@angular/router';
import { map } from 'rxjs';
import { ConfirmLeave } from './confirm-leave/confirm-leave';

export interface MayHaveUnsavedWork {
  hasUnsavedWork(): boolean;
}

export const unsavedWork: CanDeactivateFn<MayHaveUnsavedWork> = (component) => {
  if (!component.hasUnsavedWork()) return true;
  return inject(MatDialog)
    .open(ConfirmLeave)
    .afterClosed()
    .pipe(map((leave) => leave === true));
};
```

A rota não mudou, nem o formulário. Os mesmos minutos digitados, o mesmo clique:

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --url --a11y body --do 'fill Minutes = 45' --do 'click Sessions'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
url: /courses/git/add
- group
  - dialog "Leave this form?"
    - heading "Leave this form?" [level=2]
    - button "Stay" [focused]
    - button "Leave"
```

**A página inteira, como um leitor de tela a tem, agora é o diálogo**: o CDK esconde tudo atrás dele
enquanto está aberto, para ninguém sair dele por acidente. O nome dele é o título, e o foco está em
"Stay", o primeiro botão, que é a resposta segura para estar sob o dedo.

O Escape o fecha, o que conta como ficar, e o foco volta para o link que o abriu:

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --a11y 'app-course-page nav' --do 'fill Minutes = 45' --do 'click Sessions' --do 'press Escape'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
-- press Escape
- navigation "Course"
  - link "Sessions" [focused]
  - link "Add sessions"
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --today 2026-10-23 --url --text h2 --do 'fill Minutes = 45' --do 'click Sessions' --do 'click Leave'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Minutes = 45
-- click Sessions
-- click Leave
url: /courses/git
Git
```

O Stay manteve o formulário; o Leave foi para as sessões. Cada parte do que um diálogo precisa fazer
veio da biblioteca, e o planner escreveu um template e três linhas de guard.
