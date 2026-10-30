---
title: Um serviço que guarda o planner
version: 1
---

**Um serviço é uma classe que um injetor faz, guardando estado ou lógica de que mais de um componente
precisa.** O CLI escreve o vazio:

```
ana@dev:~/planner$ npx ng generate service planner-store
CREATE src/app/planner-store.spec.ts (352 bytes)
CREATE src/app/planner-store.ts (117 bytes)
```

```typescript
// src/app/planner-store.ts
import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class PlannerStore {}
```

Não há `Service` no fim do nome, como há na maior parte do código Angular que você vai ler: desde o
Angular 20 o CLI não acrescenta mais o sufixo, e o nome diz para que a classe serve. `PlannerStore`
porque guarda o planner; o arquivo de teste ao lado, `planner-store.spec.ts`, injeta um e confere que
ele existe.

## O que vai nele

O resource sai dos componentes e vai para o store, e o store decide o que o resto da aplicação pode
ver dele:

```schooling-example
{"language": "typescript", "file": "src/app/planner-store.ts", "parts": [
 {"code": "import { Injectable, computed, resource } from '@angular/core';\nimport { loadPlanner } from './planner';\n\n@Injectable({\n  providedIn: 'root',\n})\nexport class PlannerStore {\n  private readonly data = resource({ loader: loadPlanner });", "note": "O único `resource` da aplicação. Ele é `private`: nenhum componente chega a ele."},
 {"code": "  readonly isLoading = this.data.isLoading;\n  readonly error = this.data.error;", "note": "Os signals do próprio resource, repassados como estão."},
 {"code": "  readonly courses = computed(() => (this.data.hasValue() ? this.data.value().courses : []));\n  readonly sessions = computed(() => (this.data.hasValue() ? this.data.value().sessions : []));", "note": "O `hasValue()` primeiro, porque o `value()` lança erro enquanto o resource está no estado de erro. Até os dados chegarem, as duas listas ficam vazias."},
 {"code": "  toggle(id: number, done: boolean): void {\n    this.data.update((data) =>\n      data && { ...data, sessions: data.sessions.map((s) => (s.id === id ? { ...s, done } : s)) },\n    );\n  }\n}", "note": "O único jeito de mudar uma sessão, trazido do `CoursePage` para cá."}
]}
```

O `toggle` é o método que o `CoursePage` tinha, com o mesmo corpo. Ele sempre foi só sobre os dados,
e o componente o guardava porque guardava os dados. Agora o store guarda os dois.
