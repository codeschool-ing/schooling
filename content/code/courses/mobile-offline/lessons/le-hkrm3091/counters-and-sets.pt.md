---
title: Um contador e um conjunto que não perdem edição
version: 1
---

**O truque dos dois é o mesmo: nunca mandar um valor que substitui outro, só fatos que se somam.** O
contador da aula 13 perdeu 45 minutos porque cada aparelho mandou o seu total, e dois totais não se
combinam. Mande em vez disso quanto *cada aparelho* somou, e a mescla fica óbvia: guarde a maior
contagem de cada aparelho, e o total é a soma delas. Nada é sobrescrito, porque cada aparelho só
escreve a própria entrada.

O conjunto usa a mesma ideia num caso mais difícil. Remover um item e acrescentar um são operações
opostas, então um aparelho que removeu `weekly` e um que acrescentou `exam` não podem ser atendidos
os dois comparando duas listas. O **conjunto com remoção observada** (*observed-remove set*) dá a
cada adição uma etiqueta única, e uma remoção apaga só as etiquetas que o aparelho dela tinha visto.
Uma adição feita em outro lugar, que quem removeu nunca viu, tem uma etiqueta que a remoção não
menciona, então sobrevive.

Crie a pasta `~/planner/crdt` e salve isto nela como `crdt.ts`:

```schooling-example
{"language": "typescript", "file": "crdt.ts", "parts": [{"code": "// crdt.ts: a counter and a set whose copies always merge to the same state.\n"}, {"code": "// A grow-only counter: each device counts its own additions, and the total is the sum.\nexport type GCounter = Record<string, number>;\nexport const add = (c: GCounter, device: string, n: number): GCounter => ({ ...c, [device]: (c[device] ?? 0) + n });\nexport const total = (c: GCounter) => Object.values(c).reduce((a, b) => a + b, 0);", "note": "Um contador só de crescimento é uma contagem por aparelho. O `add` aumenta só a entrada do aparelho que escreve, e o total é a soma de todas."}, {"code": "export function mergeCounter(a: GCounter, b: GCounter): GCounter {\n  const out = { ...a };\n  for (const [d, n] of Object.entries(b)) out[d] = Math.max(out[d] ?? 0, n);\n  return out;\n}\n", "note": "A mescla guarda a maior contagem de cada aparelho. Tirar um máximo é comutativo, associativo e idempotente, que é a garantia inteira."}, {"code": "// An observed-remove set: every add gets a tag, and a remove deletes only the tags it has seen.\nexport type ORSet = { adds: Record<string, string[]>; removed: string[] };\nexport const empty = (): ORSet => ({ adds: {}, removed: [] });\nexport function insert(s: ORSet, value: string, tag: string): ORSet {\n  return { ...s, adds: { ...s.adds, [value]: [...(s.adds[value] ?? []), tag] } };\n}\nexport function remove(s: ORSet, value: string): ORSet {\n  return { ...s, removed: [...s.removed, ...(s.adds[value] ?? [])] };\n}", "note": "O conjunto com remoção observada. Cada adição registra uma etiqueta ao lado do valor; uma remoção marca como removidas só as etiquetas que esta cópia tem, que são as adições que ela viu."}, {"code": "export function values(s: ORSet): string[] {\n  return Object.keys(s.adds).filter((v) => s.adds[v].some((t) => !s.removed.includes(t))).sort();\n}", "note": "Um valor está no conjunto enquanto pelo menos uma das etiquetas dele não foi removida."}, {"code": "export function mergeSet(a: ORSet, b: ORSet): ORSet {\n  const adds: Record<string, string[]> = {};\n  for (const v of new Set([...Object.keys(a.adds), ...Object.keys(b.adds)])) {\n    adds[v] = [...new Set([...(a.adds[v] ?? []), ...(b.adds[v] ?? [])])].sort();\n  }\n  return { adds, removed: [...new Set([...a.removed, ...b.removed])].sort() };\n}", "note": "A mescla é uma união das adições e uma união das remoções. Uniões também são comutativas, associativas e idempotentes, e o `sort` mantém a ordem guardada igual, o que quer que tenha vindo primeiro."}]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l15-counter\" aria-label=\"Um contador só de crescimento de minutos estudados. Os dois aparelhos sincronizaram por último phone 60 e tablet 40, um total de 100. Offline, o celular soma 30: a cópia dele mostra phone 90, tablet 40, total 130. O tablet soma 45: a cópia dele mostra phone 60, tablet 85, total 145. A mescla guarda a maior contagem de cada aparelho: phone 90, tablet 85, total 175, qualquer que seja a cópia mesclada em qual.\"><defs><marker id=\"l15-counter-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-counter-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"105\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">como os dois sincronizaram</text><rect x=\"20\" y=\"100\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"176\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60</text><text x=\"34\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"176\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"34\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"176\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">100</text><text x=\"355\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o celular soma 30</text><rect x=\"270\" y=\"30\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"284\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"426\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90</text><text x=\"284\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"426\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">40</text><text x=\"284\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"426\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">130</text><text x=\"355\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o tablet soma 45</text><rect x=\"270\" y=\"160\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"284\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"426\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">60</text><text x=\"284\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"426\" y=\"198\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">85</text><text x=\"284\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"426\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">145</text><text x=\"615\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">mesclado: a maior contagem por aparelho</text><rect x=\"530\" y=\"100\" width=\"170\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"544\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">phone</text><text x=\"686\" y=\"118\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90</text><text x=\"544\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">tablet</text><text x=\"686\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">85</text><text x=\"544\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">total</text><text x=\"686\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">175</text><path d=\"M190 125 L270 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-paper-dim)\"></path><path d=\"M190 150 L270 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-paper-dim)\"></path><path d=\"M440 70 L530 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-phosphor)\"></path><path d=\"M440 200 L530 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-counter-ah-phosphor)\"></path></svg>", "caption": "Cada aparelho só escreve a própria entrada, então a mescla não tem entre o que escolher: guarda a maior contagem de cada aparelho, e o total é a soma delas.", "same": ["total"]}
```

