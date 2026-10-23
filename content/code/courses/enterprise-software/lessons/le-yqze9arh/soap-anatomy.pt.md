---
title: Do que é feita uma mensagem SOAP
version: 1
---

Quem chegou à profissão depois de 2010 costuma arquivar o SOAP como "XML sobre HTTP, o jeito
antigo de fazer REST". Essa imagem erra o protocolo de um jeito que importa quando você precisa
conversar com um. **SOAP é um formato de envelope, e o HTTP é só uma das maneiras de um envelope
viajar.** O envelope tem o seu próprio espaço para endereçamento (o header), a sua própria carga (o
body) e o seu próprio jeito de dizer que algo deu errado (o fault), e um serviço é descrito por um
contrato separado, o WSDL, a partir do qual os dois lados podem gerar código. Na Serra Alta, a
maioria dos fluxos SOAP do ESB responde por HTTP, e alguns tiram o mesmo envelope de uma fila MQ,
sem mudança.

## Duas versões, uma forma

O SOAP começou no fim dos anos 1990 com a Microsoft, a DevelopMentor e a UserLand, e foi submetido
ao W3C. **O SOAP 1.1 foi publicado como W3C Note em 2000, e o SOAP 1.2 virou W3C Recommendation em
2003.** O nome começou como sigla, Simple Object Access Protocol; a versão 1.2 abandonou a
expansão, que a essa altura não descrevia nada do que ele fazia. As duas versões estão em produção
em toda parte, e os serviços que o time de Rui construiu a partir de 2015 são SOAP 1.1, que é o
que a maioria dos seus chamadores esperava.

Uma mensagem SOAP é um documento XML com uma raiz, `Envelope`, e dentro dela dois filhos:

- `Header`, opcional, com blocos destinados à infraestrutura e não à aplicação — tokens de
  segurança, endereçamento, contexto de transação. A seção 04 desta aula trata do que foi parar
  ali.
- `Body`, obrigatório, com a carga: a requisição, a resposta ou um `Fault`.

**É o namespace do elemento `Envelope` que diz a versão**, e o receptor confere isso antes de
qualquer outra coisa. O SOAP 1.1 usa `http://schemas.xmlsoap.org/soap/envelope/`; o SOAP 1.2 usa
`http://www.w3.org/2003/05/soap-envelope`. O prefixo na frente — `soap:`, `env:`, `s:`, `ns0:` — é
escolhido por quem escreveu a mensagem e não significa nada sozinho.

## Uma requisição no fio

O Rota, o sistema de planejamento de rotas, precisa saber o tamanho do tanque de cada fazenda e
quando ele foi esvaziado pela última vez. Esse dado mora no Coleta, no IBM i, e em 2016 o time de
Rui pôs na frente dele, no barramento, um serviço SOAP chamado FarmRegistry. Uma das suas operações
é `GetFarmTank`. Por HTTP, uma chamada SOAP 1.1 é sempre um `POST`, e estes são os headers que
importam:

```
POST /services/FarmRegistry HTTP/1.1
Host: esb.serraalta.example
Content-Type: text/xml; charset=utf-8
SOAPAction: "http://schemas.serraalta.example/farm-registry/2016/GetFarmTank"
```

O header `SOAPAction` nomeia a operação, entre aspas, para que um gateway possa rotear a requisição
sem ler o XML. O corpo da requisição é o envelope:

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

Não há bloco de header aqui; o FarmRegistry na verdade exige um, um token de segurança, e a seção
04 o põe de volta. Há dois namespaces em jogo. `soap:` é o do próprio SOAP; `fr:` é o da Serra
Alta, e o `2016` no fim dele é uma versão: um FarmRegistry com mensagens incompatíveis ganharia um
namespace novo, e um cliente gerado a partir do antigo recusaria as mensagens novas em vez de
lê-las errado. A resposta volta com status 200:

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

Um tanque de 4.000 litros que enche 1.150 litros por dia comporta um pouco menos de três dias e
meio de leite, mas a regra da empresa é mais rígida que o tanque: nenhuma fazenda espera mais de 48
horas. O Rota usa os dois números.

## Um fault

Um código de fazenda que não existe não é uma pane; é uma resposta. O SOAP tem uma estrutura para
isso, o `Fault`, que toma o lugar da resposta dentro do body:

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

