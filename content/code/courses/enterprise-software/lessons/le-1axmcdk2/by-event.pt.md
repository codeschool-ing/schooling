---
title: Por evento, contando o que aconteceu
version: 1
---

Um evento é uma mensagem que afirma um fato: *a nota 4711 foi autorizada*. Ela não é endereçada a
ninguém e não pede nada. O sistema onde o fato aconteceu a publica, e todo sistema que se interessa
por notas fiscais a recebe e decide sozinho o que fazer. **Quem publica não sabe quem está ouvindo, e
não espera por nenhum deles.** Essa única propriedade é a razão de ser do estilo.

O mal-entendido comum é achar que um evento é uma chamada de API feita de forma assíncrona: a mesma
requisição, mandada por uma fila para que quem envia não espere. Isso existe, chama-se comando, e é
outro desenho. A diferença está em quem decide, e importa mais que o transporte.

## As notas da Serra Alta, por chamada

Num dia útil a Serra Alta emite cerca de 1.400 notas, e cada NF-e precisa ser autorizada pela SEFAZ
antes de a mercadoria sair. Quando a autorização volta, três outros sistemas precisam saber: o
Salesforce, para que um representante de grandes contas veja a nota no cadastro do cliente; o Portal
B2B, para que a padaria possa baixar a sua nota; e o provedor de EDI, para que o sistema de uma rede de
supermercados a receba.

Hoje cada um deles é uma integração própria, disparada do lado do SAP. Quando uma nota é autorizada,
o SAP a manda a um fluxo do ESB, e o fluxo chama a API do Salesforce, grava uma linha para o portal e
monta uma mensagem EDI, um depois do outro. São três chamadas por nota, cerca de **4.200 por dia**, e
o lado do SAP conhece os três destinatários. Quando o financeiro pediu as notas num conjunto de dados
do Power BI em 2025, foi preciso uma mudança no lado do SAP do fluxo e uma liberação no ESB, e o
calendário de liberações do ESB a jogou quatro meses para frente. Quando o Salesforce está fora do
ar, o fluxo falha no meio: o portal tem a nota e o Salesforce não, e alguém do time do Rui roda o
fluxo de novo à mão.

## As mesmas notas, por evento

