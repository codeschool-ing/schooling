---
title: Comandos, eventos e consultas
version: 1
---

Uma mensagem entre serviços é de um entre três tipos, e confundi-los é onde muitos projetos dão errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três tipos de mensagem em três linhas. Um comando, PlaceOrder, vai do checkout para o serviço de pedidos, um destinatário nomeado, e pede que ele faça algo. Um evento, OrderPlaced, vai de pedidos para quem estiver escutando e afirma que algo aconteceu. Uma consulta, GetStock, vai para o estoque e espera uma resposta de volta.\"><defs><marker id=\"l5-kinds-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">comando</text><rect x=\"130\" y=\"44\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">PlaceOrder</text><path d=\"M282 60 L348 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-kinds-ah-wire)\"></path><rect x=\"350\" y=\"44\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um destinatário, a quem se pede ação</text><text x=\"30\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">evento</text><rect x=\"130\" y=\"114\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">OrderPlaced</text><path d=\"M282 130 L348 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-kinds-ah-wire)\"></path><rect x=\"350\" y=\"114\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem escutar, informado do fato</text><text x=\"30\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">consulta</text><rect x=\"130\" y=\"184\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"205\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">GetStock</text><path d=\"M282 200 L348 200\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l5-kinds-ah-wire)\"></path><rect x=\"350\" y=\"184\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um destinatário, resposta esperada</text></svg>", "caption": "Um comando nomeia um destinatário e pede; um evento não nomeia nenhum e conta; uma consulta pergunta e espera a resposta."}
```

| tipo | gramática | quem ela nomeia | o que quem manda espera |
| --- | --- | --- | --- |
| **comando** | imperativo: `PlaceOrder`, `ChargeCard` | um destinatário, que pode recusar | que o destinatário aja, ou diga por que não |
| **evento** | passado: `OrderPlaced`, `PaymentDeclined` | ninguém; quem tiver interesse escuta | nada; é a afirmação de um fato |
| **consulta** | uma pergunta: `GetStock`, `GetPrice` | um destinatário | uma resposta, e nenhuma mudança em nada |

A gramática não é enfeite. **Um evento afirma algo que já aconteceu e não pode ser recusado**: quando
`OrderPlaced` é publicado o pedido existe, e um ouvinte que não gostar pode reagir, por exemplo mandando
um comando próprio, mas não pode fazer com que não tenha acontecido. Um comando pode ser recusado, e
quem manda precisa estar pronto para isso.

## Quem depende de quem

A diferença mais funda é o sentido da dependência. Com um comando, **quem manda conhece o
destinatário**: o checkout sabe que existe um serviço de pagamentos e o que pedir a ele. Com um evento,
**o destinatário conhece quem manda**: o serviço de e-mail sabe que pedidos publica `OrderPlaced`, e o
serviço de pedidos não sabe que o de e-mail existe. Acrescentar um serviço de pontos de fidelidade que
também escuta `OrderPlaced` não muda nada em pedidos.

É por isso que eventos são o jeito habitual de manter serviços independentes: um serviço publica o que
aconteceu no seu domínio e deixa os outros decidirem o que isso significa para os deles. É também como
um projeto sai do controle, porque ninguém consegue ver o fluxo inteiro lendo um serviço. A aula 14
chama a versão movida a eventos de **coreografia** e a movida a comandos de **orquestração**, e constrói
uma saga de cada jeito.

## Em que estilo viaja cada tipo

| tipo | estilo habitual |
| --- | --- |
| consulta | síncrono: quem chama precisa da resposta para seguir |
| comando | qualquer um: chamada síncrona quando quem chama precisa do resultado agora, mensagem numa fila quando pode esperar |
| evento | assíncrono: publicado uma vez, consumido por qualquer número de ouvintes, quando estiverem prontos |

**Não faça consultas por fila para fugir de uma dependência**: uma pergunta mandada como mensagem e uma
resposta esperada em outra fila é uma chamada síncrona com mais peças, e continua falhando quando o
outro lado está fora do ar. Só esconde que falha.
