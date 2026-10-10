---
title: SOAP, um envelope mandado a um endereço só
version: 1
---

**SOAP é um formato de mensagem, escrito em XML, e o HTTP é só o caminhão que as leva.** A imagem
com que a maioria chega é a de que SOAP é um tipo de REST mais velho e mais prolixo. É outra ideia.
O REST, do jeito que as lições 1 e 2 o usaram, espalha uma API por muitos endereços e deixa o método
HTTP dizer o que fazer com cada um. O SOAP põe a requisição inteira dentro de um documento XML, o
**envelope**, e manda todo envelope por POST para o mesmo endereço. O endereço diz *qual serviço*;
o que fazer está escrito dentro da mensagem.

## O envelope

Toda mensagem SOAP, requisição ou resposta, tem o mesmo aninhamento:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 282\" role=\"img\" aria-label=\"Uma mensagem SOAP aninhada dentro de uma requisição HTTP. A requisição HTTP é POST /invoice com content-type text/xml e um cabeçalho SOAPAction. Dentro dela está o soap:Envelope, cujo namespace diz a versão do SOAP. O envelope guarda um soap:Header opcional, para uma assinatura, um token de segurança ou um id de rastreio, e um soap:Body obrigatório. O corpo guarda uma de duas coisas: inv:IssueInvoice com orderId, amountCents e buyerTaxId, que é a operação e seus argumentos, ou soap:Fault com faultcode e faultstring, que é o erro e de quem é a culpa.\"><rect x=\"10\" y=\"10\" width=\"680\" height=\"262\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"22\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a requisição HTTP</text><text x=\"150\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /invoice   content-type: text/xml   SOAPAction: \"…#IssueInvoice\"</text><rect x=\"30\" y=\"44\" width=\"640\" height=\"214\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">soap:Envelope</text><text x=\"160\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o namespace diz qual versão do SOAP</text><rect x=\"50\" y=\"74\" width=\"600\" height=\"36\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"62\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">soap:Header</text><text x=\"170\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">opcional: uma assinatura, um token de segurança, um id de rastreio</text><rect x=\"50\" y=\"120\" width=\"600\" height=\"126\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"62\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">soap:Body</text><text x=\"170\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">obrigatório, e guarda um dos dois</text><rect x=\"70\" y=\"152\" width=\"260\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">inv:IssueInvoice</text><text x=\"200\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orderId  amountCents  buyerTaxId</text><text x=\"200\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">a operação e seus argumentos</text><rect x=\"400\" y=\"152\" width=\"230\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"515\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">soap:Fault</text><text x=\"515\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">faultcode  faultstring</text><text x=\"515\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">o erro, e de quem é a culpa</text><text x=\"365\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">ou</text></svg>", "caption": "Uma mensagem SOAP é um envelope dentro de um POST HTTP comum: um cabeçalho opcional e um corpo que guarda a operação ou uma falha."}
```

- **`Envelope`** é o elemento mais externo. O namespace dele diz que versão do SOAP a mensagem
  fala: `http://schemas.xmlsoap.org/soap/envelope/` é SOAP 1.1, e
  `http://www.w3.org/2003/05/soap-envelope` é SOAP 1.2.
- **`Header`** é opcional. Leva o que diz respeito à mensagem e não ao negócio: uma assinatura, um
  token de segurança, um id para rastreio. O serviço de notas desta lição não manda nenhum.
- **`Body`** é obrigatório. Numa requisição ele guarda um elemento com o nome da operação,
  `IssueInvoice`, com os argumentos dentro. Numa resposta ele guarda a resposta, ou um **`Fault`**.

Um fault, uma falha, é o erro do SOAP. No SOAP 1.1 ele tem um `faultcode` e uma `faultstring`, e o
código diz de quem é a culpa: **`soap:Client`** quando a requisição estava errada, **`soap:Server`**
quando o serviço falhou. É a mesma linha que a lição 1 traçou entre `4xx` e `5xx`, mudada da linha de
status para o corpo.

