---
title: O pedido declarado e a necessidade real
version: 1
---

**As pessoas raramente levam um problema a uma arquiteta. Levam uma solução que já escolheram, e o
problema está por baixo dela.** "A gente precisa de um serviço de recomendações" é uma solução. "Os
clientes recorrentes estão comprando menos" é o problema. "A diretoria precisa de uma resposta até a
revisão" é a pressão que tornou o pedido urgente. Uma boa resposta atende aos três, e o primeiro é o
que tem mais chance de estar errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um iceberg em quatro camadas. Acima da linha, o que é dito: o pedido, precisamos de um serviço de recomendações. Abaixo da linha, o que está embaixo: o problema, quem volta a comprar gasta 8% menos desde janeiro; a pressão, a diretoria quer uma resposta até a revisão; e a medida, a cesta de volta a R$ 150.\"><defs><marker id=\"iceberg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M20 92 L700 92\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><text x=\"700\" y=\"82\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que é dito</text><text x=\"700\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o que está embaixo</text><rect x=\"60.0\" y=\"30\" width=\"600\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74.0\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o pedido</text><text x=\"170.0\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">\"Precisamos de um serviço de recomendações\"</text><rect x=\"80.0\" y=\"112\" width=\"560\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"94.0\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o problema</text><text x=\"190.0\" y=\"135\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quem volta a comprar gasta 8% menos desde janeiro</text><rect x=\"100.0\" y=\"168\" width=\"520\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"114.0\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a pressão</text><text x=\"210.0\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a diretoria quer uma resposta até a revisão</text><rect x=\"120.0\" y=\"224\" width=\"480\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"134.0\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a medida</text><text x=\"230.0\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">cesta de volta a R$ 150</text></svg>", "caption": "Só o pedido é dito em voz alta. As camadas de baixo aparecem ouvindo, e a última, a medida, é o que diz depois se algo funcionou."}
```

Isso não é uma crítica a quem pede. Renata conhece os clientes melhor do que Lívia, e ouviu dizer
que recomendações aumentam a cesta em outras empresas. Propor uma solução é a forma como a maioria
das pessoas descreve um problema que ainda não sabe nomear. **O trabalho de quem escuta é manter a
solução como uma opção enquanto encontra o problema que ela deveria resolver.**

## O que Lívia descobriu

Seguindo as perguntas abertas da seção anterior, ao longo de duas conversas e uma tarde com o time
de dados:

- A cesta de quem **volta a comprar** caiu de cerca de R$ 150 para cerca de R$ 138 entre janeiro e
  abril, uma queda de 8%. A cesta dos clientes novos não mudou.
- Em janeiro o app foi redesenhado, e a lista "comprar de novo", que mostrava ao cliente os itens que
  ele mais pedia, saiu da tela inicial e foi para um menu.
- Quem ainda abria essa lista comprava tanto quanto antes. Menos clientes a abriam.

A necessidade real não era de recomendações. Era levar os clientes recorrentes de volta à lista do
que eles já compram. Pôr a lista de volta na tela inicial levou **dois dias** para o time de Bruna.
O serviço de recomendações tinha sido estimado em um trimestre para dois times.

## Jobs to be done

Clayton Christensen, que estudou como as empresas decidem o que construir, descreveu a mesma ideia
como *jobs to be done*, os trabalhos a fazer: o cliente não quer um produto, ele o "contrata" para
fazer um trabalho na vida dele, e entender o trabalho diz o que construir. O exemplo mais conhecido
dele é uma rede de fast-food que tentava vender mais milk-shakes e descobriu que muitos eram
comprados cedo de manhã por quem ia de carro para o trabalho e queria algo que tornasse a viagem
longa menos chata e segurasse a fome até o almoço. Era nesse trabalho, e não no sabor, que o
milk-shake competia.

A ideia funciona dentro de uma empresa também. **Pergunte para que trabalho a coisa pedida está sendo
contratada**, e o pedido vira um candidato entre vários.

## Quando o pedido declarado está certo

Às vezes quem pede já fez o diagnóstico, e a solução está correta. O teste não é rejeitar todo
pedido; é entender a necessidade bem o bastante para saber. Se Lívia tivesse descoberto que os
clientes recorrentes abriam a lista e mesmo assim compravam menos, um serviço de recomendações
poderia ter sido exatamente o certo, e ela o teria proposto com uma medida junto: a cesta de volta a
R$ 150. **Escutar a necessidade real é como você descobre se a solução pedida é a certa, não uma
forma de recusá-la.**
