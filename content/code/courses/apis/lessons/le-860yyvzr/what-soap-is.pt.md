---
title: O que é SOAP, e por que ele ainda está em toda parte
version: 1
---

**SOAP é um jeito de programas trocarem mensagens XML, cada uma embrulhada num envelope e quase
sempre levada por um `POST` HTTP.** Um serviço SOAP publica um contrato que descreve cada operação
numa forma que um programa consegue ler. Foi o jeito padrão de os sistemas de duas empresas
conversarem no começo dos anos 2000, e muitos desses sistemas continuam rodando.

A imagem comum é que o SOAP morreu e o REST tomou o lugar dele. Ele deixou de ser **escolhido** para
APIs públicas novas, o que é outra coisa. Um sistema que funciona há vinte anos não é reescrito
porque o formato saiu de moda; ele é integrado, e a integração é trabalho de alguém este ano. Alguns
casos que um desenvolvedor back-end no Brasil encontra:

| onde | o que fala SOAP |
|---|---|
| impostos | os web services das secretarias da fazenda estaduais que recebem a NF-e, a nota fiscal eletrônica |
| bancos | interfaces de pagamentos, extratos e compensação construídas antes de o JSON ser comum |
| ERPs | o SAP e outros sistemas corporativos publicam web services SOAP para os documentos deles |
| logística | transportadoras, distribuidores e armazéns cujos sistemas de estoque e pedidos têm décadas |
| SaaS | a Salesforce ainda oferece uma API SOAP ao lado da REST |

O distribuidor desta aula é do último tipo. A livraria compra os livros de um distribuidor cujo
sistema fala SOAP, e a loja precisa perguntar a ele o que tem em estoque e fazer pedidos.

## O envelope

Toda mensagem SOAP tem as mesmas três partes, uma dentro da outra:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 306\" role=\"img\" aria-label=\"Duas mensagens SOAP desenhadas como caixas aninhadas. À esquerda, a requisição: um soap:Envelope com um soap:Header opcional e um soap:Body, e dentro do Body um elemento, d:GetStock, com d:ISBN. À direita, a resposta a um ISBN desconhecido: um soap:Envelope cujo soap:Body tem um soap:Fault com faultcode, faultstring e um detail com o código de erro E100. A falha viaja com HTTP 500.\"><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a requisição</text><rect x=\"20\" y=\"36\" width=\"310\" height=\"250\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">soap:Envelope</text><text x=\"525\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a resposta, uma falha</text><rect x=\"370\" y=\"36\" width=\"310\" height=\"250\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"382\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">soap:Envelope</text><rect x=\"36\" y=\"66\" width=\"278\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"48\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">soap:Header</text><text x=\"48\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">opcional: segurança, roteamento, ids</text><rect x=\"36\" y=\"128\" width=\"278\" height=\"144\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">soap:Body</text><rect x=\"52\" y=\"160\" width=\"246\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">d:GetStock</text><text x=\"64\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a operação, no namespace</text><text x=\"64\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do distribuidor</text><rect x=\"64\" y=\"220\" width=\"222\" height=\"26\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"76\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">d:ISBN 9786500000030</text><rect x=\"386\" y=\"66\" width=\"278\" height=\"206\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"398\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">soap:Body</text><rect x=\"402\" y=\"98\" width=\"246\" height=\"158\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"414\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">soap:Fault</text><rect x=\"414\" y=\"128\" width=\"222\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faultcode</text><text x=\"626\" y=\"139\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">de quem é a culpa</text><text x=\"424\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">soap:Client</text><rect x=\"414\" y=\"168\" width=\"222\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faultstring</text><text x=\"626\" y=\"179\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">para uma pessoa</text><text x=\"424\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ISBN … not in the catalogue</text><rect x=\"414\" y=\"208\" width=\"222\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">detail</text><text x=\"626\" y=\"219\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">para um programa</text><text x=\"424\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ErrorCode E100</text><text x=\"525\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">enviada com HTTP 500</text></svg>", "caption": "Uma mensagem SOAP é um envelope com um cabeçalho opcional e um corpo. Uma falha toma o lugar da resposta dentro do corpo, e viaja com HTTP 500."}
```

- `Envelope` é o elemento raiz, e o namespace dele diz qual versão do SOAP é esta.
- `Header` é opcional. Leva o que é **sobre** a mensagem, e não o negócio dentro dela: um token de
  segurança, um id de transação, o roteamento para um intermediário que a repassa. A seção sobre
  WS-Security mostra um preenchido.
- `Body` leva o negócio: um elemento que nomeia a operação e traz os argumentos dela, ou, na volta,
  o resultado ou um **`Fault`**.

Compare com a aula 1. No REST o endereço nomeia a coisa e o método diz o que fazer com ela:
`GET /v1/books/3`. No SOAP há **um endereço para o serviço inteiro e um método, `POST`, para toda
operação**, inclusive as que só leem. A operação é nomeada dentro do corpo. O HTTP é só o veículo,
e o SOAP foi desenhado para viajar em outros veículos também, e é por isso que repete dentro do
envelope coisas que o HTTP poderia ter dito.

## Duas versões

| | SOAP 1.1 | SOAP 1.2 |
|---|---|---|
| namespace do envelope | `http://schemas.xmlsoap.org/soap/envelope/` | `http://www.w3.org/2003/05/soap-envelope` |
| content type | `text/xml` | `application/soap+xml` |
| a operação, no HTTP | um cabeçalho `SOAPAction` | um parâmetro `action` do content type |
| uma falha diz | `faultcode`, `faultstring`, `detail` | `Code`, `Reason`, `Detail` |

O distribuidor fala **SOAP 1.1**, a versão que você mais encontra em sistemas antigos. Um cliente
precisa usar a versão que o serviço fala, e o namespace do envelope é como um serviço distingue uma
da outra.
