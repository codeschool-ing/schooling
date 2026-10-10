---
title: What SOAP is, and why it is still everywhere
version: 1
---

**SOAP is a way for programs to send each other XML messages, each one wrapped in an envelope and
almost always carried by HTTP `POST`.** A SOAP service publishes a contract that describes every
operation in a form a program can read. It was the standard way for two companies' systems to talk
to each other in the early 2000s, and a great many of those systems are still running.

The common picture is that SOAP is dead and REST replaced it. It stopped being **chosen** for new
public APIs, which is a different thing. A system that has worked for twenty years is not
rewritten because its format went out of fashion; it is integrated with, and the integration is
somebody's job this year. Some instances a Brazilian back-end developer meets:

| where | what speaks SOAP |
|---|---|
| tax | the state tax authorities' web services that receive the NF-e, Brazil's electronic invoice |
| banks | interfaces for payments, statements and clearing built before JSON was common |
| ERPs | SAP and other enterprise systems publish SOAP web services for their documents |
| logistics | carriers, distributors and warehouses whose stock and order systems are decades old |
| SaaS | Salesforce still offers a SOAP API beside its REST one |

This lesson's distributor is the last kind. The bookshop buys its books from a distributor whose
system speaks SOAP, and the shop has to ask it what is in stock and place orders with it.

## The envelope

Every SOAP message has the same three parts, nested:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 306\" role=\"img\" aria-label=\"Two SOAP messages drawn as nested boxes. On the left, the request: a soap:Envelope holding an optional soap:Header and a soap:Body, and inside the Body one element, d:GetStock, holding d:ISBN. On the right, the answer to an unknown ISBN: a soap:Envelope whose soap:Body holds a soap:Fault with a faultcode, a faultstring and a detail carrying the error code E100. The fault travels with HTTP 500.\"><text x=\"175\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the request</text><rect x=\"20\" y=\"36\" width=\"310\" height=\"250\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">soap:Envelope</text><text x=\"525\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the answer, a fault</text><rect x=\"370\" y=\"36\" width=\"310\" height=\"250\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"382\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">soap:Envelope</text><rect x=\"36\" y=\"66\" width=\"278\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"48\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">soap:Header</text><text x=\"48\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">optional: security, routing, ids</text><rect x=\"36\" y=\"128\" width=\"278\" height=\"144\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"48\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">soap:Body</text><rect x=\"52\" y=\"160\" width=\"246\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">d:GetStock</text><text x=\"64\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the operation, in the</text><text x=\"64\" y=\"207\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">distributor&#x27;s namespace</text><rect x=\"64\" y=\"220\" width=\"222\" height=\"26\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"76\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">d:ISBN 9786500000030</text><rect x=\"386\" y=\"66\" width=\"278\" height=\"206\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"398\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">soap:Body</text><rect x=\"402\" y=\"98\" width=\"246\" height=\"158\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"414\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">soap:Fault</text><rect x=\"414\" y=\"128\" width=\"222\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faultcode</text><text x=\"626\" y=\"139\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">who is to blame</text><text x=\"424\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">soap:Client</text><rect x=\"414\" y=\"168\" width=\"222\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">faultstring</text><text x=\"626\" y=\"179\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">for a person</text><text x=\"424\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ISBN … not in the catalogue</text><rect x=\"414\" y=\"208\" width=\"222\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"424\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">detail</text><text x=\"626\" y=\"219\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">for a program</text><text x=\"424\" y=\"233\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ErrorCode E100</text><text x=\"525\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sent with HTTP 500</text></svg>", "caption": "A SOAP message is an envelope with an optional header and one body. A fault replaces the answer inside the body, and travels with HTTP 500."}
```

- `Envelope` is the root element, and its namespace says which version of SOAP this is.
- `Header` is optional. It carries what is **about** the message rather than the business in
  it: a security token, a transaction id, routing for an intermediary that forwards it. The
  section on WS-Security shows one filled in.
- `Body` carries the business: one element naming the operation and holding its arguments,
  or, on the way back, the result or a **`Fault`**.

Compare that with lesson 1. In REST the address names the thing and the method says what to do
with it: `GET /v1/books/3`. In SOAP there is **one address for the whole service and one method,
`POST`, for every operation**, including the ones that only read. The operation is named inside
the body. HTTP is only the vehicle, and SOAP was designed to travel by other vehicles too, which
is why it repeats inside the envelope things HTTP could have said.

## Two versions

| | SOAP 1.1 | SOAP 1.2 |
|---|---|---|
| envelope namespace | `http://schemas.xmlsoap.org/soap/envelope/` | `http://www.w3.org/2003/05/soap-envelope` |
| content type | `text/xml` | `application/soap+xml` |
| the operation, in HTTP | a `SOAPAction` header | an `action` parameter of the content type |
| a fault says | `faultcode`, `faultstring`, `detail` | `Code`, `Reason`, `Detail` |

The distributor speaks **SOAP 1.1**, the version you meet most in old systems. A client has to use
the version the service speaks, and the namespace of the envelope is how a service tells them
apart.