Agora os dois aparelhos da aula 13, com os dois tipos de dado que aquela regra perdia. Os minutos
estudados no mês eram 100 quando os dois sincronizaram por último, 60 contados no celular e 40 no
tablet. As etiquetas do curso de Violão eram só `weekly`. Aí, offline, cada aparelho faz a sua.
Salve como `merges.ts`:

```typescript
// merges.ts: two devices change a counter and a set offline, then merge in every order.
import { add, total, mergeCounter, empty, insert, remove, values, mergeSet } from "./crdt.ts";

// Minutes studied this month, as both devices last synced it: 100.
const synced = { phone: 60, tablet: 40 };
const phone = add(synced, "phone", 30);
const tablet = add(synced, "tablet", 45);
console.log("minutes  phone", total(phone), " tablet", total(tablet));
console.log("  phone + tablet          ", total(mergeCounter(phone, tablet)));
console.log("  tablet + phone          ", total(mergeCounter(tablet, phone)));
console.log("  phone + tablet + tablet ", total(mergeCounter(mergeCounter(phone, tablet), tablet)));

// The Guitar course's tags, as both devices last synced them.
const tags = insert(empty(), "weekly", "a1");
const p = insert(tags, "exam", "p1"); // the phone adds a tag
const t = insert(remove(tags, "weekly"), "evening", "t1"); // the tablet removes one and adds one
console.log("tags     phone", values(p).join(", "), " tablet", values(t).join(", "));
console.log("  phone + tablet          ", values(mergeSet(p, t)).join(", "));
console.log("  tablet + phone          ", values(mergeSet(t, p)).join(", "));

// The same tag, added again on the phone while the tablet removes it.
const p2 = insert(tags, "weekly", "p2");
console.log("  re-added on one, removed on the other:", values(mergeSet(p2, t)).join(", "));
```

As etiquetas `a1`, `p1`, `t1` e `p2` estão escritas à mão para a execução ser sempre a mesma; um app
geraria uma aleatória por adição, como os ids criados no aparelho da aula 4. Mescle cada par nos dois
sentidos, e o contador mais uma vez com uma atualização que ele já tinha:

```
ana@dev:~/planner/crdt$ node merges.ts
minutes  phone 130  tablet 145
  phone + tablet           175
  tablet + phone           175
  phone + tablet + tablet  175
tags     phone exam, weekly  tablet evening
  phone + tablet           evening, exam
  tablet + phone           evening, exam
  re-added on one, removed on the other: evening, weekly
```

**175 em toda ordem, e 175 de novo quando a atualização do tablet chega duas vezes.** São as três
propriedades da seção anterior, à vista: a ordem não importou e a repetição não fez nada. As
etiquetas também convergem, para `evening, exam`: a remoção de `weekly` pelo tablet e a adição de
`exam` pelo celular valeram as duas, e a adição do próprio tablet também.

A última linha é o caso que vale ler duas vezes. O celular acrescentou `weekly` de novo, com uma
etiqueta nova, `p2`, enquanto o tablet o removia. A remoção do tablet cobriu `a1`, a única etiqueta
que ele tinha visto, então `p2` sobrevive e `weekly` fica. **Quando uma adição e uma remoção do mesmo
item são concorrentes, a adição vence.** É uma regra que alguém escolheu, e é a certa para etiquetas:
uma etiqueta que reaparece é um incômodo, e uma que some depois de você acrescentá-la é um relato de
bug.

## O que o contador não faz

Um contador só de crescimento só soma. Minutos estudados nunca diminuem, então ele serve; um saldo
que pode diminuir precisa de dois, um para as somas e um para as subtrações, e o valor é a diferença.
Esse par se chama PN-counter. O que nenhum dos dois faz é recusar: nenhuma mescla impede dois
aparelhos offline de gastarem cada um os últimos dez minutos de um orçamento. Uma regra que precisa
valer em todos os aparelhos, a todo momento, precisa de um lugar que diga sim ou não, que é um
servidor, e a caixa de saída da aula 8 já manda a pergunta para ele.
