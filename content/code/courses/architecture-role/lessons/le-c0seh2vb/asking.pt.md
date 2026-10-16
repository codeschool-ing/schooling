---
title: Perguntar até virar um número
version: 1
---

**As palavras que o negócio usa para qualidades são adjetivos, e um adjetivo não pode ser testado.**
"Rápido", "sempre disponível", "seguro", "fácil de mudar" são onde uma conversa começa. O trabalho do
arquiteto é continuar perguntando, sobre objetivos e consequências e não sobre tecnologia, até cada um
virar um número ao qual um desenho possa ser cobrado.

Dois hábitos erram isso em direções opostas. Um toma o pedido ao pé da letra e começa a estimar a
tela. O outro faz à diretora de produto uma pergunta técnica — "de que latência você precisa?" — e
aceita o que vier. Helena não pensa em latência. Ela pensa em despachantes, cargas na doca e reservas
perdidas para concorrentes, e é para lá que as perguntas têm de ir.

## Perguntar pelo objetivo

Antes de pôr números num pedido, descubra para que ele serve. **Um pedido costuma ser uma solução que
alguém já escolheu**, e o problema para o qual ela foi escolhida é o requisito. A ferramenta para ir de
um ao outro é antiga: pergunte por quê, e depois pergunte por quê da resposta. Taiichi Ohno fez dos
"cinco porquês" parte do sistema de produção da Toyota, como forma de achar a causa raiz de um defeito.
Apontado para um pedido em vez de um defeito, o mesmo hábito acha o objetivo.

Renata não começou pela tela. Perguntou o que acontece hoje:

> Renata: O que acontece agora, entre a cotação e o caminhão?
>
> Helena: O preço volta na hora. Essa parte está boa. Aí o embarcador clica em "pedir caminhão" e
> espera.
>
> Renata: Por que a espera importa?
>
> Helena: Porque 30% das nossas cotações viram reservas, e eu preciso de 40% este ano. As que a gente
> perde, perde enquanto eles esperam.
>
> Renata: Por que eles desistem enquanto esperam?
>
> Helena: Uma despachante numa fábrica de móveis tem uma carga na doca às sete. Se às oito e meia ela
> não souber que vem caminhão, liga para a transportadora que usou no ano passado.
>
> Renata: Então o que ela precisa é saber que vem um caminhão. Não de uma tela só.
>
> Helena: É. A tela única foi a minha ideia de como fazer parecer mais rápido.

Três porquês, e **o requisito saiu da tela e foi para a espera.** Helena trouxe os números no dia
seguinte: a Carreto emite cerca de 42.000 cotações por mês e 12.600 viram reservas, que são os 30%.
Quarenta por cento seriam 16.800, então o objetivo vale cerca de 4.200 reservas a mais por mês. E a
espera de que ela falava tem mediana de 47 minutos entre "pedir caminhão" e um motorista aceitar, com
um pedido em cada dez esperando mais de 3 horas e 10 minutos.

Os dois últimos porquês não eram para Helena. Renata os levou a Kátia Lemos, tech lead de Matching. Por
que 47 minutos? Porque Matching oferta cada carga a um motorista por vez, e cada motorista tem dez
minutos para responder antes de a oferta passar ao próximo. Por que um por vez? Porque em 2019 dois
motoristas aceitaram a mesma carga e os dois apareceram no portão da fábrica, e ofertar a um motorista
por vez foi a correção.

**O negócio conhece o objetivo; o time conhece a causa.** Os porquês vão para quem consegue
respondê-los, e aqui as respostas mudaram o tipo de trabalho. A parte lenta não é a tela nem Pricing. É
uma regra dentro de Matching, escrita para proteger uma garantia — uma carga, um motorista — que
qualquer substituta ainda precisa manter. Isso é uma mudança estrutural em Matching, no app do
motorista e no app do embarcador, e é isso que a torna trabalho do arquiteto.

"Cinco" não é cota. Pare quando a resposta for um objetivo que o negócio defenderia nos próprios
termos, como mais reservas, ou uma causa que o time consegue mudar.

## Transformar adjetivos em números

Com o objetivo claro, "rápido" pode ganhar um número. Pedir o número diretamente não funciona: Helena
diria "instantâneo", ou inventaria um valor para encerrar a pergunta. **Pergunte sobre consequências e
ofereça números para a outra pessoa reagir.** Quem não consegue tirar um limite do nada é muito bom em
dizer qual de três está errado.

As perguntas que funcionaram com Helena:

- **Rápido para quem, fazendo o quê enquanto espera?** A despachante, com uma carga na doca e o
  telefone na mão.
- **O que acontece em cinco minutos, em quinze, em uma hora?** Em cinco, nada diferente de quinze. Em
  quinze, ela espera. Passada uma hora, está ligando para outro.
- **Para quais cargas, e quando?** Cargas completas nos corredores que levam a maior parte do volume,
  no horário em que os embarcadores trabalham. Uma carga fracionada para uma cidade pequena num sábado
  à tarde pode demorar mais.
- **Quantos precisam chegar lá?** Não todos; nove em dez já mexeriam na conversão, e o último em cada
  cem precisa ficar dentro de uma hora.

Daí saiu algo testável: **um motorista aceita em até 15 minutos em 90% dos pedidos, e em até 60
minutos em 99%,** nos corredores principais, em horário comercial. Ninguém perguntou a Helena sobre
percentis. Ela escolheu os números reagindo a consequências, e os percentis são só como o arquiteto os
escreve.

"Sempre disponível" passou pelo mesmo tratamento e se separou em dois requisitos diferentes.
Perguntada quanto custa uma hora do fluxo de reserva fora do ar numa terça às 10:00 e num domingo às
03:00, Helena disse que a primeira era um desastre e a segunda, nada: os embarcadores reservam de
segunda a sábado, entre 06:00 e 20:00. São 14 horas em 26 dias, ou 364 horas por mês, e só essas horas
contam.

