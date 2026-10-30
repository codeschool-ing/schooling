---
title: Uma matriz de notas, e o peso que a vira
version: 1
---

**Uma matriz de decisão transforma as sete perguntas em aritmética: um peso para o quanto cada
critério importa, uma nota para o quanto cada abordagem o atende, e um total por abordagem.** A
aritmética é trivial. O valor está em deixar cada julgamento visível, para que uma equipe discuta "o
tempo até a loja é 3 ou 5 para nós?" em vez de discutir qual ferramenta é melhor.

## A matriz do planner

Aqui está uma para o planner, como a startup da etapa anterior poderia preenchê-la: uma equipe que
escreve TypeScript, já tem o planner como app web e quer as duas lojas. **As notas são julgamentos
para essa equipe, não fatos sobre as ferramentas**, e a primeira coisa a fazer com este arquivo é
discordar de algumas delas. Salve em `~/planner` como `choose.ts`:

```schooling-example
{"language": "typescript", "file": "choose.ts", "parts": [{"code": "// choose.ts: criteria, approaches and weights, for one team's decision\ntype Approach = \"native\" | \"react-native\" | \"flutter\" | \"kmp\" | \"wrapper\";\ntype Row = Record<Approach, number>;\n\n// How much each criterion matters to this team: 0 (not at all) to 5.\nconst weights: Record<string, number> = {\n  languages: 4,\n  features: 2,\n  performance: 2,\n  time: 3,\n  platforms: 3,\n  cost: 3,\n  hiring: 2,\n};\n", "note": "Os pesos: as prioridades da equipe, e a parte do arquivo a discutir primeiro. Zero quer dizer que o critério não conta nada."}, {"code": "// How well each approach serves each criterion, for this team: 1 to 5.\nconst scores: Record<string, Row> = {\n  languages:   { native: 1, \"react-native\": 5, flutter: 2, kmp: 1, wrapper: 5 },\n  features:    { native: 5, \"react-native\": 4, flutter: 4, kmp: 5, wrapper: 3 },\n  performance: { native: 5, \"react-native\": 4, flutter: 4, kmp: 5, wrapper: 2 },\n  time:        { native: 1, \"react-native\": 3, flutter: 3, kmp: 2, wrapper: 5 },\n  platforms:   { native: 2, \"react-native\": 5, flutter: 5, kmp: 4, wrapper: 5 },\n  cost:        { native: 2, \"react-native\": 4, flutter: 4, kmp: 3, wrapper: 3 },\n  hiring:      { native: 4, \"react-native\": 4, flutter: 3, kmp: 2, wrapper: 4 },\n};\n", "note": "As notas, uma linha por critério. `languages` dá 5 ao React Native e ao embrulho porque esta equipe escreve TypeScript; `time` dá 5 ao embrulho porque o app web da equipe já tem as telas. Outra equipe preenche números diferentes."}, {"code": "function fail(message: string): never {\n  console.error(message);\n  process.exit(1);\n}\n\n// node choose.ts time=5 changes one weight for this run.\nfor (const arg of process.argv.slice(2)) {\n  const [name, value] = arg.split(\"=\");\n  if (!(name in weights)) fail(`no criterion \"${name}\"; there are: ${Object.keys(weights).join(\", \")}`);\n  const w = Number(value);\n  if (!Number.isInteger(w) || w < 0 || w > 5) fail(`the weight of ${name} must be 0 to 5, not \"${value}\"`);\n  weights[name] = w;\n}\n", "note": "Um peso pode ser mudado na linha de comando, para uma execução, sem editar o arquivo. Um nome que não é critério, ou um peso fora de 0 a 5, para o programa em vez de ser ignorado."}, {"code": "const approaches = Object.keys(scores.languages) as Approach[];\nconst ranked = approaches\n  .map((a) => ({ a, total: Object.keys(weights).reduce((sum, c) => sum + weights[c] * scores[c][a], 0) }))\n  .sort((x, y) => y.total - x.total);\n\nconsole.log(\"weights:\", Object.entries(weights).map(([c, w]) => `${c} ${w}`).join(\", \"));\nfor (const { a, total } of ranked) console.log(String(total).padStart(4), a);", "note": "O total de cada abordagem é a soma de peso vezes nota nos sete critérios, e a lista sai do maior para o menor, embaixo dos pesos que a produziram."}]}
```

Rode:

```
ana@dev:~/planner$ node choose.ts
weights: languages 4, features 2, performance 2, time 3, platforms 3, cost 3, hiring 2
  80 react-native
  77 wrapper
  66 flutter
  55 kmp
  47 native
