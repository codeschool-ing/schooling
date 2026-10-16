---
title: Custo unitário: o número que pode cair enquanto a fatura sobe
version: 1
---

O plano da Coreto para o ano que vem tem a fatura da nuvem subindo de R$ 212.000 por mês para
R$ 236.000. Mostrado sozinho ao Otávio, isso é **um aumento de 11,3%**, e a reação natural é
perguntar à engenharia por que ela está gastando mais. A pergunta supõe que a fatura deveria ficar
parada. Não deveria, porque no ano que vem a Coreto espera vender 520.000 ingressos por mês em vez de
410.000, e atender mais ingressos custa mais.

A fatura sozinha não diz se a engenharia está ficando melhor ou pior no que faz. Uma fatura
dividida pelo que o negócio vende diz.

## Custo por ingresso

A Coreto ganha uma taxa por ingresso, então o ingresso é a unidade natural: **custo de nuvem por
ingresso vendido**. Na sua planilha, preparada como na aula 1, o deste ano:

```localised
=ARRED(212000/410000;3)      0,517
```

E o do plano do ano que vem:

```localised
=ARRED(236000/520000;3)      0,454
```

**A fatura sobe 11,3% e o custo de atender um ingresso cai 12,2%**, de R$ 0,517 para R$ 0,454.
Apresentado assim, o plano diz o contrário do que a fatura sozinha dizia: espera-se que a plataforma
fique mais barata por unidade de negócio enquanto o negócio cresce. Essa é a frase de que o Otávio
precisa, e ela abre uma conversa diferente de "por que a engenharia está gastando mais".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-unit\" aria-label=\"Dois painéis, cada um com duas barras: este ano e o plano do ano que vem. À esquerda, a fatura mensal da nuvem sobe de R$ 212.000 para R$ 236.000, alta de 11,3%. À direita, o custo de nuvem por ingresso vendido cai de R$ 0,517 para R$ 0,454, queda de 12,2%.\"><rect x=\"20.0\" y=\"14.0\" width=\"330.0\" height=\"222.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"38.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Fatura mensal da nuvem</text><text x=\"185.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">+11,3%</text><rect x=\"90.0\" y=\"105.4\" width=\"60.0\" height=\"100.6\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"120.0\" y=\"98.4\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 212.000</text><text x=\"120.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">este ano</text><rect x=\"220.0\" y=\"94.0\" width=\"60.0\" height=\"112.0\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"250.0\" y=\"87.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 236.000</text><text x=\"250.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">plano do ano que vem</text><rect x=\"370.0\" y=\"14.0\" width=\"330.0\" height=\"222.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"38.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Custo de nuvem por ingresso vendido</text><text x=\"535.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">−12,2%</text><rect x=\"440.0\" y=\"94.0\" width=\"60.0\" height=\"112.0\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect><text x=\"470.0\" y=\"87.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 0,517</text><text x=\"470.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">este ano</text><rect x=\"570.0\" y=\"107.6\" width=\"60.0\" height=\"98.4\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"600.0\" y=\"100.6\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">R$ 0,454</text><text x=\"600.0\" y=\"224.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">plano do ano que vem</text></svg>", "caption": "O mesmo plano lido de dois jeitos. A fatura sobe porque a Coreto vende mais ingressos; cada ingresso custa menos para atender. Só o painel da direita diz se a plataforma está ficando mais ou menos eficiente."}
```

## Escolher a unidade

Um custo unitário só é tão útil quanto a sua unidade, e três testes escolhem uma boa.

**É algo com que o negócio ganha dinheiro.** Ingressos funcionam na Coreto porque a taxa é por
ingresso, e assim o custo por ingresso pode ficar ao lado da receita por ingresso e ser lido como
margem. Uma unidade que o negócio não vende, como custo por servidor ou por engenheiro, mede um
insumo e não diz nada sobre se o gasto valeu a pena.

**A definição fica parada.** Se "um ingresso" significa ingressos vendidos neste trimestre e
ingressos emitidos, inclusive os gratuitos, no próximo, a tendência mede a mudança de definição.
Escreva a definição ao lado do número.

**Os times conseguem movê-la.** Uma unidade que nenhuma decisão afeta é uma estatística, não uma
meta. O custo por ingresso se move quando o Checkout deixa uma página mais barata de servir, quando
Dados guarda menos cópias do histórico de eventos, quando a Plataforma desliga máquinas ociosas. Cada
time também pode ter uma unidade própria — o custo por busca do Catálogo, por exemplo — desde que ela
se some à da empresa.

## O que ele esconde

O custo unitário é o melhor número isolado para uma fatura de nuvem, e mesmo assim esconde duas
coisas que um líder precisa saber.

**Parte da queda é escala, não competência.** Uma parte da fatura não cresce com os ingressos: o
monitoramento, as máquinas de build, os ambientes que existem quer se venda um ingresso, quer um
milhão. Espalhada por mais ingressos, essa parte fixa faz cada ingresso parecer mais barato sem que
ninguém mude nada. O plano da Coreto tem os ingressos crescendo 26,8% (520.000 contra 410.000) e a
fatura crescendo 11,3%, e parte dessa diferença apareceria mesmo que nenhum time trabalhasse em
custo. Antes de atribuir a queda do custo unitário a uma melhoria, pergunte que parte da fatura se
mexeu.

**Ele pode cair enquanto o desperdício cresce.** Um ambiente de homologação ligado o fim de semana
inteiro custa o mesmo com 410.000 ingressos vendidos ou com 520.000. Conforme as vendas crescem, sua
parcela no custo por ingresso encolhe e ele fica mais difícil de ver no custo unitário, enquanto
continua lá na fatura. A última seção desta aula encontra exatamente isso na Coreto.

## Por que ele dura

Os provedores vão continuar mudando a forma de cobrar. O custo unitário sobrevive a cada mudança,
porque faz uma pergunta sobre o negócio, não sobre a tabela de preços do provedor. **Um número que
compara o ano que vem com este, seja lá o que o provedor tenha renomeado no meio do caminho, é o que
se reporta todo mês**, e é a primeira linha da revisão mensal na fase de operar. A próxima seção
acrescenta a segunda linha: de quais decisões a fatura é feita.
