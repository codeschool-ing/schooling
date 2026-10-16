---
title: Totais e comparações
version: 1
---

Uma resposta descritiva é um número com uma comparação ao lado. **O número sozinho diz quanto; a
comparação diz se isso é bom.** E a comparação escolhida decide o que o número parece dizer, então
esta seção monta os dois anos da Varanda numa planilha e põe as duas comparações mais comuns lado a
lado.

## Os dois anos, mês a mês

Acrescente uma aba ao arquivo da aula 1 e digite as vendas da Varanda em 2024 e 2025, em milhares de
reais, a partir de A1:

| | A | B | C |
|---|---|---|---|
| 1 | Mês | 2024 | 2025 |
| 2 | jan | 6420 | 6890 |
| 3 | fev | 6180 | 6510 |
| 4 | mar | 7050 | 7420 |
| 5 | abr | 7210 | 7700 |
| 6 | mai | 8340 | 8810 |
| 7 | jun | 6990 | 7330 |
| 8 | jul | 6870 | 7140 |
| 9 | ago | 7380 | 7810 |
| 10 | set | 7640 | 8150 |
| 11 | out | 8020 | 7960 |
| 12 | nov | 9310 | 10040 |
| 13 | dez | 11290 | 12240 |

Em A14 digite `Total`, e as duas somas vão em B14 e C14:

```localised
=SOMA(B2:B13)      92700
=SOMA(C2:C13)      98000
```

**R$ 92,7 milhões em 2024 e R$ 98,0 milhões em 2025**, R$ 5,3 milhões a mais. Isso é uma descrição,
e já útil, mas o ano esconde os seus meses.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico de barras das vendas da Varanda por mês, em milhares de reais, 2024 e 2025 lado a lado. Os dois anos sobem até dezembro, o maior mês de cada um, com 11.290 e 12.240. Todo mês de 2025 fica acima do mesmo mês de 2024, menos outubro: 7.960 contra 8.020.\" data-fig=\"l06-months\"><path d=\"M64.0 270.0 L704.0 270.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"274.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M64.0 199.2 L704.0 199.2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"203.2\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4.000</text><path d=\"M64.0 128.5 L704.0 128.5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"132.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8.000</text><path d=\"M64.0 57.7 L704.0 57.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"61.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12.000</text><path d=\"M71.7 156.4 H89.7 V270.0 H71.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M91.7 148.1 H109.7 V270.0 H91.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jan</text><path d=\"M125.0 160.7 H143.0 V270.0 H125.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M145.0 154.8 H163.0 V270.0 H145.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"144.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fev</text><path d=\"M178.3 145.3 H196.3 V270.0 H178.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M198.3 138.7 H216.3 V270.0 H198.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"197.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mar</text><path d=\"M231.7 142.4 H249.7 V270.0 H231.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M251.7 133.8 H269.7 V270.0 H251.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"250.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">abr</text><path d=\"M285.0 122.4 H303.0 V270.0 H285.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M305.0 114.1 H323.0 V270.0 H305.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"304.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mai</text><path d=\"M338.3 146.3 H356.3 V270.0 H338.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M358.3 140.3 H376.3 V270.0 H358.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"357.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jun</text><path d=\"M391.7 148.5 H409.7 V270.0 H391.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M411.7 143.7 H429.7 V270.0 H411.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"410.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">jul</text><path d=\"M445.0 139.4 H463.0 V270.0 H445.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M465.0 131.8 H483.0 V270.0 H465.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"464.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ago</text><path d=\"M498.3 134.8 H516.3 V270.0 H498.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M518.3 125.8 H536.3 V270.0 H518.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"517.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">set</text><path d=\"M551.7 128.1 H569.7 V270.0 H551.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M571.7 129.2 H589.7 V270.0 H571.7 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"570.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">out</text><path d=\"M605.0 105.3 H623.0 V270.0 H605.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M625.0 92.4 H643.0 V270.0 H625.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"624.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nov</text><path d=\"M658.3 70.3 H676.3 V270.0 H658.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M678.3 53.4 H696.3 V270.0 H678.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"677.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dez</text><text x=\"580.7\" y=\"95.2\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">out: −0,7%</text><path d=\"M580.7 101.2 L580.7 125.2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M64.0 12.0 H78.0 V26.0 H64.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"84.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2024</text><path d=\"M134.0 12.0 H148.0 V26.0 H134.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"154.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2025</text><text x=\"214.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">milhares de reais</text><text x=\"704.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">dezembro é o maior mês nos dois anos</text></svg>", "caption": "Os dois anos da Varanda por mês. O desenho se repete, com dezembro no topo nos dois, então um mês se compara com o mesmo mês do ano anterior. Outubro de 2025 é o que caiu."}
```

## Mês contra mês anterior

A comparação que quase todo mundo faz primeiro é com o mês anterior. Em E1 digite `Var. mês %`, e em E3,
ao lado de fevereiro de 2025:

```localised
=ARRED((C3/C2-1)*100;1)      -5,5
```

Copie até E13. A coluna oscila muito: maio sobe 14,4% sobre abril e junho cai 16,8% sobre maio,
novembro sobe 26,1% sobre outubro e dezembro mais 21,9% sobre novembro.

**Nenhuma dessas oscilações diz nada sobre como a Varanda foi.** Maio tem o Dia das Mães, e junho não
tem nada parecido. Novembro e dezembro são a época de presentes todo ano. Os meses de uma varejista de
jardim e móveis não são iguais, e comparar um mês com o anterior mede sobretudo o calendário.
Novembro de 2025 subiu 26,1% sobre outubro de 2025, o que soa como um triunfo, mas novembro de 2024
subiu 16,1% sobre outubro de 2024. **A oscilação é a estação, e a estação se repete.**

## Contra o mesmo mês do ano anterior

A comparação que tira a estação é com o mesmo mês um ano antes. Em D1 digite `Var. ano %`, e em D2:

```localised
=ARRED((C2/B2-1)*100;1)      7,3
```

Copie até D13, e para D14, o ano. O ano dá **5,7**, e os meses ficam entre 3,9 (julho) e 8,4
(dezembro). Há uma exceção. **Outubro, com −0,7, é o único mês de 2025 abaixo do mesmo mês de 2024.**
Contra o mês anterior, outubro mostrava −2,3% sobre setembro, que parecia mais uma oscilação. Contra o
ano anterior, é o único mês que se destaca.

Esse é todo o argumento a favor da comparação anual num negócio sazonal. Ela compara igual com igual,
então o que sobra na coluna é a história do ano, e não a do calendário.

## Parcelas do ano

Outro tipo de comparação é com o todo. Duas células dizem quanto do ano da Varanda está no fim dele:

```localised
=ARRED(SOMA(C11:C13)/C14*100;1)      30,9
=ARRED(C13/C14*100;1)      12,5
```

**O último trimestre é 30,9% do ano**, e era 30,9% em 2024 também: o desenho se manteve. Dezembro
sozinho é 12,5% de 2025. Daí saem duas coisas, e as duas são decisões que alguém toma com um número
descritivo. Estoque e equipe do último trimestre precisam ser planejados meses antes. E um outubro
ruim merece ser explicado antes de novembro começar, que é exatamente o que a aula 7 faz.
