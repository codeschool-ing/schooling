---
title: Cor, e o contraste que todo par precisa alcançar
version: 1
---

**Todo par de texto e fundo que os tokens podem produzir precisa ser legível, e legível é um número: a
razão de contraste que o WCAG define, pelo menos 4,5 para 1 para texto comum no nível AA.** A razão
compara a luminância relativa das duas cores, de 1 para cores idênticas a 21 para preto no branco. Ela só
pode ser conferida a olho por quem tem os olhos que ela existe para proteger, então é conferida por um
script.

## A conferência

O `contrast.mjs` lê o mesmo `tokens.json`, resolve cada token semântico para o seu hex e mede os seis
pares que o planner de fato desenha, nos dois temas:

```schooling-example
{"language": "javascript", "file": "contrast.mjs", "parts": [
 {"code": "// contrast.mjs\nimport { readFile } from \"node:fs/promises\";\n\nconst tokens = JSON.parse(await readFile(\"tokens.json\", \"utf8\"));\nconst hex = (ref) => tokens.color[ref.match(/\\{color\\.([\\w-]+)\\}/)[1]].$value;", "note": "De `{color.grey-600}` para `#59626a`, procurando o primitivo."},
 {"code": "const luminance = (h) => {\n  const [r, g, b] = [1, 3, 5]\n    .map((i) => parseInt(h.slice(i, i + 2), 16) / 255)\n    .map((c) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));\n  return 0.2126 * r + 0.7152 * g + 0.0722 * b;\n};", "note": "A luminância relativa do WCAG: cada canal de 0 a 1, linearizado pela curva sRGB, depois ponderado do jeito que o olho pondera, o verde mais e o azul menos."},
 {"code": "const ratio = (a, b) => {\n  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (hi + 0.05) / (lo + 0.05);\n};", "note": "A razão de contraste: a mais clara sobre a mais escura, cada uma mais 0,05. A ordem das duas cores não importa."},
 {"code": "const pairs = [[\"text\", \"surface\"], [\"text\", \"raised\"], [\"muted\", \"surface\"], [\"muted\", \"raised\"], [\"accent\", \"surface\"], [\"on-accent\", \"accent\"]];\nlet failed = 0;\nfor (const name of Object.keys(tokens.theme)) {\n  for (const [fg, bg] of pairs) {\n    const r = ratio(hex(tokens.theme[name][fg].$value), hex(tokens.theme[name][bg].$value));\n    const ok = r >= 4.5;\n    if (!ok) failed++;\n    console.log(`${name.padEnd(6)} ${`${fg} on ${bg}`.padEnd(20)} ${r.toFixed(2).padStart(5)}  ${ok ? \"AA\" : \"FAIL\"}`);\n  }\n}\nprocess.exitCode = failed ? 1 : 0;", "note": "Todo par que o planner desenha, em todo tema do arquivo. Uma falha define o código de saída, então o script consegue parar um pipeline do jeito que um teste falhando para."}
]}
```

```
ana@dev:~/planner$ npm pkg set scripts.contrast="node contrast.mjs"
ana@dev:~/planner$ npm run contrast

> planner@0.0.0 contrast
> node contrast.mjs

light  text on surface      17.63  AA
light  text on raised       16.25  AA
light  muted on surface      6.21  AA
light  muted on raised       5.72  AA
light  accent on surface     5.99  AA
light  on-accent on accent   5.99  AA
dark   text on surface      16.25  AA
dark   text on raised       12.29  AA
dark   muted on surface      8.59  AA
dark   muted on raised       6.49  AA
dark   accent on surface     8.25  AA
dark   on-accent on accent   8.25  AA
```

Doze pares, todos AA. **Agora veja para que ele serve.** O primeiro rascunho destes tokens usava
`grey-400` para o texto mais discreto, um cinza que parece perfeitamente legível numa tela clara para quem
enxerga bem. Ponha-o de volta no tema claro:

```
ana@dev:~/planner$ sed -i 's/{color.grey-600}/{color.grey-400}/' tokens.json
ana@dev:~/planner$ node contrast.mjs
light  text on surface      17.63  AA
light  text on raised       16.25  AA
light  muted on surface      3.12  FAIL
light  muted on raised       2.88  FAIL
light  accent on surface     5.99  AA
light  on-accent on accent   5.99  AA
dark   text on surface      16.25  AA
dark   text on raised       12.29  AA
dark   muted on surface      8.59  AA
dark   muted on raised       6.49  AA
dark   accent on surface     8.25  AA
dark   on-accent on accent   8.25  AA
ana@dev:~/planner$ sed -i 's/{color.grey-400}/{color.grey-600}/' tokens.json
```

**3,12 no branco e 2,88 no painel elevado**, onde 4,5 é o piso, e o último comando pôs o cinza certo de
volta. Ninguém olhando a tela teria chamado aquilo de bug. O tema escuro tem a sua versão da mesma
armadilha: o `grey-400` passa na página escura e falha no painel elevado escuro, então **uma cor precisa
ser conferida contra toda superfície em que pode pousar, em todo tema**, e é por isso que o script mede
pares, e não cores:

```
ana@dev:~/planner$ sed -i 's/{color.grey-300}/{color.grey-400}/' tokens.json
ana@dev:~/planner$ node contrast.mjs | grep FAIL
dark   muted on raised       4.27  FAIL
ana@dev:~/planner$ sed -i 's/{color.grey-400}/{color.grey-300}/' tokens.json
```

## Onde a conferência mora

No pipeline, ao lado da conferência de tipos. Uma mudança de token é uma mudança em toda tela de uma vez,
e uma falha de contraste introduzida por uma é exatamente o tipo de erro que ninguém percebe na revisão.
Acrescentar `npm run contrast` como passo no workflow da aula 3 a põe lá. A razão não é toda a
acessibilidade: ela não diz nada sobre cor usada como único sinal, ou texto sobre uma imagem. Ela é a
parte que é aritmética, e aritmética é o que uma máquina deve fazer.