```

**React Native em primeiro, o embrulho três pontos atrás.** Confira os totais contra as notas: o
React Native tem 5 em `languages`, com peso 4, o que dá 20 dos 80 dele; o nativo tem 1 ali, o que dá
4, e perde boa parte do terreno nessa linha. A matriz não disse nada que você não pudesse ter
argumentado. Ela disse de um jeito em que cada passo pode ser conferido.

## Mude um peso

Agora suponha que os investidores adiantem a data, e o tempo até a loja deixe de ser 3 e passe a ser
5. Nada mudou nas ferramentas:

```
ana@dev:~/planner$ node choose.ts time=5
weights: languages 4, features 2, performance 2, time 5, platforms 3, cost 3, hiring 2
  87 wrapper
  86 react-native
  72 flutter
  59 kmp
  49 native
```

**A ordem vira.** O embrulho tem 5 em `time` e o React Native 3, então dois pontos de peso valem 10
para um e 6 para o outro, e uma vantagem de três pontos vira uma desvantagem de um. Essa é a aula
inteira numa execução: **os pesos são a decisão.** As notas descrevem as ferramentas para esta
equipe; os pesos descrevem o que a equipe quer, e uma mudança pequena no que ela quer pode mudar a
resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l03-flip\" aria-label=\"Dois gráficos de barras da matriz do planner. Com tempo até a loja de peso 3: React Native 80, embrulho 77, Flutter 66, Kotlin Multiplatform 55, nativo 47. Com tempo até a loja de peso 5, e nada mais mudado: embrulho 87, React Native 86, Flutter 72, Kotlin Multiplatform 59, nativo 49. As duas primeiras posições trocam.\"><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">time com peso 3</text><text x=\"112\" y=\"47\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">react-native</text><rect x=\"120\" y=\"36\" width=\"176\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"302\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">80</text><text x=\"112\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">wrapper</text><rect x=\"120\" y=\"68\" width=\"169\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"295\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">77</text><text x=\"112\" y=\"111\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flutter</text><rect x=\"120\" y=\"100\" width=\"145\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"271\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">66</text><text x=\"112\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kmp</text><rect x=\"120\" y=\"132\" width=\"121\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"247\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">55</text><text x=\"112\" y=\"175\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">native</text><rect x=\"120\" y=\"164\" width=\"103\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"229\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">47</text><text x=\"380\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">time com peso 5</text><text x=\"472\" y=\"47\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">wrapper</text><rect x=\"480\" y=\"36\" width=\"191\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"677\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">87</text><text x=\"472\" y=\"79\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">react-native</text><rect x=\"480\" y=\"68\" width=\"189\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"675\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">86</text><text x=\"472\" y=\"111\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flutter</text><rect x=\"480\" y=\"100\" width=\"158\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"644\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">72</text><text x=\"472\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">kmp</text><rect x=\"480\" y=\"132\" width=\"130\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"616\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">59</text><text x=\"472\" y=\"175\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">native</text><rect x=\"480\" y=\"164\" width=\"108\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"594\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">49</text></svg>", "caption": "Um peso subiu dois pontos, e as duas primeiras posições trocam. As notas não mudaram; o que a equipe quer mudou."}
```

**Nem todo peso é tão sensível**, e isso também vale saber. Digamos que o app ganhou uma linha do
tempo animada, e o desempenho foi de 2 para 5:

```
ana@dev:~/planner$ node choose.ts performance=5
weights: languages 4, features 2, performance 5, time 3, platforms 3, cost 3, hiring 2
  92 react-native
  83 wrapper
  78 flutter
  70 kmp
  62 native
```

O nativo sobe de 47 para 62 e o Kotlin Multiplatform de 55 para 70, e o React Native continua em
primeiro, nove pontos à frente do embrulho. Uma ordem que sobrevive a uma mudança grande num peso é
uma em que a equipe pode confiar; uma ordem que vira com um ponto é sinal de que os dois primeiros
estão perto, e de que a decisão depende daquele critério. Os dois achados são úteis, e os dois vêm
de mudar um número e rodar o arquivo de novo.

## O que o programa recusa

Um erro de digitação no nome de um critério, sem essa checagem, não mudaria nada e pareceria uma
resposta, então o programa avisa e para:

```
ana@dev:~/planner$ node choose.ts speed=5
no criterion "speed"; there are: languages, features, performance, time, platforms, cost, hiring
```

**O que a matriz não faz é escolher as notas e os pesos por você.** Uma equipe que define os pesos
depois de decidir, para fazer a favorita ganhar, escreveu uma justificativa, não uma decisão. A ordem
honesta é primeiro os pesos, anotados e combinados antes de alguém somar uma coluna, depois as notas,
depois a execução. Faça o commit do arquivo:

```
ana@dev:~/planner$ git add choose.ts
ana@dev:~/planner$ git commit -q -m "A decision matrix for the planner team"
```
