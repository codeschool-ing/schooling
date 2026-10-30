---
title: Os dados do planner, anotados antes de serem declarados
version: 1
---

**Um formulário de loja é fácil de preencher com honestidade quando as respostas já existem numa
lista, e difícil quando precisam ser lembradas.** Então o planner mantém uma: todo tipo de dado que ele
toca, por que toca, a palavra da loja para esse motivo, o lugar mais longe aonde o dado viaja, e se uma
aluna conseguiria usar o app sem fornecê-lo. As respostas do formulário saem da lista, em vez de serem
digitadas de memória numa página web, e a lista vive no repositório ao lado do código que teria de mudar
para qualquer uma delas mudar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-where\" aria-label=\"Dados saindo do app para os três lugares aonde podem ir, e o que cada um significa para a declaração da loja. À esquerda, só o aparelho: não coletado, nada a declarar; os cursos, as sessões e os horários de lembrete do planner ficam aqui. No meio, o seu próprio servidor: coletado, declarado com a finalidade. À direita, a empresa de um SDK de terceiros: coletado e compartilhado, declarado mesmo o código não sendo seu.\"><defs><marker id=\"l13-where-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-where-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-where-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"300\" y=\"14\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o app</text><rect x=\"30\" y=\"90\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">só o aparelho</text><rect x=\"270\" y=\"90\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">o seu servidor</text><rect x=\"510\" y=\"90\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"105.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a empresa de um</text><text x=\"600.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">SDK de terceiros</text><path d=\"M330 48 L120 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-where-ah-phosphor)\"></path><path d=\"M360 48 L360 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-where-ah-paper-dim)\"></path><path d=\"M390 48 L600 90\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-where-ah-amber)\"></path><text x=\"120\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">não coletado</text><text x=\"120\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada a declarar</text><text x=\"360\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">coletado</text><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">declarado, com a finalidade</text><text x=\"600\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">coletado e compartilhado</text><text x=\"600\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">declarado, embora o</text><text x=\"600\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">código não seja seu</text><rect x=\"30\" y=\"200\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o planner: cursos, sessões,</text><text x=\"120.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">horários de lembrete</text></svg>", "caption": "Para onde os dados vão decide o que o formulário diz. O planner guarda tudo na caixa da esquerda."}
```

**Para onde o dado vai é a coluna que decide quase tudo.** Dado que fica no aparelho não é coletado,
pela definição da Apple, por mais que seja. Dado que chega ao seu próprio servidor é coletado. Dado que
chega a outra empresa, inclusive a empresa por trás de um SDK dentro do seu app, é coletado e
compartilhado. A figura é a escolha do planner desenhada: tudo o que ele guarda fica na caixa da
esquerda.

## O inventário, e o programa que o lê

Salve isto como `inventory.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "inventory.ts", "parts": [{"code": "// inventory.ts: every kind of data the planner touches, and where each one goes\nexport type Goes = \"device\" | \"our server\" | \"third party\";\nexport type Purpose = \"App Functionality\" | \"Analytics\" | \"Product Personalization\" | \"Third-Party Advertising\";\nexport type Item = {\n  what: string; // the kind of data, as a person would name it\n  why: string; // the reason, in a sentence; an entry without one is refused\n  purpose: Purpose; // the store's word for the reason\n  goes: Goes; // the furthest place it travels\n  optional: boolean; // can the student use the app without giving it?\n};\n", "note": "Uma entrada por tipo de dado. `purpose` usa quatro dos nomes da lista de finalidades da Apple, e `goes` tem os três lugares da figura acima. `why` é uma frase para uma pessoa; `purpose` é a palavra para o formulário."}, {"code": "// The check: every entry says why, before anything is declared.\nexport function check(items: Item[]): void {\n  const bare = items.filter((i) => i.why.trim() === \"\").map((i) => i.what);\n  if (bare.length > 0) throw new Error(`no reason given for: ${bare.join(\", \")}`);\n}\n", "note": "A recusa. Uma entrada com o motivo vazio, ou só com espaços, para tudo, e a mensagem nomeia todas essas entradas de uma vez, não só a primeira."}, {"code": "// The answers a store form asks for, worked out from the inventory. Data that\n// never leaves the device is not collected; data that reaches a third party,\n// an SDK's company included, is collected and shared.\nexport function declare(items: Item[]): string[] {\n  check(items);\n  const away = items.filter((i) => i.goes !== \"device\");\n  if (away.length === 0) return [\"collected: nothing\", \"shared: nothing\"];\n  return away.map((i) => {\n    const shared = i.goes === \"third party\" ? \"shared\" : \"not shared\";\n    const opt = i.optional ? \"optional\" : \"required\";\n    return `collected: ${i.what} (${i.purpose}; ${shared}; ${opt})`;\n  });\n}", "note": "As definições da seção anterior, em código. Só o que sai do aparelho é listado; chegar a um terceiro é o que o torna compartilhado. `declare` chama `check` primeiro, então nenhuma resposta sai de um inventário com um buraco."}]}
```

Um segundo arquivo guarda três inventários. O primeiro é o planner como ele é. O segundo é o mesmo
planner com dois SDKs acrescentados, um relatório de crashes e um kit de analytics, do jeito que uma
equipe os acrescenta numa tarde qualquer. O terceiro tem uma entrada que alguém acrescentou sem dizer
por quê. Salve-o como `declare.ts`:

```typescript
// declare.ts: three inventories, and what each one makes the planner declare
import { declare, type Item } from "./inventory.ts";

