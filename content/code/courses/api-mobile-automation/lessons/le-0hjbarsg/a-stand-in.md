---
title: A SOAP service of your own
version: 1
---

**The stand-in is a small SOAP 1.1 service written in Node, with no packages, like boxoffice.** It
plays the city's invoice web service from section 03, with one address, `/invoice`, and one
operation, `IssueInvoice`. The operation takes an order id, an amount in cents and the buyer's tax
id, and answers with an invoice number. It serves its own WSDL, and it answers a request it cannot
accept with a fault. It is not a copy of any real government service, whose messages are larger and signed; it has the
same shape, which is what a test sees.

Make a directory for this lesson's files inside your project, `mkdir ~/boxoffice/soap`, then open a
new file there and save it as `soap/invoice-service.mjs`:

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

Most of the file is the WSDL, kept as one string so that the service can hand it out. The rest is a
handful of checks in `issue` and the routing at the bottom. **Its XML reading is a few regular
expressions**, as its header says: enough for a lab, and the reason a real service uses a parser.

Start it from `~/boxoffice` in a terminal of its own, the way you start boxoffice:

```
ana@laptop:~/boxoffice$ node soap/invoice-service.mjs
invoice service listening on http://localhost:8085
```

It uses port 8085, so it can run beside boxoffice on 8080 without either noticing.

## The WSDL, asked for at its own address

In another terminal, ask for the WSDL the way a tool would, with `?wsdl` after the address. `-i`
shows the headers, and `head -12` keeps the first twelve lines:

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

`content-type: text/xml` is SOAP 1.1's type. The document is the same one the file printed, with
the namespace `urn:example:invoice:v1` filled in. A namespace is a name for a vocabulary, written
like an address and never visited: it says that `IssueInvoice` here is this service's
`IssueInvoice` and not somebody else's.

## Reading a WSDL from the bottom up

A WSDL 1.1 document has five parts, and it reads best backwards, from the address to the types:

| part | in this WSDL | answers |
|---|---|---|
| `service` | `InvoiceService`, with `soap:address location="http://localhost:8085/invoice"` | where do I send it? |
| `binding` | `InvoiceBinding`: SOAP over HTTP, `style="document"`, `use="literal"`, and the `soapAction` of each operation | how is it wrapped? |
| `portType` | `InvoicePort`, with one `operation`, `IssueInvoice`, an input and an output | what can I ask? |
| `message` | `IssueInvoiceIn` and `IssueInvoiceOut`, each one `part` pointing at an element | what goes in and out? |
| `types` | an XML Schema declaring `IssueInvoice` and `IssueInvoiceResponse` field by field | what shape, exactly? |

**The `types` part is where test cases come from.** It declares three fields in the request, in
order, and gives each a type: `orderId` and `buyerTaxId` are strings, and `amountCents` is a
`positiveInteger`, so `0`, `-5` and `19.50` are already invalid before anybody wrote a business
rule. None of the three says `minOccurs="0"`, and in XML Schema that means each must appear exactly
once. A request without `amountCents` breaks the contract, and the service should say so with a
`soap:Client` fault.

What the schema does not say is just as useful to notice. It calls `buyerTaxId` a string and
nothing more, so the rule that it must be 11 digits lives only in the code. A tester reads that gap
as a question for whoever owns the contract, because a client generated from this WSDL will happily
send `123`.

`document` and `literal` in the binding mean that the `Body` holds the element from `types` exactly
as declared. That is the style you will meet almost everywhere today; the older `rpc` and `encoded`
styles wrap the arguments differently, and tools such as SoapUI read whichever the WSDL declares.
