---
title: Pairwise, ou todo par em vez de toda combinação
version: 1
---

**Teste pairwise (todos os pares) escolhe combinações de modo que todo valor de toda dimensão se
encontre com todo valor de cada outra dimensão pelo menos uma vez.** Ele se apoia numa observação
sobre defeitos reais. A maioria é disparada por um ajuste sozinho, como uma tela pequena, ou por dois
juntos, como uma tela pequena em português. Bem menos precisam de três ou mais valores específicos
ao mesmo tempo. Estudos de relatos de falha feitos pelo NIST, entre outros, encontraram esse padrão
em muitos tipos de software. Testar todo par pega os dois primeiros tipos com uma fração das linhas.

A crença errada é que menos combinações significam menos cobertura na mesma proporção, e que 12 linhas de
72 testariam um sexto do que as 72 testam. Elas testam todo par de valores junto, que é tudo o
que a maioria dos defeitos precisa. **O que elas abrem mão tem nome.** Pense num defeito que só aparece com
Android 12 num tablet da Xiaomi em inglês, três valores específicos ao mesmo tempo. Ele só é pego se essa
linha calhar de ser escolhida.

## Um conjunto pairwise, montado por um script

A matriz da seção 02 tem quatro versões do Android: as três que cobrem 90% das sessões da seção 03,
mais a 12, a mais antiga que ainda vale uma linha. Tem três classes de tela, os três fabricantes que
cobrem 96.4% e dois idiomas. O script monta o produto completo e lista todo par de valores que
precisa se encontrar. Então, de forma gulosa, vai pegando a combinação que cobre mais pares ainda não cobertos,
até não sobrar nenhum. Salve como `matrix/pairwise.mjs`:

```js
// matrix/pairwise.mjs: a pairwise set for a compatibility matrix, built greedily
const factors = {
  android: ['12', '13', '14', '15'],
  screen: ['small phone', 'large phone', 'tablet'],
  maker: ['Samsung', 'Motorola', 'Xiaomi'],
  language: ['pt-BR', 'en'],
};
const names = Object.keys(factors);

// every combination of one value per factor: the full product
let all = [[]];
for (const name of names) {
  all = all.flatMap((row) => factors[name].map((value) => [...row, value]));
}

// the pairs one row covers: a value of one factor beside a value of another
const pairsOf = (row) => {
  const out = [];
  for (let i = 0; i < row.length; i++) {
    for (let j = i + 1; j < row.length; j++) out.push(`${i}=${row[i]}|${j}=${row[j]}`);
  }
  return out;
};
const uncovered = new Set(all.flatMap(pairsOf));
const total = uncovered.size;

// greedy: take the row that covers the most pairs not yet covered, until none is left
const chosen = [];
while (uncovered.size > 0) {
  let best = null;
  let gain = 0;
  for (const row of all) {
    const g = pairsOf(row).filter((p) => uncovered.has(p)).length;
    if (g > gain) [best, gain] = [row, g];
  }
  chosen.push(best);
  for (const p of pairsOf(best)) uncovered.delete(p);
}

console.log(names.map((n) => n.padEnd(13)).join('').trimEnd());
for (const row of chosen) console.log(row.map((v) => v.padEnd(13)).join('').trimEnd());
console.log(`${chosen.length} rows cover all ${total} pairs; the full product has ${all.length} rows`);
```

```
ana@laptop:~/boxoffice$ node matrix/pairwise.mjs
android      screen       maker        language
12           small phone  Samsung      pt-BR
12           large phone  Motorola     en
13           small phone  Xiaomi       en
13           tablet       Motorola     pt-BR
14           large phone  Xiaomi       pt-BR
14           tablet       Samsung      en
15           small phone  Motorola     pt-BR
15           large phone  Samsung      en
12           tablet       Xiaomi       pt-BR
13           large phone  Samsung      pt-BR
14           small phone  Motorola     pt-BR
15           tablet       Xiaomi       pt-BR
12 rows cover all 53 pairs; the full product has 72 rows
```

