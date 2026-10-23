---
title: Um diagrama responde a uma pergunta
version: 1
---

**Um diagrama vale o desenho quando responde a uma pergunta que alguém tem, para um leitor que vai
agir com a resposta.** Dê nome à pergunta e ao leitor primeiro, e a maior parte das decisões sobre o
que desenhar se resolve sozinha.

A falha comum é a ordem inversa: o desenho vem primeiro, porque se espera que um documento tenha
um, e a pergunta nunca é feita. O que sai é um retrato de tudo, que não responde a nada em
particular.

## O desenho na parede da Carcará

No primeiro dia de Bento, Rui apontou para um impresso colado ao lado das mesas do time de
Plataforma: "Essa é a arquitetura." Ele parecia a metade esquerda desta figura. Lá estavam os
logotipos do provedor de nuvem, do banco de dados e do broker de mensagens, um celular, um ônibus,
uma nuvem, e setas entre quase todos eles. Nenhuma seta tinha uma palavra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-decorated\" aria-label=\"Dois desenhos da Carcará. À esquerda, o impresso na parede: oito caixas com nomes de produtos, como PostgreSQL, Redis, RabbitMQ, o provedor de nuvem e um celular, ligadas por nove setas sem nenhuma palavra. À direita, o diagrama desenhado para responder a uma pergunta, qual serviço recebe o dinheiro quando alguém compra uma passagem: um passageiro, o app do passageiro, a API de passagens, o banco de reservas e o gateway de pagamento, cada um com seu tipo, ligados por quatro linhas com rótulo.\"><defs><marker id=\"l01-decorated-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l01-decorated-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o impresso na parede</text><text x=\"545.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desenhado para uma pergunta</text><path d=\"M360.0 30.0 L360.0 315.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"28.0\" y=\"55.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Celular</text><rect x=\"158.0\" y=\"45.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Nuvem</text><rect x=\"258.0\" y=\"95.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">PostgreSQL</text><rect x=\"48.0\" y=\"155.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Redis</text><rect x=\"178.0\" y=\"145.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">RabbitMQ</text><rect x=\"258.0\" y=\"215.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"300.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Pagamentos</text><rect x=\"38.0\" y=\"255.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Ônibus</text><rect x=\"158.0\" y=\"265.0\" width=\"84.0\" height=\"30.0\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">PostgreSQL</text><path d=\"M112.0 66.8 L154.6 63.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M230.0 75.0 L267.6 93.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M203.0 75.0 L216.8 143.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M178.0 163.2 L135.4 166.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M87.0 155.0 L73.2 86.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M237.1 175.0 L281.5 213.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M300.0 215.0 L300.0 126.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M99.1 255.0 L199.4 176.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><path d=\"M217.5 175.0 L202.7 263.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper-dim)\"></path><circle cx=\"440.0\" cy=\"56.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"394.0\" y=\"70.0\" width=\"92.0\" height=\"44.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"440.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Passageiro</text><rect x=\"545.0\" y=\"52.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">App do passageiro</text><text x=\"620.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[web e celular]</text><rect x=\"545.0\" y=\"152.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">API de passagens</text><text x=\"620.0\" y=\"181.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[serviço Kotlin]</text><rect x=\"375.0\" y=\"247.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"263.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Banco de reservas</text><text x=\"450.0\" y=\"276.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[PostgreSQL]</text><rect x=\"545.0\" y=\"262.0\" width=\"150.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"620.0\" y=\"278.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Gateway de pagamento</text><text x=\"620.0\" y=\"291.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[sistema externo]</text><path d=\"M486.0 80.0 L543.0 76.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper)\"></path><text x=\"514.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">compra</text><path d=\"M620.0 98.0 L620.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper)\"></path><text x=\"628.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">HTTPS: cria reserva</text><path d=\"M560.0 198.0 L490.0 245.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper)\"></path><text x=\"538.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">SQL: grava</text><path d=\"M620.0 198.0 L620.0 260.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-decorated-am-fill-paper)\"></path><text x=\"650.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">HTTPS: cobra</text></svg>", "caption": "O desenho da esquerda afirma que oito coisas estão ligadas. O da direita diz o que cada coisa é e o que passa por cada linha, então quem lê pode conferir, e discordar.", "same": ["PostgreSQL", "RabbitMQ", "Redis", "[PostgreSQL]"]}
```

Bento fez três perguntas naquela semana, e o impresso não respondeu a nenhuma:

1. *Quando alguém compra uma passagem, qual serviço recebe o dinheiro?* O desenho tem uma caixa com
   o logotipo do gateway de pagamento, e três setas tocam nela. Ele não diz qual delas é a compra.
2. *Se o gateway de pagamento está lento, o assento continua reservado?* Nada no desenho fala de
   tempo, então ele não tem como dizer.
3. *Onde fica guardado o CPF de um passageiro?* Há dois logotipos de banco de dados e nenhum jeito
   de saber que dado está em qual.

A metade direita da figura é o que Tainá desenhou quando Bento fez a primeira pergunta. Ela mostra
cinco elementos em vez de doze, e **cada um deles tem nome, tem tipo e está ligado por uma linha que
diz o que passa por ela.** Ela também não responde à terceira pergunta, e nem precisa: essa ganha um
desenho próprio, que a aula 3 faz.

## Decoração e comunicação

Um diagrama decorativo não é inútil por ser feio. Ele pode ser muito bonito. Ele falha porque
**afirma coisas que o leitor não consegue conferir**: que essas partes existem, que estão ligadas,
que a ligação importa. Quem lê preenche o sentido de cada linha com um palpite seu, e dois leitores
chutam diferente sem saber que chutaram.

Três sinais dizem que um diagrama é decoração:

- **É o mesmo desenho para todo público.** A diretoria, o engenheiro novo e o auditor receberam o
  impresso. Eles precisam de coisas diferentes, então ele não serviu bem a nenhum.
- **Nada nele poderia estar errado.** Um diagrama que não faz nenhuma afirmação específica, como qual
  serviço chama qual por qual protocolo, não pode ser contradito pelo sistema. É isso que o torna
  inútil como referência.
- **Os logotipos carregam o sentido.** Um logotipo diz qual produto é usado. Não diz o que esse
  produto faz neste sistema, e o mesmo produto de banco de dados pode ser três repositórios
  diferentes.

## Comece pela pergunta

Antes de desenhar, escreva duas linhas no alto da página:

> **Pergunta:** quando um passageiro compra uma passagem, que partes participam, e em que ordem?
> **Leitor:** Bento, engenheiro novo no time de Vendas.

Com essas duas linhas, o desenho tem um escopo. O app de embarque fica de fora, porque embarcar não
faz parte de comprar. A ordem importa, então um diagrama de sequência da aula 2 talvez sirva melhor
do que caixas. O leitor é engenheiro, então os protocolos e as tecnologias vão nas linhas.

**Desenhe você também.** Escolha um sistema que você conhece, do trabalho ou de um projeto de curso.
Escreva uma pergunta que alguém novo faria sobre ele, e o leitor que faria essa pergunta. Depois
desenhe só o que responde a ela, e conte os elementos: se passar de uma dúzia, mais ou menos, a
pergunta está ampla demais, ou o diagrama está respondendo a uma segunda também.
