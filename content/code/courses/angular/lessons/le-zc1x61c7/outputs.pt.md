---
title: Outputs, eventos passados para cima
version: 1
---

**Um output é um evento que um componente anuncia, que o pai escuta com `(nome)="…"`.** Os inputs
levam dados para baixo; os outputs levam notícias para cima. Um filho não muda os dados do pai: ele
diz o que aconteceu, e o pai, que é dono dos dados, decide o que fazer. O planner precisa de um: uma
sessão marcada como feita.

## Uma linha que diz que foi marcada

Cada sessão ganha uma linha com um checkbox:

```
ana@dev:~/planner$ npx ng generate component session-row --inline-template --inline-style --skip-tests
CREATE src/app/session-row/session-row.ts (286 bytes)
```

```typescript
// src/app/session-row/session-row.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { Session } from '../planner';

@Component({
  selector: 'app-session-row',
  imports: [],
  template: `
    <label>
      <input type="checkbox" [checked]="session().done" (change)="changed($event)" />
      {{ session().date }}, {{ session().minutes }} minutes
    </label>
  `,
  styles: ``,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionRow {
  readonly session = input.required<Session>();
  readonly toggled = output<boolean>();

  protected changed(event: Event): void {
    this.toggled.emit((event.target as HTMLInputElement).checked);
  }
}
```

**`output<boolean>()`** declara um evento que leva um booleano, e o `emit` o anuncia. A linha não
define `session().done` ela mesma: a sessão é um input, só de leitura para a linha, e os dados pertencem
a quem os passou.

A lista repassa a notícia, acrescentando de que sessão se tratava:

```typescript
// src/app/session-list/session-list.ts
import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';
import { Session } from '../planner';
import { SessionRow } from '../session-row/session-row';

@Component({
  selector: 'app-session-list',
  imports: [SessionRow],
  template: `
    <ul>
      @for (session of sessions(); track session.id) {
        <li><app-session-row [session]="session" (toggled)="toggled.emit({ id: session.id, done: $event })" /></li>
      } @empty {
        <li>No sessions yet.</li>
      }
    </ul>
  `,
  styles: ``,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SessionList {
  readonly sessions = input.required<Session[]>();
  readonly toggled = output<{ id: number; done: boolean }>();
}
```

Em `(toggled)="…"`, **o `$event` é o que o filho emitiu**, o booleano, não um evento do DOM: para o
output de um componente, o `$event` é o que foi passado ao `emit`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"A página do curso, no topo, guarda os dados. Uma seta chamada sessions desce até a lista de sessões, e uma seta chamada session desce da lista até cada linha. De uma linha, uma seta chamada toggled, levando true, sobe até a lista, e da lista uma seta chamada toggled, levando o id e o done, sobe até a página, que atualiza os seus dados. Os dados novos então descem de novo.\"><rect x=\"250\" y=\"20\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CoursePage</text><text x=\"360.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">dono dos dados</text><rect x=\"250\" y=\"120\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionList</text><text x=\"360.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repassa</text><rect x=\"250\" y=\"220\" width=\"220\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SessionRow</text><text x=\"360.0\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma por sessão</text><line x1=\"300\" y1=\"66\" x2=\"300\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,118.0 296.9,110.6 303.1,110.6\" fill=\"var(--phosphor)\"></polygon><text x=\"292\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">[sessions]</text><line x1=\"300\" y1=\"166\" x2=\"300\" y2=\"218\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,218.0 296.9,210.6 303.1,210.6\" fill=\"var(--phosphor)\"></polygon><text x=\"292\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">[session]</text><text x=\"120\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">os dados descem,</text><text x=\"120\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pelos inputs</text><line x1=\"420\" y1=\"218\" x2=\"420\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,168.0 423.1,175.4 416.9,175.4\" fill=\"var(--amber)\"></polygon><text x=\"428\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">(toggled) true</text><line x1=\"420\" y1=\"118\" x2=\"420\" y2=\"68\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"420.0,68.0 423.1,75.4 416.9,75.4\" fill=\"var(--amber)\"></polygon><text x=\"428\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">(toggled) { id, done }</text><text x=\"620\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">as notícias sobem,</text><text x=\"620\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">pelos outputs</text><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o dono atualiza os dados, e o valor novo desce de novo</text></svg>", "caption": "Inputs levam dados para baixo; outputs levam notícias para cima; só o dono muda os dados."}
```

## O dono muda os dados

A página do curso é dona dos dados, então a mudança acontece lá. O valor de um `resource` é um signal
que aceita escrita, e o `update` o troca por um novo, um array novo com um objeto novo para a sessão
alterada, como a aula 6 exigiu:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, input, resource } from '@angular/core';
import { loadPlanner } from '../planner';
import { SessionList } from '../session-list/session-list';

@Component({
  selector: 'app-course-page',
  imports: [SessionList],
  templateUrl: './course-page.html',
  styleUrl: './course-page.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class CoursePage {
  readonly courseId = input.required<string>();
  protected readonly data = resource({ loader: loadPlanner });
  protected readonly course = computed(() =>
    this.data.value()?.courses.find((c) => c.id === this.courseId()),
  );
  protected readonly sessions = computed(() =>
    (this.data.value()?.sessions ?? [])
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );

  protected toggle(id: number, done: boolean): void {
    this.data.update((data) =>
      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },
    );
  }
}
```

