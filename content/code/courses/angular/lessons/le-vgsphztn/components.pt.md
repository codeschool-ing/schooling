---
title: Um componente do Material no planner
version: 1
---

**Um componente do Material substitui um elemento que você estilizaria e ligaria por conta própria, e
traz a acessibilidade junto.** A caixa da sessão é o caso mais simples. O `mat-checkbox` desenha uma
caixa com o tema, mantém um `<input type="checkbox">` de verdade dentro dela para teclados e leitores
de tela, e relata mudanças pelo próprio output `change`, com o estado novo em `checked`:

```typescript
// src/app/session-row/session-row.ts
import { DatePipe } from '@angular/common';
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { MatCheckbox } from '@angular/material/checkbox';
import { MinutesPipe } from '../minutes-pipe';
import { Session } from '../planner';

@Component({
  selector: 'app-session-row',
  imports: [DatePipe, MatCheckbox, MinutesPipe],
  template: `
    <mat-checkbox [checked]="session().done" (change)="toggled.emit($event.checked)">
      {{ session().date | date: 'EEE d MMM' }}, {{ session().minutes | minutes }}
    </mat-checkbox>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionRow {
  readonly session = input.required<Session>();
  readonly toggled = output<boolean>();
}
```

A linha não precisa mais do método `changed`: o `$event.checked` já é um booleano. Cada componente é
importado do próprio ponto de entrada, `@angular/material/checkbox`, então o build inclui só os
componentes usados.

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --a11y app-course-sessions --do 'check Sat 24 Oct, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Sat 24 Oct, 50 minutes
- list
  - listitem [level=1]
    - ListMarker "• "
    - checkbox "Tue 13 Oct, 45 minutes" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox "Tue 20 Oct, 1 hour" [checked]
  - listitem [level=1]
    - ListMarker "• "
    - checkbox "Sat 24 Oct, 50 minutes" [focused] [checked]
```

Para um leitor de tela é a mesma caixa de antes, com o mesmo nome, e a mesma ação do `look` a marca,
porque a caixa ainda é achada pelo label. Essa igualdade é o ponto: uma biblioteca de componentes que
quebrasse o nome acessível de uma caixa seria um passo para trás, por mais bonita que ficasse.

O Material tem um componente para a maioria dos controles de que uma aplicação precisa, do
`matButton`, um atributo num `<button>` de verdade, ao `mat-table` e ao seletor de datas. O planner
pega mais um deles duas seções adiante, o diálogo, porque o diálogo é o controle mais difícil de
construir direito.
