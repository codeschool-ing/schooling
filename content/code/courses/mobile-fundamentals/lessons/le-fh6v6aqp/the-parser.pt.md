---
title: Um link é entrada, e o parser recusa o que não conhece
version: 1
---

**Seja qual for o caminho de um link, o app acaba segurando uma string, e transformar essa string numa
tela é código do próprio app.** O sistema decide *se* o planner abre. Em que tela ele abre é decidido
por uma função que lê a URL, e essa função é o único lugar em que um link de um desconhecido encontra o
app. Por isso ela é escrita do jeito que a documentação da Apple pede: tudo o que ela não reconhece é
recusado, com nome, e nada do que ela aceita consegue fazer mais do que abrir uma tela.

O planner aceita três endereços, nas duas grafias:

| tela | esquema próprio | link verificado |
|---|---|---|
| a lista de cursos | `planner://courses` | `https://planner.example.com/courses` |
| um curso | `planner://course/sql` | `https://planner.example.com/course/sql` |
| a semana | `planner://week` | `https://planner.example.com/week` |

O parser transforma um desses numa rota, e a rota nas pilhas da aula 10, então os arquivos desta aula
ficam ao lado do `backstack.ts` em `~/planner`. Salve isto como `links.ts`:

```schooling-example
{"language": "typescript", "file": "links.ts", "parts": [{"code": "// links.ts: a link from outside the app, turned into a planner screen or refused\nimport { start, open, tap, type Nav } from \"./backstack.ts\";\n\nexport type Route = { screen: \"courses\" } | { screen: \"course\"; id: string } | { screen: \"week\" };\n\nconst HOST = \"planner.example.com\";\nconst ID = /^[a-z0-9-]{1,40}$/; // a course id as the planner writes them\n", "note": "Uma `Route` é a lista inteira de lugares aonde um link pode levar, e são três. Nada no tipo consegue dizer \"apagar\" ou \"enviar\", então nenhum link pode pedir isso. `ID` é o formato de um id de curso: letras minúsculas, dígitos e hífens, nunca um título."}, {"code": "// The parts of the path, the same for planner://course/sql and\n// https://planner.example.com/course/sql; anything else is refused.\nfunction parts(url: URL): string[] {\n  const path = url.pathname.split(\"/\").filter((p) => p !== \"\");\n  if (url.protocol === \"planner:\") return [url.host, ...path];\n  if (url.protocol === \"https:\" && url.host === HOST) return path;\n  throw new Error(`not a planner link: ${url.protocol}//${url.host}`);\n}\n", "note": "Em `planner://course/sql` o parser de URL lê `course` como o host, então ele volta para a frente da lista. Um link `https` só vale no host do próprio planner, comparado inteiro, porta incluída. Qualquer outro esquema ou host para aqui."}, {"code": "export function parse(link: string): Route {\n  if (!URL.canParse(link)) throw new Error(\"not a URL at all\");\n  const p = parts(new URL(link));\n  if (p.length === 1 && p[0] === \"courses\") return { screen: \"courses\" };\n  if (p.length === 1 && p[0] === \"week\") return { screen: \"week\" };\n  if (p.length === 2 && p[0] === \"course\" && ID.test(p[1])) return { screen: \"course\", id: p[1] };\n  throw new Error(`no such screen: /${p.join(\"/\")}`);\n}\n", "note": "Uma lista do que é permitido, lida de cima para baixo: três formatos exatos são aceitos e todo o resto cai na recusa. Conferir o tamanho primeiro é o que recusa uma tela conhecida com algo a mais no fim."}, {"code": "// The stacks a link opens: the screen it names, with the screens the app\n// would have shown before it put underneath, so that back and up still work.\nexport function toNav(route: Route): Nav {\n  if (route.screen === \"course\") return open(start(), `course:${route.id}`);\n  if (route.screen === \"week\") return tap(start(), \"Week\");\n  return start();\n}", "note": "A rota vira o `Nav` da aula 10. Um curso abre com `courses` embaixo, a pilha que a aluna teria montado tocando, e a semana é a aba Week na raiz."}]}
```

**`toNav` é onde o *subir* da aula 10 se paga.** Uma aluna que toca num link para um curso nunca viu a
lista de cursos, mas a pilha que o link abre tem `courses` embaixo de `course:sql` mesmo assim. Os
princípios de navegação do Android chamam isso de pilha sintética e pedem que ela seja uma que a aluna
poderia ter montado tocando, que é exatamente o que `open(start(), ...)` constrói. Voltar do curso
então cai na lista, dentro do app, em vez de jogar a aluna para fora dele no primeiro toque.

## Dez links, quatro aceitos

Um segundo arquivo alimenta o parser com links do jeito que eles aparecem na prática: os quatro que ele
deve aceitar, e seis que se parecem o bastante para enganar algo menos rigoroso. Salve-o como
`follow.ts`:

```typescript
// follow.ts: links from outside, and what the planner makes of each
import { parse, toNav } from "./links.ts";

