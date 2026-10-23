---
title: What a SOAP message is made of
version: 1
---

Engineers who arrived after 2010 tend to file SOAP as "XML over HTTP, the old way of doing REST".
That picture gets the protocol wrong in a way that matters when you have to talk to one. **SOAP is
an envelope format, and HTTP is only one of the ways an envelope travels.** The envelope carries its
own addressing room (the header), its own payload (the body) and its own way of saying something
went wrong (the fault), and a service is described by a separate contract, the WSDL, from which both
sides can generate code. At Serra Alta most of the ESB's SOAP flows answer over HTTP, and a few
take the same envelope off an MQ queue, unchanged.

## Two versions, one shape

SOAP began at the end of the 1990s with Microsoft, DevelopMentor and UserLand, and was submitted to
the W3C. **SOAP 1.1 was published as a W3C Note in 2000, and SOAP 1.2 became a W3C Recommendation in
2003.** The name started as an acronym, Simple Object Access Protocol; version 1.2 dropped the
expansion, which by then described nothing it did. Both versions are in production everywhere, and
the services Rui's team built from 2015 are SOAP 1.1, which is what most of their callers
expected.

A SOAP message is an XML document with one root, `Envelope`, and inside it two children:

- `Header`, optional, holding blocks meant for the infrastructure rather than the application —
  security tokens, addressing, transaction context. Section 04 of this lesson is about what went in
  there.
- `Body`, required, holding the payload: the request, the response, or a `Fault`.

**The namespace of the `Envelope` element is what tells you the version**, and a receiver checks it
before anything else. SOAP 1.1 uses `http://schemas.xmlsoap.org/soap/envelope/`; SOAP 1.2 uses
`http://www.w3.org/2003/05/soap-envelope`. The prefix in front of it — `soap:`, `env:`, `s:`,
`ns0:` — is chosen by whoever wrote the message and means nothing on its own.

## A request on the wire

Rota, the route-planning system, needs to know how big each farm's tank is and when it was last
emptied. That data lives in Coleta, on the IBM i, and in 2016 Rui's team put a SOAP service called
FarmRegistry in front of it on the bus. One of its operations is `GetFarmTank`. Over HTTP, a SOAP
1.1 call is always a `POST`, and these are the headers that matter:

```
POST /services/FarmRegistry HTTP/1.1
Host: esb.serraalta.example
Content-Type: text/xml; charset=utf-8
SOAPAction: "http://schemas.serraalta.example/farm-registry/2016/GetFarmTank"
```

The `SOAPAction` header names the operation, in quotes, so that a gateway can route the request
without parsing the XML. The body of the request is the envelope:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:fr="http://schemas.serraalta.example/farm-registry/2016">
  <soap:Body>
    <fr:GetFarmTank>
      <fr:farmCode>0412736</fr:farmCode>
    </fr:GetFarmTank>
  </soap:Body>
</soap:Envelope>
```

There is no header block here; FarmRegistry actually demands one, a security token, and section 04
puts it back. Two namespaces are in play. `soap:` is SOAP's own; `fr:` is Serra Alta's, and the
`2016` at its end is a version: a FarmRegistry with incompatible messages would get a new
namespace, and a client generated from the old one would refuse the new messages rather than
misread them. The answer comes back with status 200:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:fr="http://schemas.serraalta.example/farm-registry/2016">
  <soap:Body>
    <fr:GetFarmTankResponse>
      <fr:farmCode>0412736</fr:farmCode>
      <fr:tankLitres>4000</fr:tankLitres>
      <fr:averageDailyLitres>1150</fr:averageDailyLitres>
      <fr:lastCollection>2026-10-21T05:40:00-03:00</fr:lastCollection>
    </fr:GetFarmTankResponse>
  </soap:Body>
</soap:Envelope>
```

A 4,000-litre tank filling at 1,150 litres a day holds a little under three and a half days of
milk, but the company's rule is stricter than the tank: no farm waits more than 48 hours. Rota
uses both numbers.

## A fault

A farm code that does not exist is not a crash; it is an answer. SOAP has a structure for it, the
`Fault`, which takes the place of the response inside the body:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <soap:Fault>
      <faultcode>soap:Client</faultcode>
      <faultstring>No farm with code 0399018</faultstring>
      <detail>
        <fr:FarmNotFound xmlns:fr="http://schemas.serraalta.example/farm-registry/2016">
          <fr:farmCode>0399018</fr:farmCode>
        </fr:FarmNotFound>
      </detail>
    </soap:Fault>
  </soap:Body>
</soap:Envelope>
```

Read it from the outside in. `faultcode` says whose fault it is: `soap:Client` means the request
was wrong and sending it again will get the same answer, `soap:Server` means the request may have
been fine and the service failed. `faultstring` is for a person. `detail` is for a program: a typed
element, declared in the contract, that the client can turn into a meaningful error. In SOAP 1.1
the children `faultcode`, `faultstring` and `detail` carry no namespace prefix; that is the
specification, not a slip.

**Over HTTP, SOAP 1.1 sends every fault with status 500 Internal Server Error.** A client that
treats every 500 as "the server is down, try again later" will retry a request that is wrong
forever, and will throw away the one element that said why.

## What changed in 1.2

| | SOAP 1.1 | SOAP 1.2 |
|---|---|---|
| envelope namespace | `http://schemas.xmlsoap.org/soap/envelope/` | `http://www.w3.org/2003/05/soap-envelope` |
| content type over HTTP | `text/xml` | `application/soap+xml` |
| how the operation is named | a `SOAPAction` HTTP header | an `action` parameter on the content type |
| fault structure | `faultcode`, `faultstring`, `detail` | `Code` with `Value`, `Reason` with `Text`, `Detail` |
| the two main fault codes | `Client`, `Server` | `Sender`, `Receiver` |
| HTTP status of a fault | always 500 | 400 for a `Sender` fault, 500 otherwise |

