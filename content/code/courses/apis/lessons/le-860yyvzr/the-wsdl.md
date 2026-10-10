---
title: Reading a WSDL
version: 1
---

A SOAP service publishes its contract as a **WSDL**, the Web Services Description Language: an XML
document that says which operations exist, what goes in and out of each one, how the messages
travel and at which address. The usual mistake is to treat it as documentation for people. It is
written **for programs**: a SOAP toolkit reads it and builds a client, which is what the section
after next does. A person reads it to find out what the toolkit will do.

This is the distributor's contract, the one the stand-in in the next section serves. Save it in
`~/shelf` as `distributor.wsdl`, the same way you saved `db.py` in lesson 1:

```xml
<!-- shelf/distributor.wsdl -->
<definitions name="Distributor"
    targetNamespace="http://distributor.example/stock"
    xmlns="http://schemas.xmlsoap.org/wsdl/"
    xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:tns="http://distributor.example/stock">

  <types>
    <xsd:schema targetNamespace="http://distributor.example/stock"
        elementFormDefault="qualified">
      <xsd:element name="GetStock">
        <xsd:complexType><xsd:sequence>
          <xsd:element name="ISBN" type="xsd:string"/>
        </xsd:sequence></xsd:complexType>
      </xsd:element>
      <xsd:element name="GetStockResponse">
        <xsd:complexType><xsd:sequence>
          <xsd:element name="ISBN" type="xsd:string"/>
          <xsd:element name="QtyAvail" type="xsd:int"/>
          <xsd:element name="UnitPrice" type="xsd:decimal"/>
          <xsd:element name="NextDelivery" type="xsd:string"/>
        </xsd:sequence></xsd:complexType>
      </xsd:element>
      <xsd:element name="PlaceOrder">
        <xsd:complexType><xsd:sequence>
          <xsd:element name="ISBN" type="xsd:string"/>
          <xsd:element name="Qty" type="xsd:int"/>
          <xsd:element name="CustomerRef" type="xsd:string"/>
        </xsd:sequence></xsd:complexType>
      </xsd:element>
      <xsd:element name="PlaceOrderResponse">
        <xsd:complexType><xsd:sequence>
          <xsd:element name="OrderNo" type="xsd:string"/>
          <xsd:element name="Repeated" type="xsd:boolean"/>
        </xsd:sequence></xsd:complexType>
      </xsd:element>
    </xsd:schema>
  </types>

  <message name="GetStockIn"><part name="body" element="tns:GetStock"/></message>
  <message name="GetStockOut"><part name="body" element="tns:GetStockResponse"/></message>
  <message name="PlaceOrderIn"><part name="body" element="tns:PlaceOrder"/></message>
  <message name="PlaceOrderOut"><part name="body" element="tns:PlaceOrderResponse"/></message>

  <portType name="StockPort">
    <operation name="GetStock">
      <input message="tns:GetStockIn"/>
      <output message="tns:GetStockOut"/>
    </operation>
    <operation name="PlaceOrder">
      <input message="tns:PlaceOrderIn"/>
      <output message="tns:PlaceOrderOut"/>
    </operation>
  </portType>

  <binding name="StockBinding" type="tns:StockPort">
    <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http"/>
    <operation name="GetStock">
      <soap:operation soapAction="http://distributor.example/stock/GetStock"/>
      <input><soap:body use="literal"/></input>
      <output><soap:body use="literal"/></output>
    </operation>
    <operation name="PlaceOrder">
      <soap:operation soapAction="http://distributor.example/stock/PlaceOrder"/>
      <input><soap:body use="literal"/></input>
      <output><soap:body use="literal"/></output>
    </operation>
  </binding>

  <service name="DistributorService">
    <port name="StockPort" binding="tns:StockBinding">
      <soap:address location="http://127.0.0.1:8001/distributor"/>
    </port>
  </service>
</definitions>
```

