---
title: OEE: um turno desmontado
version: 1
---

A Serra Azul Embalagens faz tampas, tampinhas e potes de plástico em Joinville, Santa Catarina, em
14 injetoras que rodam três turnos por dia. Ela é inventada, como toda organização deste curso. O
engenheiro de processos, Rafael Hoffmann, também monta os relatórios da fábrica, e as perguntas que
ele recebe se encaixam nas quatro da aula 17 assim:

| a pergunta da aula 17 | numa fábrica |
|---|---|
| as decisões tomadas sem parar | qual máquina faz qual pedido, quando parar uma máquina para manutenção, se um lote de peças pode ser expedido, quantas pessoas cada turno precisa |
| os indicadores que servem a elas | o OEE e os seus três fatores; MTBF, MTTR e disponibilidade; taxa de refugo, partes por milhão, rendimento de primeira passagem; o gráfico de controle |
| os dados, e o que eles têm de estranho | as máquinas registram cada ciclo ao segundo, o ERP registra pedidos e caixas, e **as pessoas anotam o refugo à mão no fim do turno**: três registros de um mesmo evento, com três relógios |
| a armadilha típica | confiar no número que uma pessoa digitou, porque ele está na mesma tabela que os números contados por uma máquina |

## A pergunta errada: a máquina estava rodando?

Uma máquina ligada o turno inteiro parece totalmente aproveitada. O primeiro relatório de Rafael,
anos atrás, dizia exatamente isso: a IM-07 rodou o segundo turno inteiro. Ele não dizia que ela
parou duas vezes, rodou mais devagar do que devia quando rodou e fez peças que foram para a caçamba
de refugo. **O OEE, eficiência global do equipamento (*overall equipment effectiveness*), é o jeito
padrão de contar as três perdas num número só**:

OEE = disponibilidade × desempenho × qualidade

Cada fator responde a uma pergunta sobre o tempo em que a máquina devia estar produzindo.

## Um turno, digitado

IM-07, segundo turno, terça-feira, 11 de novembro de 2025, das 14:00 às 22:00. O molde faz uma
tampa a cada 15 segundos na velocidade nominal. Digite o turno numa planilha nova:

| | A | B |
|---|---|---|
| 1 | Duração do turno (min) | 480 |
| 2 | Paradas planejadas (min) | 30 |
| 3 | Paradas não planejadas (min) | 63 |
| 4 | Ciclo ideal (s por peça) | 15 |
| 5 | Peças feitas | 1350 |
| 6 | Peças boas | 1296 |

Os 30 minutos planejados são o intervalo da equipe, e não são perda: a máquina nunca deveria rodar
nessa hora. Os 63 minutos não planejados são uma troca de molde que levou 35 e uma quebra que levou
28.

**Disponibilidade** é a parcela do tempo planejado em que a máquina de fato rodou:

```localised
=B1-B2      450
=B1-B2-B3      387
=ARRED((B1-B2-B3)/(B1-B2)*100;1)      86
```

**Desempenho** é quantas peças ela fez contra quantas poderia ter feito no tempo em que rodou, no
ciclo ideal. O ciclo está em segundos e o tempo em minutos, daí o 60:

```localised
=ARRED(B4*B5/((B1-B2-B3)*60)*100;1)      87,2
```

**Qualidade** é a parcela das peças que saíram boas:

```localised
=ARRED(B6/B5*100;1)      96
```

Multiplique os três e o OEE do turno é de **72,0%**. Há um caminho mais curto para o mesmo número, e
ele serve de conferência: o tempo que levaria para fazer só as peças boas no ciclo ideal, sobre o
tempo planejado.

```localised
=ARRED(B4*B6/((B1-B2)*60)*100;1)      72
```

## Para onde foram os minutos

O valor do OEE não está nos 72; está na divisão. Dos 450 minutos planejados, 324 viraram peças boas.
Os outros 126 são perdas, e cada uma tem dono:

| perda | minutos | onde aparece | quem age |
|---|---|---|---|
| paradas | 63 | disponibilidade, 86,0% | a manutenção, e quem planeja as trocas de molde |
| ciclos lentos | 49,5 | desempenho, 87,2% | a engenharia de processos: parâmetros, material, o molde |
| refugo | 13,5 | qualidade, 96,0% | a qualidade e os operadores |

**A maior perda aqui são as paradas, e a menos visível é a velocidade.** Ninguém no chão de fábrica
vê uma máquina rodando a 17 segundos por ciclo em vez de 15; a máquina está rodando, a luz está
verde, e 49,5 minutos somem ao longo do turno, dois segundos de cada vez. As 1.350 peças contra as
1.548 que o tempo rodando permitiria na velocidade máxima são o único lugar onde eles aparecem.

## A tela no fim do turno

