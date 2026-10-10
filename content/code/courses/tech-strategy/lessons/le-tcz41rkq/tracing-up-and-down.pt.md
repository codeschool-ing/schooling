---
title: Rastreando o trabalho para cima e para baixo
version: 1
---

Quatro documentos que respondem cada um à sua pergunta ainda precisam concordar entre si. **Cada
item do backlog deveria se ligar a um item do roadmap, o item do roadmap a uma ação da estratégia, e
a estratégia à visão.** No sentido contrário, cada ação da estratégia deveria descer até um trabalho
que alguém está fazendo nesta sprint. As verificações são baratas e acham as duas falhas que a
seção anterior descreveu: trabalho sem razão acima dele, e estratégia sem trabalho abaixo dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"Quatro linhas, de cima para baixo: visão, estratégia, roadmap, backlog. Uma caixa de visão ocupa a largura toda. Na primeira coluna, um item de backlog, reproduzir o tráfego de uma abertura passada, aponta para cima até a linha do roadmap T1 teste de carga da abertura pronto, que aponta para a ação 2 da estratégia, construir o teste de carga antes, que aponta para a visão. Na segunda coluna, um item de backlog aponta para a linha do roadmap T2 gateway GraphQL para o app mobile, e acima dela uma caixa tracejada âmbar diz não leva a nada. Na terceira coluna, a ação 4 da estratégia, nenhum deploy antes de uma abertura, aponta para baixo até a linha do roadmap T3 congelamento de deploy automatizado, e abaixo dela uma caixa tracejada âmbar diz nenhum item no backlog de time algum.\"><defs><marker id=\"trace-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"trace-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"18\" y=\"63\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Visão</text><text x=\"18\" y=\"153\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Estratégia</text><text x=\"18\" y=\"243\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Roadmap</text><text x=\"18\" y=\"333\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper-dim)\">Backlog</text><rect x=\"110\" y=\"30\" width=\"600\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"410.0\" y=\"62.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quem compra às 10h tem o mesmo checkout de quem compra às 3h</text><rect x=\"110\" y=\"120\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"143.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">ação 2: construir o</text><text x=\"205.0\" y=\"160.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">teste de carga antes</text><rect x=\"110\" y=\"210\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"233.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">T1: teste de carga</text><text x=\"205.0\" y=\"250.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">da abertura pronto</text><rect x=\"110\" y=\"300\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"205.0\" y=\"323.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">reproduzir o tráfego</text><text x=\"205.0\" y=\"340.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">de uma abertura passada</text><path d=\"M205.0 298 L205.0 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M205.0 208 L205.0 180\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M205.0 118 L205.0 90\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><rect x=\"320\" y=\"120\" width=\"190\" height=\"56\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"415.0\" y=\"152.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">não leva a nada</text><rect x=\"320\" y=\"210\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"233.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">T2: gateway GraphQL</text><text x=\"415.0\" y=\"250.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">para o app mobile</text><rect x=\"320\" y=\"300\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"415.0\" y=\"323.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">schema do gateway</text><text x=\"415.0\" y=\"340.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">para eventos</text><path d=\"M415.0 298 L415.0 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M415.0 208 L415.0 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#trace-am)\"></path><rect x=\"530\" y=\"120\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"143.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">ação 4: nenhum deploy</text><text x=\"620.0\" y=\"160.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">antes de uma abertura</text><rect x=\"530\" y=\"210\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"620.0\" y=\"233.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">T3: congelamento de</text><text x=\"620.0\" y=\"250.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">deploy automatizado</text><rect x=\"530\" y=\"300\" width=\"180\" height=\"56\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"620.0\" y=\"323.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">nenhum item no</text><text x=\"620.0\" y=\"340.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">backlog de time algum</text><path d=\"M620.0 178 L620.0 206\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#trace-ah)\"></path><path d=\"M620.0 268 L620.0 296\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#trace-am)\"></path><text x=\"205.0\" y=\"384\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">ligado até a visão</text><text x=\"415.0\" y=\"384\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">um órfão: trabalho sem razão</text><text x=\"620.0\" y=\"384\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">decoração: razão sem trabalho</text></svg>", "caption": "O rastreamento nos dois sentidos. A maior parte do trabalho se liga do backlog até a visão; um órfão tem trabalho e nenhuma razão acima dele, e uma ação decorativa tem razão e nenhum trabalho abaixo dela.", "same": ["Roadmap", "Backlog"]}
```

## Rastreando para cima: trabalho sem razão

Comece pelo backlog e pergunte de cada item "para qual linha do roadmap é isto?", e depois de cada
linha do roadmap "para qual parte da estratégia é isto?". A maioria dos itens responde na hora. Os
que não respondem são os interessantes.

No começo do segundo trimestre, Davi pegou as linhas do roadmap de todos os times e anotou ao lado
de cada uma aonde ela levava:

| linha do roadmap, T2 | time | liga-se a |
|---|---|---|
| tirar as travas de linha do caminho da reserva de assentos | Reservas | estratégia, ação 3 |
| reproduzir no teste de carga o tráfego de uma abertura passada | Plataforma | estratégia, ação 2 |
| mapas de assentos para festivais | Catálogo | o roadmap de produto |
| atualizar Rails e Ruby para versões com suporte | Plataforma | manter as luzes acesas |
| a nova API de tokenização de cartão do provedor de pagamentos | Pagamentos | manter as luzes acesas |
| gateway GraphQL para o app mobile | Mobile | nada |
| levar a busca do Catálogo para um serviço próprio | Catálogo | nada |

A coluna tem quatro tipos de resposta, e **só o último é um problema**.

Uma linha pode se ligar à estratégia técnica. Pode se ligar ao roadmap de produto, porque a maior
parte do que a engenharia constrói é trabalho de produto, e esse trabalho responde à estratégia do
próprio produto, não a esta. Pode ser manter as luzes acesas: um framework que saiu do período de
suporte, um provedor aposentando uma API numa data que outra pessoa escolheu. Esse trabalho é real,
não é opcional, e **deve ser rotulado pelo que é**, em vez de ganhar uma ligação inventada com a
estratégia. Um roadmap em que toda linha diz servir à estratégia é um roadmap em que essas
afirmações pararam de significar alguma coisa.

As duas linhas que não levam a nada são o achado. O gateway GraphQL era uma ideia do time de Mobile
do ano anterior, que ficou porque ninguém a tirou. Levar a busca para um serviço próprio era o
projeto do T4 do roadmap antigo, que simplesmente escorregou para a frente. **Nenhuma das duas era
uma ideia errada.** Cada uma era a migração para microsserviços chegando um serviço de cada vez,
coisa que a política tinha excluído para o ano.

Um órfão tem três desfechos possíveis, e escolher um é o objetivo do exercício:

- o trabalho para, e as pessoas vão para algo que se liga à estratégia;
- o trabalho acaba servindo a algo que a estratégia deveria ter dito, e a estratégia é emendada às
  claras, para que todos vejam a mudança;
- o trabalho é reclassificado com honestidade, como trabalho de produto ou como manter as luzes
  acesas, se é isso que ele é de fato.

O que não pode acontecer é o órfão seguir sem ser examinado. Duas linhas em sete são uma boa parte
da engenharia de um trimestre indo para um trabalho que a empresa decidiu, por escrito, não fazer.

## Rastreando para baixo: uma estratégia que não chega a nada

O outro sentido é menos óbvio e acha uma falha mais silenciosa. Pegue cada ação da estratégia e siga
para baixo: que linha do roadmap a carrega, e que time a tem no backlog agora?

Davi fez isso com as quatro ações da Coreto. As três primeiras chegaram ao fundo: o time de Reservas
existia, o teste de carga estava na sprint da Plataforma, e as travas de linha estavam no backlog de
Reservas. **A quarta parou no meio do caminho.** "Nenhum deploy no módulo de reservas nas 24 horas
antes de uma grande abertura" estava no roadmap do T3, como uma verificação automática no pipeline
de deploy. Mas a verificação precisava de um calendário das grandes aberturas do ano que o pipeline
pudesse ler, e nenhum time tinha isso no backlog. A Plataforma achava que Reservas forneceria as
datas; Reservas achava que a Plataforma era dona do pipeline e pediria. Enquanto isso, o
congelamento era garantido por uma mensagem num canal de chat, quando alguém lembrava.

Uma ação que nenhum item de backlog alcança é **decoração**: soa como compromisso, e nada está
acontecendo. É também a falha que as pessoas resistem a nomear, porque o documento de estratégia
continua parecendo completo, e apontar o buraco soa como acusação contra quem é dono dele. O
rastreamento torna isso impessoal. Ou existe um item num backlog, ou não existe.

## Como manter o rastreamento sem um processo

Nada disso exige ferramenta. Exige uma coluna.

- No roadmap, uma coluna dizendo a que ação cada linha serve, ou a que outra fonte ela responde: o
  roadmap de produto, ou manter as luzes acesas.
- No rastreador de cada time, um rótulo ou um link de cada item do backlog para sua linha do
  roadmap.
- Uma vez por trimestre, quando o roadmap é redesenhado, uma sessão curta lendo a coluna para cima
  em busca de órfãos e a estratégia para baixo em busca de ações sem nada embaixo.

Uma planilha no formato da tabela acima basta. **O que importa é a coluna existir antes de alguém
perguntar**, porque um rastreamento reconstruído sob pressão numa reunião sempre acha uma ligação,
por mais fina que seja.

## O que o rastreamento não diz

Uma linha que se liga não é, só por isso, uma boa linha. O time de Reservas poderia ligar uma mudança
mal projetada direto à ação 3, e a coluna ficaria perfeita. O rastreamento responde uma pergunta —
este trabalho tem uma razão com a qual a empresa concordou? — e não diz nada sobre se o trabalho é
bem feito, do tamanho certo ou vale o que custa. As aulas 5 e 13 trazem o dinheiro que responde a
isso.

A aula 3 trata do documento de estratégia em si: a página única que um time consegue carregar na
cabeça, e a lista do que a empresa não vai fazer, que é o que tornou os dois órfãos acima
reconhecíveis à primeira vista.