```html
<!-- src/app/course-page/course-page.html -->
@if (data.isLoading()) {
  <p>Loading the course…</p>
} @else if (data.error(); as error) {
  <p>The course could not be loaded: {{ error.message }}</p>
} @else if (course(); as course) {
  <h2>{{ course.name }}</h2>
  <app-session-list [sessions]="sessions()" (toggled)="toggle($event.id, $event.done)" />
} @else {
  <p>There is no course called {{ courseId() }}.</p>
}
```

A sessão de JavaScript de sábado ainda não está feita. Marque-a:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --a11y main --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check 2026-10-24, 50 minutes
- main
  - heading "This week" [level=2]
  - paragraph
    - text: 165 minutes planned, 90 done.
  - paragraph
    - text: 75 minutes to go.
  - LabelText
    - text: Done this week
  - progressbar "Done this week": 90
  - heading "Courses" [level=3]
  - list
    - listitem [level=1]
      - ListMarker "• "
      - text: HTML and CSS
      - text: : 30 minutes
    - listitem [level=1]
      - ListMarker "• "
      - text: JavaScript
      - text: : 110 minutes
    - listitem [level=1]
      - ListMarker "• "
      - text: Git
      - text: : 25 minutes
  - heading "JavaScript" [level=2]
  - list
    - listitem [level=1]
      - ListMarker "• "
      - checkbox " 2026-10-13, 45 minutes" [checked]
    - listitem [level=1]
      - ListMarker "• "
      - checkbox " 2026-10-20, 60 minutes" [checked]
    - listitem [level=1]
      - ListMarker "• "
      - checkbox " 2026-10-24, 50 minutes" [focused] [checked]
```

A caixa do dia 24 está marcada, porque os dados da página do curso agora dizem isso. **E a semana lá em
cima continua dizendo 90 feitos**, não 140. A semana tem a própria cópia dos dados, carregada
separadamente, e nada a avisou. Dois componentes guardando cada um a verdade é o problema que a aula 6
previu, e ele acaba de produzir uma tela que contradiz a si mesma. A aula 11 dá aos dados um único dono
que as duas telas compartilham, e a aula 12 manda a mudança para um servidor, para que ela sobreviva a
um recarregamento, o que hoje não acontece.

## Os outputs que você ainda vai encontrar

Antes do Angular 17.3, um output era um `EventEmitter` com decorator:

```typescript
@Output() toggled = new EventEmitter<boolean>();
```

Ele é usado do mesmo jeito, `emit` e `(toggled)`, e o `ng generate @angular/core:output-migration` o
reescreve como `output()`.
