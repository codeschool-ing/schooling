---
title: Chamando com o curl, e lendo as falhas
version: 1
---

**Uma requisição SOAP é um POST HTTP comum cujo corpo calha de ser um envelope.** O curl a manda
como manda qualquer outra coisa: o envelope num arquivo, dois cabeçalhos e o endereço. O que muda
é a leitura, porque a resposta é XML numa linha só, e para isso você precisa de mais uma ferramenta.

## xmllint

O `xmllint` vem da libxml2, a biblioteca de XML que a maioria dos programas Linux já usa. Ele
formata XML para gente ler, confere se um documento está bem formado e avalia XPath, que é o
assunto da seção 06. No Ubuntu 24.04 e no WSL ele é um pacote:

```sh
sudo apt-get update
sudo apt-get install -y libxml2-utils
```

O macOS traz o xmllint com o sistema, o que não foi testado para este curso. Confira que ele
responde; ele imprime a versão na saída de erro, daí o `2>&1`:

```
ana@laptop:~/boxoffice$ xmllint --version 2>&1 | head -1
xmllint: using libxml version 20914
```

`20914` é como a libxml2 escreve a versão 2.9.14.

## O envelope

O pedido de nota é um arquivo. É o pedido de três lugares do sh-103 da lição 1, 19500 centavos.
Salve como `soap/issue.xml`:

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

O prefixo `soap` está ligado ao namespace do SOAP 1.1, então este envelope fala 1.1. O prefixo
`inv` está ligado a `urn:example:invoice:v1`, o `targetNamespace` do WSDL, que é como um serviço de
verdade sabe que esses elementos são dele; as expressões regulares do substituto ignoram o prefixo.
O `soap:Header` vazio poderia ficar de fora; ele está ali para mostrar onde iria uma assinatura ou
um token de segurança.

## Uma requisição que funciona

O `--data-binary` manda o arquivo byte a byte. O `-d` tiraria as quebras de linha, que o XML
aguenta e um documento assinado pode não aguentar. Os dois cabeçalhos são o `content-type` do SOAP
1.1 e o `SOAPAction` do binding, com aspas e tudo:

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

`200 OK`, um envelope, e dentro do `Body` dele o `IssueInvoiceResponse` com um número de nota. Numa
linha só é difícil de ler, e o `xmllint --format -` indenta o que chegar pela entrada padrão:

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

A mesma requisição uma segunda vez recebeu o número seguinte. O `issuedAt` e o `verificationCode`
que você receber vão ser diferentes destes: o primeiro é o momento da chamada, em UTC como diz o
`Z`, e o segundo é calculado a partir do número, do pedido e do valor.

## Três falhas que o serviço deveria dar

**Um teste de serviço SOAP passa a maior parte do tempo aqui.** Cada requisição abaixo quebra uma
coisa e espera uma falha. O `sed` muda o envelope no caminho até o curl, e o `@-` diz ao curl para
ler o corpo do pipe, então o arquivo no disco continua como está.

Um CPF de três dígitos:

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

**HTTP `500` para um erro que é inteiramente do cliente, e aqui isso está certo.** A lição 1 chamou
de defeito um `500` para uma requisição malformada, e numa API REST é. O SOAP 1.1 responde toda
falha com `500`, então o status só diz *vem uma falha aí*. A culpa está no `faultcode`:
`soap:Client`, com uma `faultstring` que nomeia o campo.

Nenhum cabeçalho `SOAPAction`:

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

Uma falha `soap:Client` que diz que ação ela esperava. Alguns serviços ignoram o cabeçalho e leem o
`Body` no lugar dele; este o exige, e o WSDL disse a você o valor.

O mesmo envelope rotulado como SOAP 1.2:

```
ana@laptop:~/boxoffice$ curl -si localhost:8085/invoice -H 'content-type: application/soap+xml' -H 'SOAPAction: "urn:example:invoice:v1#IssueInvoice"' --data-binary @soap/issue.xml
HTTP/1.1 415 Unsupported Media Type
Date: Sat, 10 Oct 2026 07:35:15 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked
```

`415 Unsupported Media Type`, sem envelope nenhum. O serviço fala só SOAP 1.1, e recusa o tipo do
1.2 antes de ler qualquer coisa.

## Uma falha que é um defeito

O WSDL diz que `amountCents` tem de aparecer. Tire a linha dele do envelope:

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

**`soap:Server` para uma requisição que quebrou o contrato.** O serviço culpou a si mesmo, e a
`faultstring` é um erro de JavaScript, o sinal de uma verificação que nunca foi escrita: o código
chamou `.trim()` num campo que não estava ali. Duas coisas estão erradas, e um relatório de defeito
nomeia as duas:

| | |
|---|---|
| **título** | IssueInvoice sem `amountCents` responde `soap:Server` e mostra um erro interno |
| **passos** | mandar `soap/issue.xml` com o elemento `amountCents` removido |
| **esperado** | `soap:Client`, com uma `faultstring` que nomeie `amountCents`, como para um CPF curto |
| **obtido** | `soap:Server`, `faultstring` *Cannot read properties of undefined (reading 'trim')* |
| **por que importa** | quem chama e repete falhas `Server` vai repetir uma requisição que nunca vai dar certo; a mensagem conta a um estranho em que o serviço foi escrito |

O segundo ponto é um achado de segurança, além de uma questão de capricho. Uma mensagem de erro que
repete o funcionamento interno não ajuda ninguém que usa o serviço e ajuda qualquer um que o esteja
sondando, então quem testa confere que uma falha diz o que estava errado na requisição e nada sobre
o código.
