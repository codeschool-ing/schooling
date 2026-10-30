---
title: Contraste, calculado em vez de julgado a olho
version: 1
---

**Se uma cor pode ser lida sobre outra é um número, e o número é uma fórmula publicada, não questão
de gosto.** Um designer diante de um monitor claro vê perfeitamente uma data em cinza claro. Um aluno
numa tela barata, ao ar livre, com o brilho baixo para poupar bateria, ou com baixa visão, não vê. As
Web Content Accessibility Guidelines, a WCAG 2.2, publicadas pelo W3C em `w3.org/TR/WCAG22`, definem a
aritmética, e as duas plataformas apontam para ela: a página de acessibilidade das HIG cita a WCAG, e
a documentação do Android dá os mesmos limites nas unidades dela.

## Os limites

| o quê | razão de pelo menos | WCAG 2.2 |
|---|---|---|
| texto comum | **4,5 : 1** | 1.4.3 Contrast (Minimum), nível AA |
| texto grande: 18 pontos, ou 14 pontos em negrito | **3 : 1** | a exceção do mesmo critério para texto em escala grande |
| as partes de um controle de que o usuário precisa para vê-lo, como a borda de uma caixa de seleção | **3 : 1** | 1.4.11 Non-text Contrast, nível AA |

A documentação do Android enuncia a regra do texto em `sp`: 4,5:1 para texto menor que 18sp, ou em
negrito e menor que 14sp, e 3:1 para o resto. A tabela das HIG diz o mesmo em pontos. **As duas valem
em cada aparência separadamente**, e é por isso que o planner confere as cores claras e as escuras.

## A fórmula

A WCAG a define em dois passos. A **luminância relativa** de uma cor é o brilho dela numa escala de 0
para o preto a 1 para o branco, calculado a partir do vermelho, do verde e do azul depois de desfazer
a curva com que o sRGB os guarda. A **razão de contraste** de duas cores é a luminância da mais clara
mais 0,05, dividida pela da mais escura mais 0,05: 1 para uma cor contra ela mesma, 21 para preto
sobre branco. As duas definições foram lidas no texto do W3C da WCAG 2.2 em 30 de outubro de 2026, e
o programa as segue linha a linha. Salve-o como `contrast.ts` em `~/planner`, ao lado do `tokens.ts`
da aula 18, de onde ele lê as cores:

```schooling-example
{"language": "typescript", "file": "contrast.ts", "parts": [{"code": "// contrast.ts: WCAG's contrast ratio, checked on the planner's colour pairs\nimport { brand } from \"./tokens.ts\";\n", "note": "O programa lê as cores do planner do `tokens.ts` da aula 18, então confere as cores que os dois temas usam de fato, não uma cópia delas."}, {"code": "// Relative luminance of an sRGB colour such as \"#2F6F4E\", as WCAG 2.2 defines it.\nexport function luminance(hex: string): number {\n  const [r, g, b] = [1, 3, 5].map((i) => {\n    const c = parseInt(hex.slice(i, i + 2), 16) / 255;\n    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;\n  });\n  return 0.2126 * r + 0.7152 * g + 0.0722 * b;\n}\n", "note": "A luminância relativa da WCAG, linha a linha: cada canal de 0 a 255 vira 0 a 1, a curva do sRGB é desfeita, e os três são ponderados. O verde pesa mais porque o olho é mais sensível a ele."}, {"code": "// (lighter + 0.05) / (darker + 0.05): 1 for the same colour, 21 for black on white.\nexport function ratio(a: string, b: string): number {\n  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (hi + 0.05) / (lo + 0.05);\n}\n", "note": "A razão em si. Ordenar põe a cor mais clara em cima, então a ordem em que o par é escrito não importa."}, {"code": "// Each pair the planner draws, and what WCAG asks of it: 4.5 for text, 3 for a control's edge.\nconst pairs = [\n  { what: \"session title\", fg: \"onSurface\", bg: \"surface\", need: 4.5 },\n  { what: \"date under it\", fg: \"muted\", bg: \"surface\", need: 4.5 },\n  { what: \"button label\", fg: \"onPrimary\", bg: \"primary\", need: 4.5 },\n  { what: \"checkbox edge\", fg: \"primary\", bg: \"surface\", need: 3 },\n] as const;\n", "note": "Quatro pares que a tela da semana desenha, cada um com o limite que vale para ele: texto precisa de 4,5, a borda de um controle de 3. Os nomes são chaves de `brand.light` e `brand.dark`."}, {"code": "let failed = 0;\nfor (const mode of [\"light\", \"dark\"] as const) {\n  for (const p of pairs) {\n    const fg = brand[mode][p.fg];\n    const bg = brand[mode][p.bg];\n    const r = ratio(fg, bg);\n    const ok = r >= p.need;\n    if (!ok) failed++;\n    console.log(`${mode.padEnd(6)}${p.what.padEnd(15)}${fg} on ${bg}  ${r.toFixed(2).padStart(5)}:1  needs ${p.need}  ${ok ? \"pass\" : \"FAIL\"}`);\n  }\n}\nconsole.log(failed === 0 ? \"every pair passes\" : `${failed} pair(s) fail`);\nprocess.exitCode = failed === 0 ? 0 : 1;", "note": "Todo par, nas duas aparências, com a razão em duas casas decimais para que um quase acerto apareça como tal. Uma reprovação também põe o código de saída em 1."}]}
```

Rode-o:

```
ana@dev:~/planner$ node contrast.ts; echo "exit $?"
light session title  #1C1B1F on #FFFFFF  17.13:1  needs 4.5  pass
light date under it  #8A8A8A on #FFFFFF   3.45:1  needs 4.5  FAIL
light button label   #FFFFFF on #2F6F4E   5.99:1  needs 4.5  pass
light checkbox edge  #2F6F4E on #FFFFFF   5.99:1  needs 3  pass
dark  session title  #E6E1E5 on #1C1B1F  13.27:1  needs 4.5  pass
dark  date under it  #938F99 on #1C1B1F   5.41:1  needs 4.5  pass
dark  button label   #00391F on #8FD3AE   7.54:1  needs 4.5  pass
dark  checkbox edge  #8FD3AE on #1C1B1F   9.87:1  needs 3  pass
1 pair(s) fail
exit 1
```

**Um par reprova, e é aquele sobre o qual a aula 18 deixou uma pergunta.** A data embaixo de cada
sessão é `muted`, `#8A8A8A`, sobre branco: 3,45:1 contra os 4,5 de que o texto precisa. O mesmo cinza
na versão escura passa com 5,41, e todos os outros pares passam com folga. O programa também põe o
código de saída em 1 quando algo reprova, e é isso que permite a uma verificação como esta parar um
build.

