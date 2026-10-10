---
title: Datas, montadas e desmontadas
version: 1
---

**Uma data é um número de dias, e toda função de data ou monta esse número a partir de um ano, um
mês e um dia, ou tira um dos três de volta.** A aula 1 mostrou o número: 2 de janeiro de 2025 é o
dia 45659. Esta seção o usa, primeiro para transformar os oito dígitos do sistema antigo em datas de
verdade, depois para desmontar as datas de `Sales`, e por fim para lidar com o único formato de data
que o Excel lê diferente conforme a configuração da máquina.

## Montando uma data: DATA

`DATA(ano; mês; dia)` (`DATE` no Excel em inglês) devolve o número do dia dessas três partes. A
coluna `Date` de `Old export` guarda `20241202`: o ano nos quatro primeiros dígitos, o mês nos dois
seguintes e o dia nos dois últimos. `ESQUERDA`, `EXT.TEXTO` e `DIREITA`, da seção 04, os recortam, e
`DATA` os junta. Em **N1** digite `Date`, e em **N2**:

```localised
=DATA(ESQUERDA(B2;4); EXT.TEXTO(B2;5;2); DIREITA(B2;2))
```

A resposta é **45628**, que o Excel mostra como data: 2 de dezembro de 2024. Se a sua célula mostrar
o número puro, dê a ela um formato de data em **Página Inicial › Formato de Número**. Preenchida até
N13, a coluna se confere do jeito de sempre:

```localised
=CONT.NÚM(N2:N13)
=MÍNIMO(N2:N13)
=MÁXIMO(N2:N13)
```

**12** datas, de **45628** a **45649**, ou seja, de 2 a 23 de dezembro de 2024. Uma primeira e uma
última data que fazem sentido são a prova mais barata de que nenhuma linha foi cortada no lugar
errado: um mês e um dia trocados cairiam em outro mês, ou dariam erro.

`ESQUERDA` recebeu aqui um número, `20241202`, e devolveu o texto `2024`. `DATA` transformou o texto
de volta em número sem reclamar. Esse é um dos poucos lugares em que o Excel converte texto em número
sozinho, e é por isso que a fórmula não precisa de `VALOR`.

## Desmontando uma data: ANO, MÊS, DIA e FIMMÊS

Na planilha `Sales`, numa célula vazia como **J2**, a data de B2 se desmonta com uma função por
pedaço, `ANO` (`YEAR`), `MÊS` (`MONTH`) e `DIA` (`DAY`):

```localised
=ANO(B2)
=MÊS(B2)
=DIA(B2)
```

**2025**, **1** e **2**. Duas combinações aparecem o tempo todo em análise. O primeiro dia do mês de
uma venda,

```localised
=DATA(ANO(B2); MÊS(B2); 1)
```

responde **45658**, 1º de janeiro de 2025, e preenchida numa coluna dá a cada venda um mês pelo qual
agrupar. E `FIMMÊS` (`EOMONTH`) devolve o último dia do mês que está a um certo número de meses de
distância:

```localised
=FIMMÊS(B2; 0)
=DIA(FIMMÊS(B2; 0))
```

A primeira responde **45688**, 31 de janeiro de 2025. A segunda pergunta o dia dessa data e responde
**31**, o tamanho do mês. Com 1 no lugar de 0 seria o último dia de fevereiro.

Como datas são números, a distância entre duas delas é uma subtração. Os dados vão de B2 a B109, e

```localised
=B109-B2
```

responde **537** dias, os dezoito meses de `Sales`.

## Dia primeiro ou mês primeiro

Uma data escrita `03/12/2024` quer dizer 3 de dezembro no Brasil e 12 de março nos Estados Unidos,
e **o Excel a lê do jeito que a configuração regional do computador manda**, sem perguntar. Para ver
acontecer, digite `'03/12/2024` numa célula vazia como **P6**, com o apóstrofo, que a mantém como
texto. Depois:

```localised
=DATA.VALOR(P6)
```

`DATA.VALOR` (`DATEVALUE`) transforma um texto em data pela configuração regional. Um Excel
configurado em inglês dos Estados Unidos responde **45363**, 12 de março de 2024; um configurado em
português do Brasil responde 3 de dezembro de 2024. A mesma pasta de trabalho dá duas respostas em
dois computadores, e nenhuma mostra erro.

