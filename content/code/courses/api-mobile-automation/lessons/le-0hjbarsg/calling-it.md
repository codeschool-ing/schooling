---
title: Calling it with curl, and reading the faults
version: 1
---

**A SOAP request is an ordinary HTTP POST whose body happens to be an envelope.** curl sends it as
it sends anything else: the envelope in a file, two headers, and the address. What changes is the
reading, because the answer is XML on a single line, and for that you need one more tool.

## xmllint

`xmllint` comes from libxml2, the XML library most Linux programs already use. It formats XML for
people, checks that a document is well formed, and evaluates XPath, which section 06 is about. On
Ubuntu 24.04 and in WSL it is one package:

```sh
sudo apt-get update
sudo apt-get install -y libxml2-utils
```

macOS ships xmllint with the system, which was not tried for this course. Check that it answers;
it prints its version on the error stream, hence the `2>&1`:

```
ana@laptop:~/boxoffice$ xmllint --version 2>&1 | head -1
xmllint: using libxml version 20914
```

`20914` is how libxml2 writes version 2.9.14.

## The envelope

The request for an invoice is a file. It is the order of three seats for sh-103 from lesson 1,
19500 cents. Save it as `soap/issue.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:inv="urn:example:invoice:v1">
  <soap:Header/>
  <soap:Body>
    <inv:IssueInvoice>
      <inv:orderId>ord-1001</inv:orderId>
      <inv:amountCents>19500</inv:amountCents>
      <inv:buyerTaxId>12345678909</inv:buyerTaxId>
    </inv:IssueInvoice>
  </soap:Body>
</soap:Envelope>
```

The `soap` prefix is bound to SOAP 1.1's namespace, so this envelope speaks 1.1. The `inv` prefix
is bound to `urn:example:invoice:v1`, the `targetNamespace` of the WSDL, which is how a real service
knows these are its elements; the stand-in's regular expressions ignore the prefix. The empty `soap:Header` could be left out; it is there to show where
a signature or a security token would go.

## A request that works

`--data-binary` sends the file byte for byte. `-d` would strip its line breaks, which XML survives
and a signed document may not. The two headers are SOAP 1.1's `content-type` and the `SOAPAction`
from the binding, quotes included:

```
ana@laptop:~/boxoffice$ curl -si localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml
HTTP/1.1 200 OK
content-type: text/xml; charset=utf-8
Date: Sat, 10 Oct 2026 07:35:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><IssueInvoiceResponse xmlns="urn:example:invoice:v1"><invoiceNumber>NFS-000001</invoiceNumber><verificationCode>F0999D34</verificationCode><issuedAt>2026-10-10T07:35:15.705Z</issuedAt></IssueInvoiceResponse></soap:Body></soap:Envelope>
```

`200 OK`, an envelope, and inside its `Body` the `IssueInvoiceResponse` with an invoice number.
On one line it is hard to read, and `xmllint --format -` indents whatever arrives on its standard
input:

```
ana@laptop:~/boxoffice$ curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml | xmllint --format -
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <IssueInvoiceResponse xmlns="urn:example:invoice:v1">
      <invoiceNumber>NFS-000002</invoiceNumber>
      <verificationCode>B03D2B62</verificationCode>
      <issuedAt>2026-10-10T07:35:15.743Z</issuedAt>
    </IssueInvoiceResponse>
  </soap:Body>
</soap:Envelope>
```

The same request a second time got the next number. The `issuedAt` and `verificationCode` you get
will differ from these: the first is the moment of the call, in UTC as the `Z` says, and the second
is computed from the number, the order and the amount.

## Three faults the service should give

**A test of a SOAP service spends most of its time here.** Each request below breaks one thing and
expects one fault. `sed` changes the envelope on its way to curl, and `@-` tells curl to read the
body from the pipe, so the file on disk stays as it is.

A tax id of three digits:

```
ana@laptop:~/boxoffice$ sed 's/12345678909/123/' soap/issue.xml | curl -si localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @-
HTTP/1.1 500 Internal Server Error
content-type: text/xml; charset=utf-8
Date: Sat, 10 Oct 2026 07:35:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><soap:Fault><faultcode>soap:Client</faultcode><faultstring>buyerTaxId must be 11 digits</faultstring></soap:Fault></soap:Body></soap:Envelope>
```

**HTTP `500` for a mistake that is entirely the client's, and that is correct here.** Lesson 1
called a `500` for a malformed request a defect, and in a REST API it is. SOAP 1.1 answers every
fault with `500`, so the status only says *a fault follows*. The blame is in `faultcode`:
`soap:Client`, with a `faultstring` that names the field.

No `SOAPAction` header at all:

```
ana@laptop:~/boxoffice$ curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' --data-binary @soap/issue.xml | xmllint --format -
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>SOAPAction must be "urn:example:invoice:v1#IssueInvoice"</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
```

A `soap:Client` fault that says which action it expected. Some services ignore the header and read
the `Body` instead; this one requires it, and the WSDL told you its value.

The same envelope labelled as SOAP 1.2:

```
ana@laptop:~/boxoffice$ curl -si localhost:8085/invoice -H 'content-type: application/soap+xml' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml
HTTP/1.1 415 Unsupported Media Type
Date: Sat, 10 Oct 2026 07:35:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked
```

`415 Unsupported Media Type`, with no envelope at all. The service speaks only SOAP 1.1, and it
refuses the 1.2 type before reading anything.

## A fault that is a defect

The WSDL says `amountCents` must appear. Remove its line from the envelope:

```
ana@laptop:~/boxoffice$ sed '/amountCents/d' soap/issue.xml | curl -s localhost:8085/invoice -H 'content-type: text/xml; charset=utf-8' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @- | xmllint --format -
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Server</faultcode>
      <faultstring>Cannot read properties of undefined (reading 'trim')</faultstring>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
```

**`soap:Server` for a request that broke the contract.** The service blamed itself, and the
`faultstring` is a JavaScript error, the sign of a check that was never written: the code called
`.trim()` on a field that was not there. Two things are wrong, and a defect report names both:

| | |
|---|---|
| **title** | IssueInvoice without `amountCents` answers `soap:Server` and shows an internal error |
| **steps** | post `soap/issue.xml` with the `amountCents` element removed |
| **expected** | `soap:Client`, with a `faultstring` naming `amountCents`, as for a short tax id |
| **actual** | `soap:Server`, `faultstring` *Cannot read properties of undefined (reading 'trim')* |
| **why it matters** | a caller that retries `Server` faults will retry a request that can never succeed; the message tells a stranger what the service is written in |

The second point is a security finding as well as a tidiness one. An error message that repeats the
internals helps nobody using the service and helps anybody probing it, so a tester checks that a
fault says what was wrong with the request and nothing about the code.
