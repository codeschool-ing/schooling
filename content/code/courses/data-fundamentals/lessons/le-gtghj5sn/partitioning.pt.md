---
title: Particionamento: qual máquina guarda cada linha
version: 1
---

**Particionar é dividir um conjunto de dados em partes e entregar cada parte a uma máquina. A decisão
que importa é a chave que manda uma linha para a sua parte, porque essa chave decide quais perguntas
ficam baratas.** A imagem errada é a de um bolo: corte a tabela em quatro fatias iguais, de qualquer
jeito, e distribua. Quatro fatias iguais cortadas ao acaso respondem a toda pergunta consultando as
quatro máquinas.

Três palavras antes. Cada parte é uma **partição**; muitos bancos de dados a chamam de **shard**, e
dividir um banco desse jeito é fazer **sharding**. A coluna cujo valor decide para onde vai uma linha
é a **chave de partição**. E você já viu uma partição: a aula 3 guarda cada dia de viagens num
diretório com o nome da data, como `date=2025-09-15`, e isso é um conjunto de dados particionado por
dia.

## Por intervalo

**O particionamento por intervalo dá a cada partição uma sequência de chaves consecutivas.** A
primeira semana de setembro numa partição e a segunda na seguinte; ou as estações ST01 a ST03 numa
máquina, ST04 a ST06 em outra. Uma pergunta sobre um intervalo — as viagens da segunda semana de
setembro — lê uma partição, ou duas, e pula o resto. É por isso que dados em disco são tantas vezes
particionados por data.

A fraqueza está em onde os dados novos caem. Toda viagem que começa hoje tem a data de hoje, então
toda escrita de hoje vai para uma partição só, enquanto as outras guardam o passado. E um intervalo
que por acaso está movimentado está movimentado numa máquina só.

## Por hash

**O particionamento por hash passa a chave por uma função de hash e deixa o número que sai escolher a
partição.** Uma função de hash transforma `R000001` e `R000002` em dois números que parecem não ter
relação, então chaves vizinhas caem longe uma da outra, e com muitas chaves cada partição fica com
mais ou menos a mesma parte. As viagens de hoje se espalham por todas as máquinas em vez de se
amontoarem numa.

O preço é o espelho da virtude do intervalo. Chaves que eram vizinhas não ficam mais juntas, então
uma pergunta sobre um intervalo delas, as viagens desta semana, precisa consultar todas as partições.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Duas fileiras de quatro partições. Por intervalo de estação: a partição 0 tem ST01 a ST03, a 1 tem ST04 a ST06, a 2 tem ST07 a ST09, a 3 tem ST10 a ST12. Por hash da estação: a partição 0 tem ST10; a 1 tem ST03, ST04, ST05 e ST12; a 2 tem ST01, ST07, ST09 e ST11; a 3 tem ST02, ST06 e ST08. A partição que tem a ST02 está marcada nas duas fileiras.\" data-fig=\"partitioning\"><defs><marker id=\"partitioning-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">por intervalo</text><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">da estação</text><rect x=\"150\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 0</text><text x=\"214.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST01 ST02 ST03</text><rect x=\"292\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"356.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 1</text><text x=\"356.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST04 ST05 ST06</text><rect x=\"434\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 2</text><text x=\"498.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST07 ST08 ST09</text><rect x=\"576\" y=\"30\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"61.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 3</text><text x=\"640.0\" y=\"76.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST10 ST11 ST12</text><text x=\"20\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">por hash</text><text x=\"20\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">da estação</text><rect x=\"150\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 0</text><text x=\"214.0\" y=\"180.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST10</text><rect x=\"292\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"356.0\" y=\"157.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 1</text><text x=\"356.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST03 ST04</text><text x=\"356.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST05 ST12</text><rect x=\"434\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"157.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 2</text><text x=\"498.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST01 ST07</text><text x=\"498.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST09 ST11</text><rect x=\"576\" y=\"134\" width=\"128\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"157.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">partição 3</text><text x=\"640.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST02 ST06</text><text x=\"640.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ST08</text><text x=\"150\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">em destaque: a partição com a ST02, a estação concorrida</text></svg>", "caption": "As mesmas doze estações em quatro partições. Por intervalo, as vizinhas ficam juntas; por hash, elas se espalham. De um jeito ou de outro, a caixa que tem a ST02 tem todas as viagens dela."}
```

| | por intervalo | por hash |
|---|---|---|
| uma pergunta sobre um intervalo de chaves | lê uma partição, ou poucas | lê todas as partições |
| chaves novas chegando em ordem, como as datas de hoje | vão todas para uma partição | se espalham por todas |
| uma parte igual por partição | só se os intervalos forem bem escolhidos | quase igual, se houver muitas chaves |
| onde você vai encontrar | arquivos por data num data lake | na maioria dos bancos distribuídos |

Muitos sistemas usam os dois ao mesmo tempo: arquivos particionados por dia e, dentro de cada dia,
linhas espalhadas por hash. Escolher a chave para um sistema de verdade é parte de
`warehouse-modeling` e de `bigdata`. Aqui o ponto é mais estreito: **a chave pela qual você
particiona é a pergunta que você tornou barata**, e todas as outras perguntas pagam por ela. A
próxima seção mostra o que acontece quando um valor dessa chave é muito mais movimentado que os
outros.