const planner: Item[] = [
  { what: "courses", why: "to list what the student is taking", purpose: "App Functionality", goes: "device", optional: false },
  { what: "study sessions", why: "to plan the week and add it up", purpose: "App Functionality", goes: "device", optional: false },
  { what: "reminder times", why: "to remind before a session", purpose: "App Functionality", goes: "device", optional: true },
];

const withSdks: Item[] = [
  ...planner,
  { what: "crash logs", why: "to find and fix crashes", purpose: "App Functionality", goes: "third party", optional: false },
  { what: "screens opened, with a device id", why: "to see which screens are used", purpose: "Analytics", goes: "third party", optional: false },
];

const careless: Item[] = [
  ...planner,
  { what: "contacts", why: "", purpose: "Product Personalization", goes: "our server", optional: true },
];

const inventories: [string, Item[]][] = [
  ["the planner", planner],
  ["with two SDKs", withSdks],
  ["careless", careless],
];

for (const [name, items] of inventories) {
  console.log(`${name}: ${items.length} kinds of data`);
  try {
    for (const line of declare(items)) console.log("  " + line);
  } catch (e) {
    console.log("  refused: " + (e as Error).message);
  }
}
```

Rode:

```
ana@dev:~/planner$ node declare.ts
the planner: 3 kinds of data
  collected: nothing
  shared: nothing
with two SDKs: 5 kinds of data
  collected: crash logs (App Functionality; shared; required)
  collected: screens opened, with a device id (Analytics; shared; required)
careless: 4 kinds of data
  refused: no reason given for: contacts
```

## O que as três respostas dizem

**O planner como ele é não declara nada, porque nada sai do celular.** Cursos, sessões e horários de
lembrete são todos `device`, então a resposta do formulário é que nenhum dado é coletado e nenhum é
compartilhado. Isso não é uma brecha: é a definição, e é a declaração de privacidade mais forte que um
app pode fazer, porque é a única em que a pessoa não precisa confiar em ninguém para ela ser cumprida.

**Dois SDKs transformam três linhas de nada em duas linhas de coleta, as duas compartilhadas.** Nenhum
dos dois é código do planner, e os dois põem o nome do planner na resposta. A entrada de analytics leva
um id do aparelho, que é o detalhe que liga as telas a um aparelho, e esse é o tipo de dado que o
formulário da Apple trata como *ligado ao usuário*. Nada nas telas do planner mudou entre o primeiro
inventário e o segundo. Só as bibliotecas mudaram.

**O inventário descuidado é recusado antes de qualquer declaração.** `contacts` tem um `why` vazio, e
`check` para a declaração inteira em vez de imprimir uma com um buraco. Repare que `why: ""` é uma
`string` perfeitamente boa para o TypeScript, e que o `node` remove os tipos sem conferi-los, como a
aula 1 disse. A regra de que toda entrada tem um motivo é uma regra que o programa impõe quando roda,
porque nenhum tipo consegue dizer "uma frase que signifique algo". Uma entrada que ninguém consegue
explicar é o sinal mais claro de um dado que não vale a pena coletar, que é o assunto da próxima seção.

Faça o commit dos dois arquivos, para que o inventário mude nos mesmos commits que o código que ele
descreve:

```
ana@dev:~/planner$ git add inventory.ts declare.ts
ana@dev:~/planner$ git commit -q -m "The planner's data inventory, and what it declares"
```