Os motoristas são outra história. Eles estão na estrada a qualquer hora, entregam à noite e comprovam
a entrega com foto e assinatura em lugares sem sinal. **Para eles, "sempre disponível" não tem nada a
ver com os servidores**: quer dizer que o app do motorista registra o comprovante sem conexão e o envia
quando o celular achar uma. É um requisito diferente para um time diferente, e nenhuma redundância de
servidor o teria atendido.

Para o fluxo de reserva, o número é uma porcentagem, e a porcentagem tem preço. Cada nove a mais
elimina a maior parte do tempo fora do ar que era permitido e acrescenta custo: mais uma réplica do
banco, failover automático, um plantão que responde em minutos. Num mês de 30 dias:

| disponibilidade | tempo fora do ar permitido no mês |
|---|---|
| 99% | 7,2 horas |
| 99,5% | 3,6 horas |
| 99,9% | 43,2 minutos |
| 99,99% | 4,32 minutos |

Medido só nas 364 horas comerciais, 99,5% permite cerca de 109 minutos fora do ar por mês. Helena
escolheu isso depois que Sílvio Matos, diretor financeiro, viu o que 99,99% acrescentaria à conta de
infraestrutura e ao plantão para um fluxo que ninguém usa à noite. **Não deixe o negócio escolher um
número porque ele soa sério.** Mostre quanto cada um custa e deixe que escolham com o preço à vista; a
aula 13 volta a essa conversa.

## Pôr o fluxo na parede

Entrevistas acham o que uma pessoa sabe. Alguns requisitos vivem entre as pessoas: numa passagem de
bastão que ninguém tem como sua, ou num contorno que um time inventou e os outros nunca ouviram falar.
**Uma oficina que põe o fluxo inteiro diante de todos ao mesmo tempo acha esses.**

A que Renata usou é o **event storming**, criado por Alberto Brandolini. As pessoas que conhecem o
negócio ficam diante de uma parede comprida e escrevem *eventos de domínio* — coisas que aconteceram,
no passado — em post-its: "cotação emitida", "motorista aceitou", "CT-e autorizado". Põem tudo em ordem
de tempo, discutem a ordem e marcam *pontos quentes* onde alguém discorda ou algo dói. Sem laptops, sem
caixas e setas, sem palavras de tecnologia.

Renata conduziu uma de três horas com Helena, Kátia, Diego Araújo do app do motorista, Bruno Farias de
Payments, duas pessoas do suporte ao cliente e uma despachante da fábrica de móveis que aceitou vir
passar uma manhã. A parte da parede que importou ficou assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 302\" role=\"img\" aria-label=\"Oito eventos de domínio em post-its, em ordem de tempo, em duas fileiras: cotação emitida, caminhão solicitado, carga ofertada a um motorista, oferta expirou após 10 minutos, depois motorista aceitou, CT-e autorizado, caminhão saiu, entrega comprovada. Uma seta volta de oferta expirou para carga ofertada, com o rótulo próximo motorista, 10 minutos cada. Um ponto quente em volta do laço diz: mediana de 47 minutos até o aceite; após uma hora, o suporte liga para motoristas.\"><defs><marker id=\"l7storm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"362\" y=\"52\" width=\"336\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"362\" y=\"6\" width=\"336\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"19\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">ponto quente: mediana de 47 min até o aceite</text><text x=\"530\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">após uma hora, o suporte liga para motoristas</text><rect x=\"30\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Cotação emitida</text><path d=\"M180 83.0 L198 83.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"200\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Caminhão solicitado</text><path d=\"M350 83.0 L368 83.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"370\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Carga ofertada</text><text x=\"445.0\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a um motorista</text><path d=\"M520 83.0 L538 83.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"540\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Oferta expirou</text><text x=\"615.0\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">após 10 min</text><rect x=\"30\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Motorista aceitou</text><path d=\"M180 223.0 L198 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"200\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CT-e autorizado</text><path d=\"M350 223.0 L368 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"370\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Caminhão saiu</text><path d=\"M520 223.0 L538 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"540\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Entrega comprovada</text><path d=\"M600 106 L600 124 L460 124 L460 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><text x=\"530\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">próximo motorista, 10 min cada</text><path d=\"M690 83.0 L708 83.0 L708 172 L14 172 L14 223.0 L28 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><path d=\"M30 276 L690 276\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><text x=\"30\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tempo</text></svg>", "caption": "Parte da parede depois do event storming de Renata. O laço entre ofertar uma carga e a oferta expirar é onde vão os 47 minutos, e o ponto quente registra o contorno manual de que ninguém na engenharia tinha ouvido falar."}
```

Três coisas saíram da parede que nenhuma entrevista tinha produzido. **O suporte liga para motoristas
à mão** quando uma carga espera mais de uma hora, um processo que ninguém na engenharia sabia que
existia e que o novo desenho teria de substituir ou de manter funcionando. **"CT-e autorizado" vem
depois de "motorista aceitou"**, então confirmar o caminhão ao embarcador não precisa esperar a SEFAZ;
só a saída precisa. E a despachante disse que aceitaria um caminhão uma hora mais tarde se soubesse na
hora que ele vinha, o que mudou os 15 minutos de "o caminhão chega" para "o motorista se compromete".

O event storming também é o começo usual de um modelo de domínio, e a aula 11 de `design-patterns` o
leva daí para os contextos delimitados. Ouvir bem numa entrevista é um ofício à parte, que a aula 6 de
`architect-communication` ensina, e a aula 7 de `architecture-modeling` cobre a análise de negócio
estruturada a fundo.
