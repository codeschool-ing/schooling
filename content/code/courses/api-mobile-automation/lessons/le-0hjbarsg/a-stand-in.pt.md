---
title: Um serviço SOAP só seu
version: 1
---

**O substituto é um pequeno serviço SOAP 1.1 escrito em Node, sem pacotes, como o boxoffice.** Ele
faz o papel do web service de notas da prefeitura da seção 03, com um endereço, `/invoice`, e uma
operação, `IssueInvoice`. A operação recebe um id de pedido, um valor em centavos e o CPF de quem
compra, e responde com um número de nota. Ele serve o próprio WSDL, e responde com uma falha a uma
requisição que não pode aceitar. Não é cópia de nenhum serviço real do governo, cujas mensagens são
maiores e assinadas; ele tem a mesma forma, que é o que um teste enxerga.

Crie um diretório para os arquivos desta lição dentro do seu projeto, `mkdir ~/boxoffice/soap`,
depois abra um arquivo novo ali e salve como `soap/invoice-service.mjs`:

```js
// invoice-service.mjs: a stand-in for the city's invoice web service, which
// boxoffice would call for every ticket sold. SOAP 1.1 over HTTP, one
// operation, IssueInvoice. Start it with `node soap/invoice-service.mjs`; it
// listens on port 8085 (PORT changes that) and serves its WSDL at /invoice?wsdl.
// Its XML reading is a few regular expressions: enough for a lab, not a parser.
import http from 'node:http';
import crypto from 'node:crypto';

const PORT = Number(process.env.PORT || 8085);
const NS = 'urn:example:invoice:v1';
const ACTION = `${NS}#IssueInvoice`;
let nextInvoice = 1;

const WSDL = `<?xml version="1.0" encoding="UTF-8"?>
<definitions name="InvoiceService" targetNamespace="${NS}"
    xmlns="http://schemas.xmlsoap.org/wsdl/"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:tns="${NS}">
  <types>
    <xs:schema targetNamespace="${NS}" elementFormDefault="qualified">
      <xs:element name="IssueInvoice">
        <xs:complexType><xs:sequence>
          <xs:element name="orderId" type="xs:string"/>
          <xs:element name="amountCents" type="xs:positiveInteger"/>
          <xs:element name="buyerTaxId" type="xs:string"/>
        </xs:sequence></xs:complexType>
      </xs:element>
      <xs:element name="IssueInvoiceResponse">
        <xs:complexType><xs:sequence>
          <xs:element name="invoiceNumber" type="xs:string"/>
          <xs:element name="verificationCode" type="xs:string"/>
          <xs:element name="issuedAt" type="xs:dateTime"/>
        </xs:sequence></xs:complexType>
      </xs:element>
    </xs:schema>
  </types>
  <message name="IssueInvoiceIn"><part name="body" element="tns:IssueInvoice"/></message>
  <message name="IssueInvoiceOut"><part name="body" element="tns:IssueInvoiceResponse"/></message>
  <portType name="InvoicePort">
    <operation name="IssueInvoice">
      <input message="tns:IssueInvoiceIn"/>
      <output message="tns:IssueInvoiceOut"/>
    </operation>
  </portType>
  <binding name="InvoiceBinding" type="tns:InvoicePort">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <operation name="IssueInvoice">
      <soap:operation soapAction="${ACTION}"/>
      <input><soap:body use="literal"/></input>
      <output><soap:body use="literal"/></output>
    </operation>
  </binding>
  <service name="InvoiceService">
    <port name="InvoicePort" binding="tns:InvoiceBinding">
      <soap:address location="http://localhost:${PORT}/invoice"/>
    </port>
  </service>
</definitions>
`;

const envelope = (body) => `<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>${body}</soap:Body></soap:Envelope>
`;

// SOAP 1.1 answers every fault with HTTP 500, whoever was to blame. The
// faultcode says who: soap:Client for the request, soap:Server for the service.
function fault(res, code, text) {
  res.writeHead(500, { 'content-type': 'text/xml; charset=utf-8' });
  res.end(envelope(`<soap:Fault><faultcode>soap:${code}</faultcode><faultstring>${text}</faultstring></soap:Fault>`));
}

// The text of the first element called `name`, whatever its prefix.
const field = (xml, name) => xml.match(new RegExp(`<(?:\\w+:)?${name}>([^<]*)</(?:\\w+:)?${name}>`))?.[1];

function issue(res, xml) {
  if (!/<(?:\w+:)?Envelope[\s>]/.test(xml) || !/<(?:\w+:)?Body[\s>]/.test(xml)) {
    return fault(res, 'Client', 'the request is not a SOAP envelope');
  }
  if (!/<(?:\w+:)?IssueInvoice[\s>]/.test(xml)) {
    return fault(res, 'Client', 'the body names no operation this service has');
  }
  const orderId = field(xml, 'orderId');
  const amount = Number(field(xml, 'amountCents').trim());
  const taxId = field(xml, 'buyerTaxId');
  if (!/^ord-\d+$/.test(orderId || '')) return fault(res, 'Client', 'orderId must look like ord-1001');
  if (!Number.isInteger(amount) || amount < 1) return fault(res, 'Client', 'amountCents must be a whole number above 0');
  if (!/^\d{11}$/.test(taxId || '')) return fault(res, 'Client', 'buyerTaxId must be 11 digits');
  const number = `NFS-${String(nextInvoice++).padStart(6, '0')}`;
  const code = crypto.createHash('sha256').update(`${number}:${orderId}:${amount}`).digest('hex').slice(0, 8).toUpperCase();
  res.writeHead(200, { 'content-type': 'text/xml; charset=utf-8' });
  res.end(envelope(`<IssueInvoiceResponse xmlns="${NS}"><invoiceNumber>${number}</invoiceNumber>`
    + `<verificationCode>${code}</verificationCode><issuedAt>${new Date().toISOString()}</issuedAt></IssueInvoiceResponse>`));
}

