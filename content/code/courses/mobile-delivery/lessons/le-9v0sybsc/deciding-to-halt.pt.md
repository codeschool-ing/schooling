---
title: Decidir interromper, antes que alguém precise decidir
version: 1
---

**A decisão de interromper uma liberação deveria ser uma regra escrita antes do release, e não um
julgamento feito às onze da noite.** A regra compara a versão nova com a antiga, no mesmo dia, entre
pessoas do mesmo tipo, e se recusa a dizer qualquer coisa até que gente suficiente tenha usado a
versão nova para a comparação significar algo.

## A 1.5.0 do planner, simulada

Vinte mil instalações do planner. A versão 1.5.0 tem um bug: em celulares Android mais antigos,
cerca de 8% das instalações, um quarto das aberturas quebra. A liberação segue os sete passos da
Apple. A cada dia, toda instalação cujo **balde** está abaixo da porcentagem do dia recebe a 1.5.0, e
a regra compara os **usuários sem crash** das duas versões: a fração de pessoas que não viu um único
crash naquele dia.

Salve isto como `rollout.ts`:

```schooling-example
{"language": "typescript", "file": "rollout.ts", "parts": [{"code": "// rollout.ts: a staged rollout simulated day by day, and the rule that halts it\nconst STAGES = [1, 2, 5, 10, 20, 50, 100];\nconst INSTALLS = 20_000;\nconst MIN_USERS = 500;\nconst MAX_DROP = 0.5;", "note": "Os sete passos diários da Apple, vinte mil instalações, e os dois números da regra: não dizer nada abaixo de 500 pessoas, interromper numa queda de mais de meio ponto."}, {"code": "function hash(text: string): number {\n  let h = 0x811c9dc5;\n  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 0x01000193) >>> 0;\n  return h;\n}\nconst installs = Array.from({ length: INSTALLS }, (_, i) => `install-${i}`);\nconst bucket = (id: string) => hash(`rollout:${id}`) % 10_000;", "note": "FNV-1a, um hash pequeno que dá o mesmo número para o mesmo texto em toda execução. Cada instalação cai num de 10.000 baldes, para sempre."}, {"code": "const crashes = (id: string, version: \"1.4.0\" | \"1.5.0\") => {\n  const roll = hash(`crash:${version}:${id}`) % 1000;\n  const oldAndroid = hash(`os:${id}`) % 100 < 8;\n  return version === \"1.5.0\" && oldAndroid ? roll < 250 : roll < 5;\n};\nfunction crashFree(ids: string[], version: \"1.4.0\" | \"1.5.0\"): number {\n  return (100 * ids.filter((id) => !crashes(id, version)).length) / ids.length;\n}", "note": "O bug inventado: meio por cento das pessoas quebra em qualquer versão, e na 1.5.0 um quarto dos 8% com Android antigo quebra. Usuários sem crash é a fração que não viu nenhum."}, {"code": "console.log(\"day  stage  on 1.5.0  crash-free 1.5.0  crash-free 1.4.0  decision\");\nfor (const [day, stage] of STAGES.entries()) {\n  const onNew = installs.filter((id) => bucket(id) < stage * 100);\n  const onOld = installs.filter((id) => bucket(id) >= stage * 100);\n  const fresh = crashFree(onNew, \"1.5.0\");\n  const old = onOld.length ? crashFree(onOld, \"1.4.0\") : NaN;", "note": "A cada dia, as instalações abaixo da porcentagem do dia estão na 1.5.0, e o resto ainda na 1.4.0."}, {"code": "  let decision = \"continue\";\n  if (onNew.length < MIN_USERS) decision = `wait: fewer than ${MIN_USERS} users`;\n  else if (old - fresh > MAX_DROP) decision = \"HALT\";\n  console.log(`${String(day + 1).padStart(3)}  ${String(stage).padStart(4)}%  ${String(onNew.length).padStart(8)}  ${fresh.toFixed(2).padStart(15)}%  ${old.toFixed(2).padStart(15)}%  ${decision}`);\n  if (decision === \"HALT\") {\n    console.log(`halted on day ${day + 1}: ${onNew.length} installs keep 1.5.0 until a fix reaches them`);\n    break;\n  }\n}", "note": "A regra, na ordem em que uma pessoa a aplicaria: primeiro, há o bastante para julgar; depois, a versão nova é pior."}]}
```

