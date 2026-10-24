---
title: Signals para fora, métodos para dentro
version: 1
---

**Um store só é uma cópia se nada de fora puder mudar a cópia pelas costas dele.** Todo componente que
injeta o `PlannerStore` recebe a mesma instância, então um componente que pudesse escrever direto nos
dados dele os mudaria para toda tela, de um jeito que o store nunca vê e não pode conferir. O store
acima tem uma forma que impede isso, e o compilador diz quando alguém tenta.

Um método no `CoursePage` que tenta os dois caminhos:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
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
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );

  protected clear(): void {
    this.store.sessions.set([]);
    this.store.data.set(undefined);
  }
}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A4 ERROR
✘ [ERROR] TS2339: Property 'set' does not exist on type 'Signal<Session[]>'. [plugin angular-compiler]

    src/app/course-page/course-page.ts:25:24:
      25 │     this.store.sessions.set([]);
         ╵                         ~~~
--
✘ [ERROR] TS2341: Property 'data' is private and only accessible within class 'PlannerStore'. [plugin angular-compiler]

    src/app/course-page/course-page.ts:26:15:
      26 │     this.store.data.set(undefined);
         ╵                ~~~~
```

**O `sessions` é um `computed`, e um `computed` não tem `set`.** O tipo dele é `Signal<Session[]>`,
que pode ser lido e nada mais: o valor é calculado a partir do resource, então o único jeito de mudá-lo
é mudar o resource. E o resource é `private`, então só os métodos do próprio store podem. Dois erros,
os dois no build, antes de qualquer pessoa rodar qualquer coisa.

A forma tem nome na maior parte das bibliotecas de estado, e vale ter um aqui: **signals para fora,
métodos para dentro**. O que o resto da aplicação lê é um signal só de leitura; o que ela pode fazer é
um método com nome, `toggle`, que diz o que faz e é o único lugar que faz. Quando a aula 14
acrescentar um formulário para sessões novas, ele chama `store.add(...)`, e a aula 12 transforma o
`toggle` num pedido a um servidor, sem nenhum dos componentes mudar.

Quando o estado é um `signal` comum em vez de um resource, o `asReadonly()` dá a mesma proteção:
`readonly sessions = this.state.asReadonly();` entrega um `Signal` que lê o gravável e não pode
escrevê-lo.

O método sai, e o `course-page.ts` volta a ser o da seção anterior:

```typescript
// src/app/course-page/course-page.ts
import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { PlannerStore } from '../planner-store';
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
  protected readonly store = inject(PlannerStore);
  protected readonly course = computed(() => this.store.courses().find((c) => c.id === this.courseId()));
  protected readonly sessions = computed(() =>
    this.store
      .sessions()
      .filter((s) => s.courseId === this.courseId())
      .sort((a, b) => a.date.localeCompare(b.date)),
  );
}
```
