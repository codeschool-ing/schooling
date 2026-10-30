---
title: Timestamps, e o relógio que está errado
version: 1
---

**O relógio de um celular é uma configuração que a pessoa pode mudar, e que a rede pode corrigir
tarde ou nunca. Uma mudança carimbada com ele e buscada comparando carimbos se perde sempre que o
relógio que a escreveu estava atrás do relógio que pergunta.** Esse é o argumento inteiro contra
sincronizar por hora, e vale vê-lo acontecer uma vez.

O relógio de um celular está errado com mais frequência do que se imagina. Ele é ajustado à mão para
burlar o cronômetro de um jogo, atrasa num aparelho que ficou desligado uma semana, salta quando uma
rede o corrige e carrega o fuso errado num tablet que nunca saiu da caixa. Nada disso é problema do
servidor até o servidor usar a hora para decidir o que enviar.

## Dois celulares, dez minutos de diferença

O servidor guarda o carimbo que cada celular manda com uma escrita, e responde `/changed-since?t=`
com as linhas carimbadas depois de uma hora: sincronizar por timestamp, como muitos apps fazem. Este
programa faz o papel dos dois celulares. O celular A, com o relógio certo, busca às 10:00 e guarda
dois marcadores, a hora e o cursor. O celular B, com o relógio dez minutos atrasado, acrescenta uma
sessão às 10:05, e a carimba como 09:55. Depois o celular A pergunta o que mudou, dos dois jeitos.
Salve como `clocks.ts`:

```typescript
// clocks.ts: phone A asks what changed, once by timestamp and once by cursor, after phone B,
// whose clock is ten minutes slow, adds a session. The times are written out, not read.
const SERVER = "http://127.0.0.1:8011";
const get = async (path: string) => (await fetch(SERVER + path)).json();

// 10:00 by phone A's clock, which is right: A pulls, and keeps both kinds of bookmark.
const lastPull = "2026-10-21T10:00:00Z";
const { cursor } = await get("/changes?after=0");

// 10:05 in fact: phone B adds a session. B's clock says 09:55, and B stamps the row with it.
await fetch(`${SERVER}/sessions/s7?stamp=2026-10-21T09:55:00Z`, {
  method: "PUT", body: JSON.stringify({ course: "guitar", date: "2026-10-23", minutes: 25 }),
});

// 10:10 by A's clock: what changed since the last pull?
const byTime = (await get(`/changed-since?t=${lastPull}`)) as { id: string }[];
const byCursor = (await get(`/changes?after=${cursor}`)).changes as { id: string }[];
console.log(`by timestamp, after ${lastPull}: ${byTime.map((r) => r.id).join(", ") || "nothing"}`);
console.log(`by cursor, after ${cursor}: ${byCursor.map((r) => r.id).join(", ") || "nothing"}`);
```

Reinicie o servidor, para ele começar de novo das seis sessões da aula 1, e rode:

```
ana@dev:~/planner/delta$ node clocks.ts
by timestamp, after 2026-10-21T10:00:00Z: nothing
by cursor, after 6: s7
```

**Por timestamp, a sessão não existe.** Ela foi escrita depois da última busca do celular A e
carimbada antes dela, então toda pergunta futura "o que mudou depois das 10:00?" a deixa de fora, e
o celular A nunca a vê. Nada falha. Pelo cursor, a mesma pergunta a devolve, porque o servidor
numerou a escrita quando ela chegou, na ordem em que as coisas aconteceram no servidor.

## Se uma hora é tudo o que você tem

Alguns back-ends só oferecem um campo "atualizado em". Três reparos, em ordem de preferência:

- **Carimbe no servidor, não no celular.** O relógio do servidor é um relógio só, e um `updated_at`
  que ele escreve na chegada só erra o quanto aquela máquina erra.
- **Sobreponha a janela.** Peça as mudanças desde alguns minutos antes da última busca, e ignore as
  linhas que já tem. Isso sobrevive a uma diferença pequena e custa algumas duplicatas.
- **Nunca deixe o relógio do celular decidir o que é enviado.** Ele ainda pode ser mostrado à
  pessoa, que reconhece "terça à noite", e ainda pode ser guardado como o que a pessoa viu.

A aula 13 encontra o mesmo relógio de novo, decidindo qual de duas edições vence, onde ele faz mais
estrago.
