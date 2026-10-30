---
title: Escrevendo de volta
version: 1
---

**Ler é um resource; escrever é um pedido que você faz quando algo acontece.** O `http.patch` monta
um: um método, uma URL e um corpo, aqui `{ done }`. O que ele retorna é um **Observable**, o tipo de
que trata a aula 13, e um Observable não faz nada até alguém assiná-lo. Um pedido que ninguém assina
nunca é enviado, e esse é o jeito mais comum de escrever um que não faz nada em silêncio.

O `toggle` continua mudando a cópia do store na hora, então a caixa marca no momento do clique, e
agora avisa o servidor também:

```typescript
// src/app/planner-store.ts
import { HttpClient, httpResource } from '@angular/common/http';
import { Injectable, computed, inject } from '@angular/core';
import { Session, isoDay, parsePlanner, totals, weekOf } from './planner';
import { TODAY } from './today';

@Injectable({
  providedIn: 'root',
})
export class PlannerStore {
  private readonly http = inject(HttpClient);
  private readonly data = httpResource(() => '/api/planner', { parse: parsePlanner });

  readonly isLoading = this.data.isLoading;
  readonly error = this.data.error;
  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));
  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));
  readonly week = weekOf(isoDay(inject(TODAY)));
  readonly weekTotals = computed(() => totals(this.sessions(), this.week));

  minutesThisWeek(courseId: string): number {
    return totals(this.sessions().filter((s) => s.courseId === courseId), this.week).planned;
  }

  toggle(id: number, done: boolean): void {
    this.data.update((data) =>
      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },
    );
    this.http.patch<Session>(`/api/sessions/${id}`, { done }).subscribe();
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary --network --do 'check 2026-10-24, 50 minutes'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
net  GET /api/planner  200
-- check 2026-10-24, 50 minutes
net  PATCH /api/sessions/5  200
165 minutes planned, 140 done.

25 minutes to go.

Done this week
```

O `PATCH` saiu depois da marcação, e o servidor respondeu 200. O teste de verdade é uma página nova,
que não sabe nada do que a anterior fez:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
165 minutes planned, 140 done.

25 minutes to go.

Done this week
```

**140 minutos feitos, numa página que os carregou do servidor.** A marcação sobreviveu à página pela
primeira vez neste curso. O `CoursePage` e o `Week` não mudaram: a aula 11 pôs toda mudança numa
sessão atrás do `toggle`, então havia um lugar só para ensinar sobre o servidor.

Mudar a cópia primeiro e avisar o servidor depois se chama atualização **otimista**. Ela faz a
página parecer instantânea, e faz uma promessa que o servidor pode não cumprir; a última seção desta
aula trata do servidor dizendo não. O `curl` desfaz a sessão 5, para as seções depois desta:

```
ana@dev:~/planner$ curl -s -X PATCH http://localhost:3000/api/sessions/5 -d '{"done":false}'; echo
{"id":5,"courseId":"javascript","date":"2026-10-24","minutes":50,"done":false}
```
