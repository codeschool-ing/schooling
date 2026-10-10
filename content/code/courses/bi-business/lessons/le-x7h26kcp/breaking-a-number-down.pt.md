---
title: Decompor um número
version: 1
---

Um diagnóstico começa onde o relatório descritivo da aula 6 parou: outubro de 2025 vendeu R$ 7.960
mil, 0,7% abaixo de outubro de 2024, e foi o único mês do ano abaixo do valor de 2024. Todo mundo na
Varanda tinha uma explicação pronta. **O primeiro trabalho não é escolher uma delas. É achar em que
parte do número a variação está de fato**, e isso se faz quebrando o total em partes que somam ou
multiplicam de volta até ele.

## Um total é feito de partes

O instinto errado é sair procurando causas logo de cara: o tempo, um concorrente, a economia. Cada
uma delas agiria sobre alguma parte do negócio e não sobre outras, então antes de testar qualquer uma
vale saber que parte se mexeu. Um total pode ser dividido de três jeitos que todo varejista tem nos
seus dados:

- por canal: as nove lojas, e a loja online;
- por lugar ou produto: cada loja, cada categoria (móveis, jardim, cozinha, iluminação, decoração);
- em uma contagem e uma média: vendas = número de pedidos × tíquete médio, em que o tíquete médio é
  vendas divididas por pedidos.

Os dois primeiros são somas. O outubro da Varanda é as nove lojas mais a loja online, e cada loja é
as suas cinco categorias somadas. O terceiro é uma multiplicação, e responde a outra pergunta: se
menos gente comprou, ou se as mesmas pessoas gastaram menos. **Menos pedidos aponta para tráfego,
campanha ou estoque; um tíquete menor aponta para preço, desconto ou mix de produtos.** As duas
listas de causas quase não se cruzam, e é por isso que essa divisão vale a pena antes de qualquer
outra coisa.

## A árvore de decomposição

Aplicadas uma depois da outra, as divisões formam uma árvore. A Lívia desenhou a de outubro com os
números dos cupons das lojas e dos pedidos pagos da loja online:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma árvore. No topo, outubro de 2025: R$ 7.960 mil, 0,7% abaixo de outubro de 2024. Ela se divide nas lojas, R$ 6.880 mil, alta de 3,5%, e na loja online, R$ 1.080 mil, queda de 21,2%. As lojas se dividem em 17.920 cupons, alta de 2,4%, vezes um tíquete médio de R$ 384, alta de 1,0%. A loja online se divide em 2.160 pedidos, queda de 21,2%, vezes um tíquete médio de R$ 500, sem mudança.\" data-fig=\"l07-tree\"><rect x=\"250.0\" y=\"14.0\" width=\"220.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"34.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">outubro de 2025, tudo</text><text x=\"360.0\" y=\"53.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">R$ 7.960 mil</text><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">−0,7% sobre out/2024</text><rect x=\"90.0\" y=\"124.0\" width=\"200.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"144.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">as nove lojas</text><text x=\"190.0\" y=\"163.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">R$ 6.880 mil</text><text x=\"190.0\" y=\"180.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">+3,5%</text><rect x=\"440.0\" y=\"124.0\" width=\"200.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"540.0\" y=\"144.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a loja online</text><text x=\"540.0\" y=\"163.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">R$ 1.080 mil</text><text x=\"540.0\" y=\"180.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">−21,2%</text><rect x=\"20.0\" y=\"240.0\" width=\"160.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">cupons</text><text x=\"100.0\" y=\"279.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">17.920</text><text x=\"100.0\" y=\"296.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">+2,4%</text><rect x=\"200.0\" y=\"240.0\" width=\"160.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tíquete médio</text><text x=\"280.0\" y=\"279.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">R$ 384</text><text x=\"280.0\" y=\"296.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">+1,0%</text><rect x=\"370.0\" y=\"240.0\" width=\"160.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pedidos</text><text x=\"450.0\" y=\"279.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">2.160</text><text x=\"450.0\" y=\"296.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">−21,2%</text><rect x=\"550.0\" y=\"240.0\" width=\"160.0\" height=\"64.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"260.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tíquete médio</text><text x=\"630.0\" y=\"279.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">R$ 500</text><text x=\"630.0\" y=\"296.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">0,0%</text><path d=\"M360.0 78.0 L360.0 100.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 100.0 L540.0 100.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 100.0 L190.0 122.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M540.0 100.0 L540.0 122.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M190.0 188.0 L190.0 214.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M100.0 214.0 L280.0 214.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M100.0 214.0 L100.0 238.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M280.0 214.0 L280.0 238.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"190.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper-dim)\">×</text><path d=\"M540.0 188.0 L540.0 214.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M450.0 214.0 L630.0 214.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M450.0 214.0 L450.0 238.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M630.0 214.0 L630.0 238.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"540.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" fill=\"var(--paper-dim)\">×</text></svg>", "caption": "Outubro de 2025 decomposto duas vezes: por canal, e depois cada canal em pedidos e tíquete médio. A queda está num galho só, e num fator dele: os pedidos online.", "same": ["R$ 384", "R$ 500"]}
```

Leia de cima para baixo. O total caiu 0,7%. Um galho, as lojas, cresceu 3,5%; o outro, a loja
online, caiu 21,2%. Dentro da loja online, o tíquete médio ficou em R$ 500 e o número de pedidos caiu
de 2.740 para 2.160. **Então a pergunta mudou de forma.** "Por que outubro caiu?" é ampla demais para
testar. "Por que foram pagos 580 pedidos online a menos em outubro?" pode ser testada contra uma
lista curta de coisas.

## Até onde descer

Uma árvore pode ser dividida até cada folha ser um produto numa loja num dia, e nesse nível toda
folha se mexe, então nada se destaca. **Pare de dividir quando um galho concentra a variação e os
irmãos dele não.** Aqui isso aconteceu no segundo nível: as nove lojas cresceram, então dividi-las
por categoria gastaria uma tarde descrevendo um crescimento que não precisa de explicação. O galho
online foi dividido mais uma vez, em pedidos e tíquete, porque essa divisão escolhe entre duas
listas diferentes de causas.

A ordem das divisões importa menos do que as pessoas temem. Dividir primeiro em pedidos e tíquete, e
depois por canal, teria chegado à mesma folha: os pedidos online. O que importa é que cada divisão
some de volta ao galho de cima, para nada cair num vão entre os galhos. A próxima seção faz isso
numa planilha.