Five parts, and **each is defined in terms of the one before it**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"The five parts of distributor.wsdl in a row, each one referring to the part on its left. types declares the elements GetStock, GetStockResponse, PlaceOrder and PlaceOrderResponse. message wraps one element, as in GetStockIn. portType lists the operations of StockPort, each with an input and an output message. binding says how StockPort travels: SOAP 1.1, document, literal, a SOAPAction per operation. service says where: http://127.0.0.1:8001/distributor. The first three are abstract, what can be said; the last two are concrete, how and where.\"><defs><marker id=\"l05-wsdl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">types</text><text x=\"30\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStock</text><text x=\"30\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStockResponse</text><text x=\"30\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlaceOrder</text><text x=\"30\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlaceOrderResponse</text><rect x=\"160\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">message</text><text x=\"170\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStockIn</text><text x=\"182\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">= GetStock</text><text x=\"170\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStockOut</text><text x=\"182\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">= …Response</text><line x1=\"160\" y1=\"170\" x2=\"142\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><rect x=\"300\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">portType</text><text x=\"310\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">StockPort</text><text x=\"322\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStock</text><text x=\"322\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlaceOrder</text><line x1=\"300\" y1=\"170\" x2=\"282\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><rect x=\"440\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">binding</text><text x=\"450\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">StockBinding</text><text x=\"462\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">document</text><text x=\"462\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">literal</text><text x=\"462\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SOAPAction</text><line x1=\"440\" y1=\"170\" x2=\"422\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><rect x=\"580\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">service</text><text x=\"590\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">StockPort at</text><text x=\"590\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">127.0.0.1:8001</text><text x=\"590\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/distributor</text><line x1=\"580\" y1=\"170\" x2=\"562\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><text x=\"220.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">abstract: what can be said</text><line x1=\"20\" y1=\"44\" x2=\"420\" y2=\"44\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><text x=\"570.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">concrete: how, and where</text><line x1=\"440\" y1=\"44\" x2=\"700\" y2=\"44\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"350\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each arrow: &quot;is defined in terms of&quot;</text></svg>", "caption": "A WSDL in five parts. The first three describe the messages and operations; the binding and the service fix the protocol and the address."}
```

Reading it from the top, as it is written, means meeting the types before knowing what they are for.
Reading it **from the bottom** follows the questions a caller has, in order:

| part | answers | in this file |
|---|---|---|
| `service` | where do I send it? | `http://127.0.0.1:8001/distributor` |
| `binding` | how is it carried? | SOAP 1.1 over HTTP, `document` style, `literal` bodies, and the `SOAPAction` for each operation |
| `portType` | which operations are there? | `GetStock` and `PlaceOrder`, each an input message and an output message |
| `message` | what is each message? | one part, which is one element of the schema |
| `types` | what does that element contain? | an XML Schema: `GetStock` holds an `ISBN` of type `xsd:string`, and so on |

## Two details that decide what goes on the wire

**`document` and `literal` mean the body carries the schema's element exactly as declared.** A
`GetStock` request is a `GetStock` element with an `ISBN` inside it, and nothing else. Naming the
element after the operation, as this file does, is called the *wrapped* convention. Older services
use `rpc` style with `encoded` bodies, where the toolkit adds type annotations of its own to every
value. The WS-I Basic Profile, the interoperability rules most toolkits follow, forbids `encoded`,
and a service that uses it is the one where two toolkits most often disagree.

**`elementFormDefault="qualified"` puts the namespace on every element, not only the outer one.**
That is why the request in the section after next writes `d:ISBN` and not a bare `ISBN`. A service
whose schema says `qualified` refuses a bare `ISBN` or does not find it, depending on how strict it
is.

## Types, with names

The schema gives every value a type: `QtyAvail` is an `xsd:int`, `UnitPrice` an `xsd:decimal`. JSON
has numbers and strings and nothing between them; a WSDL can say that a price is a decimal and not a
float, and a toolkit that reads it will hand you a decimal. What it cannot do is make the names good.
`QtyAvail`, `NextDelivery` written as a plain string, a price in reais: those are the distributor's
choices, and the contract only makes them precise.

`xmllint` checks that the file you typed is well-formed XML. It does not check that it is a valid
WSDL; the toolkit does that when it reads it.

```
ana@api:~/shelf$ xmllint --noout distributor.wsdl && echo well-formed
well-formed
```
