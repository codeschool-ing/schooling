---
title: Arquitetura de solução: um resultado atravessando vários sistemas
version: 1
---

Quase nada do que o negócio pede cabe dentro de um único serviço. **Arquitetura de solução é o
desenho de um resultado de negócio que atravessa vários sistemas, vários times e, muitas vezes, uma
parte de fora da empresa.** O assunto dela são as setas, e não as caixas: quem avisa quem, de quê,
em que ordem, em quanto tempo, e o que acontece quando um deles está fora do ar.

É também onde uma empresa sem arquiteto sente a falta primeiro. Cada time desenha bem o próprio
serviço, e ninguém desenha o caminho entre eles, porque ninguém é dono dele. Na Carreto, esse vão
foi o motivo de Tomás Viana ter criado o cargo da Renata.

## O pedido: pagar o motorista em até 24 horas

A Carreto paga os motoristas uma vez por semana, na sexta, por todas as entregas concluídas na
semana anterior. Um motorista que entrega numa segunda espera até onze dias pelo dinheiro, e quem
tem um caminhão só e paga o diesel adiantado sente isso. Helena Prado, a diretora de produto, levou
números para a reunião de planejamento: no último trimestre, um terço dos motoristas que pararam de
usar a Carreto disseram na pesquisa de saída que um concorrente pagava mais rápido.

O pedido dela cabia numa frase: **pagar o motorista em até 24 horas depois da entrega.** Sílvio
Matos, o diretor financeiro, acrescentou duas condições na mesma reunião. O embarcador precisa ter a
chance de contestar uma entrega antes de o dinheiro sair, porque pagar por uma carga que não chegou
é um prejuízo que a Carreto não recupera do motorista; e nenhuma entrega pode ser paga duas vezes.

Nenhum time sozinho entrega essa frase. Quatro sistemas e uma parte de fora estão envolvidos:

| parte | o que faz por este resultado | quem é dono |
|---|---|---|
| Driver app | captura a prova: foto, assinatura de quem recebe, posição GPS | o time do Diego Araújo |
| Tracking | decide que uma entrega está provada, e guarda a prova | o time de Tracking |
| Shipper app | mostra a prova ao embarcador, que pode contestá-la | o time Shipper |
| Payments | espera a janela de contestação, paga o motorista, fatura o embarcador | o time do Bruno Farias |
| banco parceiro | executa a transferência Pix para a conta do motorista | fora da Carreto |

Cada time conseguiria construir a própria parte em uma ou duas sprints. **O que ninguém conseguia
construir sozinho era a promessa**, porque as 24 horas são gastas em todos eles.

## O orçamento, e por que ele é a arquitetura

O primeiro passo da Renata foi transformar a frase num orçamento de tempo, contado a partir do
momento em que o caminhão é descarregado:

- **até 4 horas** para a prova chegar ao Tracking, porque os motoristas descarregam com frequência
  em zona rural sem sinal, e o app envia quando encontra um;
- **12 horas** em que o embarcador pode contestar, a condição do Sílvio, a partir do momento em que
  a prova é mostrada;
- **até 1 hora** para o Payments fazer as checagens dele e para o banco parceiro concluir o Pix.