http.createServer((req, res) => {
  res.on('finish', () => console.log(`${req.method} ${req.url} ${res.statusCode}`));
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname !== '/invoice') {
    res.writeHead(404).end();
  } else if (req.method === 'GET' && url.searchParams.has('wsdl')) {
    res.writeHead(200, { 'content-type': 'text/xml; charset=utf-8' }).end(WSDL);
  } else if (req.method !== 'POST') {
    res.writeHead(405, { allow: 'POST' }).end();
  } else if (!(req.headers['content-type'] || '').startsWith('text/xml')) {
    res.writeHead(415).end();
  } else if (req.headers.soapaction?.replace(/"/g, '') !== ACTION) {
    fault(res, 'Client', `SOAPAction must be "${ACTION}"`);
  } else {
    let xml = '';
    req.on('data', (chunk) => { xml += chunk; });
    req.on('end', () => {
      try {
        issue(res, xml);
      } catch (err) {
        fault(res, 'Server', err.message);
      }
    });
  }
}).listen(PORT, () => console.log(`invoice service listening on http://localhost:${PORT}`));
```

A maior parte do arquivo é o WSDL, guardado numa string só para que o serviço possa entregá-lo. O
resto é um punhado de verificações em `issue` e o roteamento no fim. **A leitura de XML dele são
algumas expressões regulares**, como diz o cabeçalho: o bastante para um laboratório, e o motivo de
um serviço de verdade usar um parser.

Inicie-o a partir de `~/boxoffice` num terminal só dele, do jeito que você inicia o boxoffice:

```
ana@laptop:~/boxoffice$ node soap/invoice-service.mjs
invoice service listening on http://localhost:8085
```

Ele usa a porta 8085, então pode rodar ao lado do boxoffice na 8080 sem que nenhum dos dois perceba.

## O WSDL, pedido no próprio endereço

Em outro terminal, peça o WSDL do jeito que uma ferramenta pediria, com `?wsdl` depois do endereço.
O `-i` mostra os cabeçalhos, e o `head -12` guarda as primeiras doze linhas:

```
ana@laptop:~/boxoffice$ curl -si 'localhost:8085/invoice?wsdl' | head -12
HTTP/1.1 200 OK
content-type: text/xml; charset=utf-8
Date: Sat, 10 Oct 2026 07:35:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

<?xml version="1.0" encoding="UTF-8"?>
<definitions name="InvoiceService" targetNamespace="urn:example:invoice:v1"
    xmlns="http://schemas.xmlsoap.org/wsdl/"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
```

`content-type: text/xml` é o tipo do SOAP 1.1. O documento é o mesmo que o arquivo imprimiu, com o
namespace `urn:example:invoice:v1` preenchido. Um namespace é um nome para um vocabulário, escrito
como um endereço e nunca visitado: ele diz que o `IssueInvoice` daqui é o `IssueInvoice` deste
serviço, e não o de outro.

## Lendo um WSDL de baixo para cima

Um documento WSDL 1.1 tem cinco partes, e se lê melhor de trás para a frente, do endereço até os
tipos:

| parte | neste WSDL | responde |
|---|---|---|
| `service` | `InvoiceService`, com `soap:address location="http://localhost:8085/invoice"` | para onde eu mando? |
| `binding` | `InvoiceBinding`: SOAP sobre HTTP, `style="document"`, `use="literal"`, e o `soapAction` de cada operação | como vai embrulhado? |
| `portType` | `InvoicePort`, com uma `operation`, `IssueInvoice`, uma entrada e uma saída | o que posso pedir? |
| `message` | `IssueInvoiceIn` e `IssueInvoiceOut`, cada uma com uma `part` que aponta para um elemento | o que entra e o que sai? |
| `types` | um XML Schema que declara `IssueInvoice` e `IssueInvoiceResponse` campo a campo | que forma, exatamente? |

**A parte `types` é de onde vêm os casos de teste.** Ela declara três campos na requisição, em
ordem, e dá um tipo a cada um: `orderId` e `buyerTaxId` são strings, e `amountCents` é um
`positiveInteger`, então `0`, `-5` e `19.50` já são inválidos antes de alguém escrever uma regra de
negócio. Nenhum dos três diz `minOccurs="0"`, e em XML Schema isso significa que cada um tem de
aparecer exatamente uma vez. Uma requisição sem `amountCents` quebra o contrato, e o serviço deveria
dizer isso com uma falha `soap:Client`.

O que o schema não diz é igualmente útil de notar. Ele chama `buyerTaxId` de string e nada mais,
então a regra de que precisa ter 11 dígitos só existe no código. Quem testa lê essa lacuna como uma
pergunta para o dono do contrato, porque um cliente gerado a partir deste WSDL vai mandar `123` sem
reclamar.

`document` e `literal` no binding querem dizer que o `Body` guarda o elemento de `types` exatamente
como foi declarado. É o estilo que você vai encontrar em quase todo lugar hoje; os estilos mais
antigos, `rpc` e `encoded`, embrulham os argumentos de outro jeito, e ferramentas como o SoapUI leem
o que o WSDL declarar.