Colar uma coluna dessas datas é pior, porque o Excel as converte enquanto chegam:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 250\" role=\"img\" data-fig=\"l06-dates\" aria-label=\"Cinco datas escritas com o dia primeiro, como texto, lidas por dois Excels. Com o dia primeiro, todas viram a data certa de dezembro. Com o mês primeiro, 03, 05 e 10 viram datas de março, maio e outubro, e 16 e 23 continuam texto, porque não existe mês dezesseis nem vinte e três.\"><text x=\"40.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">colado</text><text x=\"230.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um Excel que lê o dia primeiro</text><text x=\"490.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um Excel que lê o mês primeiro</text><rect x=\"40.0\" y=\"58.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"70.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">03/12/2024</text><path d=\"M168.0 70.0 L222.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 70.0 L214.0 66.0 L214.0 74.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"58.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"70.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-03</text><rect x=\"490.0\" y=\"58.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"604.0\" y=\"70.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2024-03-12</text><text x=\"620.0\" y=\"70.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">data errada</text><rect x=\"40.0\" y=\"88.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"100.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">05/12/2024</text><path d=\"M168.0 100.0 L222.0 100.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 100.0 L214.0 96.0 L214.0 104.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"88.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"100.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-05</text><rect x=\"490.0\" y=\"88.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"604.0\" y=\"100.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2024-05-12</text><text x=\"620.0\" y=\"100.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">data errada</text><rect x=\"40.0\" y=\"118.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10/12/2024</text><path d=\"M168.0 130.0 L222.0 130.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 130.0 L214.0 126.0 L214.0 134.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"118.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"130.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-10</text><rect x=\"490.0\" y=\"118.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"604.0\" y=\"130.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2024-10-12</text><text x=\"620.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">data errada</text><rect x=\"40.0\" y=\"148.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">16/12/2024</text><path d=\"M168.0 160.0 L222.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 160.0 L214.0 156.0 L214.0 164.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"148.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"160.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-16</text><rect x=\"490.0\" y=\"148.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">16/12/2024</text><text x=\"620.0\" y=\"160.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">continua texto</text><rect x=\"40.0\" y=\"178.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"46.0\" y=\"190.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">23/12/2024</text><path d=\"M168.0 190.0 L222.0 190.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M222.0 190.0 L214.0 186.0 L214.0 194.0 Z\" fill=\"var(--wire)\" stroke=\"none\"></path><rect x=\"230.0\" y=\"178.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"344.0\" y=\"190.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2024-12-23</text><rect x=\"490.0\" y=\"178.0\" width=\"120.0\" height=\"24.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"496.0\" y=\"190.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">23/12/2024</text><text x=\"620.0\" y=\"190.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">continua texto</text><text x=\"230.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">todo valor uma data, à direita</text><text x=\"490.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">dois tipos de valor numa coluna</text></svg>", "caption": "Os mesmos cinco textos colados em dois Excels. Onde o dia é 12 ou menos, um Excel que lê o mês primeiro cria uma data válida no mês errado; acima de 12 ele desiste e deixa texto. Nada nas células diz quais linhas deram errado."}
```

Num Excel que lê o mês primeiro, todo dia de 1 a 12 vira uma data errada mas válida, e todo dia de
13 em diante continua texto, porque não existe mês treze. A coluna fica com dois tipos de valor, e as
datas erradas parecem exatamente as certas. O sintoma é uma coluna cujos valores ficam uns à direita
das células e outros à esquerda.

A cura é nunca deixar o Excel adivinhar. Quando uma data chega como texto numa ordem conhecida,
desmonte-a você mesmo, exatamente como com os oito dígitos:

```localised
=DATA(DIREITA(P6;4); EXT.TEXTO(P6;4;2); ESQUERDA(P6;2))
```

Essa diz na própria fórmula que o dia vem primeiro, e responde **45629**, 3 de dezembro de 2024, em
qualquer computador do mundo. Quando você escrever datas para outras pessoas, escreva `2024-12-03`,
com o ano primeiro, que o Excel lê do mesmo jeito em toda região, e é por isso que os dados que você
colou na aula 1 usam esse formato.

## O que guardar

As colunas limpas, de I a N de `Old export`, são fórmulas sobre o original. Para guardar os valores
limpos sozinhos, selecione-as, copie e use **Colar Especial › Valores**, que troca cada fórmula pelo
que ela respondeu. Nenhuma aula seguinte precisa da planilha `Old export` nem das células usadas aqui
em `Sales`; apague-as antes da aula 7, que transforma `Sales` em tabela. A aula 14 faz esse mesmo
tipo de limpeza com o Power Query, em etapas que se repetem sozinhas a cada exportação nova.