## A correção, feita num lugar só

**Uma cor que reprova se corrige movendo a luminosidade dela, e o menor movimento que passa mantém o
design mais perto do que se queria.** A marca queria um cinza discreto embaixo de um título escuro, e
essa intenção sobrevive a um cinza um pouco mais escuro. Em `tokens.ts`, troque o `muted` claro de
`"#8A8A8A"` para `"#777777"`, um passo mais escuro, e rode a verificação de novo:

```
ana@dev:~/planner$ node contrast.ts; echo "exit $?"
light session title  #1C1B1F on #FFFFFF  17.13:1  needs 4.5  pass
light date under it  #777777 on #FFFFFF   4.48:1  needs 4.5  FAIL
light button label   #FFFFFF on #2F6F4E   5.99:1  needs 4.5  pass
light checkbox edge  #2F6F4E on #FFFFFF   5.99:1  needs 3  pass
dark  session title  #E6E1E5 on #1C1B1F  13.27:1  needs 4.5  pass
dark  date under it  #938F99 on #1C1B1F   5.41:1  needs 4.5  pass
dark  button label   #00391F on #8FD3AE   7.54:1  needs 4.5  pass
dark  checkbox edge  #8FD3AE on #1C1B1F   9.87:1  needs 3  pass
1 pair(s) fail
exit 1
```

**4,48 não é 4,5, e um limite é um limite.** Arredondado para uma casa decimal pareceria aprovado, e
é por isso que o programa imprime duas. Mais um passo resolve. Troque `"#777777"` por `"#767676"`:

```
ana@dev:~/planner$ node contrast.ts; echo "exit $?"
light session title  #1C1B1F on #FFFFFF  17.13:1  needs 4.5  pass
light date under it  #767676 on #FFFFFF   4.54:1  needs 4.5  pass
light button label   #FFFFFF on #2F6F4E   5.99:1  needs 4.5  pass
light checkbox edge  #2F6F4E on #FFFFFF   5.99:1  needs 3  pass
dark  session title  #E6E1E5 on #1C1B1F  13.27:1  needs 4.5  pass
dark  date under it  #938F99 on #1C1B1F   5.41:1  needs 4.5  pass
dark  button label   #00391F on #8FD3AE   7.54:1  needs 4.5  pass
dark  checkbox edge  #8FD3AE on #1C1B1F   9.87:1  needs 3  pass
every pair passes
exit 0
```

`#767676` chega a 4,54:1, o cinza neutro mais claro, com vermelho, verde e azul iguais, que passa
sobre branco. A edição foi uma linha em `tokens.ts`, e os dois temas da aula 18 a leem, então o
`onSurfaceVariant` do tema Material e o `secondaryLabel` do tema iOS mudaram juntos. É o arranjo que a
aula 18 defendeu, se pagando.

## O que o número não cobre

**O contraste mede duas cores chapadas.** Texto sobre uma fotografia, sobre um degradê ou sobre o
Liquid Glass, que deixa o conteúdo de baixo aparecer, não tem um fundo único contra o qual medir, e
as HIG pedem que ele seja conferido em cada aparência e com o ajuste Aumentar Contraste do sistema
ligado. **E o contraste não diz nada sobre daltonismo**: duas cores podem ter ótimo contraste contra o
branco e ser a mesma para quem não distingue vermelho de verde, que é o último assunto da próxima
seção.
