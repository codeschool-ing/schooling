---
title: WS-Security, e onde a segurança própria do SOAP aparece
version: 1
---

Uma API REST põe as credenciais num cabeçalho HTTP e confia no TLS para protegê-las no caminho; as
aulas 7, 8 e 13 tratam de fazer isso bem. O SOAP tem um padrão próprio que trabalha um nível acima,
dentro do envelope: o **WS-Security**, publicado pela OASIS em 2004. As peças dele vão no `Header`:

| peça | para que serve |
|---|---|
| `UsernameToken` | um nome de usuário e uma senha, ou um digest da senha |
| `BinarySecurityToken` | um certificado X.509 que identifica quem envia |
| uma asserção SAML | uma identidade emitida por alguém em quem os dois lados confiam; a aula 9 apresenta o SAML |
| `Timestamp` | quando a mensagem foi feita e quando ela deixa de ser aceitável |
| XML Signature | prova de que partes nomeadas da mensagem não foram alteradas, e de quem as assinou |
| XML Encryption | partes da mensagem que só o destinatário consegue ler |

**A diferença para o TLS é onde a proteção mora.** O TLS protege uma conexão, de uma ponta à outra,
e termina onde quer que ela seja encerrada. Uma assinatura WS-Security pertence à mensagem: continua
lá depois de um gateway, uma fila ou um arquivo morto a repassarem, e pode ser conferida por quem ler
a mensagem anos depois. É por isso que os sistemas com peso legal a usam; a NF-e da primeira seção é
um documento XML com uma assinatura dentro.

## Um token, feito pelo zeep

O substituto não pede credenciais, mas o zeep consegue mostrar como é um token sem enviar nada. O
`wsse.py` monta o envelope que mandaria com um `UsernameToken`, usando uma senha inventada para isso,
e o imprime:

```python
# shelf/wsse.py
"""Print the envelope zeep would send with a WS-Security UsernameToken, without sending it."""
from lxml import etree
import zeep
from zeep.wsse.username import UsernameToken

token = UsernameToken("shelf", "not-a-real-password", use_digest=True)
client = zeep.Client("distributor.wsdl", wsse=token)
envelope = client.create_message(client.service, "GetStock", ISBN="9786500000030")
print(etree.tostring(envelope, pretty_print=True).decode(), end="")
```

```
ana@api:~/shelf$ python3 wsse.py
<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
  <soap-env:Header>
    <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <wsse:UsernameToken>
        <wsse:Username>shelf</wsse:Username>
        <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest">hd5c619t3FjTsGN7TGqGpUl/aVE=</wsse:Password>
        <wsse:Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">/5Ul494LFNjc7pS+UVVpAA==</wsse:Nonce>
        <wsu:Created xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">2026-10-10T04:41:13+00:00</wsu:Created>
      </wsse:UsernameToken>
    </wsse:Security>
  </soap-env:Header>
  <soap-env:Body>
    <ns0:GetStock xmlns:ns0="http://distributor.example/stock">
      <ns0:ISBN>9786500000030</ns0:ISBN>
    </ns0:GetStock>
  </soap-env:Body>
</soap-env:Envelope>
```

O `Header` não está mais vazio, e a senha não está nele: com `use_digest=True`, o `Password` é um
**digest** do nonce, do horário de criação e da senha juntos, então a mesma senha dá um valor
diferente em cada mensagem. O nonce e o `Created` são como um servidor cuidadoso recusa uma mensagem
capturada e enviada de novo: ele rejeita um `Created` velho demais e um nonce que já viu. O digest
também tem um custo do outro lado. Para conferi-lo, o servidor precisa da própria senha, então não
pode guardar só um hash dela, que é justamente o que a aula 10 exige. Sem `use_digest`, o elemento
`Password` levaria a senha em texto puro, e a mensagem só estaria segura dentro do TLS. Na prática os
parceiros pedem TLS **e** um token ou uma assinatura, e muitas vezes TLS mútuo, em que o cliente
também apresenta um certificado.

## Defendendo um endpoint SOAP

Toda mensagem SOAP é XML, e um parser de XML faz coisas por um documento que ninguém pediu que fizesse
por uma mensagem: expande as entidades que o documento declara, busca as externas, segue uma
declaração de tipo de documento. Esses recursos são a raiz de uma família conhecida de ataques a
endpoints XML, e a defesa é a mesma em todo lugar: desligá-los. **O SOAP 1.1 diz que uma mensagem não
pode conter declaração de tipo de documento nenhuma**, então um serviço pode recusar uma antes de ler
o XML, e o substituto faz isso:

```
ana@api:~/shelf$ { echo '<!DOCTYPE x>'; cat getstock.xml; } | curl -s localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @- | xmllint --xpath 'string(//faultstring)' -
a SOAP message must not contain a DTD
```

Um cliente também lê XML, o das respostas que recebe. As configurações do próprio zeep dizem o que
ele permite:

```
ana@api:~/shelf$ python3 -c 'import zeep; s = zeep.Settings(); print(s.forbid_dtd, s.forbid_entities, s.forbid_external)'
False True True
```

`forbid_dtd` é `False`, então uma declaração numa resposta é lida; `forbid_entities` e
`forbid_external` são `True`, então as entidades que ela declara são recusadas e nada fora da
mensagem é buscado. Seja qual for o seu toolkit, encontre os equivalentes e saiba os valores deles.

**Assinaturas precisam de mais uma verificação.** Uma assinatura prova que o elemento assinado não
foi alterado; ela não prova que o elemento que o seu código lê depois é o assinado. Uma mensagem pode
levar uma assinatura válida sobre uma cópia de um valor e uma segunda cópia em outro lugar, e o código
que confere a primeira e lê a segunda não verificou nada. A defesa é uma biblioteca mantida em vez de
uma verificação sua, e um código que processa o elemento coberto pela assinatura, encontrado por meio
dela, e nada mais.
