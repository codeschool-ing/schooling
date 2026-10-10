---
title: Lendo um WSDL
version: 1
---

Um serviço SOAP publica o contrato como um **WSDL**, a Web Services Description Language: um
documento XML que diz quais operações existem, o que entra e sai de cada uma, como as mensagens
viajam e em que endereço. O erro comum é tratá-lo como documentação para pessoas. Ele é escrito
**para programas**: um toolkit de SOAP o lê e constrói um cliente, que é o que a seção depois da
próxima faz. Uma pessoa o lê para descobrir o que o toolkit vai fazer.

Este é o contrato do distribuidor, o mesmo que o substituto da próxima seção serve. Salve-o em
`~/shelf` como `distributor.wsdl`, do mesmo jeito que você salvou o `db.py` na aula 1:

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

São cinco partes, e **cada uma é definida em termos da anterior**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"As cinco partes do distributor.wsdl em fila, cada uma se referindo à parte à sua esquerda. types declara os elementos GetStock, GetStockResponse, PlaceOrder e PlaceOrderResponse. message embrulha um elemento, como em GetStockIn. portType lista as operações de StockPort, cada uma com uma mensagem de entrada e uma de saída. binding diz como StockPort viaja: SOAP 1.1, document, literal, um SOAPAction por operação. service diz onde: http://127.0.0.1:8001/distributor. As três primeiras são abstratas, o que pode ser dito; as duas últimas são concretas, como e onde.\"><defs><marker id=\"l05-wsdl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">types</text><text x=\"30\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStock</text><text x=\"30\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStockResponse</text><text x=\"30\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlaceOrder</text><text x=\"30\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlaceOrderResponse</text><rect x=\"160\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">message</text><text x=\"170\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStockIn</text><text x=\"182\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">= GetStock</text><text x=\"170\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStockOut</text><text x=\"182\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">= …Response</text><line x1=\"160\" y1=\"170\" x2=\"142\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><rect x=\"300\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">portType</text><text x=\"310\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">StockPort</text><text x=\"322\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GetStock</text><text x=\"322\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">PlaceOrder</text><line x1=\"300\" y1=\"170\" x2=\"282\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><rect x=\"440\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"500.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">binding</text><text x=\"450\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">StockBinding</text><text x=\"462\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">document</text><text x=\"462\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">literal</text><text x=\"462\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SOAPAction</text><line x1=\"440\" y1=\"170\" x2=\"422\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><rect x=\"580\" y=\"70\" width=\"120\" height=\"120\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">service</text><text x=\"590\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">StockPort at</text><text x=\"590\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">127.0.0.1:8001</text><text x=\"590\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">/distributor</text><line x1=\"580\" y1=\"170\" x2=\"562\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l05-wsdl-ah)\"></line><text x=\"220.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">abstrato: o que pode ser dito</text><line x1=\"20\" y1=\"44\" x2=\"420\" y2=\"44\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><text x=\"570.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">concreto: como, e onde</text><line x1=\"440\" y1=\"44\" x2=\"700\" y2=\"44\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></line><text x=\"350\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada seta: &quot;é definido em termos de&quot;</text></svg>", "caption": "Um WSDL em cinco partes. As três primeiras descrevem as mensagens e as operações; o binding e o service fixam o protocolo e o endereço."}
```

Ler de cima para baixo, como está escrito, é encontrar os tipos antes de saber para que servem.
Ler **de baixo para cima** segue as perguntas de quem chama, na ordem:

| parte | responde | neste arquivo |
|---|---|---|
| `service` | para onde eu mando? | `http://127.0.0.1:8001/distributor` |
| `binding` | como isso é levado? | SOAP 1.1 sobre HTTP, estilo `document`, corpos `literal` e o `SOAPAction` de cada operação |
| `portType` | quais operações existem? | `GetStock` e `PlaceOrder`, cada uma com uma mensagem de entrada e uma de saída |
| `message` | o que é cada mensagem? | uma parte, que é um elemento do schema |
| `types` | o que esse elemento contém? | um XML Schema: `GetStock` tem um `ISBN` do tipo `xsd:string`, e assim por diante |

## Dois detalhes que decidem o que vai pelo fio

**`document` e `literal` querem dizer que o corpo leva o elemento do schema exatamente como foi
declarado.** Uma requisição `GetStock` é um elemento `GetStock` com um `ISBN` dentro, e nada mais.
Dar ao elemento o nome da operação, como este arquivo faz, se chama convenção *wrapped*. Serviços
mais antigos usam o estilo `rpc` com corpos `encoded`, em que o toolkit acrescenta anotações de tipo
próprias a cada valor. O WS-I Basic Profile, as regras de interoperabilidade que a maioria dos
toolkits segue, proíbe `encoded`, e um serviço que o usa é aquele em que dois toolkits mais
discordam.

**`elementFormDefault="qualified"` põe o namespace em todo elemento, não só no de fora.** É por isso
que a requisição da seção depois da próxima escreve `d:ISBN`, e não um `ISBN` solto. Um serviço cujo
schema diz `qualified` recusa um `ISBN` solto ou não o encontra, conforme o quanto é rigoroso.

## Tipos, com nomes

O schema dá um tipo a cada valor: `QtyAvail` é um `xsd:int`, `UnitPrice` um `xsd:decimal`. O JSON tem
números e strings e nada entre eles; um WSDL consegue dizer que um preço é decimal e não float, e um
toolkit que o lê vai entregar um decimal. O que ele não consegue é tornar os nomes bons. `QtyAvail`,
`NextDelivery` escrita como string comum, um preço em reais: essas são escolhas do distribuidor, e o
contrato só as torna precisas.

O `xmllint` confere que o arquivo que você digitou é XML bem formado. Ele não confere que é um WSDL
válido; o toolkit faz isso quando o lê.

```
ana@api:~/shelf$ xmllint --noout distributor.wsdl && echo well-formed
well-formed
```
