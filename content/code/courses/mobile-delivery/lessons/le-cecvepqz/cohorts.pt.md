---
title: Coortes, e a curva que se achata
version: 1
---

**Retenção é a fração das pessoas que voltam, medida para um grupo de pessoas que começou ao mesmo
tempo.** Esse grupo é uma **coorte**: todo mundo que instalou na semana de 7 de setembro é uma, a
semana de 14 de setembro outra. Acompanhar cada coorte separadamente é o que torna a retenção
honesta. Um total de usuários ativos mistura as instalações novas desta semana com as fiéis do ano
passado, e pode subir enquanto cada coorte vai embora mais rápido que a anterior.

## Quatro coortes, no SQLite

Os dados são uma lista dos dias em que cada instalação abriu o app, os eventos `app_open` da lição 16
reduzidos a uma linha por instalação por dia. Para ter oito semanas deles aqui, um programa curto
faz quatro coortes semanais de 300 instalações, começando nas quatro segundas-feiras de setembro de
2026, com dois tipos de pessoa dentro: um quarto que transforma o planner em hábito, e o resto, que o
experimenta e se afasta. Um gerador com semente faz os mesmos dados em toda execução. Salve isto como
`retention.ts` em `~/planner`:

```typescript
// retention.ts: four weekly cohorts of installs, the weeks they came back, and the ratios people quote
import Database from "better-sqlite3";

let seed = 17;
const random = () => ((seed = (seed * 1103515245 + 12345) % 2147483648) / 2147483648);
const day = (start: string, plus: number) => {
  const d = new Date(`${start}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() + plus);
  return d.toISOString().slice(0, 10);
};

const db = new Database(":memory:");
db.exec("create table opens (install text, cohort text, day text)");
const insert = db.prepare("insert into opens values (?, ?, ?)");
const cohorts = ["2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28"];
for (const cohort of cohorts) {
  for (let i = 0; i < 300; i++) {
    const install = `${cohort}/${i}`;
    const keen = random() < 0.25;
    for (let d = 0; d < 56 && day(cohort, d) <= "2026-10-31"; d++) {
      const week = Math.floor(d / 7);
      const chance = d === 0 ? 1 : (keen ? 0.3 : 0.08) * Math.pow(keen ? 0.92 : 0.35, week);
      if (random() < chance) insert.run(install, cohort, day(cohort, d));
    }
  }
}

console.log("cohort      installs  week 0  week 1  week 2  week 3  week 4");
for (const cohort of cohorts) {
  const cells = [0, 1, 2, 3, 4].map((w) => {
    if (day(cohort, w * 7 + 6) > "2026-10-31") return "".padStart(6);
    const { n } = db.prepare("select count(distinct install) as n from opens where cohort = ? and day >= ? and day < ?")
      .get(cohort, day(cohort, w * 7), day(cohort, w * 7 + 7)) as { n: number };
    return `${Math.round((100 * n) / 300)}%`.padStart(6);
  });
  console.log(`${cohort}  ${"300".padStart(8)}  ${cells.join("  ")}`.trimEnd());
}

const on = "2026-10-26";
const active = (from: string) =>
  (db.prepare("select count(distinct install) as n from opens where day >= ? and day <= ?").get(from, on) as { n: number }).n;
const dau = active(on), wau = active(day(on, -6)), mau = active(day(on, -29));
console.log(`on ${on}: DAU ${dau}, WAU ${wau}, MAU ${mau}, DAU/MAU ${Math.round((100 * dau) / mau)}%, WAU/MAU ${Math.round((100 * wau) / mau)}%`);
```

```
ana@dev:~/planner$ node retention.ts
cohort      installs  week 0  week 1  week 2  week 3  week 4
2026-09-07       300    100%     36%     25%     23%     22%
2026-09-14       300    100%     41%     30%     25%     25%
2026-09-21       300    100%     37%     26%     20%     19%
2026-09-28       300    100%     38%     24%     22%
on 2026-10-26: DAU 59, WAU 247, MAU 652, DAU/MAU 9%, WAU/MAU 38%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l17-curves\" aria-label=\"Quatro curvas de retenção, uma por coorte semanal de setembro de 2026. As quatro começam em 100% na semana 0, caem para entre 36% e 41% na semana 1, e então se achatam: entre 24% e 30% na semana 2, de 20% a 25% na semana 3, e de 19% a 25% na semana 4, em que a última coorte ainda não tem dados.\"><path d=\"M84 230.0 L530 230.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><path d=\"M84 180.0 L530 180.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">25%</text><path d=\"M84 130.0 L530 130.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M84 80.0 L530 80.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">75%</text><path d=\"M84 30.0 L530 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"78\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"90.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"197.5\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"305.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"412.5\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"520.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"305.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">semana</text><text x=\"20\" y=\"12\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fração da coorte que abriu o app</text><path d=\"M90.0 30.0 L197.5 158.0 L305.0 180.0 L412.5 184.0 L520.0 186.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M90.0 30.0 L197.5 148.0 L305.0 170.0 L412.5 180.0 L520.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M90.0 30.0 L197.5 156.0 L305.0 178.0 L412.5 190.0 L520.0 192.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M90.0 30.0 L197.5 154.0 L305.0 182.0 L412.5 186.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M560 180 L590 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">2026-09-07</text><path d=\"M560 198 L590 198\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">2026-09-14</text><path d=\"M560 216 L590 216\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">2026-09-21</text><path d=\"M560 234 L590 234\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"598\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-09-28</text><text x=\"560\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">a primeira semana perde seis em dez</text><text x=\"560\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">depois a curva se achata</text></svg>", "caption": "As quatro coortes desenhadas a partir da tabela. A parte íngreme é a semana 1 e a parte plana são as pessoas para quem o app existe; toda curva tem a mesma forma."}
```

## Lendo a tabela

**Toda coorte perde cerca de seis em cada dez pessoas na primeira semana.** Isso é normal para apps
mobile, e é o número mais importante da tabela: a semana 1 é onde o planner entra ou não entra na
semana de alguém. **Depois a curva se achata.** A partir da semana 2 as coortes perdem poucos pontos
por semana, e na semana 4 cerca de um quinto de cada uma ainda está ali. Essas são as pessoas para
quem o produto existe de fato, e a parte plana da curva é aquilo sobre o que um negócio se constrói.

A última coorte não tem semana 4, porque a quinta semana dela termina depois de 31 de outubro, onde
os dados terminam. Uma semana que não acabou informaria menos pessoas do que vai ter, e pareceria uma
queda que não aconteceu.

## O que um número de retenção precisa ao lado

- **A definição de "voltou"**: aqui, abriu o app pelo menos uma vez na semana. "Terminou uma sessão",
  o último passo da lição 16, é mais rigorosa e mais baixa, e muitas vezes é a melhor.
- **O tamanho da coorte**: 300 pessoas fazem uma porcentagem andar um terço de ponto por pessoa; 30
  pessoas a fazem saltar três.
- **A comparação**: retenção se lê entre coortes, as mais antigas contra as mais novas, para ver se um
  release ou uma mudança na entrada mexeu na semana 1.
