---
title: Três opções numa planilha só
version: 1
---

Com todas as linhas contadas para todas as opções, a comparação é curta de escrever e longa de
discutir. **Os totais ordenam as opções; a forma ao longo do tempo, as datas e a sensibilidade da
ordem às premissas mais fracas decidem se a ordem quer dizer alguma coisa.** Esta seção apresenta as
quatro coisas, para as três opções da Serra Alta.

## As premissas por trás de B e C

A planilha de A está na seção 03 desta aula. B e C são montadas do mesmo jeito, a partir destas
premissas, todas estimativas inventadas da Serra Alta:

- *B, estender o SAP.* Não pode entrar em produção antes do S/4HANA, e a conversão da Serra Alta
  está planejada para entrar em produção em janeiro de 2028, o mês 13. Consultores funcionais a
  desenham e configuram do mês 1 ao mês 16, a R$ 62.500 por mês. Das 46 regras, 30 viram condições de
  preço padrão de compras do SAP; as outras 16, e o aplicativo de coleta nos coletores dos caminhões,
  são desenvolvimento customizado do mês 4 ao mês 16, a R$ 120.000 por mês. Licenças adicionais do
  SAP e a plataforma em que o aplicativo dos coletores roda custam R$ 15.000 por mês. Uma pessoa do
  time de Edson trabalha nela o tempo todo. O primeiro pagamento aos produtores é em maio de 2028, o
  mês 17, e o Coleta é desligado depois do mês 19.
- *C, construir.* Sete pessoas por doze meses a constroem na mesma stack do Rota, Kotlin e
  PostgreSQL. A execução em paralelo vai do mês 13 ao 15, o primeiro pagamento aos produtores é em
  abril de 2028, o mês 16, e o Coleta é desligado depois do mês 18. A manutenção a partir do mês 13
  segue a premissa de 20% da seção 04 desta aula: R$ 35.000 por mês.

## A planilha

Todos os valores em reais, nos 36 meses:

| linha | A: comprar | B: estender o SAP | C: construir |
|---|---|---|---|
| licença ou assinatura | 1.825.200 | 540.000 | 0 |
| implantação | 360.000 | 1.000.000 | 2.100.000 |
| migração de dados | 150.000 | 150.000 | 150.000 |
| integração | 240.000 | 150.000 | 300.000 |
| customização | 150.000 | 1.560.000 | 0 |
| infraestrutura | 90.000 | 96.000 | 252.000 |
| operação e suporte | 108.000 | 160.000 | 320.000 |
| time interno | 562.500 | 900.000 | 840.000 |
| treinamento | 80.000 | 80.000 | 80.000 |
| atualizações | 90.000 | 150.000 | 60.000 |
| Coleta mantido no ar | 180.000 | 285.000 | 270.000 |
| **gasto** | **3.835.700** | **5.071.000** | **4.372.000** |
| saída | 397.800 | 190.000 | 307.000 |
| **TCO** | **4.233.500** | **5.261.000** | **4.679.000** |

**A é a mais barata, por R$ 445.500 sobre C e por R$ 1.027.500 sobre B.** Dois zeros na coluna de C
foram digitados de propósito: uma construção não tem licença a pagar nem nada a customizar, porque
tudo é escrito sob medida, e o custo de ajustar está na linha de implantação. Migração de dados e
treinamento são iguais em todas as colunas, porque as fazendas, o histórico e os motoristas são os
mesmos para qualquer sistema. Uma linha idêntica em todas as opções não muda nenhuma ordem, e fica na
planilha mesmo assim, porque continua sendo dinheiro que alguém precisa arrumar.