São 4 + 12 + 1 = 17 horas no pior caso normal, o que deixa **7 horas de folga** para tudo o que não
é normal: uma nova tentativa, uma queda do banco parceiro, uma entrega que precisa que uma pessoa
olhe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro caixas em fila: Driver app, Tracking, Payments e banco parceiro, ligadas por setas com os rótulos prova enviada, entrega provada e pagamento Pix. Abaixo de Tracking e Payments, uma caixa Shipper app: o embarcador vê a prova e pode contestá-la. Embaixo, uma barra de 24 horas contada a partir da entrega: até 4 horas para a prova, 12 horas em que o embarcador pode contestar, 1 hora para o pagamento e 7 horas de folga.\"><defs><marker id=\"pay24-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"20\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Driver app</text><text x=\"76\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time Driver</text><rect x=\"202\" y=\"20\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Tracking</text><text x=\"262\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time Tracking</text><rect x=\"388\" y=\"20\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Payments</text><text x=\"448\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time Payments</text><rect x=\"574\" y=\"20\" width=\"130\" height=\"56\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"639\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Banco parceiro</text><text x=\"639\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">fora da Carreto</text><path d=\"M138 48 L198 48\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><path d=\"M324 48 L384 48\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#pay24-ah)\"></path><path d=\"M510 48 L570 48\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><text x=\"169\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">prova</text><text x=\"169\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">enviada</text><text x=\"355\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">entrega</text><text x=\"355\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">provada</text><text x=\"541\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pix</text><text x=\"541\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pagamento</text><path d=\"M262 78 L262 130\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><path d=\"M448 130 L448 80\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><rect x=\"202\" y=\"134\" width=\"306\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"153\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Shipper app</text><text x=\"355\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o embarcador vê a prova e pode contestá-la</text><text x=\"40\" y=\"214\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o orçamento de 24 horas, contado a partir da entrega</text><rect x=\"40\" y=\"224\" width=\"107\" height=\"30\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"147\" y=\"224\" width=\"320\" height=\"30\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"467\" y=\"224\" width=\"27\" height=\"30\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"494\" y=\"224\" width=\"186\" height=\"30\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"93\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">prova: 4 h</text><text x=\"307\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">contestação: 12 h</text><text x=\"587\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">folga: 7 h</text><path d=\"M480 256 L480 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"480\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">pagamento: 1 h</text><text x=\"40\" y=\"284\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">0 h</text><text x=\"680\" y=\"284\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">24 h</text></svg>", "caption": "Uma promessa, quatro sistemas e um parceiro. As caixas já existiam; a solução são as setas, e o orçamento de tempo que nenhum dos times tem sozinho.", "same": ["Driver app", "Tracking", "Payments", "Pix", "Shipper app", "0 h", "24 h"]}
```

**O orçamento é a arquitetura desta solução.** Todas as perguntas de design que vieram depois foram
respondidas contra ele. O Payments pode saber das entregas provadas por um lote que roda a cada seis
horas? Não, se a folga é de sete horas e uma única execução perdida consome seis delas. A janela de
contestação pode começar quando o caminhão é descarregado, e não quando a prova é mostrada? O Sílvio
disse que não: um embarcador não consegue contestar uma prova que não viu.

## As perguntas que moram entre as caixas

Com o orçamento escrito, a Renata fez uma sessão de trabalho com os quatro tech leads e uma pessoa
do financeiro. Ela não levou um desenho. Levou as perguntas que nenhum time faria sozinho, porque
cada uma fica numa fronteira:

- **Quem decide que uma entrega está provada?** O Tracking já tinha a foto, a assinatura e a posição
  GPS, então o Tracking é dono da regra, e ninguém mais a reimplementa. O Payments confia na palavra
  do Tracking.
- **Como o Payments fica sabendo?** Consultando de tempos em tempos, por uma chamada direta, ou por
  um evento no message broker que a Carreto já roda. A aula 5 mostra essa decisão escrita por
  inteiro, com as opções que ela rejeitou.
- **O que acontece quando o banco parceiro está fora?** O pagamento espera e é tentado de novo, a
  folga absorve, e o financeiro recebe um alerta se um pagamento continua pendente na hora 20.
- **Como se evita um pagamento duplicado?** Todo pagamento leva o id da entrega como chave de
  idempotência, então uma nova tentativa ou uma mensagem repetida não paga duas vezes. O curso
  `architecture` cobriu a técnica na aula 7; aqui a pergunta é só quem a garante, e a resposta é o
  Payments.
- **O que o embarcador vê se contestar?** O time Shipper é dono da tela, e o Payments é dono da
  retenção do dinheiro. O contrato entre os dois é um campo e uma mudança de estado.

Cada resposta é pequena. **O valor está em fazer as cinco perguntas antes de alguém escrever
código**, porque a mesma pergunta descoberta nos testes custa uma sprint, e descoberta em produção
custa o pagamento de um motorista.

## Horizonte, público e artefatos

**O horizonte é um programa**: meses de construção, e depois anos da solução rodando e sendo
alterada. O pagamento em 24 horas foi da frase da Helena ao primeiro motorista pago em onze semanas,
e o contrato entre Tracking e Payments vai sobreviver a cada linha escrita nessas semanas.

**O público é amplo e misturado**: vários times, a diretora de produto, o financeiro e, neste caso,
um banco de fora cujos termos de API definem um dos números. Por isso os artefatos precisam
funcionar para gente que não lê código:

- uma **visão de contexto e uma visão de contêineres** (os dois primeiros níveis do C4) mostrando
  quais sistemas participam e como conversam, que a aula 8 ajuda a escolher e `architecture-modeling`
  aula 3 desenha;
- o **orçamento de tempo**, escrito como um número por etapa, com o dono de cada etapa nomeado;
- os **contratos** entre sistemas: os campos do evento, os erros da API, quem tenta de novo o quê;
- os **registros de decisão** de cada escolha que atravessa times, dos quais a aula 5 mostra um
  inteiro;
- um **documento de desenho da solução** curto amarrando tudo, escrito tanto para a Helena e o Sílvio
  quanto para os engenheiros.

**E a solução precisa de um dono.** A Renata não construiu nada disso. Ela foi dona do orçamento, dos
contratos e das perguntas em aberto até cada uma ter resposta, e era a pessoa a quem a Helena
perguntava "estamos no prazo?", porque ninguém mais enxergava os quatro times ao mesmo tempo.

## Como este nível aparece na semana da Renata

No primeiro trimestre, é aqui que vai a maior parte do tempo da Renata: o pagamento em 24 horas, um
novo leiaute do CT-e que as autoridades fiscais vão exigir, e o pedido de uma rede de supermercados
para publicar cargas a partir do próprio sistema dela. **Cada um desses atravessa times, e cada um
teria sido resolvido quatro vezes, de jeitos ligeiramente diferentes, por quatro times.**

É também o nível em que um arquiteto numa empresa do tamanho da Carreto mais claramente vale o
salário. A arquitetura de aplicação já tem donos nos times. A arquitetura corporativa, assunto da
próxima seção, importa, mas uma empresa de cinquenta engenheiros precisa de pouca. A arquitetura de
solução é o trabalho que ninguém estava fazendo.
