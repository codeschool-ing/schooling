---
title: Uma tela que diz o que sabe
version: 1
---

**Uma tela que depende da rede está num de quatro estados, e nunca deveria ficar em dúvida qual.**
Ela está carregando, ou mostra o que o servidor acabou de dizer, ou mostra uma cópia mais antiga
porque não conseguiu alcançar o servidor, ou não tem nada para mostrar. O erro comum é desenhar só os
dois primeiros: um spinner, e depois os dados. Aí vem o elevador, e a aluna ganha um spinner que
nunca para, ou uma semana vazia que parece exatamente uma semana sem nada planejado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l14-states\" aria-label=\"Os quatro estados de uma tela que carrega pela rede. Carregando leva a atual quando o servidor responde. Quando não responde, a tela procura uma cópia salva: com ela, mostra o estado desatualizado, os dados salvos e a idade deles; sem ela, mostra o estado de erro, o que deu errado e um botão Tentar de novo. Tentar de novo, a partir de desatualizado ou de erro, volta a carregando.\"><defs><marker id=\"l14-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l14-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carregando</text><text x=\"95.0\" y=\"131.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedindo, com um prazo</text><rect x=\"270\" y=\"20\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"38.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">atual</text><text x=\"355.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a semana, como veio</text><rect x=\"290\" y=\"170\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"355.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">há cópia</text><text x=\"355.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">salva?</text><rect x=\"520\" y=\"110\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"128.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desatualizada</text><text x=\"615.0\" y=\"141.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a semana salva, e a idade</text><rect x=\"520\" y=\"190\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"208.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">erro</text><text x=\"615.0\" y=\"221.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o que deu errado, e Tentar de novo</text><path d=\"M170 112 L270 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-phosphor)\"></path><text x=\"200\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">respondeu</text><path d=\"M170 138 L290 192\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-amber)\"></path><text x=\"200\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falhou ou estourou o prazo</text><path d=\"M420 186 L520 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path><text x=\"466\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sim</text><path d=\"M420 206 L520 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path><text x=\"470\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">não</text><path d=\"M615 110 L615 90 L95 90 L95 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path><text x=\"560\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">Tentar de novo</text><path d=\"M710 215 L714 215 L714 250 L12 250 L12 125 L20 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l14-states-ah-paper-dim)\"></path></svg>", "caption": "Quatro estados, e cada um diz uma coisa diferente. Desatualizada com a idade, e um erro com saída, são os dois que a maioria dos apps esquece."}
```

Cada estado tem uma coisa que precisa dizer:

| estado | o que a tela mostra | o que ela não pode fazer |
|---|---|---|
| carregando | que está perguntando | girar para sempre: o prazo encerra isso |
| atual | a semana, como o servidor mandou | nada além disso |
| desatualizada | a semana salva, **e a idade dela** | fazer a cópia antiga passar por atual |
| erro | o que deu errado, nas palavras do usuário, e um jeito de tentar de novo | mostrar uma semana vazia, ou um stack trace |

**O estado desatualizado é o que torna um app usável num elevador.** A semana do planner muda
poucas vezes por dia, no máximo, então uma cópia de duas horas atrás quase sempre está certa, e é
muito mais útil do que nada. O que a torna honesta é a idade ao lado: a aluna pode decidir por
conta própria se a cópia serve. Um app que mostra a cópia antiga sem dizer troca "não consegui
conferir" por uma afirmação de que conferiu.

## A tela da semana, sem tela

O `screen.ts` faz o que a tela da semana do planner faz com a rede, e imprime o texto da tela em vez
de desenhá-la. Ele pergunta ao servidor com um prazo de cinco segundos; quando dá certo, salva a
resposta em `week.json` com a hora em que ela veio. Quando falha, lê a cópia salva e diz a idade
dela. O "agora" vem como argumento, como o "hoje" no `week.ts` da aula 1, para que as idades abaixo
saiam iguais no seu computador. Salve como `screen.ts`:

```typescript
// screen.ts: what the week screen says, from the server or from the copy it kept
import { readFileSync, writeFileSync } from "node:fs";
import { fetchWeek } from "./fetchweek.ts";