```
ana@dev:~/planner$ node rollout.ts
day  stage  on 1.5.0  crash-free 1.5.0  crash-free 1.4.0  decision
  1     1%       195            97.95%            99.46%  wait: fewer than 500 users
  2     2%       390            98.21%            99.46%  wait: fewer than 500 users
  3     5%      1011            96.24%            99.46%  HALT
halted on day 3: 1011 installs keep 1.5.0 until a fix reaches them
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l08-halt\" aria-label=\"Um gráfico de usuários sem crash por dia da liberação, de 95% a 100%. A versão 1.4.0 fica em 99,46% nos dias 1 a 3. A versão 1.5.0 tem 97,95% no dia 1 e 98,21% no dia 2, os dois numa faixa sombreada marcada como poucos usuários para julgar, e 96,24% no dia 3, quando a regra interrompe a liberação. Os dias 4 a 7 nunca chegam.\"><rect x=\"65.0\" y=\"30\" width=\"148.33333333333331\" height=\"220\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"139.16666666666666\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">poucos usuários para julgar</text><rect x=\"365.0\" y=\"30\" width=\"335.0\" height=\"220\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"532.5\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">nunca chegam</text><path d=\"M60 250.0 L690 250.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">95%</text><path d=\"M60 206.0 L690 206.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">96%</text><path d=\"M60 162.0 L690 162.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"162.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">97%</text><path d=\"M60 118.0 L690 118.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"118.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">98%</text><path d=\"M60 74.0 L690 74.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">99%</text><path d=\"M60 30.0 L690 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\" fill=\"none\"></path><text x=\"54\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><text x=\"90.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"188.33333333333331\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"286.66666666666663\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"385.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"483.3333333333333\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"581.6666666666667\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"680.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"385.0\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dia</text><text x=\"20\" y=\"12\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">usuários sem crash</text><path d=\"M90.0 53.760000000000275 L188.33333333333331 53.760000000000275 L286.66666666666663 53.760000000000275\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M90.0 120.19999999999987 L188.33333333333331 108.76000000000028 L286.66666666666663 195.44000000000023\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"298.66666666666663\" y=\"53.760000000000275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">1.4.0  99.46%</text><text x=\"100.0\" y=\"134.19999999999987\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">97.95%</text><text x=\"188.33333333333331\" y=\"96.76000000000028\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">98.21%</text><text x=\"298.66666666666663\" y=\"195.44000000000023\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">1.5.0  96.24%</text><text x=\"286.66666666666663\" y=\"217.44000000000023\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">interrompe</text></svg>", "caption": "Os dias 1 e 2 já parecem piores, e a regra ainda espera: com poucas centenas de pessoas, um punhado de crashes move a taxa em um ponto. O dia 3 tem mil, e a diferença é de três pontos."}
```

## Três coisas que a simulação faz e de que uma regra de verdade precisa

**O balde é um hash estável da instalação, e não uma moeda jogada a cada dia.** As mesmas pessoas
ficam na liberação conforme ela cresce, então o grupo do dia 3 contém o do dia 2, e ninguém é levado
de uma versão para outra e de volta. O Google escolhe os usuários do mesmo jeito; o hash da lição só
o torna visível.

**Ela espera uma amostra.** No dia 1, a 1.5.0 parecia pior que a 1.4.0, com 195 pessoas. No dia 2
parecia um pouco melhor do que no dia 1, com 390. Nenhum dos dois números bastava para agir: com
poucas centenas de pessoas, um punhado de crashes move a taxa em um ponto. A regra não diz nada
abaixo de 500, e isso é uma decisão escrita, não uma sensação.

**Ela compara com a versão antiga no mesmo dia.** Uma taxa de 96% sem crash não significa nada
sozinha. Ao lado de 99,46% da versão que todo mundo tem, no mesmo dia e no mesmo tipo de celular,
ela é a queda de 3 pontos que para o release.

## De onde vêm os números na realidade

A simulação inventa os crashes. Uma liberação de verdade os lê no coletor de crashes da lição 12, que
os agrupa por versão, e no console de cada loja: o **Android vitals** do Play Console mostra a taxa
de crash por release, e o App Store Connect mostra crashes por versão dos aparelhos que compartilham
análises. A lição 12 é onde esses números começam.