Às 22:00 o segundo turno passa para o terceiro, e o supervisor que chega precisa da resposta à
pergunta da aula 14 antes de qualquer outra coisa: o que precisa da minha atenção agora?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"Maquete da tela do supervisor de turno da Serra Azul, fim do segundo turno, 22:00 de terça, 11 de novembro de 2025. OEE do turno: 77,1%. Catorze quadros de máquina, as paradas primeiro: IM-11 parada por quebra há 18 minutos; IM-03 em troca de molde; depois as doze máquinas rodando, cada uma com o seu OEE neste turno. Embaixo, o turno da IM-07 dividido em disponibilidade, desempenho e qualidade.\" data-fig=\"l20-shift-screen\"><rect x=\"10.0\" y=\"10.0\" width=\"700.0\" height=\"400.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"28.0\" y=\"40.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Injeção · turno 2</text><text x=\"692.0\" y=\"34.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">ter., 11/11/2025, 22:00</text><text x=\"692.0\" y=\"50.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">contadores das máquinas, a cada minuto</text><text x=\"28.0\" y=\"76.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">OEE do turno: 77,1%</text><rect x=\"28.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"36.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-11</text><text x=\"36.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">parada 18 min</text><rect x=\"124.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"132.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-03</text><text x=\"132.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">troca molde</text><rect x=\"220.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-07</text><text x=\"228.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">72,0%</text><rect x=\"316.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-13</text><text x=\"324.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">73,7%</text><rect x=\"412.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"420.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-09</text><text x=\"420.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">74,1%</text><rect x=\"508.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"516.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-02</text><text x=\"516.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">76,8%</text><rect x=\"604.0\" y=\"92.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"612.0\" y=\"112.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-05</text><text x=\"612.0\" y=\"138.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">77,5%</text><rect x=\"28.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-06</text><text x=\"36.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">80,4%</text><rect x=\"124.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"132.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-10</text><text x=\"132.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">82,0%</text><rect x=\"220.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"228.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-12</text><text x=\"228.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">82,9%</text><rect x=\"316.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"324.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-01</text><text x=\"324.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">83,8%</text><rect x=\"412.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"420.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-14</text><text x=\"420.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">85,7%</text><rect x=\"508.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"516.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-04</text><text x=\"516.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">86,5%</text><rect x=\"604.0\" y=\"164.0\" width=\"88.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"612.0\" y=\"184.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">IM-08</text><text x=\"612.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">88,4%</text><text x=\"28.0\" y=\"260.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">IM-07 neste turno: para onde foram os minutos</text><text x=\"28.0\" y=\"296.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">disponibilidade</text><path d=\"M150.0 282.0 H450.0 V300.0 H150.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M150.0 282.0 H408.0 V300.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"460.0\" y=\"296.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">86,0%</text><text x=\"520.0\" y=\"296.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">paradas: troca de molde, quebra</text><text x=\"28.0\" y=\"326.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">desempenho</text><path d=\"M150.0 312.0 H450.0 V330.0 H150.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M150.0 312.0 H411.6 V330.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"460.0\" y=\"326.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">87,2%</text><text x=\"520.0\" y=\"326.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais lenta que o ciclo de 15 s</text><text x=\"28.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">qualidade</text><path d=\"M150.0 342.0 H450.0 V360.0 H150.0 Z\" fill=\"var(--scan)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M150.0 342.0 H438.0 V360.0 H150.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"460.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">96,0%</text><text x=\"520.0\" y=\"356.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">peças refugadas</text><text x=\"28.0\" y=\"396.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">OEE = disponibilidade × desempenho × qualidade</text></svg>", "caption": "A tela do supervisor começa pelas máquinas que não estão produzindo, depois mostra o OEE de cada uma das outras e divide o turno de uma máquina nas três perdas, para o supervisor saber que tipo de problema vai encontrar quando chegar lá."}
```

As duas máquinas que não estão produzindo vêm primeiro, seja qual for o OEE delas. As que estão
rodando mostram o OEE do turno, e os três fatores de uma máquina aparecem por extenso, porque "72%"
diz ao supervisor que algo está errado e as três barras dizem que tipo de pessoa chamar.

## O que uma comparação de OEE não aguenta

O OEE é padrão na fórmula, e não nas entradas. Uma fábrica conta a troca de molde como parada
planejada e outra como perda; uma usa a velocidade do manual da máquina e outra a melhor velocidade
que ela já atingiu. **Cada escolha mexe o número em pontos, e nenhuma está errada**, então comparar
o OEE de duas fábricas é comparar dois conjuntos de escolhas, a menos que os dois estejam escritos e
sejam iguais. O OEE "de classe mundial", de cerca de 85%, que circula na indústria é uma regra de
bolso e não uma medição, e os 72% da Serra Azul dizem mais comparados com o mês passado da própria
IM-07 do que com ele.
