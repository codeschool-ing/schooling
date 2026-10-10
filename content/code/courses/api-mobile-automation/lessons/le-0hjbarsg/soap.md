---
title: SOAP, an envelope sent to one address
version: 1
---

**SOAP is a format for messages, written in XML, and HTTP is only the van that carries them.** The
picture most people arrive with is that SOAP is an older, wordier kind of REST. It is a different
idea. REST, as lessons 1 and 2 used it, spreads an API over many addresses and lets the HTTP method
say what to do with each. SOAP puts the whole request inside one XML document, the **envelope**,
and posts every envelope to the same address. The address says *which service*; what to do is
written inside the message.

## The envelope

Every SOAP message, request or response, has the same nesting:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 282\" role=\"img\" aria-label=\"A SOAP message nested inside an HTTP request. The HTTP request is POST /invoice with content-type text/xml and a SOAPAction header. Inside it is soap:Envelope, whose namespace says the SOAP version. The envelope holds an optional soap:Header, for a signature, a security token or a trace id, and a compulsory soap:Body. The body holds one of two things: inv:IssueInvoice with orderId, amountCents and buyerTaxId, which is the operation and its arguments, or soap:Fault with faultcode and faultstring, which is the error and who is to blame.\"><rect x=\"10\" y=\"10\" width=\"680\" height=\"262\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"22\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the HTTP request</text><text x=\"150\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /invoice   content-type: text/xml   SOAPAction: \"…#IssueInvoice\"</text><rect x=\"30\" y=\"44\" width=\"640\" height=\"214\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"42\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">soap:Envelope</text><text x=\"160\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the namespace says which version of SOAP</text><rect x=\"50\" y=\"74\" width=\"600\" height=\"36\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"62\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">soap:Header</text><text x=\"170\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">optional: a signature, a security token, a trace id</text><rect x=\"50\" y=\"120\" width=\"600\" height=\"126\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"62\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">soap:Body</text><text x=\"170\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">compulsory, and holds one of the two</text><rect x=\"70\" y=\"152\" width=\"260\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"200\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">inv:IssueInvoice</text><text x=\"200\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">orderId  amountCents  buyerTaxId</text><text x=\"200\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">the operation and its arguments</text><rect x=\"400\" y=\"152\" width=\"230\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"515\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">soap:Fault</text><text x=\"515\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">faultcode  faultstring</text><text x=\"515\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">the error, and who is to blame</text><text x=\"365\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">or</text></svg>", "caption": "A SOAP message is an envelope inside an ordinary HTTP POST: an optional header, and a body holding either the operation or a fault."}
```

- **`Envelope`** is the outermost element. Its namespace says which version of SOAP the message
  speaks: `http://schemas.xmlsoap.org/soap/envelope/` is SOAP 1.1, and
  `http://www.w3.org/2003/05/soap-envelope` is SOAP 1.2.
- **`Header`** is optional. It carries what is about the message rather than the business: a
  signature, a security token, an id for tracing. The invoice service of this lesson sends none.
- **`Body`** is compulsory. In a request it holds one element named after the operation,
  `IssueInvoice`, with its arguments inside. In a response it holds the answer, or a **`Fault`**.

A fault is SOAP's error. In SOAP 1.1 it has a `faultcode` and a `faultstring`, and the code says
who is to blame: **`soap:Client`** when the request was wrong, **`soap:Server`** when the service
failed. That is the same line lesson 1 drew between `4xx` and `5xx`, moved from the status line
into the body.

## One address, and the operation inside

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 236\" role=\"img\" aria-label=\"Two halves. On the left, REST: GET goes to /v1/shows, POST to /v1/orders and DELETE to /v1/orders/ord-1001, each request to an address of its own, so the method and the path say what to do. On the right, SOAP: three operations, IssueInvoice, CancelInvoice and QueryInvoice, all go to the same POST /invoice, and the SOAPAction header and the Body say what to do.\"><defs><marker id=\"f09one-address-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">REST: one address per thing</text><text x=\"525\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">SOAP: one address, the operation inside</text><line x1=\"350\" y1=\"10\" x2=\"350\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"24\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">GET</text><line x1=\"90\" y1=\"65\" x2=\"176\" y2=\"65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"178\" y=\"48\" width=\"156\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/v1/shows</text><text x=\"24\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST</text><line x1=\"90\" y1=\"125\" x2=\"176\" y2=\"125\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"178\" y=\"108\" width=\"156\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/v1/orders</text><text x=\"24\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">DELETE</text><line x1=\"90\" y1=\"185\" x2=\"176\" y2=\"185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"178\" y=\"168\" width=\"156\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"256\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/v1/orders/ord-1001</text><rect x=\"366\" y=\"48\" width=\"150\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"441\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">IssueInvoice</text><line x1=\"516\" y1=\"65\" x2=\"574\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"366\" y=\"108\" width=\"150\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"441\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">CancelInvoice</text><line x1=\"516\" y1=\"125\" x2=\"574\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"366\" y=\"168\" width=\"150\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"441\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">QueryInvoice</text><line x1=\"516\" y1=\"185\" x2=\"574\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f09one-address-ah)\"></line><rect x=\"576\" y=\"62\" width=\"104\" height=\"84\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"628\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">POST</text><text x=\"628\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/invoice</text><text x=\"175\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the method and the path say what to do</text><text x=\"525\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the SOAPAction and the Body say what to do</text></svg>", "caption": "REST spreads an API over addresses and methods. SOAP sends every operation to one address by POST and names the operation inside the request."}
```

The drawing gives the SOAP side three operations to make the point; the stand-in of section 04
has one. The difference changes what a test looks at:

| | REST, as boxoffice does it | SOAP, as the invoice service does it |
|---|---|---|
| addresses | one per thing: `/v1/shows`, `/v1/orders/ord-1001` | one: `/invoice` |
| method | GET, POST, DELETE, chosen per action | POST, for every operation |
| what to do is named by | the method and the path | the `SOAPAction` header and the first element of the `Body` |
| body | JSON | XML, inside an envelope |
| a failure is told by | the status code, with problem details | HTTP `500` and a `Fault`, with a `faultcode` |
| the contract | OpenAPI, which lesson 2 wrote by hand | WSDL, which the service usually serves itself |

**The status code says much less in SOAP 1.1.** The specification has every fault answered with
`500 Internal Server Error`, whoever was to blame. A test that stops at the status cannot tell a
typo in the request from a crashed service; it has to read the `faultcode`. SOAP 1.2 changed that:
a fault blaming the sender, which it calls `env:Sender`, travels as `400`, and the rest as `500`.

## The two versions, as a tester tells them apart

You will meet both, and three things say which one is in front of you:

| | SOAP 1.1 | SOAP 1.2 |
|---|---|---|
| `content-type` | `text/xml` | `application/soap+xml` |
| the operation | a separate `SOAPAction` header | an optional `action` parameter inside the `content-type` |
| fault codes | `Client`, `Server` | `Sender`, `Receiver` |

A service speaks one version or both, and sending the wrong one is a failure in its own right,
which section 05 provokes on purpose.

## WSDL, the contract that comes with it

**WSDL**, the Web Services Description Language, is an XML document that lists a service's
operations, the exact shape of every request and response, and the address to send them to. Most
SOAP services publish it at their own address with `?wsdl` on the end. It is stricter than most
OpenAPI documents you will meet, because the types inside it are XML Schema: a field declared
`positiveInteger` is a promise a tool can check.

That strictness is what tools are built on. Give SoapUI, or a Java or .NET project, the WSDL and it
generates every request with its fields already in place. Section 04 serves one and reads it part
by part.
