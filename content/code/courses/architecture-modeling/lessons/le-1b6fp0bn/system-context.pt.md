---
title: Nível 1, contexto do sistema
version: 1
---

**O diagrama de contexto do sistema mostra o sistema de software como uma caixa só, as pessoas que
o usam e os outros sistemas de software de que ele depende ou que dependem dele.** Nada de dentro da
caixa aparece. É o desenho que qualquer pessoa consegue ler, técnica ou não, e o que deveria existir
para todo sistema.

Ele responde a três perguntas: *para que serve este sistema?*, *quem o usa?* e *do que ele precisa
do mundo em volta?*

## A venda de passagens Carcará em contexto

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l03-context\" aria-label=\"O diagrama de contexto da venda de passagens da Carcará. No meio, uma caixa: venda de passagens Carcará, um sistema de software que vende e confere passagens. À esquerda, três pessoas: o passageiro compra passagens com ele, o agente de guichê vende no guichê, o motorista confere passagens com ele. À direita, três sistemas de software externos, em cinza e tracejados: o gateway de pagamento, que cobra cartão e Pix; o Frota, que manda as viagens do dia seguinte; e o provedor de notificação, pelo qual as passagens são enviadas.\"><defs><marker id=\"l03-context-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"260.0\" y=\"135.0\" width=\"200.0\" height=\"70.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"157.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Venda de passagens Carcará</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Sistema de software]</text><text x=\"360.0\" y=\"182.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">vende e confere passagens</text><circle cx=\"90.0\" cy=\"30.0\" r=\"11\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"43.0\" width=\"112.0\" height=\"40.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Passageiro</text><text x=\"90.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">[Pessoa]</text><circle cx=\"90.0\" cy=\"140.0\" r=\"11\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"153.0\" width=\"112.0\" height=\"40.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Agente de guichê</text><text x=\"90.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">[Pessoa]</text><circle cx=\"90.0\" cy=\"250.0\" r=\"11\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"263.0\" width=\"112.0\" height=\"40.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Motorista</text><text x=\"90.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">[Pessoa]</text><rect x=\"550.0\" y=\"37.0\" width=\"160.0\" height=\"46.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Gateway de pagamento</text><text x=\"630.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Sistema de software]</text><rect x=\"550.0\" y=\"147.0\" width=\"160.0\" height=\"46.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"163.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Frota</text><text x=\"630.0\" y=\"176.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Sistema de software]</text><rect x=\"550.0\" y=\"257.0\" width=\"160.0\" height=\"46.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"273.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Provedor de notificação</text><text x=\"630.0\" y=\"286.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Sistema de software]</text><path d=\"M146.0 66.0 L262.0 146.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M146.0 172.0 L258.0 172.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M146.0 276.0 L262.0 196.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M460.0 150.0 L550.0 76.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M550.0 172.0 L460.0 172.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M460.0 194.0 L550.0 268.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><text x=\"198.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">compra passagens</text><text x=\"202.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">vende no guichê</text><text x=\"186.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">confere passagens</text><text x=\"530.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">cobra cartão e Pix</text><text x=\"505.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">manda as viagens do dia</text><text x=\"520.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">envia passagens por</text></svg>", "caption": "Uma caixa para o sistema inteiro, e só pessoas e outros sistemas em volta. O Frota é cinza embora seja da Carcará: cinza quer dizer fora do escopo, não fora da empresa.", "same": ["Frota"]}
```

Tudo nele é uma pessoa ou um sistema de software:

- **Passageiros** buscam viagens, compram passagens e as recebem no celular.
- **Agentes de guichê** vendem passagens no balcão de 26 rodoviárias, para quem paga em dinheiro ou
  não usa o app.
- **Motoristas** conferem as passagens na porta do ônibus.
- **O gateway de pagamento**, operado por outra empresa, cobra cartões e Pix e confirma os
  pagamentos.
- **A Frota**, o sistema de frota da própria Carcará, comprado em 2009, guarda os ônibus, os
  motoristas e os horários, e manda toda noite as viagens do dia seguinte.
- **O provedor de notificação** envia os e-mails e SMS com as passagens e as mudanças.

A Frota está em cinza embora seja da Carcará, porque **ela está fora do sistema que está sendo
descrito**. A cor diz *no escopo* e *fora do escopo*, não *nosso* e *deles*. A legenda deveria dizer
isso, porque é exatamente a convenção que quem lê adivinha errado.

## O que deixar de fora

O diagrama de contexto muitas vezes sai detalhado demais, porque o autor sabe o que tem dentro e não
resiste a mostrar. Três coisas não pertencem a ele:

- **containers**, como o banco de dados ou a API: eles são o nível seguinte;
- **protocolos e tecnologias**: um diagrama de contexto é para todo mundo, e *HTTPS/JSON* não
  significa nada para a maioria;
- **infraestrutura**, como o provedor de nuvem, balanceadores de carga ou firewalls: a não ser que o
  provedor de nuvem seja de fato um sistema com que os usuários ou o sistema interagem, isso é
  implantação, que é outro diagrama.

O que ele deve ter é **um rótulo em cada linha dizendo o que flui ou o que é feito**, do ponto de
vista da origem da seta: *compra passagens usando*, *manda as viagens do dia seguinte para*, *cobra
cartão e Pix por meio de*.

## Desenhando um para um sistema que você não conhece

O diagrama de contexto também é a primeira coisa a desenhar quando você chega num time, antes de ler
qualquer código. Ele só precisa de conversas: pergunte *quem usa?* e *com o que ele fala?*, e
desenhe o que ouvir. As discordâncias entre as respostas de duas pessoas costumam ser a coisa mais
útil que você vai aprender naquela semana.

**Desenhe você também.** Desenhe o contexto do sistema da Frota, o sistema de frota, tratando-a como
o sistema no escopo. A venda de passagens Carcará agora é uma das caixas cinza em volta dela. Que
pessoas usam a Frota e nunca aparecem para a venda de passagens?
