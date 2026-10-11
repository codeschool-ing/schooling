---
title: A SOAP call by hand
version: 1
---

**A SOAP call is an HTTP `POST` with an XML body and two headers.** Nothing in it needs a SOAP
library, and making one call by hand is the best way to see what a library hides: when a toolkit
and a service disagree, this is the level at which you find out why.

The request is a file. Save it as `getstock.xml`:

```xml
<!-- shelf/getstock.xml -->
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:d="http://distributor.example/stock">
  <soap:Header/>
  <soap:Body>
    <d:GetStock>
      <d:ISBN>9786500000030</d:ISBN>
    </d:GetStock>
  </soap:Body>
</soap:Envelope>
```

It is the envelope from the first section: an empty `Header`, and a `Body` holding one `GetStock`
element in the distributor's namespace, with the ISBN of *A Hora da Estrela* inside it. The prefix
`d:` is bound to that namespace on the `Envelope`, which is what makes `d:GetStock` mean the
distributor's `GetStock` and nobody else's.

Send it with the two headers SOAP 1.1 asks for:

```
ana@api:~/shelf$ curl -si localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @getstock.xml; echo
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:40:47 GMT
Content-Type: text/xml; charset=utf-8
Content-Length: 301

<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GetStockResponse xmlns="http://distributor.example/stock"><ISBN>9786500000030</ISBN><QtyAvail>25</QtyAvail><UnitPrice>18.90</UnitPrice><NextDelivery>20261012</NextDelivery></GetStockResponse></soap:Body></soap:Envelope>
```

- `Content-Type: text/xml` is SOAP 1.1's media type. Version 1.2 would be
  `application/soap+xml`.
- `SOAPAction` names the operation, with the value the binding gave it in the WSDL. The
  quotes are part of the value.

The answer is **200** and one long line of XML, because a program wrote it for a program.
`xmllint --format` lays it out for a person, reading from standard input when it is given `-`:

```
ana@api:~/shelf$ curl -s localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @getstock.xml | xmllint --format -
<?xml version="1.0"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetStockResponse xmlns="http://distributor.example/stock">
      <ISBN>9786500000030</ISBN>
      <QtyAvail>25</QtyAvail>
      <UnitPrice>18.90</UnitPrice>
      <NextDelivery>20261012</NextDelivery>
    </GetStockResponse>
  </soap:Body>
</soap:Envelope>
```

Twenty-five copies at 18.90 each, and a delivery date written as eight digits. The names are the
distributor's, and so are the units.

## What the headers and the namespace are for

Leave out `SOAPAction`, and this service answers with a fault before it reads the body. Many SOAP
servers dispatch on that header, so it is the first thing they check. `xmllint --xpath` picks the
one value out of the answer:

```
ana@api:~/shelf$ curl -s localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' --data-binary @getstock.xml | xmllint --xpath 'string(//faultstring)' -
the SOAPAction header is missing
```

The namespace matters just as much. The schema says `qualified`, so the ISBN has to be `d:ISBN`;
write a bare `ISBN` and the service looks for an element that is not there:

```
ana@api:~/shelf$ sed 's/d:ISBN/ISBN/g' getstock.xml | curl -s localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @- | xmllint --xpath 'string(//faultstring)' -
ISBN  is not in the catalogue
```

**The service did not say that your XML was wrong. It looked up an empty ISBN**, the gap between
the two spaces in its answer, because an `ISBN` element in no namespace is, to this schema, a
different element that nobody asked for. That answer looks like a data problem and is a namespace
problem, and it is a common way for a hand-written envelope to fail.

## What HTTP no longer knows

Compare this with lesson 1. `GetStock` only reads, and in REST it would be a `GET`, which every
cache, proxy and retrying client knows to be safe. Here it is a `POST` to the same address as
`PlaceOrder`, so nothing between the two programs can tell a question from an order. **Whether a
SOAP call may be repeated is written in the contract's prose, if anywhere, and never in the
protocol.** The section on resilience comes back to what that costs.
