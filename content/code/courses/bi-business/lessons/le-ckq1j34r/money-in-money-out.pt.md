---
title: Dinheiro que entra, dinheiro que sai
version: 1
---

Um organograma mostra a empresa como caixas de pessoas: finanças, marketing, operações, recursos
humanos. **Para um analista, é mais útil vê-la como fluxos: dinheiro entrando dos clientes, saindo
para fornecedores, equipe e todo o resto, e o que sobra.** Todo número que um analista de BI relata
mede um desses fluxos, ou algo que move um deles, e saber qual diz quem se importa com ele e por quê.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 440\" role=\"img\" aria-label=\"A Varanda como fluxos de dinheiro e de mercadoria. No centro, a empresa. Os clientes pagam, em cima: R$ 98,0 milhões de vendas em 2025. O dinheiro sai para os fornecedores pelas mercadorias, R$ 55,4 milhões, para as pessoas pelo trabalho, R$ 18,8 milhões, e para aluguel, marketing, depósito e outros custos, R$ 21,0 milhões. O que sobra é o lucro operacional, R$ 2,9 milhões. Em volta da empresa, as quatro áreas e o que cada uma decide: marketing traz clientes, operações compra, guarda e entrega as mercadorias, pessoas contrata e mantém a equipe, finanças conta tudo e decide para onde vai o dinheiro.\" data-fig=\"l05-flows\"><rect x=\"250.0\" y=\"160.0\" width=\"220.0\" height=\"110.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper)\">Varanda</text><text x=\"360.0\" y=\"220.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">lucro operacional</text><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">R$ 2,9 milhões</text><rect x=\"250.0\" y=\"20.0\" width=\"220.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">clientes</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pagam R$ 98,0 milhões</text><path d=\"M360.0 82.0 L360.0 158.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M360.0 158.0 L356.1 149.9 L363.9 149.9 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"30.0\" y=\"350.0\" width=\"200.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"376.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">fornecedores</text><text x=\"130.0\" y=\"396.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">mercadorias: R$ 55,4 mi</text><path d=\"M279.5 272.0 L130.0 348.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M130.0 348.0 L135.5 340.8 L139.0 347.8 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"260.0\" y=\"350.0\" width=\"200.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"376.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">equipe</text><text x=\"360.0\" y=\"396.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">salários: R$ 18,8 mi</text><path d=\"M360.0 272.0 L360.0 348.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M360.0 348.0 L356.1 339.9 L363.9 339.9 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"490.0\" y=\"350.0\" width=\"200.0\" height=\"60.0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"376.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">todo o resto</text><text x=\"590.0\" y=\"396.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">R$ 21,0 mi</text><path d=\"M440.5 272.0 L590.0 348.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M590.0 348.0 L581.0 347.8 L584.5 340.8 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><rect x=\"16.0\" y=\"120.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"121.0\" y=\"146.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">marketing</text><text x=\"121.0\" y=\"166.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">traz os clientes</text><rect x=\"16.0\" y=\"220.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"121.0\" y=\"246.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">operações</text><text x=\"121.0\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">compra, guarda, entrega</text><rect x=\"494.0\" y=\"120.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"599.0\" y=\"146.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">finanças</text><text x=\"599.0\" y=\"166.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">conta e decide gastos</text><rect x=\"494.0\" y=\"220.0\" width=\"210.0\" height=\"62.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"599.0\" y=\"246.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">pessoas</text><text x=\"599.0\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">contrata e mantém</text><text x=\"360.0\" y=\"434.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o dinheiro entra por cima e sai por baixo</text></svg>", "caption": "O 2025 da Varanda como dinheiro que entra e que sai. De cada R$ 100 que os clientes pagaram, sobraram R$ 2,92 de lucro operacional; as quatro áreas decidem como o resto é gasto.", "same": ["Varanda", "marketing"]}
```

## Os fluxos da Varanda em 2025

**Os clientes pagaram R$ 98,0 milhões**, as vendas do ano da aula 1. Quase tudo saiu de volta. R$ 55,4
milhões pagaram os fornecedores pelos móveis, plantas e utensílios de cozinha vendidos. R$ 18,8
milhões pagaram as 410 pessoas que trabalham lá. R$ 21,0 milhões foram para todo o resto: aluguel e
funcionamento das nove lojas, marketing, o depósito em Contagem e seus caminhões, e os custos menores
que toda empresa tem. **Sobraram R$ 2,9 milhões de lucro operacional, ou R$ 2,92 de cada R$ 100 que um
cliente pagou.**

Esse número pequeno é a primeira coisa que um analista novo precisa absorver sobre o varejo. Uma alta
de 5% no custo das mercadorias, com os preços iguais, custaria R$ 2,77 milhões, quase todos os R$ 2,86
milhões de lucro. **Num negócio de margem estreita, pequenas mudanças em fluxos grandes decidem o
ano**, e por isso tantas perguntas que um analista recebe são sobre custos que parecem pequenos perto
das vendas.

## Quatro áreas, quatro tipos de decisão

Cada área existe para cuidar de alguns fluxos, e cada uma toma um tipo diferente de decisão:

| área | os fluxos de que cuida | as decisões que toma | quem a lidera na Varanda |
|---|---|---|---|
| finanças | todos, como números | para onde vai o dinheiro, o que é aprovado, quando as contas são pagas | Otávio Lins |
| marketing e vendas | os clientes que entram | que clientes alcançar, como, e a que preço | Renata Sá |
| operações | as mercadorias que entram e saem | o que comprar, quanto estoque manter, como entregar | Caio Barreto |
| pessoas | a equipe, o maior custo depois das mercadorias | quem contratar, como pagar, como manter | Sônia Freitas |

A CEO, Helena, decide sobre as quatro, e o conselho acima dela também. As próximas seções tratam de
uma área cada: o que ela mede, o que os números dela querem dizer e o que costuma dar errado com eles.

## Por que um analista precisa deste mapa

**O mesmo número quer dizer coisas diferentes para áreas diferentes.** Uma alta no estoque é um risco
para finanças (dinheiro parado), um alívio para operações (menos prateleira vazia) e uma promessa para
marketing (algo para promover). Um analista que relata "o estoque subiu 12%" sem saber quem vai ler não
respondeu à pergunta de ninguém. O mapa também diz onde olhar quando um número se mexe: o lucro caiu,
então entrou menos dinheiro, ou saiu mais, e por qual fluxo?

A aula 6 começa a análise propriamente dita pela mais simples dessas perguntas, o que aconteceu, e os
números desta aula são o vocabulário que ela usa.
