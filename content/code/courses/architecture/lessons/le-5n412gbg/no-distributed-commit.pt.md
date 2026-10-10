---
title: Onde não há commit distribuído
version: 1
---

Dentro de um banco, um checkout é fácil de tornar seguro: reservar o estoque, registrar o pagamento,
agendar a entrega, tudo numa transação, e se qualquer parte falhar o banco desfaz o resto. Nada de fora
jamais vê um checkout pela metade.

Divida esses três em serviços, cada um dono do seu banco como a aula 2 argumentou que deveriam ser, e a
transação some. **Nenhum banco consegue desfazer uma mudança em outro banco.** Se a entrega não puder
ser agendada depois de o cartão ser cobrado, nada desfaz a cobrança sozinho.

Existe um protocolo para transações entre bancos, o **commit em duas fases** (*two-phase commit*): um
coordenador pede a todo participante que se prepare, e só confirma se todos disseram sim. Ele existe (XA
em Java, `PREPARE TRANSACTION` no PostgreSQL) e raramente é usado entre serviços, por motivos que o curso
já encontrou. Todo participante segura as travas até o coordenador decidir, então um participante lento
deixa todos lentos, como na aula 12. Se o coordenador some depois do "prepare", os participantes esperam
com as travas seguras, o que a aula 8 chamaria de escolher consistência em vez de disponibilidade, para
todos os serviços ao mesmo tempo. E a maior parte do que um checkout conversa, um gateway de pagamento, a
API de uma transportadora, um broker, nem fala esse protocolo.

## A saga

Hector Garcia-Molina e Kenneth Salem descreveram a alternativa em 1987, para transações longas dentro de
um banco, e o nome pegou. **Uma saga é uma sequência de transações locais, cada uma com uma transação de
compensação que a desfaz semanticamente.** Os passos rodam em ordem, cada um confirmando sozinho. Se um
falha, as compensações dos passos já feitos rodam em ordem inversa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Uma saga de três passos em fila: reservar estoque, cobrar o cartão, agendar a entrega. Sob os dois primeiros, as compensações: liberar estoque e reembolsar o cartão. O terceiro passo falha, e setas voltam dele para o reembolso e depois para a liberação, em ordem inversa.\"><defs><marker id=\"l14-saga-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-saga-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"220\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">reservar estoque</text><path d=\"M222 65 L268 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-phosphor)\"></path><rect x=\"270\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cobrar cartão</text><path d=\"M452 65 L498 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-phosphor)\"></path><rect x=\"500\" y=\"40\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">agendar entrega</text><text x=\"590\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">falha</text><rect x=\"40\" y=\"150\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">liberar estoque</text><rect x=\"270\" y=\"150\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">reembolsar cartão</text><path d=\"M590 116 L590 175 L452 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-amber)\"></path><path d=\"M268 175 L222 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-saga-ah-amber)\"></path></svg>", "caption": "Cada passo confirma sozinho. Quando um passo posterior falha, os anteriores não são desfeitos por rollback; são compensados, em ordem inversa."}
```

Para o checkout da Quitanda:

| passo | serviço | compensação |
| --- | --- | --- |
| reservar o café | estoque | liberar a reserva |
| cobrar o cartão | pagamentos | reembolsar a cobrança |
| agendar a entrega | entregas | nenhuma: é o último passo |
| confirmar a reserva como vendida | estoque | nenhuma: o pedido está completo |

O resto da aula é sobre o que essa tabela deixa de fora. Quem roda os passos. O que "desfazer" pode e não
pode significar. E o que outros clientes veem enquanto uma saga está na metade, o que uma transação
esconde e uma saga não.