## A forma ao longo do tempo

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l15-cumulative\" aria-label=\"Gasto acumulado das três opções em 36 meses, a partir de janeiro de 2027, em milhões de reais. As três começam juntas. C, a construção, sobe mais rápido no ano 1 e chega a R$ 2,71 milhões no mês 12; B, a extensão do SAP, a ultrapassa e chega a R$ 3,97 milhões no mês 18; A, o produto SaaS, achata depois do mês 9. No mês 36 A gastou R$ 3,84 milhões, C R$ 4,37 milhões e B R$ 5,07 milhões. Um ponto em cada linha marca o primeiro pagamento aos produtores pelo sistema novo: A no mês 10, C no mês 16, B no mês 17. Uma linha vertical tracejada no mês 18 marca a aposentadoria de Sebastião. Os custos de saída não estão desenhados.\"><path d=\"M80.0 300.0 L590.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72.0\" y=\"300.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M80.0 250.9 L590.0 250.9\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"250.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,00 mi</text><path d=\"M80.0 201.8 L590.0 201.8\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"201.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,00 mi</text><path d=\"M80.0 152.7 L590.0 152.7\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"152.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3,00 mi</text><path d=\"M80.0 103.6 L590.0 103.6\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"103.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4,00 mi</text><path d=\"M80.0 54.5 L590.0 54.5\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72.0\" y=\"54.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5,00 mi</text><text x=\"80.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"165.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><text x=\"250.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><text x=\"335.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><text x=\"420.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24</text><text x=\"505.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30</text><text x=\"590.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">36</text><text x=\"335.0\" y=\"334.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">meses a partir de janeiro de 2027</text><path d=\"M335.0 30.0 L335.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"341.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sebastião se aposenta</text><path d=\"M80.0 300.0 L94.2 293.6 L108.3 285.8 L122.5 276.7 L136.7 266.4 L150.8 256.1 L165.0 245.8 L179.2 234.1 L193.3 222.5 L207.5 212.1 L221.7 208.1 L235.8 204.1 L250.0 199.6 L264.2 196.2 L278.3 192.9 L292.5 189.0 L306.7 185.6 L320.8 182.2 L335.0 178.3 L349.2 174.9 L363.3 171.6 L377.5 167.7 L391.7 164.3 L405.8 160.9 L420.0 157.0 L434.2 153.4 L448.3 149.8 L462.5 145.7 L476.7 142.1 L490.8 138.5 L505.0 134.4 L519.2 130.7 L533.3 127.1 L547.5 123.0 L561.7 119.4 L575.8 115.8 L590.0 111.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"221.7\" cy=\"208.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M80.0 300.0 L94.2 294.2 L108.3 288.5 L122.5 282.7 L136.7 271.0 L150.8 259.4 L165.0 247.7 L179.2 236.1 L193.3 223.2 L207.5 210.3 L221.7 197.4 L235.8 184.5 L250.0 170.2 L264.2 155.6 L278.3 141.0 L292.5 126.3 L306.7 111.7 L320.8 108.4 L335.0 105.1 L349.2 101.8 L363.3 99.3 L377.5 96.7 L391.7 94.2 L405.8 91.6 L420.0 89.1 L434.2 86.5 L448.3 84.0 L462.5 81.4 L476.7 78.8 L490.8 76.3 L505.0 66.4 L519.2 63.8 L533.3 61.3 L547.5 58.7 L561.7 56.2 L575.8 53.6 L590.0 51.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"320.8\" cy=\"108.4\" r=\"4\" fill=\"var(--amber)\"></circle><path d=\"M80.0 300.0 L94.2 290.5 L108.3 281.1 L122.5 271.6 L136.7 262.1 L150.8 250.8 L165.0 239.5 L179.2 228.2 L193.3 216.8 L207.5 205.5 L221.7 192.7 L235.8 179.9 L250.0 167.2 L264.2 161.0 L278.3 154.8 L292.5 150.1 L306.7 146.7 L320.8 143.4 L335.0 140.0 L349.2 137.3 L363.3 134.7 L377.5 132.0 L391.7 129.4 L405.8 126.7 L420.0 122.1 L434.2 119.4 L448.3 116.8 L462.5 114.1 L476.7 111.5 L490.8 108.8 L505.0 103.2 L519.2 100.6 L533.3 97.9 L547.5 95.3 L561.7 92.6 L575.8 90.0 L590.0 85.4\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"6 3\"></path><circle cx=\"306.7\" cy=\"146.7\" r=\"4\" fill=\"var(--paper)\"></circle><text x=\"600.0\" y=\"110.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">A: comprar</text><text x=\"600.0\" y=\"124.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3,84 mi</text><text x=\"600.0\" y=\"44.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B: estender o SAP</text><text x=\"600.0\" y=\"58.1\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5,07 mi</text><text x=\"600.0\" y=\"78.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">C: construir</text><text x=\"600.0\" y=\"92.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4,37 mi</text><circle cx=\"90.0\" cy=\"348.0\" r=\"4\" fill=\"var(--paper-dim)\"></circle><text x=\"100.0\" y=\"348.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">primeiro pagamento aos produtores pelo sistema novo</text></svg>", "caption": "Gasto acumulado, em milhões de reais, antes de qualquer custo de saída. A construção gasta primeiro e a extensão gasta mais; a compra é a única que paga produtores antes de 2028."}
```

As curvas dizem o que os totais não dizem:

- **B é a opção mais barata nos primeiros oito meses.** Ela gasta com consultores e licenças, não com
  um time de sete nem com a assinatura de 1.900 fazendas. Quem comparasse o gasto no mês 6 —
  R$ 1.065.000 para B, R$ 1.105.000 para A e R$ 1.233.000 para C — a poria em primeiro. Ela passa C
  no mês 13, quando o desenvolvimento customizado está a pleno vapor, e termina como a mais alta;
- **C gasta primeiro.** No mês 12 ela já gastou R$ 2.706.000 e não pagou ninguém. Cada mês de atraso
  nesse ano são R$ 175.000 de um time que não terminou;
- **A achata.** Quando os custos únicos acabam, no mês 9, a curva de A sobe cerca de R$ 70.000 a
  R$ 90.000 por mês, e o ponto no mês 10 mostra que ela é a única opção pagando fazendas em 2027.

## O que o dinheiro não mede

| | A: comprar | B: estender o SAP | C: construir |
|---|---|---|---|
| primeiro pagamento aos produtores | outubro de 2027, mês 10 | maio de 2028, mês 17 | abril de 2028, mês 16 |
| Coleta desligado | depois do mês 12 | depois do mês 19 | depois do mês 18 |
| em relação à aposentadoria de Sebastião, fim de junho de 2028 | seis meses antes | um mês depois | no mesmo mês |
| como as 46 regras se encaixam | 41 configuradas, 5 estendidas ao lado | 30 como condições de preço, 16 customizadas | as 46 escritas pela Serra Alta |
| do que depende | de um fornecedor manter o produto e o preço | do S/4HANA em produção em janeiro de 2028 | de contratar sete pessoas e mantê-las |

**A linha do prazo foi a que Marcos leu duas vezes.** Sebastião é a única pessoa capaz de explicar o
que o Coleta faz quando a resposta dele e a do sistema novo diferem, e a execução em paralelo da aula
13 é o período em que essas diferenças aparecem. A termina a execução em paralelo e desliga o Coleta
com seis meses de Sebastião ainda na empresa. C desliga o Coleta no mês em que ele sai. B precisa do
Coleta, e portanto dele, por um mês depois que ele já foi, e só começa quando outro programa — o
S/4HANA — termina no prazo.

## Sensibilidade: a ordem resiste às premissas mais fracas?

Uma ordem é tão forte quanto a premissa a que ela é mais sensível. Duas são obviamente frágeis.

**E se a construção levar 50% mais tempo?** Dezoito meses em vez de doze não é pessimismo; é um
projeto de software comum. Os seis meses a mais do time somam R$ 1.050.000 (6 × R$ 175.000). Algumas
linhas caem, porque o sistema começa a rodar mais tarde: a manutenção começa no mês 19 em vez do 13,
R$ 210.000 a menos; a operação, R$ 60.000 a menos; a infraestrutura, R$ 36.000 a menos (seis meses a
mais do ambiente de desenvolvimento a R$ 3.000, seis a menos de produção a R$ 9.000). O Coleta roda
seis meses a mais, R$ 90.000 a mais. A variação líquida é:

> R$ 1.050.000 − 210.000 − 60.000 − 36.000 + 90.000 = **R$ 834.000**

C passa a R$ 5.513.000 — **mais cara que B**, então a ordem das duas atrás de A muda. As datas mudam
mais: o primeiro pagamento aos produtores vai para outubro de 2028, e o Coleta roda até dezembro,
seis meses depois de Sebastião ter saído.

**E se o preço do SaaS subir 15% na renovação em vez de 4%?** O preço do ano 3 passa a R$ 28,75 por
fazenda, e dois números se mexem. A assinatura do ano 3 vai de R$ 655.200 para R$ 724.500 (2.100 ×
28,75 × 12), R$ 69.300 a mais. Os três meses de sobreposição na saída vão de R$ 163.800 para
R$ 181.125, R$ 17.325 a mais. A passa a R$ 4.320.125, ainda a mais barata, por R$ 358.875.

Quanto o reajuste teria de ser para A perder? O preço da renovação vale para 15 meses de 2.100
fazendas — doze no ano 3 e três de sobreposição —, 31.500 fazendas-mês. A empata com C quando elas
custam R$ 445.500 a mais do que custam a R$ 26:

> R$ 445.500 ÷ 31.500 = R$ 14,14, portanto um preço de **R$ 40,14** por fazenda por mês

São 61% acima dos R$ 25 de hoje. **Uma conclusão que resiste a um reajuste de 61% é robusta quanto
ao preço**, e dizer isso no registro de decisão mostra ao leitor exatamente quanta folga existe.

## O horizonte também escolhe

Três anos favorecem a compra, e o ano 3 sozinho mostra por quê. A gasta R$ 923.200 nele (seção 03
desta aula). C gasta R$ 748.000: R$ 108.000 de infraestrutura, R$ 160.000 de operação com um teste de
intrusão, R$ 420.000 de manutenção e R$ 60.000 de atualizações. Depois de construída, C é R$ 175.200
por ano mais barata de rodar. No mês 36, C gastou R$ 536.300 a mais que A. Se os custos do ano 3
simplesmente se repetissem, C alcançaria A em R$ 536.300 ÷ R$ 175.200 = 3,06 anos a mais —
**durante o sétimo ano**.

Isso não é motivo para escolher C. Sete anos é tempo demais para supor que nada muda: fazendas
continuam entrando, o que aumenta a conta de A, e a premissa de manutenção tem de valer em cada um
desses anos, e ela é a que mais provavelmente está errada. Mas é motivo para dizer, no registro, que a
escolha é uma escolha de três anos, e para marcar o dia em que ela deve ser olhada de novo.