Leia de fora para dentro. `faultcode` diz de quem é a culpa: `soap:Client` significa que a
requisição estava errada e que mandá-la de novo vai dar a mesma resposta; `soap:Server` significa
que a requisição pode estar certa e o serviço falhou. `faultstring` é para uma pessoa. `detail` é
para um programa: um elemento tipado, declarado no contrato, que o cliente pode transformar num erro
com significado. No SOAP 1.1, os filhos `faultcode`, `faultstring` e `detail` não levam prefixo de
namespace; isso é a especificação, não um descuido.

**Por HTTP, o SOAP 1.1 manda todo fault com status 500 Internal Server Error.** Um cliente que trata
todo 500 como "o servidor caiu, tente mais tarde" vai repetir para sempre uma requisição errada, e
vai jogar fora o único elemento que dizia por quê.

## O que mudou na 1.2

| | SOAP 1.1 | SOAP 1.2 |
|---|---|---|
| namespace do envelope | `http://schemas.xmlsoap.org/soap/envelope/` | `http://www.w3.org/2003/05/soap-envelope` |
| content type por HTTP | `text/xml` | `application/soap+xml` |
| como a operação é nomeada | um header HTTP `SOAPAction` | um parâmetro `action` no content type |
| estrutura do fault | `faultcode`, `faultstring`, `detail` | `Code` com `Value`, `Reason` com `Text`, `Detail` |
| os dois códigos de fault principais | `Client`, `Server` | `Sender`, `Receiver` |
| status HTTP de um fault | sempre 500 | 400 para um fault `Sender`, 500 nos outros casos |

Você vai encontrar SOAP 1.2 sem sair do Brasil: os web services pelos quais toda NF-e chega à
autoridade tributária do estado são SOAP 1.2, e as cerca de 1.400 notas que a Serra Alta emite num
dia útil comum viajam por esse caminho.

## O contrato

A parte do SOAP que as empresas mais valorizavam não está na mensagem. **Um documento WSDL (Web
Services Description Language) descreve um serviço de forma completa o bastante para que uma
ferramenta gere o cliente a partir dele**: as operações, as mensagens que cada uma recebe e
devolve, os tipos de cada campo em XML Schema, os faults e o endereço. Este é o do FarmRegistry, em
WSDL 1.1, a versão que quase todo serviço SOAP que você vai encontrar usa:

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

É longo para uma operação só, e cada parte responde a uma pergunta diferente:

| parte | a pergunta que ela responde |
|---|---|
| `types` | como é cada elemento, em XML Schema: `tankLitres` é um inteiro, `lastCollection` uma data e hora com o seu fuso |
| `message` | que elementos viajam juntos como uma entrada, uma saída ou um fault |
| `portType` | que operações existem e o que cada uma recebe, devolve e com que pode falhar — a interface abstrata |
| `binding` | como essa interface vai para o fio: SOAP 1.1 sobre HTTP, estilo document, XML literal, qual `SOAPAction` |
| `service` | onde ele mora: o endereço |

Uma armadilha na leitura: dentro de um WSDL, `soap:` está ligado a
`http://schemas.xmlsoap.org/wsdl/soap/`, o vocabulário do WSDL para descrever um binding SOAP 1.1.
Não é o namespace do envelope que você viu nas mensagens, embora os dois compartilhem o prefixo por
convenção.

`style="document"` com `use="literal"` significa que o body carrega exatamente os elementos que o
schema declara. Serviços mais antigos usam um estilo RPC com o sistema de tipos "encoded" do
próprio SOAP, que ferramentas diferentes liam de formas diferentes. O WS-I Basic Profile, publicado
em 2004 para que as ferramentas Java e .NET concordassem entre si, excluiu o estilo encoded, e
document/literal é o que você vai encontrar.

## Por que as empresas gostavam dele

Ponha esse WSDL na ferramenta certa e sai uma classe com um método `getFarmTank(String)` que
devolve um objeto com quatro campos tipados, e uma exceção tipada para `FarmNotFound`. **Um time
conseguia integrar com um serviço que nunca tinha visto, e o compilador avisava quando ele mandava o
tipo errado.** Em 2005, quando a alternativa era um PDF descrevendo um arquivo de largura fixa,
isso era um avanço grande. É também a parte do SOAP que vale lembrar quando você encontrar os seus
descendentes. O OpenAPI deu a mesma coisa ao JSON sobre HTTP anos depois, e um contrato que uma
máquina consegue ler continua sendo a melhor defesa contra dois times que acreditam, cada um, ter
combinado uma coisa diferente.

O preço foi pago no header, que é a próxima seção.
