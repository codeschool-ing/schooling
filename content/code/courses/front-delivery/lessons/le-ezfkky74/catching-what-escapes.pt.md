---
title: Capturando o que escapa
version: 1
---

**Dois eventos de `window` veem o que nenhum `catch` viu: `error`, para uma exceção que escapou, e
`unhandledrejection`, para uma promise rejeitada sem nada esperando pelo resultado.** Uma página que escuta
os dois, e também relata a partir dos próprios `catch`, viu todo erro que consegue ver.

O monitor do planner é um arquivo só:

```typescript
// src/monitor.ts
const url = import.meta.env.VITE_ERRORS_URL;
const release = import.meta.env.VITE_RELEASE ?? "dev";

export function report(error: unknown, source: string): void {
  const e = error instanceof Error ? error : new Error(String(error));
  console.error(source, e);
  if (!url) return;
  const body = { message: e.message, stack: e.stack, source, release, path: location.pathname };
  navigator.sendBeacon(url, JSON.stringify(body));
}

export function watchErrors(): void {
  window.addEventListener("error", (event) => report(event.error ?? event.message, "error"));
  window.addEventListener("unhandledrejection", (event) => report(event.reason, "unhandledrejection"));
}
```

- **`report`** recebe qualquer coisa que tenha sido lançada. O JavaScript lança uma string ou um número tão
  facilmente quanto um `Error`, e só um `Error` tem pilha, então qualquer outra coisa é embrulhada num.
  Ele continua escrevendo no console, que é onde um desenvolvedor com a página aberta olha primeiro.
- **`source`** diz qual parte do planner relatou: `saveDone`, `load`, `Planner` ou um dos dois listeners.
- **`navigator.sendBeacon`** manda um `POST` pequeno que o navegador termina mesmo se a página estiver
  fechando, que é justamente quando alguns erros acontecem. Ele não espera resposta, e devolve `false` se o
  navegador se recusou a enfileirá-lo; um relatório que não pôde ser mandado não é relatado de novo,
  porque a alternativa é um loop.
- **`event.error ?? event.message`**: um evento `error` traz o valor lançado em `error`. Para um script de
  outra origem carregado sem `crossorigin`, o navegador o esconde e manda só a mensagem *Script error.*,
  então scripts de terceiros que devem ser monitorados são carregados com
  `<script crossorigin="anonymous">` e servidos com um cabeçalho CORS.
- **Sem URL, sem relatório.** O build estático não tem coletor para onde mandar, então só escreve no
  console, como antes.

## As duas variáveis novas

A aula 2 disse que a aula 11 acrescentaria o nome de uma release. Ela acrescenta também o endereço do
coletor, e as duas entram primeiro nos tipos:

```typescript
// src/vite-env.d.ts
interface ViteTypeOptions {
  strictImportMetaEnv: unknown;
}

interface ImportMetaEnv {
  readonly VITE_TITLE?: string;
  readonly VITE_GRAPHQL_URL?: string;
  readonly VITE_ERRORS_URL?: string;
  readonly VITE_RELEASE?: string;
}
```

## O planner, relatando

Quatro linhas mudam no `main.ts`: o import, uma chamada a `watchErrors()` antes de qualquer outra coisa
rodar, e os dois `console.error`, que viram relatórios. Três `sed` fazem as mudanças, e o `grep` mostra o
resultado:

```
ana@dev:~/planner$ sed -i 's#^import { saveDone, watch } from "./api";#&\nimport { report, watchErrors } from "./monitor";#' src/main.ts
ana@dev:~/planner$ sed -i 's#^const base = import.meta.env.BASE_URL;#watchErrors();\n\n&#' src/main.ts
ana@dev:~/planner$ sed -i 's#console.error("Could not save", error)#report(error, "saveDone")#; s#console.error("Could not load", error)#report(error, "load")#' src/main.ts
ana@dev:~/planner$ grep -n 'report\|watchErrors' src/main.ts
4:import { report, watchErrors } from "./monitor";
8:watchErrors();
37:        saveDone(id).catch((error) => report(error, "saveDone"));
56:}).catch((error) => report(error, "load"));
```

O `apollo.ts` relata uma consulta que falhou do mesmo jeito, com o nome da operação como origem, que é o
que a aula 9 quis dizer com um relatório de erro levando a operação:

```
ana@dev:~/planner$ sed -i 's#^import type { Planner } from "./api";#&\nimport { report } from "./monitor";#' src/apollo.ts
ana@dev:~/planner$ sed -i 's#console.error("Could not load", result.error)#report(result.error, "Planner")#' src/apollo.ts
ana@dev:~/planner$ grep -n 'report' src/apollo.ts
4:import { report } from "./monitor";
28:    if (result.error) report(result.error, "Planner");
ana@dev:~/planner$ npx tsc && echo types ok
types ok
```

O `watchErrors()` roda no topo do `main.ts` para que os listeners estejam no lugar antes da primeira linha
que poderia falhar. Um erro lançado antes dele, num módulo que o `main.ts` importa, continua escapando; uma
página que precise ver esses também põe os listeners num `<script>` pequeno embutido no `index.html`, antes
de todo o resto.