Publicada como evento, a autorização vira uma mensagem num tópico, *nota autorizada*, cerca de 1.400
por dia. A integração do Salesforce, o portal e o fluxo de EDI assinam o tópico e recebem cada
mensagem. **Acrescentar um quarto consumidor é uma assinatura, e quem publica não muda nada.** O
conjunto de dados do Power BI teria sido um novo assinante, construído por quem o queria, sem nada a
liberar no lado do SAP.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l09-fan-out\" aria-label=\"Dois painéis. À esquerda, por chamada: o lado do SAP manda cada nota autorizada para o Salesforce, o Portal B2B e o provedor de EDI, três setas saindo de uma caixa, e um quarto destinatário significa uma mudança no lado do SAP. À direita, por evento: o SAP publica uma mensagem no tópico nota autorizada, e Salesforce, Portal B2B e o provedor de EDI assinam cada um; um quarto assinante, o Power BI, tracejado, entra depois sem o SAP mudar.\"><defs><marker id=\"l09-fan-out-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-fan-out-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"175.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">por chamada</text><text x=\"545.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">por evento</text><path d=\"M360.0 14.0 L360.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><rect x=\"20.0\" y=\"110.0\" width=\"100.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP</text><rect x=\"210.0\" y=\"53.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Salesforce</text><path d=\"M120.0 130.0 L208.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"210.0\" y=\"113.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M120.0 130.0 L208.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"210.0\" y=\"173.0\" width=\"120.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provedor de EDI</text><path d=\"M120.0 130.0 L208.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><text x=\"175.0\" y=\"248.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o lado do SAP conhece os três;</text><text x=\"175.0\" y=\"261.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um quarto é uma mudança ali</text><rect x=\"370.0\" y=\"110.0\" width=\"80.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SAP</text><rect x=\"475.0\" y=\"107.0\" width=\"110.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"123.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tópico</text><text x=\"530.0\" y=\"136.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nota autorizada</text><path d=\"M450.0 130.0 L473.0 130.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"39.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><path d=\"M586.0 130.0 L601.0 55.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"89.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><path d=\"M586.0 130.0 L601.0 105.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"139.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor de EDI</text><path d=\"M586.0 130.0 L601.0 155.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-fan-out-es-ah-phosphor)\"></path><rect x=\"603.0\" y=\"189.0\" width=\"104.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"655.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Power BI</text><path d=\"M586.0 130.0 L601.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-fan-out-es-ah-paper-dim)\"></path><text x=\"530.0\" y=\"248.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o SAP publica uma vez;</text><text x=\"530.0\" y=\"261.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um quarto é uma assinatura</text></svg>", "caption": "As mesmas notas, enviadas de dois jeitos. Com chamadas, quem envia conhece cada destinatário; com um evento, conhece só o tópico, e o Power BI entra sem o SAP mudar.", "same": ["Portal B2B", "Power BI", "SAP", "Salesforce"]}
```

A falha também muda de forma. Se o Salesforce ficar fora do ar por uma hora, as mensagens dele
esperam, e quando ele volta trabalha nelas até zerar. O portal e o fluxo de EDI nem perceberam.
Ninguém roda nada de novo, porque nada falhou; um consumidor ficou para trás.

## Eventos e comandos

Uma mensagem numa fila pode ser de qualquer um dos dois tipos, e a diferença está no que ela pede:

| | um evento | um comando |
|---|---|---|
| exemplo | *a nota 4711 foi autorizada* | *crie o cliente 30117 no Salesforce* |
| tempo verbal | passado: já aconteceu | imperativo: faça isto |
| destinatários | qualquer número, desconhecidos de quem envia | um, escolhido por quem envia |
| quem decide o que acontece depois | cada destinatário | quem envia |
| o que quem envia espera de volta | nada | que seja feito, e muitas vezes saber que foi |

**Um comando ainda acopla quem envia ao trabalho de quem recebe**: quem envia decidiu que o Salesforce
precisa criar um cliente, e se o modelo de cliente do Salesforce mudar, a mensagem de quem envia tem
que mudar junto. Um comando mandado por uma fila tira o acoplamento no tempo e mantém o acoplamento no
conhecimento. Um evento tira os dois, e é por isso também que serve para menos casos: quando quem
envia precisa que uma coisa específica seja feita, por um sistema específico, o comando é a mensagem
honesta.

Vale distinguir duas formas de evento, e o artigo de Martin Fowler de 2017, *What do you mean by
"Event-Driven"?*, dá nome a elas. Uma **notificação de evento** traz pouco mais que o fato e um
identificador: *a nota 4711 foi autorizada*. Um consumidor que precisa do valor ou do cliente chama
então o SAP para perguntar, e o acoplamento no tempo volta por essa chamada. A **transferência de
estado carregada pelo evento** põe dentro dele o que os consumidores precisam: o número da nota, o
cliente, o valor, a chave de acesso da NF-e, os itens. Ninguém chama de volta, e o conteúdo do evento
vira um contrato que o lado do SAP precisa manter, porque consumidores que ele nunca conheceu leem cada
campo. O evento de nota da Serra Alta carrega o estado; o contrato dele é do tipo que a aula 12 põe no
papel.

## Consistência eventual, em termos de negócio

Quando o portal fica sabendo de uma nota por evento, existe um momento em que o SAP sabe que a nota
existe e o portal não. Normalmente é um segundo ou dois. Engenheiros chamam isso de **consistência
eventual**: todos os sistemas vão concordar, mas não no mesmo instante. A expressão assusta quem
toca um negócio, e o jeito de torná-la comum é dizê-la nos termos dessas pessoas:

- Uma padaria vê a nota no portal alguns segundos depois de ela ser autorizada, em vez de no mesmo
  instante. Ninguém percebe a diferença.
- Se o consumidor do portal ficar parado 40 minutos para um deploy, as padarias não veem notas novas
  por 40 minutos, e depois veem todas de uma vez. Nada se perde. Uma padaria que liga nesse intervalo
  ouve do atendimento que a nota está sendo emitida.
- O portal mostra um pedido como *confirmado* até o evento da nota chegar, e depois como *faturado*.
  Por alguns segundos duas telas da empresa discordam, e a mais nova está certa.

O que precisa ser decidido não é se o intervalo existe, mas **o que cada tela diz durante ele**, e
quanto tempo de intervalo é demais. O Marcos, o diretor financeiro, não se incomodou com segundos.
Perguntou o que aconteceria se o intervalo fosse de três dias, e essa é a pergunta certa: a falha de
uma integração por evento não parece um erro, parece um atraso. **O alarme de uma integração por evento
fica na idade da mensagem mais antiga que ninguém consumiu**, e não nos erros, porque um consumidor
parado não produz erro nenhum.

## O que esta aula deixa para a próxima

Tudo o que veio acima trata o broker como uma caixa que guarda mensagens até os consumidores as
pegarem. Como ele faz isso é a aula 10: o que são uma fila e um tópico, o que a entrega *at least
once* significa para um consumidor que recebe a mesma nota duas vezes, como publicar um evento e
atualizar o próprio banco do SAP sem perder um dos dois, o que fazer com uma mensagem que nunca
consegue ser processada, e se as notas chegam na ordem em que foram emitidas. Cada um desses é um
jeito de o parágrafo acima, sobre nada se perder, acabar sendo falso, e é por isso que ganham uma aula
só para eles.

O estilo é fácil de enunciar e mais difícil de adotar do que parece, porque ele muda uma decisão de
lugar. Com chamadas, o lado do SAP decidia quem ficava sabendo das notas. Com eventos, cada
consumidor decide por si, e **alguém precisa ser dono do tópico**: o que um evento de nota contém,
quem pode publicá-lo, e o que acontece quando o contrato dele muda. Na Serra Alta esse dono agora é o
time do Edson, porque o fato acontece no SAP.
