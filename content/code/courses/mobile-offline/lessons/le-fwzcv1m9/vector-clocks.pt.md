---
title: Relógios vetoriais, quando não existe um contador único
version: 1
---

**Um número de versão funciona porque um servidor faz a contagem; um relógio vetorial funciona sem
ele.** Cada aparelho mantém o próprio contador para cada linha, e a linha carrega todos eles.
Comparar dois desses relógios diz se uma escrita tinha visto a outra, em qualquer direção, ou
nenhuma das duas. Não precisa de servidor no meio, o que importa quando dois aparelhos sincronizam
diretamente entre si, ou quando vários servidores aceitam escritas e as trocam depois.

As regras cabem em três funções. Salve isto como `vclock.ts` na `~/planner/versions`:

```typescript
// vclock.ts: vector clocks, one counter per device that has written.
export type Clock = Record<string, number>;

// A device's write: its own counter goes up by one.
export const tick = (c: Clock, device: string): Clock => ({ ...c, [device]: (c[device] ?? 0) + 1 });

// What a device knows after receiving another's row: the larger counter of each.
export function merge(a: Clock, b: Clock): Clock {
  const out: Clock = { ...a };
  for (const [k, n] of Object.entries(b)) out[k] = Math.max(out[k] ?? 0, n);
  return out;
}

// a is before b if b has seen everything a has, and more; neither, and they are concurrent.
export function compare(a: Clock, b: Clock): "equal" | "before" | "after" | "concurrent" {
  let less = false;
  let more = false;
  for (const k of new Set([...Object.keys(a), ...Object.keys(b)])) {
    if ((a[k] ?? 0) < (b[k] ?? 0)) less = true;
    if ((a[k] ?? 0) > (b[k] ?? 0)) more = true;
  }
  return less && more ? "concurrent" : less ? "before" : more ? "after" : "equal";
}
```

Um **tick** é uma escrita: o aparelho que escreve aumenta a própria entrada. Um **merge** é o que um
aparelho faz quando recebe a linha de outro: pega o maior valor de cada entrada, então o relógio
dele passa a dizer que viu tudo o que o outro tinha. E o **compare** olha todas as entradas: se um
relógio está atrás em alguma e à frente em nenhuma, ele vem antes do outro; se cada um está à frente
em algum lugar, eles são concorrentes, e isso é um conflito.

Aqui estão as duas manhãs: quarta-feira, quando os dois aparelhos editaram `s3` offline a partir da
mesma linha, e quinta, quando o tablet puxou a mudança do celular antes de fazer a sua. Salve como
`clocks.ts`:

```typescript
// clocks.ts: the two mornings of this lesson, as vector clocks on s3.
import { tick, merge, compare, type Clock } from "./vclock.ts";

const show = (c: Clock) => JSON.stringify(c);

// Wednesday: both devices edit offline, from the same row.
const start: Clock = {};
const phone = tick(start, "phone");
const tablet = tick(start, "tablet");
console.log(`wednesday  phone ${show(phone)}  tablet ${show(tablet)}  -> ${compare(phone, tablet)}`);

// Thursday: the tablet pulls the phone's row first, then edits.
const pulled = merge(start, phone);
const later = tick(pulled, "tablet");
console.log(`thursday   phone ${show(phone)}  tablet ${show(later)}  -> ${compare(phone, later)}`);
console.log(`           tablet ${show(later)}  phone ${show(phone)}  -> ${compare(later, phone)}`);
```

```
ana@dev:~/planner/versions$ node clocks.ts
wednesday  phone {"phone":1}  tablet {"tablet":1}  -> concurrent
thursday   phone {"phone":1}  tablet {"phone":1,"tablet":1}  -> before
           tablet {"phone":1,"tablet":1}  phone {"phone":1}  -> after
```

Na quarta, `{"phone":1}` e `{"tablet":1}` estão cada um à frente numa entrada, então nenhum tinha
visto o outro: **concorrentes**, `concurrent`. Na quinta, o relógio do tablet é `{"phone":1,"tablet":1}`, que cobre o
do celular e acrescenta, então a escrita do celular vem **antes**, `before`, e a do tablet
simplesmente a substitui. Nenhum timestamp foi lido em nenhum dos dias, e um celular duas horas
adiantado daria as mesmas respostas.

## O que um relógio vetorial custa

O relógio cresce uma entrada por aparelho que já escreveu a linha. Um planner usado num celular e num
tablet carrega dois números por linha; um documento compartilhado editado por quarenta pessoas
carrega quarenta, e a entrada de um celular perdido em 2025 fica até alguma coisa decidir que é
seguro descartá-la. Os sistemas que os usam, a começar pelo Dynamo da Amazon, podam entradas antigas
ou usam refinamentos como os *dotted version vectors*, e os detalhes são um assunto à parte.

**Um relógio vetorial detecta um conflito; não o resolve.** "Concorrente" diz ao aparelho que duas
versões precisam ser olhadas. O que guardar de cada uma é a próxima seção, e o trabalho é o mesmo
quer o conflito tenha sido achado por um número de versão, quer por um relógio.

Para o planner, que sincroniza por um servidor só, o número de versão da seção anterior basta, e é um
inteiro por linha. Recorra a relógios vetoriais quando não existe um lugar único que vê toda escrita
primeiro.
