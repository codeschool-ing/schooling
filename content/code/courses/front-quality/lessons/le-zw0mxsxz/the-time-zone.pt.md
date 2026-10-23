---
title: O defeito é o fuso horário
version: 1
---

**`new Date("2026-10-21")` é meia-noite em Londres, não meia-noite onde você está.** Uma data escrita
sem hora é lida como UTC, e todo método `get…` de um `Date` responde no fuso do próprio computador.
Este curso foi gravado em São Paulo, três horas atrás do UTC, onde essa meia-noite é 21:00 da terça,
dia 20.

Então o `weekOf` pergunta ao dia errado que dia é. O `getDay()` diz terça, a segunda fica um dia
atrás, e o código volta até as 21:00 da segunda 19 em São Paulo, que é meia-noite do dia **20** no
UTC. O `toISOString()` escreve em UTC, e mostra `2026-10-20`. Cada passo está certo sozinho, e a
resposta sai um dia atrasada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l02-midnight\" aria-label=\"Duas linhas do tempo, uma acima da outra, cobrindo a terça 20 e a quarta 21 de outubro de 2026. A de cima é o UTC, a de baixo é São Paulo, três horas atrás. new Date(&quot;2026-10-21&quot;) está marcado à meia-noite do dia 21 no UTC, e o mesmo instante cai às 21:00 da terça 20 em São Paulo. O getDay() lê a linha de baixo e responde terça, então a semana calculada a partir dele começa um dia atrasada.\"><text x=\"138\" y=\"70\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">UTC</text><path d=\"M150 70 L690 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150.0 62 L150.0 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"154.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">terça 20</text><path d=\"M420.0 62 L420.0 78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"424.0\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quarta 21</text><text x=\"138\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">São Paulo (UTC−3)</text><path d=\"M150 160 L690 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M183.75 152 L183.75 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"187.75\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">terça 20</text><path d=\"M453.75 152 L453.75 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"457.75\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quarta 21</text><path d=\"M420.0 40 L420.0 172\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"420.0\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">new Date(\"2026-10-21\")</text><text x=\"426.0\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">o mesmo instante</text><rect x=\"183.75\" y=\"176\" width=\"270.0\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"318.75\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o getDay() lê esta linha: terça</text><text x=\"414.0\" y=\"145\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">21:00</text><text x=\"414.0\" y=\"84\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">00:00</text></svg>", "caption": "Uma data sem hora é lida como meia-noite no UTC. Três horas atrás, esse instante ainda é a noite anterior, e todo método local responde pela noite anterior.", "same": ["UTC", "São Paulo (UTC−3)"]}
```

O teste prova que é o fuso, porque passa num fuso em que as duas meias-noites caem no mesmo dia:

```
ana@dev:~/planner$ TZ=UTC npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  22:31:27
   Duration  150ms (transform 50%, import 29%, tests 12%, worker 9%)
```

A variável `TZ` diz a um programa que fuso usar, só naquele comando. No UTC não há o que errar, e
**alguém em Lisboa ou em Londres teria visto este teste passar**, publicado o planner, e ouvido falar
do problema por um estudante no Brasil. Um teste que depende do fuso da máquina tem uma resposta que
depende de quem o roda.

## A correção

Faça toda a conta num fuso só. Um dia sem hora não pertence a fuso nenhum, então leia-o como UTC de
propósito e fique no UTC: `getUTCDay` e `setUTCDate` no lugar de `getDay` e `setDate`, e o
`toISOString` fica como está, porque já era UTC.

```
ana@dev:~/planner$ git diff src/planner.ts
diff --git a/src/planner.ts b/src/planner.ts
index 50c1b3f..979e7ab 100644
--- a/src/planner.ts
+++ b/src/planner.ts
@@ -38,11 +38,11 @@ export function today(now: Date = new Date()): string {
 }
 
 export function weekOf(day: string): [string, string] {
-  const d = new Date(day);
+  const d = new Date(`${day}T00:00:00Z`);
   const monday = new Date(d);
-  monday.setDate(d.getDate() - ((d.getDay() + 6) % 7));
+  monday.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
   const sunday = new Date(monday);
-  sunday.setDate(monday.getDate() + 6);
+  sunday.setUTCDate(monday.getUTCDate() + 6);
   return [monday.toISOString().slice(0, 10), sunday.toISOString().slice(0, 10)];
 }
 
```

O `T00:00:00Z` diz meia-noite no UTC em voz alta, em vez de deixar isso para o jeito como o `Date`
lê uma data sem hora. Agora os mesmos três testes em três fusos, Tóquio nove horas à frente, São Paulo
três atrás e Honolulu dez atrás:

```
ana@dev:~/planner$ for tz in Asia/Tokyo America/Sao_Paulo Pacific/Honolulu; do echo "== $tz"; TZ=$tz npx vitest run | grep Tests; done
== Asia/Tokyo
      Tests  3 passed (3)
== America/Sao_Paulo
      Tests  3 passed (3)
== Pacific/Honolulu
      Tests  3 passed (3)
```

Verde em todos. **Rode um teste de data em mais de um fuso pelo menos uma vez**, porque aquele em que
você está é aquele em que seus erros não aparecem. O `today()` é o caso oposto: ele precisa usar o
calendário local, porque o "hoje" de um estudante é a data na parede da casa dele, e o teste dele está
na seção sobre substitutos e tempo.

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Test the week, and compute it in UTC"
```
