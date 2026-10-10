---
title: Trabalhando com produto: o quê, por quê, e quanto custa
version: 1
---

A relação entre um arquiteto e uma diretora de produto dá errado de dois jeitos opostos. Num, o
arquiteto é quem diz não: toda feature encontra uma lista de motivos pelos quais não dá para construí-la
direito, produto aprende a contornar o arquiteto, e as decisões são tomadas sem a informação de que
precisavam. No outro, o arquiteto diz sim a tudo e absorve o custo em silêncio, então as features saem
no prazo e a estrutura por baixo fica mais difícil de mudar a cada uma. **Produto é dono do que é
construído, por quê e em que ordem. O arquiteto é dono do como estrutural, e da tarefa de tornar seu
custo visível antes da decisão, não depois.** Nenhum dos dois decide a troca sozinho; produto decide
com as consequências na mesa.

## Uma feature que parecia um formulário

Em agosto Helena trouxe um pedido das cooperativas de grãos. Na safra, uma cooperativa costuma ter mais
grão para mover do que um caminhão leva, e hoje o embarcador cria uma carga por caminhão à mão,
digitando a mesma origem, destino e mercadoria duas ou três vezes. O pedido da Helena era um campo no
formulário da carga: *número de caminhões*. Na tela era um campo e uma regra de validação. O time
Shipper estimou uma semana.

Renata leu o pedido contra a estrutura. No monólito uma carga corresponde a exatamente um motorista, um
CT-e, um repasse, uma sessão de rastreamento e uma linha na fatura do embarcador. Esse um-para-um passa
pelas ofertas de Matching, pela cotação de Pricing, pelos repasses de Payments e pelas sessões de
Tracking. Uma carga com três caminhões o quebra em todos de uma vez. **O custo da feature não estava no
formulário; estava numa suposição sobre a qual cinco times tinham construído.**

Ela não respondeu com "não", e não respondeu com um desenho. Escreveu para a Helena uma página com duas
opções, cada uma com o que custa e o que dá:

| | A: cargas ligadas | B: um embarque com trechos |
|---|---|---|
| o que é | o formulário cria três cargas comuns que compartilham uma referência de pedido | um novo *embarque* que contém vários *trechos*, cada um um caminhão |
| times envolvidos | Shipper | Shipper, Matching, Pricing, Payments, Tracking |
| estimativa | 3 semanas | 11 semanas |
| o embarcador vê | três cotações, três CT-e, três linhas na fatura | uma cotação e uma fatura; ainda um CT-e por caminhão, como a lei exige |
| o que deixa | relatórios contam três cargas onde a cooperativa vê um pedido | a base para rotas com várias paradas, já no roadmap de 2027 |

A estimativa de A é três semanas e não uma porque o formulário era só uma parte: a referência do pedido
precisa aparecer nas telas do embarcador e nas ferramentas do suporte, senão ninguém consegue saber que
três cargas andam juntas.

**Helena escolheu A, com uma condição escrita na decisão**: se as cargas ligadas passarem de 300 por mês,
B entra no roadmap. É um bom resultado, e não porque A fosse a resposta certa em geral. É bom porque a
dona da prioridade escolheu com as onze semanas e o problema dos relatórios na frente dela, e porque a
condição faz com que ninguém precise ganhar a discussão de novo depois. Renata registrou tudo num ADR
(aula 5), com o gatilho nas consequências.

## O custo estrutural, dito em termos de produto

A página funcionou porque estava escrita nas unidades da Helena. Ela não precisa saber que uma chave
estrangeira liga repasses a cargas. Precisa saber que a opção B ocupa cinco times por onze semanas, o
que mais essas semanas teriam construído, e o que a cooperativa vai ver na fatura. **A contribuição de
um arquiteto para uma decisão de produto é um conjunto de opções com tempo, custo, risco e o que cada
uma deixa para trás**, nas palavras de quem decide.

Três hábitos fizeram isso funcionar na Carreto:

- Renata entra na descoberta, não só no planejamento. Quando uma feature chega ao planejamento
  trimestral, a forma dela já está decidida e um arquiteto só consegue pôr preço. Duas semanas antes,
  enquanto o time da Helena ainda conversa com as cooperativas, uma pergunta sobre o um-para-um pode
  mudar a forma.
- Cada brief de produto tem um parágrafo estrutural. Uma pergunta, respondida por quem no time souber
  melhor: em quais suposições do sistema esta feature mexe? A maioria das respostas é "nenhuma". As que
  não são é onde o arquiteto gasta tempo.
- Opções, não veredictos. Renata dá duas ou três opções quando consegue, incluindo a mais barata que
  seja honesta. Uma proposta única convida a um sim ou a um não; opções convidam a uma decisão.

## O arquiteto também traz ideias

Trabalhar com produto não é só pôr preço no pedido dos outros. O arquiteto sabe o que a estrutura torna
barato, e parte disso vale para clientes que ainda nem pediram.

Tracking já emite um evento de posição para cada caminhão a cada trinta segundos. Transformar isso numa
previsão de chegada para o embarcador era um cálculo sobre eventos que já existem, e o time de Tracking
estimou duas semanas. Embarcadores ligavam para o suporte perguntando onde estava o caminhão; o suporte
registrava cerca de 1.400 dessas ligações por mês. Renata levou a ideia à sessão de descoberta da Helena
como uma possibilidade com estimativa e um palpite das ligações que pouparia, e Helena a pôs no plano do
trimestre seguinte. **A estrutura é um ativo que produto pode gastar, e o arquiteto é quem conhece o
saldo.**

O mesmo vale para trabalho sem feature associada. Uma atualização do framework do monólito, o próprio
serviço de CT-e, a remoção de um serviço que ninguém precisa: cada um disputa as mesmas semanas que as
features. O SAFe chama o trabalho estrutural que mantém as próximas features baratas de **pista
arquitetural** (*architectural runway*); o nome importa menos que a prática, que é pô-lo no mesmo
roadmap das features, defendido nos mesmos termos, em vez de fazê-lo nas brechas. A aula 18 de
`tech-strategy` trata de um roadmap com dois autores, e a aula 16 de lá trata das decisões técnicas que
são decisões de produto disfarçadas.

## Onde fica a linha

Algumas coisas são da Helena e não da Renata, por mais forte que seja a opinião da Renata: quais
clientes importam mais, o que entra no próximo trimestre, se as cooperativas valem onze semanas.
Algumas são da Renata e não da Helena: como um embarque é modelado, que serviço guarda os dados do CT-e, se
um serviço novo se justifica. O teste útil para uma divergência é perguntar **de quem é a
consequência**. Se o custo cai em clientes e receita, produto decide com a informação do arquiteto. Se
cai na estrutura, o arquiteto decide com a informação de produto, e diz isso.

O que continua compartilhado é a troca entre as duas: uma data contra uma estrutura, uma feature contra
pista. Essa conversa é uma negociação, e negociar prazo, escopo e dívida é a aula 13 de
`architect-communication`. A aula 13 deste curso volta à troca em si, com uma data regulatória fixa no
meio.