**12 linhas cobrem todos os 53 pares que as 72 linhas contêm.** Leia duas colunas quaisquer e todo
pareamento aparece em algum lugar: Android 12 com tablet na linha 9, Xiaomi com inglês na linha 3, um
celular pequeno em português nas linhas 1, 7 e 11. Doze é também o mínimo que qualquer conjunto
conseguiria aqui. As quatro versões do Android e as três telas sozinhas formam doze pares, e
cada linha só carrega um deles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 342\" role=\"img\" aria-label=\"Uma grade com as 72 combinações: quatro versões do Android vezes três classes de tela na lateral, três fabricantes vezes dois idiomas no alto. Doze células estão preenchidas e numeradas de 1 a 12 na ordem em que o script pairwise as imprimiu; todo grupo de três telas de uma versão do Android, e toda coluna de fabricante e idioma, tem pelo menos uma célula preenchida, e todo par de valores divide uma célula preenchida em algum lugar.\"><text x=\"284\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Samsung</text><text x=\"249\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pt-BR</text><text x=\"319\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">en</text><text x=\"424\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Motorola</text><text x=\"389\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pt-BR</text><text x=\"459\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">en</text><text x=\"564\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Xiaomi</text><text x=\"529\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">pt-BR</text><text x=\"599\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">en</text><text x=\"56\" y=\"102.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 12</text><text x=\"204\" y=\"83.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular pequeno</text><rect x=\"216\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"249\" y=\"83.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><rect x=\"286\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"76\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"102.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular grande</text><rect x=\"216\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"459\" y=\"102.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><rect x=\"496\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"95\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"121.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"529\" y=\"121.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">9</text><rect x=\"566\" y=\"114\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"56\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 13</text><text x=\"204\" y=\"140.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular pequeno</text><rect x=\"216\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"133\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"599\" y=\"140.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"204\" y=\"159.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular grande</text><rect x=\"216\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"249\" y=\"159.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">10</text><rect x=\"286\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"152\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"178.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"389\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><rect x=\"426\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"171\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"56\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 14</text><text x=\"204\" y=\"197.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular pequeno</text><rect x=\"216\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"389\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">11</text><rect x=\"426\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"190\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"216.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular grande</text><rect x=\"216\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"529\" y=\"216.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><rect x=\"566\" y=\"209\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"235.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"319\" y=\"235.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><rect x=\"356\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"228\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"56\" y=\"273.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Android 15</text><text x=\"204\" y=\"254.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular pequeno</text><rect x=\"216\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"389\" y=\"254.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">7</text><rect x=\"426\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"247\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"273.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">celular grande</text><rect x=\"216\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"319\" y=\"273.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">8</text><rect x=\"356\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"566\" y=\"266\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"204\" y=\"292.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tablet</text><rect x=\"216\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"286\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"356\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"426\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><rect x=\"496\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"529\" y=\"292.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">12</text><rect x=\"566\" y=\"285\" width=\"66\" height=\"15\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1\"></rect><text x=\"350\" y=\"324\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12 das 72 combinações, numeradas como o script as imprimiu; todo par de valores se encontra em pelo menos uma</text></svg>", "caption": "O produto completo tem 72 células; o conjunto pairwise preenche 12 delas e ainda junta todo par de valores pelo menos uma vez.", "same": ["Android 12", "Android 13", "Android 14", "Android 15", "Motorola", "Samsung", "Xiaomi", "tablet"]}
```

## O que uma ferramenta faz e este script não

Um script guloso como este basta para ver a ideia e montar uma matriz pequena. Ferramentas de
verdade, o PICT da Microsoft entre elas, acrescentam o que uma matriz real precisa:

- restrições, porque algumas combinações não existem. Um tablet Motorola com Android 15 pode não
  ser vendido, e o conjunto precisa ser montado em volta disso em vez de conter uma linha que
  ninguém consegue rodar;
- uma força maior onde se quer: todo trio de valores para as duas ou três dimensões que você
  mais teme, pares para o resto;
- sementes, para linhas que você precisa ter, como o seu celular mais vendido na versão atual.
  Elas ficam dentro, e o resto é montado em volta.

Seja o que for que o monte, **um conjunto pairwise é uma lista de configurações, não de testes**.
Cada linha é um aparelho onde rodar a mesma suíte: os testes Appium ou Espresso das lições 15 e 16,
que a seção 06 aponta para uma nuvem.
