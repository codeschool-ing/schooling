---
title: A biblioteca, num repositório próprio
version: 1
---

**A biblioteca começa como uma cópia, uma vez, numa pasta nova que vira o próprio repositório**, e dali em
diante ela é a única cópia: no fim da aula o planner apaga a sua e instala o pacote. As peças são as que as
aulas 5 e 6 escreveram: os arquivos de tokens e os scripts deles, os componentes e o formatador de duração
que eles usam.

```
ana@dev:~$ mkdir -p ~/planner-ui/src && cd ~/planner-ui
ana@dev:~/planner-ui$ cp ../planner/tokens.json ../planner/tokens.mjs ../planner/contrast.mjs .
ana@dev:~/planner-ui$ cp ../planner/src/components.ts ../planner/src/format.ts src/
ana@dev:~/planner-ui$ git init -q
ana@dev:~/planner-ui$ find . -path ./.git -prune -o -type f -print | sort
./contrast.mjs
./src/components.ts
./src/format.ts
./tokens.json
./tokens.mjs
```

## Do que a biblioteca não pode depender

O `components.ts` importava o tipo `Session` do `planner.ts` do planner. Uma biblioteca que importa de um
app não é uma biblioteca, então ela ganha um tipo próprio com o mesmo formato, e o import passa a apontar
para ele:

```typescript
// src/types.ts
export interface Session {
  id: number;
  course: string;
  date: string;
  minutes: number;
  done: boolean;
}
```

```
ana@dev:~/planner-ui$ sed -i 's#"./planner"#"./types"#' src/components.ts
ana@dev:~/planner-ui$ grep -n import src/components.ts
2:import { duration } from "./format";
3:import type { Session } from "./types";
```

**Os tipos da biblioteca descrevem o que os componentes dela precisam, não o que um app por acaso tem.** Se
o app dos professores tiver sessões com mais campos, elas ainda cabem, porque o TypeScript compara
formatos: um objeto com campos a mais satisfaz uma interface que lista menos.

## Uma porta de entrada

Um pacote tem uma porta da frente, o arquivo que diz o que ele oferece. Tudo o que não é exportado por ela
é privado, e pode mudar sem ninguém depender disso:

```typescript
// src/index.ts
export { actionButton, sessionRow, weekSummary } from "./components";
export { duration } from "./format";
export type { Session } from "./types";
```

Três componentes, o formatador que eles usam, e o tipo. **Esta lista é a interface pública da
biblioteca**, e a seção sobre versões é sobre quanto custa mudá-la.