type Week = { monday: string; planned: number; done: number };
type Saved = { fetchedAt: string; week: Week };

const now = new Date(process.argv[2]); // given, like "today" in week.ts
const show = (w: Week) => `week of ${w.monday}: ${w.done} of ${w.planned} minutes done`;

function ago(then: string): string {
  const min = Math.round((now.getTime() - new Date(then).getTime()) / 60000);
  return min < 60 ? `${min} min` : `${Math.floor(min / 60)} h ${min % 60} min`;
}

function saved(): Saved | undefined {
  try {
    return JSON.parse(readFileSync("week.json", "utf8"));
  } catch {
    return undefined; // no copy, or one that cannot be read: either way nothing to show
  }
}

console.log("Loading the week…");
try {
  const week: Week = await fetchWeek("http://127.0.0.1:8014/week", { timeoutMs: 5000 });
  writeFileSync("week.json", JSON.stringify({ fetchedAt: now.toISOString(), week }));
  console.log(show(week));
} catch {
  const copy = saved();
  if (copy) {
    console.log(`${show(copy.week)} (saved ${ago(copy.fetchedAt)} ago, could not refresh)`);
  } else {
    console.log("Could not reach the planner, and there is no saved copy yet.");
  }
  console.log("[Try again]");
}
```

**Rode três vezes: com o servidor de pé, com ele parado e com a cópia salva apagada.** A primeira
execução é às 8h30 da manhã em São Paulo. Depois pare o servidor com Ctrl+C no terminal dele, e rode
de novo às 10h45:

```
ana@dev:~/planner$ node screen.ts 2026-10-21T08:30:00-03:00
Loading the week…
week of 2026-10-19: 120 of 180 minutes done
ana@dev:~/planner$ cat week.json
{"fetchedAt":"2026-10-21T11:30:00.000Z","week":{"monday":"2026-10-19","planned":180,"done":120}}
ana@dev:~/planner$ node screen.ts 2026-10-21T10:45:00-03:00
Loading the week…
week of 2026-10-19: 120 of 180 minutes done (saved 2 h 15 min ago, could not refresh)
[Try again]
ana@dev:~/planner$ rm week.json
ana@dev:~/planner$ node screen.ts 2026-10-21T10:46:00-03:00
Loading the week…
Could not reach the planner, and there is no saved copy yet.
[Try again]
```

A primeira execução alcançou o servidor e salvou a resposta; o `week.json` guarda a hora em UTC, que
está três horas à frente de São Paulo, e a semana como veio. A segunda execução encontrou uma
conexão recusada, porque nada escuta mais na porta 8014, e mostrou a semana salva com a idade:
**2 h 15 min**, das 8h30 às 10h45. A terceira não tinha cópia em que se apoiar, e disse isso, junto
com a única coisa que a aluna pode fazer a respeito.

## O que fica de fora de propósito

**A cópia aqui é um pequeno arquivo JSON na pasta de trabalho**, o que basta para mostrar os estados.
Num celular ela mora no armazenamento do próprio app, e a aula 16 é sobre onde fica isso e o que o
sistema pode apagar. O erro também é vago de propósito para a aluna: "não consegui alcançar o
planner" é algo sobre o qual ela pode agir, e o `ECONNREFUSED` por trás disso pertence a um log para
quem desenvolve, não à tela.

**A tela também se atualiza sozinha**, num app de verdade, quando a rede volta, que é o callback de
conectividade fazendo o único trabalho em que é bom. O curso `mobile-offline` leva a ideia muito mais
longe na aula 7, em que o app escreve primeiro na própria cópia e o servidor fica sabendo depois.
