---
title: Conversão de instalação, e quando uma diferença é real
version: 1
---

**Um teste da página da loja compara duas taxas de conversão, e a pergunta nunca é qual é maior; é se
a diferença é maior que o acaso.** Com poucos visitantes, duas páginas idênticas mostram taxas
diferentes todo dia. As duas lojas respondem à pergunta com uma faixa de confiança; esta seção calcula
uma, para que a faixa não seja um número aceito de olhos fechados.

## Duas variantes da página do planner

A variante A é a página atual. A variante B põe a semana com o total primeiro entre as capturas, o
conselho da lição 4. O script recebe os visitantes e as instalações de cada uma, e imprime cada taxa,
a diferença, e um **intervalo de confiança de 95%** para a diferença: a faixa que, pela aproximação
normal de costume, conteria a diferença verdadeira em 95 de 100 testes como este. Salve isto como
`conversion.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "conversion.ts", "parts": [{"code": "// conversion.ts: two variants of the store page, and whether the difference between them is larger than chance\nconst [visitsA, installsA, visitsB, installsB] = process.argv.slice(2, 6).map(Number);\nconst a = installsA / visitsA;\nconst b = installsB / visitsB;", "note": "Visitantes e instalações de cada variante, pela linha de comando, e a taxa de conversão de cada uma."}, {"code": "const se = Math.sqrt((a * (1 - a)) / visitsA + (b * (1 - b)) / visitsB);\nconst low = b - a - 1.96 * se;\nconst high = b - a + 1.96 * se;", "note": "O erro-padrão de uma diferença entre duas proporções, e 1,96 deles para cada lado: o intervalo de 95% de costume."}, {"code": "const pts = (x: number) => `${(100 * x).toFixed(1)}`;\nconsole.log(`A ${pts(a)}%  B ${pts(b)}%  difference ${pts(b - a)} points, 95% interval ${pts(low)} to ${pts(high)}`);\nconsole.log(low > 0 ? \"B converts better\" : high < 0 ? \"A converts better\" : \"not enough evidence either way\");", "note": "O veredito segue o intervalo: todo acima de 0, todo abaixo, ou cruzando o zero."}]}
```

Rode duas vezes: com uma quinzena de visitantes, e com o décimo deles do primeiro dia:

```
ana@dev:~/planner$ node conversion.ts 4200 1176 4180 1296
A 28.0%  B 31.0%  difference 3.0 points, 95% interval 1.1 to 5.0
B converts better
ana@dev:~/planner$ node conversion.ts 420 118 418 130
A 28.1%  B 31.1%  difference 3.0 points, 95% interval -3.2 to 9.2
not enough evidence either way
```

## Lendo as duas execuções

**Com cerca de 4200 visitantes por variante, os 3 pontos de B são reais**: o intervalo vai de cerca de
1 a 5 pontos e não chega a 0. **Com cerca de 420, as mesmas taxas não provam nada**: o intervalo vai de
cerca de -3 a 9 pontos, então a diferença verdadeira poderia muito bem ser zero, ou negativa. A página
não mudou entre as duas execuções; só o número de pessoas que a viu.

Essa é a lição para ler os consoles também. **Pare um teste quando a amostra for grande o bastante, e
não quando a diferença parecer boa**; uma equipe que confere toda manhã e para no primeiro dia bom vai
"achar" um vencedor num teste entre duas páginas idênticas.

## O que a conversão não mede

Uma página que converte mais pode atrair pessoas que vão embora na semana 1, lição 17. O teste melhor
lê as duas coisas: a conversão de cada variante, e a retenção da semana 1 das pessoas que cada uma
trouxe. Uma página que promete menos e segura mais é a página melhor.
