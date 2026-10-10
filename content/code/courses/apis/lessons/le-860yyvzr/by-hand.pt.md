---
title: Uma chamada SOAP à mão
version: 1
---

**Uma chamada SOAP é um `POST` HTTP com um corpo XML e dois cabeçalhos.** Nada nela precisa de uma
biblioteca SOAP, e fazer uma chamada à mão é o melhor jeito de ver o que uma biblioteca esconde:
quando um toolkit e um serviço discordam, é neste nível que você descobre por quê.

A requisição é um arquivo. Salve-o como `getstock.xml`:

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

É o envelope da primeira seção: um `Header` vazio e um `Body` com um elemento `GetStock` no
namespace do distribuidor, com o ISBN de *A Hora da Estrela* dentro. O prefixo `d:` é ligado a esse
namespace no `Envelope`, e é isso que faz `d:GetStock` significar o `GetStock` do distribuidor e de
mais ninguém.

Envie com os dois cabeçalhos que o SOAP 1.1 pede:

```
ana@api:~/shelf$ curl -si localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @getstock.xml; echo
HTTP/1.1 200 OK
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:40:47 GMT
Content-Type: text/xml; charset=utf-8
Content-Length: 301

<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GetStockResponse xmlns="http://distributor.example/stock"><ISBN>9786500000030</ISBN><QtyAvail>25</QtyAvail><UnitPrice>18.90</UnitPrice><NextDelivery>20261012</NextDelivery></GetStockResponse></soap:Body></soap:Envelope>
```

- `Content-Type: text/xml` é o tipo de mídia do SOAP 1.1. Na versão 1.2 seria
  `application/soap+xml`.
- `SOAPAction` nomeia a operação, com o valor que o binding deu a ela no WSDL. As aspas fazem parte
  do valor.

A resposta é **200** e uma linha longa de XML, porque um programa a escreveu para um programa. O
`xmllint --format` a organiza para uma pessoa, lendo da entrada padrão quando recebe `-`:

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

Vinte e cinco cópias a 18.90 cada, e uma data de entrega escrita com oito dígitos. Os nomes são do
distribuidor, e as unidades também.

## Para que servem os cabeçalhos e o namespace

Deixe de fora o `SOAPAction`, e este serviço responde com uma falha antes de ler o corpo. Muitos
servidores SOAP despacham por esse cabeçalho, então ele é a primeira coisa que conferem. O
`xmllint --xpath` tira o único valor que interessa da resposta:

```
ana@api:~/shelf$ curl -s localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' --data-binary @getstock.xml | xmllint --xpath 'string(//faultstring)' -
the SOAPAction header is missing
```

O namespace importa do mesmo jeito. O schema diz `qualified`, então o ISBN tem de ser `d:ISBN`;
escreva um `ISBN` solto e o serviço procura um elemento que não está lá:

```
ana@api:~/shelf$ sed 's/d:ISBN/ISBN/g' getstock.xml | curl -s localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @- | xmllint --xpath 'string(//faultstring)' -
ISBN  is not in the catalogue
```

**O serviço não disse que o seu XML estava errado. Ele procurou um ISBN vazio**, o buraco entre os
dois espaços da resposta, porque um elemento `ISBN` sem namespace é, para este schema, outro
elemento, que ninguém pediu. Essa resposta parece um problema de dados e é um problema de namespace,
e é um jeito comum de um envelope escrito à mão falhar.

## O que o HTTP deixou de saber

Compare com a aula 1. `GetStock` só lê, e no REST seria um `GET`, que todo cache, proxy e cliente
que repete requisições sabe que é seguro. Aqui é um `POST` para o mesmo endereço do `PlaceOrder`,
então nada entre os dois programas consegue distinguir uma pergunta de um pedido. **Se uma chamada
SOAP pode ser repetida está escrito na prosa do contrato, quando está, e nunca no protocolo.** A
seção sobre resiliência volta ao que isso custa.