const links = [
  "planner://course/sql",
  "https://planner.example.com/course/sql",
  "https://planner.example.com/week?from=email",
  "planner://courses",
  "http://planner.example.com/course/sql",
  "https://planner.example.net/course/sql",
  "planner://course/SQL Databases",
  "planner://settings/reset",
  "planner://course/sql/delete",
  "planner course sql",
];

for (const link of links) {
  try {
    const nav = toNav(parse(link));
    console.log(`open    ${link}\n        ${nav.tab}: ${nav.stacks[nav.tab].join(" > ")}`);
  } catch (e) {
    console.log(`refuse  ${link}\n        ${(e as Error).message}`);
  }
}
```

Ele precisa do `backstack.ts` da aula 10 ao lado, e de mais nada. Rode:

```
ana@dev:~/planner$ node follow.ts
open    planner://course/sql
        Courses: courses > course:sql
open    https://planner.example.com/course/sql
        Courses: courses > course:sql
open    https://planner.example.com/week?from=email
        Week: week
open    planner://courses
        Courses: courses
refuse  http://planner.example.com/course/sql
        not a planner link: http://planner.example.com
refuse  https://planner.example.net/course/sql
        not a planner link: https://planner.example.net
refuse  planner://course/SQL Databases
        no such screen: /course/SQL%20Databases
refuse  planner://settings/reset
        no such screen: /settings/reset
refuse  planner://course/sql/delete
        no such screen: /course/sql/delete
refuse  planner course sql
        not a URL at all
```

**As duas grafias de um curso abrem a mesma pilha.** É para isso que serve a função `parts`: depois
dela, `planner://course/sql` e o endereço `https` são a mesma lista, `course` e `sql`, e o resto do
parser nunca pergunta como o link foi escrito.

**Cada recusa nomeia um erro diferente.** `http://` não é `https://`, e um link verificado é sempre
`https`, então o simples é recusado em vez de promovido em silêncio. `planner.example.net` está a uma
letra do domínio do planner e pertence a outra pessoa. `SQL Databases` é o título de um curso onde
deveria estar o id; o parser de URL já transformou o espaço em `%20`, e é por isso que a mensagem o
mostra assim, e o padrão do id o recusa. A aula 1 fez as sessões apontarem para um curso pelo id e
nunca pelo título, e um link segue a mesma regra. `settings/reset` nomeia uma tela que o planner não
tem, e `course/sql/delete` acrescenta uma ação a uma tela real: um link abre uma tela, e um caminho com
uma parte a mais não é um pedido para fazer alguma coisa.

**A query string do link da semana é ignorada, não confiada.** `?from=email` é o tipo de etiqueta que
uma newsletter acrescenta a todo link que envia, e recusá-la quebraria os links que as pessoas recebem
de verdade. O parser só lê o esquema, o host e o caminho, então o que a query disser não tem como
chegar a uma tela. A aula 13 volta a etiquetas como essa, pelo lado do que elas revelam.
