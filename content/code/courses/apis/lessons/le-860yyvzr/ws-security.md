---
title: WS-Security, and where SOAP's own security shows up
version: 1
---

A REST API puts its credentials in an HTTP header and relies on TLS to protect them on the way;
lessons 7, 8 and 13 are about doing that well. SOAP has a standard of its own that works one level
up, inside the envelope: **WS-Security**, published by OASIS in 2004. Its pieces go in the
`Header`:

| piece | what it is for |
|---|---|
| `UsernameToken` | a user name and a password, or a digest of the password |
| `BinarySecurityToken` | an X.509 certificate that identifies the sender |
| a SAML assertion | an identity issued by somebody both sides trust; lesson 9 meets SAML |
| `Timestamp` | when the message was made and when it stops being acceptable |
| XML Signature | proof that named parts of the message were not changed, and who signed them |
| XML Encryption | parts of the message that only the receiver can read |

**The difference from TLS is where the protection lives.** TLS protects a connection, from one end
to the other, and ends at whatever terminates it. A WS-Security signature belongs to the message:
it is still there after a gateway, a queue or an archive has passed it along, and it can be checked
by whoever reads the message years later. That is why the systems that carry legal weight use it;
the NF-e from the first section is an XML document with a signature inside it.

## A token, made by zeep

The stand-in asks for no credentials, but zeep can show you what a token looks like without sending
anything. `wsse.py` builds the envelope it would send with a `UsernameToken`, using a password made
up for the purpose, and prints it:

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

The `Header` is no longer empty, and the password is not in it: with `use_digest=True`, `Password`
is a **digest** of the nonce, the creation time and the password together, so the same password
gives a different value in every message. The nonce and `Created` are how a careful server refuses a captured message
sent again: it rejects a `Created` that is too old and a nonce it has already seen. The digest has
a cost on the other side, too. To check it, the server needs the password itself, so it cannot
store only a hash of it, which is the thing lesson 10 insists on. Without `use_digest`, the
`Password` element would carry the password in plain text, and the message would be safe only
inside TLS. In practice partners ask for TLS **and** a token or a signature, and often for mutual
TLS, where the client presents a certificate too.

## Defending a SOAP endpoint

Every SOAP message is XML, and an XML parser will do things for a document that nobody asked it to
do for a message: expand entities the document declares, fetch external ones, follow a document
type declaration. Those features are the root of a known family of attacks on XML endpoints, and
the defence is the same everywhere: turn them off. **SOAP 1.1 says a message must not contain a
document type declaration at all**, so a service can refuse one before parsing, and the stand-in
does:

```
ana@api:~/shelf$ { echo '<!DOCTYPE x>'; cat getstock.xml; } | curl -s localhost:8001/distributor -H 'Content-Type: text/xml; charset=utf-8' -H 'SOAPAction: "http://distributor.example/stock/GetStock"' --data-binary @- | xmllint --xpath 'string(//faultstring)' -
a SOAP message must not contain a DTD
```

A client parses XML too, the answers it receives. zeep's own settings say what it allows:

```
ana@api:~/shelf$ python3 -c 'import zeep; s = zeep.Settings(); print(s.forbid_dtd, s.forbid_entities, s.forbid_external)'
False True True
```

`forbid_dtd` is `False`, so a declaration in an answer is parsed; `forbid_entities` and
`forbid_external` are `True`, so the entities it declares are refused and nothing outside the
message is fetched. Whichever toolkit you use, find its equivalents and know their values.

**Signatures need one more check.** A signature proves that the signed element was not changed; it
does not prove that the element your code then reads is the signed one. A message can carry a
valid signature over one copy of a value and a second copy elsewhere, and code that checks the
first and reads the second has verified nothing. The defence is a maintained library rather than
your own verification, and code that processes the element the signature covers, found through the
signature, and nothing else.
