---
title: Um segundo store, para uma preferência
version: 1
---

**Uma preferência é estado como qualquer outro, e ganha a mesma forma.** A página do curso lista toda
sessão, feita ou não; quem planeja o que falta quer esconder as já feitas, e quer que a escolha fique
quando abrir outro curso. Isso é estado compartilhado entre visitas a cursos diferentes, então vai num
serviço, não no `CourseSessions`.

```schooling-example
{"language": "typescript", "file": "src/app/preferences.ts", "parts": [
 {"code": "// src/app/preferences.ts\nimport { Injectable, computed, signal } from '@angular/core';\n\ninterface Saved {\n  hideDone: boolean;\n}\n\n@Injectable({ providedIn: 'root' })\nexport class Preferences {\n  private readonly state = signal<Saved>({ hideDone: false });\n  readonly hideDone = computed(() => this.state().hideDone);\n\n  setHideDone(hide: boolean): void {\n    this.state.update((saved) => ({ ...saved, hideDone: hide }));\n  }\n}", "note": "A mesma forma do `PlannerStore`, pequena: estado privado, um signal só de leitura para fora, um método para dentro."}
]}
```

As sessões do curso a leem, e oferecem a caixa que a define. O `shown` é um `computed` sobre dois
stores ao mesmo tempo, o que os signals tornam corriqueiro:

```typescript
// src/app/course-sessions/course-sessions.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { MatCheckbox } from '@angular/material/checkbox';
import { PlannerStore } from '../planner-store';
import { Preferences } from '../preferences';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-sessions',
  imports: [MatCheckbox, SessionList],
  template: `
    @if (store.saveError(); as message) {
      <p role="alert">{{ message }}</p>
    }
    <mat-checkbox [checked]="preferences.hideDone()" (change)="preferences.setHideDone($event.checked)">
      Hide sessions that are done
    </mat-checkbox>
    <app-session-list [sessions]="shown()" (toggled)="store.toggle($event.id, $event.done)" />
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CourseSessions {
  readonly courseId = input.required<string>();
  protected readonly store = inject(PlannerStore);
  protected readonly preferences = inject(Preferences);
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
  protected readonly shown = computed(() =>
    this.preferences.hideDone() ? this.sessions().filter((s) => !s.done) : this.sessions(),
  );
}
```

A caixa marcada na página do JavaScript, depois um link para a semana e um clique em Git, que não tem
sessão feita; e de volta ao JavaScript, pelo endereço, o que carrega a aplicação de novo:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'click This week' --do 'click JavaScript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Hide sessions that are done
-- click This week
-- click JavaScript
Hide sessions that are done
Sat 24 Oct, 50 minutes
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'go /courses/javascript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Hide sessions that are done
-- go /courses/javascript
[vite] connecting...
Angular is running in development mode.
[vite] connected.
Hide sessions that are done
Tue 13 Oct, 45 minutes
Tue 20 Oct, 1 hour
Sat 24 Oct, 50 minutes
```

O primeiro manteve a escolha de uma página da aplicação para a outra, porque o serviço sobreviveu aos
componentes. O segundo a perdeu: carregar a aplicação de novo fez um `Preferences` novo, com o estado
com que ele começa. Uma preferência esquecida a cada visita é meia preferência.
