---
title: Contraste que não é texto
version: 1
---

**Texto não é a única coisa que precisa ser vista.** O 1.4.11 *Contraste não textual*, nível AA, pede 3:1 contra o que está ao lado para dois tipos de coisa. Um
é o controle: as partes que dizem que ele é um controle, como a borda de um campo ou a caixinha de uma
caixa de seleção, e os seus estados, como o anel de foco. O outro é a parte de um gráfico necessária para
entendê-lo, como as linhas de um gráfico.

**O axe não mede nada disso.** Uma borda, um contorno e o traço de um SVG não são texto, e a regra
`color-contrast` dele só lê texto. Então o 1.4.11 é verificado do jeito que esta seção o verifica: dando nome
a cada coisa não textual que uma pessoa precisa ver, e medindo.

| no planner | contra | razão, claro | razão, escuro | precisa |
|---|---|---|---|---|
| o anel de foco, `--link` | a página | 5,99:1 | 8,71:1 | 3:1 |
| as bordas dos campos e botões | a página | as do navegador | as do navegador | 3:1 |
| a linha entre as linhas, `--line` | a página | 1,36:1 | 1,59:1 | nada: ela separa, não identifica |

O navegador desenha os campos e os botões sozinho, nos dois esquemas, por causa do `color-scheme`, e a WCAG
deixa ao navegador um controle que a página não estilizou: o contraste dele é responsabilidade do
navegador, não da página. Uma folha de estilo que os reestiliza assume o dever. A linha entre as linhas é o
caso interessante: ela falha nos 3:1 e não precisa de nada, porque quem não consegue vê-la não perde nada.
Cada linha continua sendo uma linha.

## Só a cor

O 1.4.1 *Uso de cores*, nível A, pede que a cor nunca seja o **único** jeito de dizer algo. As sessões
feitas do planner são cinzas, e também terminam na palavra *done*; quem não distingue o cinza do preto
ainda lê a palavra. Um link dentro de um parágrafo é a falha clássica: uma palavra verde entre pretas, sem
sublinhado, é um link só para quem consegue ver verde. Os links do planner ficam em linhas próprias e
mantêm o sublinhado do navegador, e isso basta.