You will meet SOAP 1.2 without leaving Brazil: the web services through which every NF-e reaches
the state tax authority are SOAP 1.2. and the 1,400 or so invoices Serra Alta issues on an ordinary weekday
travel that way.

## The contract

The part of SOAP enterprises valued most is not in the message at all. **A WSDL (Web Services
Description Language) document describes a service completely enough that a tool can generate the
client from it**: the operations, the messages each one takes and returns, the types of every field
as XML Schema, the faults, and the address. This is FarmRegistry's, in WSDL 1.1, the version almost
every SOAP service you will meet uses:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<wsdl:definitions name="FarmRegistry"
    targetNamespace="http://schemas.serraalta.example/farm-registry/2016"
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fr="http://schemas.serraalta.example/farm-registry/2016">
  <wsdl:types>
    <xs:schema targetNamespace="http://schemas.serraalta.example/farm-registry/2016"
               elementFormDefault="qualified">
      <xs:element name="GetFarmTank">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="farmCode" type="xs:string"/>
          </xs:sequence>
        </xs:complexType>
      </xs:element>
      <xs:element name="GetFarmTankResponse">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="farmCode" type="xs:string"/>
            <xs:element name="tankLitres" type="xs:int"/>
            <xs:element name="averageDailyLitres" type="xs:int"/>
            <xs:element name="lastCollection" type="xs:dateTime"/>
          </xs:sequence>
        </xs:complexType>
      </xs:element>
      <xs:element name="FarmNotFound">
        <xs:complexType>
          <xs:sequence>
            <xs:element name="farmCode" type="xs:string"/>
          </xs:sequence>
        </xs:complexType>
      </xs:element>
    </xs:schema>
  </wsdl:types>
  <wsdl:message name="GetFarmTankRequest">
    <wsdl:part name="parameters" element="fr:GetFarmTank"/>
  </wsdl:message>
  <wsdl:message name="GetFarmTankResponse">
    <wsdl:part name="parameters" element="fr:GetFarmTankResponse"/>
  </wsdl:message>
  <wsdl:message name="FarmNotFoundFault">
    <wsdl:part name="fault" element="fr:FarmNotFound"/>
  </wsdl:message>
  <wsdl:portType name="FarmRegistryPort">
    <wsdl:operation name="GetFarmTank">
      <wsdl:input message="fr:GetFarmTankRequest"/>
      <wsdl:output message="fr:GetFarmTankResponse"/>
      <wsdl:fault name="FarmNotFound" message="fr:FarmNotFoundFault"/>
    </wsdl:operation>
  </wsdl:portType>
  <wsdl:binding name="FarmRegistrySoap" type="fr:FarmRegistryPort">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <wsdl:operation name="GetFarmTank">
      <soap:operation soapAction="http://schemas.serraalta.example/farm-registry/2016/GetFarmTank"/>
      <wsdl:input><soap:body use="literal"/></wsdl:input>
      <wsdl:output><soap:body use="literal"/></wsdl:output>
      <wsdl:fault name="FarmNotFound"><soap:fault name="FarmNotFound" use="literal"/></wsdl:fault>
    </wsdl:operation>
  </wsdl:binding>
  <wsdl:service name="FarmRegistry">
    <wsdl:port name="FarmRegistrySoap" binding="fr:FarmRegistrySoap">
      <soap:address location="https://esb.serraalta.example/services/FarmRegistry"/>
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
```

It is long for one operation, and every part answers a different question:

| part | the question it answers |
|---|---|
| `types` | what each element looks like, in XML Schema: `tankLitres` is an integer, `lastCollection` a date and time with its offset |
| `message` | which elements travel together as one input, one output or one fault |
| `portType` | which operations exist and what each takes, returns and can fail with — the abstract interface |
| `binding` | how that interface is put on the wire: SOAP 1.1 over HTTP, document style, literal XML, which `SOAPAction` |
| `service` | where it lives: the address |

One trap in reading it: inside a WSDL, `soap:` is bound to `http://schemas.xmlsoap.org/wsdl/soap/`,
the WSDL's vocabulary for describing a SOAP 1.1 binding. It is not the envelope namespace you saw
in the messages, although the two share a prefix by convention.

`style="document"` with `use="literal"` means the body carries exactly the elements the schema
declares. Older services use an RPC style with SOAP's own "encoded" type system, which different
toolkits read differently. The WS-I Basic Profile, published in 2004 so that Java and .NET toolkits
would agree with each other, ruled the encoded style out, and document/literal is what you will
meet.

## Why enterprises liked it

Put that WSDL into the right tool and out comes a class with a method `getFarmTank(String)`
returning an object with four typed fields, and a typed exception for `FarmNotFound`. **A team
could integrate with a service it had never seen, and the compiler told it when it sent the wrong
type.** In 2005, when the alternative was a PDF describing a fixed-width file, that was a large
improvement, and it is the part of SOAP worth remembering when you meet its descendants: OpenAPI
gave JSON over HTTP the same thing years later, and a contract a machine can read is still the
best defence against two teams that each believe they agreed on something different.

The price was paid in the header, which is the next section.