## Um endereço, e a operação lá dentro

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 236\" role=\"img\" aria-label=\"Duas metades. À esquerda, REST: GET vai para /v1/shows, POST para /v1/orders e DELETE para /v1/orders/ord-1001, cada requisição para um endereço próprio, então o método e o caminho dizem o que fazer. À direita, SOAP: três operações, IssueInvoice, CancelInvoice e QueryInvoice, vão todas para o mesmo POST /invoice, e o cabeçalho SOAPAction e o Body dizem o que fazer.\"><defs><marker id=\"f09one-address-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">REST: um endereço para cada coisa</text><text x=\"525\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">SOAP: um endereço, a operação dentro</text><line x1=\"350\" y1=\"10\" x2=\"350\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"24\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET</text><line x1=\"90\" y1=\"65\" x2=\"176\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"178\" y=\"48\" width=\"156\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/v1/shows</text><text x=\"24\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST</text><line x1=\"90\" y1=\"125\" x2=\"176\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"178\" y=\"108\" width=\"156\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/v1/orders</text><text x=\"24\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DELETE</text><line x1=\"90\" y1=\"185\" x2=\"176\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"178\" y=\"168\" width=\"156\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/v1/orders/ord-1001</text><rect x=\"366\" y=\"48\" width=\"150\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"441\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">IssueInvoice</text><line x1=\"516\" y1=\"65\" x2=\"574\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"366\" y=\"108\" width=\"150\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"441\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">CancelInvoice</text><line x1=\"516\" y1=\"125\" x2=\"574\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"366\" y=\"168\" width=\"150\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"441\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">QueryInvoice</text><line x1=\"516\" y1=\"185\" x2=\"574\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"576\" y=\"62\" width=\"104\" height=\"84\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"628\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST</text><text x=\"628\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/invoice</text><text x=\"175\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o método e o caminho dizem o que fazer</text><text x=\"525\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o SOAPAction e o Body dizem o que fazer</text></svg>", "caption": "O REST espalha uma API por endereços e métodos. O SOAP manda toda operação para um endereço só, por POST, e nomeia a operação dentro da requisição."}
```

O desenho dá três operações ao lado SOAP para mostrar a ideia; o substituto da seção 04 tem uma. A
diferença muda o que um teste olha:

| | REST, como o boxoffice faz | SOAP, como o serviço de notas faz |
|---|---|---|
| endereços | um para cada coisa: `/v1/shows`, `/v1/orders/ord-1001` | um: `/invoice` |
| método | GET, POST, DELETE, escolhido por ação | POST, para toda operação |
| o que fazer é nomeado por | o método e o caminho | o cabeçalho `SOAPAction` e o primeiro elemento do `Body` |
| corpo | JSON | XML, dentro de um envelope |
| uma falha é avisada por | o código de status, com problem details | HTTP `500` e um `Fault`, com um `faultcode` |
| o contrato | OpenAPI, que a lição 2 escreveu à mão | WSDL, que o próprio serviço geralmente serve |

**O código de status diz muito menos no SOAP 1.1.** A especificação manda responder toda falha com
`500 Internal Server Error`, seja de quem for a culpa. Um teste que para no status não distingue um
erro de digitação na requisição de um serviço que caiu; ele precisa ler o `faultcode`. O SOAP 1.2
mudou isso: uma falha que culpa quem mandou, que ele chama de `env:Sender`, viaja como `400`, e as
outras como `500`.

## As duas versões, como quem testa as distingue

Você vai encontrar as duas, e três coisas dizem qual está na sua frente:

| | SOAP 1.1 | SOAP 1.2 |
|---|---|---|
| `content-type` | `text/xml` | `application/soap+xml` |
| a operação | um cabeçalho `SOAPAction` separado | um parâmetro `action` opcional dentro do `content-type` |
| códigos de falha | `Client`, `Server` | `Sender`, `Receiver` |

Um serviço fala uma versão ou as duas, e mandar a errada é uma falha por si só, que a seção 05
provoca de propósito.

## WSDL, o contrato que vem junto

O **WSDL**, Web Services Description Language, é um documento XML que lista as operações de um
serviço, a forma exata de cada requisição e resposta, e o endereço para onde mandá-las. A maioria
dos serviços SOAP o publica no próprio endereço, com `?wsdl` no fim. Ele é mais rigoroso que a
maior parte dos documentos OpenAPI que você vai encontrar, porque os tipos dentro dele são XML
Schema: um campo declarado `positiveInteger` é uma promessa que uma ferramenta consegue conferir.

É sobre esse rigor que as ferramentas são construídas. Dê o WSDL ao SoapUI, ou a um projeto Java ou
.NET, e ele gera cada requisição com os campos já no lugar. A seção 04 serve um e o lê parte por
parte.
