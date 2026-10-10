---
title: "SAML: o mesmo trabalho em XML assinado"
version: 1
---

**O SAML 2.0 resolve o problema que o OpenID Connect resolve, autenticar uma pessoa numa aplicação
com uma conta guardada em outro lugar, e resolveu primeiro**: a OASIS o publicou em 2005, nove anos
antes do OpenID Connect. O lugar dele é a empresa. Quando uma firma compra uma ferramenta e quer que
os funcionários entrem com as contas de trabalho, em geral se espera que a ferramenta fale SAML.

O vocabulário é outro e os papéis se correspondem:

| SAML | o que é | o mais próximo no OpenID Connect |
|---|---|---|
| **provedor de identidade** (*identity provider*, IdP) | o serviço que conhece a pessoa e a autentica | o servidor de autorização |
| **provedor de serviço** (*service provider*, SP) | a aplicação que a pessoa quer usar | o cliente |
| **asserção** (*assertion*) | um documento XML assinado dizendo quem a pessoa é | o ID token |
| **metadados** (*metadata*) | um arquivo XML que cada lado publica: endereços, certificado | o discovery e o JWKS |

## O binding POST pelo navegador

Os dois servidores nunca conversam entre si durante uma entrada. **A asserção viaja pelo navegador,
num formulário que a página do provedor de identidade envia sozinha ao provedor de serviço**, e é
por isso que tudo depende da assinatura dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 500\" role=\"img\" aria-label=\"O binding POST do SAML pelo navegador. Uma vez, na configuração, o provedor de serviço e o provedor de identidade trocam metadados com endereços e o certificado. Na entrada: o navegador pede uma página ao provedor de serviço, é redirecionado ao provedor de identidade com um SAMLRequest, a Ana entra lá, o provedor de identidade responde com uma página cujo formulário leva o SAMLResponse assinado, o navegador o envia por POST ao /saml/acs do provedor de serviço, que confere a assinatura com o certificado que já tem e depois a audiência, o destinatário, os horários, o InResponseTo e o ID, e responde com um cookie de sessão. Os dois servidores nunca conversam durante a entrada.\"><defs><marker id=\"l09-saml-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"100.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">navegador</text><text x=\"100.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Ana</text><line x1=\"100\" y1=\"60\" x2=\"100\" y2=\"480\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"300\" y=\"14\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor de serviço</text><text x=\"380.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">books.shelf.example</text><line x1=\"380\" y1=\"60\" x2=\"380\" y2=\"480\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"550\" y=\"14\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor de identidade</text><text x=\"630.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">idp.shelf.example</text><line x1=\"630\" y1=\"60\" x2=\"630\" y2=\"480\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"380\" y1=\"92\" x2=\"630\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l09-saml-ah)\" marker-start=\"url(#l09-saml-ah)\"></line><text x=\"505.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">metadados, uma vez, na configuração</text><text x=\"505.0\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">endereços e o certificado</text><line x1=\"100\" y1=\"150\" x2=\"380\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /library</text><line x1=\"380\" y1=\"196\" x2=\"100\" y2=\"196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">302 para o IdP, com um SAMLRequest</text><line x1=\"100\" y1=\"242\" x2=\"630\" y2=\"242\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"365.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET /sso?SAMLRequest=…</text><line x1=\"630\" y1=\"288\" x2=\"100\" y2=\"288\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\" marker-start=\"url(#l09-saml-ah)\"></line><text x=\"365.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a Ana entra</text><line x1=\"630\" y1=\"334\" x2=\"100\" y2=\"334\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"365.0\" y=\"326.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">200: um formulário com o SAMLResponse assinado</text><line x1=\"100\" y1=\"380\" x2=\"380\" y2=\"380\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"372.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">POST /saml/acs  SAMLResponse=…</text><rect x=\"392\" y=\"390\" width=\"236\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"404\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">confere a assinatura com o certificado</text><text x=\"510\" y=\"419\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">do IdP que já tem, depois Audience,</text><text x=\"510\" y=\"434\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Recipient, horários, ID</text><line x1=\"380\" y1=\"452\" x2=\"100\" y2=\"452\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l09-saml-ah)\"></line><text x=\"240.0\" y=\"444.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">302 para /library, com um cookie de sessão</text><text x=\"20\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"20\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"20\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"20\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"20\" y=\"334\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"20\" y=\"380\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"20\" y=\"452\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text></svg>", "caption": "O binding POST pelo navegador. A asserção chega ao provedor de serviço pelo navegador, então a assinatura, conferida com um certificado trocado antes, é a única coisa que responde por ela.", "same": ["Ana"]}
```

O provedor de serviço tem o certificado do provedor de identidade antes de qualquer entrada, dos
metadados trocados quando os dois foram configurados. Ele verifica a asserção com **esse**
certificado, nunca com um que a mensagem traga junto, já que uma mensagem pode trazer o certificado
que quiser.

## Uma asserção, assinada e alterada

O laboratório não tem uma biblioteca de SAML, e uma não faz falta para ver o que importa: o que o
provedor de identidade assina, e o que a conferência do provedor de serviço faz com uma alteração.
Primeiro uma chave e um certificado para o provedor de identidade. O `genpkey -quiet` gera a chave
sem imprimir o progresso, e o `req -x509` faz a partir dela um certificado autoassinado:

```
ana@api:~/shelf$ openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out saml/idp-key.pem
ana@api:~/shelf$ openssl req -x509 -new -key saml/idp-key.pem -subj /CN=idp.shelf.example -days 365 -out saml/idp-cert.pem
ana@api:~/shelf$ openssl x509 -in saml/idp-cert.pem -noout -subject -enddate
subject=CN = idp.shelf.example
notAfter=Oct 10 04:31:04 2027 GMT
```

Agora a asserção. Salve-a como `~/shelf/saml/assertion.xml`. Ela é um modelo: o elemento
`ds:Signature` está lá com os valores vazios, e assinar os preenche. Os horários nela são valores
fixos, já que nada neste exercício os confere:

```xml
<!-- shelf/saml/assertion.xml -->
<saml:Assertion xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
                ID="_8f2c41d6e0a94b7f" Version="2.0" IssueInstant="2026-10-10T12:00:00Z">
  <saml:Issuer>https://idp.shelf.example</saml:Issuer>
  <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
      <ds:Reference URI="#_8f2c41d6e0a94b7f">
        <ds:Transforms>
          <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
          <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
        </ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
        <ds:DigestValue/>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue/>
  </ds:Signature>
  <saml:Subject>
    <saml:NameID>ana@shelf.example</saml:NameID>
    <saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
      <saml:SubjectConfirmationData InResponseTo="_req4c1e" NotOnOrAfter="2026-10-10T12:05:00Z"
                                    Recipient="https://books.shelf.example/saml/acs"/>
    </saml:SubjectConfirmation>
  </saml:Subject>
  <saml:Conditions NotBefore="2026-10-10T11:59:30Z" NotOnOrAfter="2026-10-10T12:05:00Z">
    <saml:AudienceRestriction>
      <saml:Audience>https://books.shelf.example/saml</saml:Audience>
    </saml:AudienceRestriction>
  </saml:Conditions>
  <saml:AuthnStatement AuthnInstant="2026-10-10T12:00:00Z">
    <saml:AuthnContext>
      <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml:AuthnContextClassRef>
    </saml:AuthnContext>
  </saml:AuthnStatement>
  <saml:AttributeStatement>
    <saml:Attribute Name="role">
      <saml:AttributeValue>reader</saml:AttributeValue>
    </saml:Attribute>
  </saml:AttributeStatement>
</saml:Assertion>
```

Leia de cima para baixo. `Issuer` diz qual é o provedor de identidade. `Subject` diz quem é a
pessoa, e o `SubjectConfirmationData` dele diz a qual pedido isto responde (`InResponseTo`), onde
pode ser entregue (`Recipient`) e até quando. `Conditions` dá a janela em que vale e o único
provedor de serviço a que se destina (`Audience`). `AuthnStatement` diz como a pessoa provou quem
era. `AttributeStatement` leva fatos sobre ela, aqui um papel.

A `Reference` da assinatura aponta para a asserção pelo `ID` dela. **O `--id-attr:ID` diz ao
`xmlsec1` qual atributo guarda o id de um elemento**, já que o XML não diz isso sozinho, e assinar
preenche o digest e o valor da assinatura:

```
ana@api:~/shelf$ xmlsec1 --sign --privkey-pem saml/idp-key.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion --output saml/signed.xml saml/assertion.xml
ana@api:~/shelf$ sed -n '/<ds:DigestValue>/p; /<ds:SignatureValue>/,/<\/ds:SignatureValue>/p' saml/signed.xml
        <ds:DigestValue>VjIXV2lRxa4hMowfNm8k5ZxkaTdNjtJpl0a5Cfae+fs=</ds:DigestValue>
    <ds:SignatureValue>T8t3L0jchEw03By2w/qZ0Mc2EVPtDcJsy18aVy96zt72YEOukRHb0rhQiLWq3yJ9
oBZlyGeRdM+PMc4VAF8UDv8vfmdPdoLgsdVpzscl8TWPLa1J+V++Z6Tg1JxeDyQl
Zytq5m9fw2wGDzbL7fpo2wLVqWWNfIQliyXPhPbk5ocSGQ/rd707Uk7+B6SDO9Tr
Ydvm4jlg5+YzUQdYdnsYvKjAQ36uF0rfTlubVje0uv2m7OJa1BmmZ2Kp+8TGXrDF
Wt97mTdSbXkGdBkhnqld+SaZcYeGa+LDHEA/wd84WkRov42HxonjuJZnA+A7D6sO
ms3U2OutI0+LnP+uPqLigw==</ds:SignatureValue>
```

O digest é um SHA-256 da própria asserção, então, se o seu arquivo for o da lição byte por byte, o
seu digest é o de cima. O valor da assinatura depende também da chave, e o seu é outro.

A conferência do provedor de serviço, com o certificado do provedor de identidade:

```
ana@api:~/shelf$ xmlsec1 --verify --pubkey-cert-pem saml/idp-cert.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion saml/signed.xml
OK
SignedInfo References (ok/all): 1/1
Manifests References (ok/all): 0/0
```

Agora troque uma palavra, `reader` por `admin`, como qualquer coisa no caminho pelo navegador
poderia trocar:

```
ana@api:~/shelf$ sed 's/>reader</>admin</' saml/signed.xml > saml/changed.xml
ana@api:~/shelf$ diff saml/signed.xml saml/changed.xml
43c43
<       <saml:AttributeValue>reader</saml:AttributeValue>
---
>       <saml:AttributeValue>admin</saml:AttributeValue>
ana@api:~/shelf$ xmlsec1 --verify --pubkey-cert-pem saml/idp-cert.pem --id-attr:ID urn:oasis:names:tc:SAML:2.0:assertion:Assertion saml/changed.xml
func=xmlSecOpenSSLEvpDigestVerify:file=digests.c:line=355:obj=sha256:subj=unknown:error=12:invalid data:data and digest do not match
FAIL
SignedInfo References (ok/all): 0/1
Manifests References (ok/all): 0/0
Error: failed to verify file "saml/changed.xml"
```

**O digest do elemento assinado não bate mais com o que está dentro da assinatura**, então a
referência falha e o arquivo também. Sem a assinatura a alteração seria invisível: o XML continua
bem formado, e um provedor de serviço que só o lesse daria à Ana o papel de administradora.

## O que a assinatura não confere

Os horários da asserção são uma janela de cinco minutos e meio em 10 de outubro de 2026, e quando
quer que você rode isto, quase certamente está fora dela; o `xmlsec1` imprimiu `OK` mesmo assim,
porque ele confere assinaturas e não sabe nada de SAML. **Uma assinatura válida diz quem escreveu a
asserção e que ninguém a mudou; todo o resto cabe ao provedor de serviço conferir**:

- `Audience` é este provedor de serviço, e `Recipient` é o endereço em que ela chegou;
- a hora atual está entre `NotBefore` e `NotOnOrAfter`;
- `InResponseTo` cita um pedido que este provedor de serviço enviou, e o `ID` da asserção não foi
  visto antes, o que impede que a mesma asserção seja enviada duas vezes;
- o elemento que a aplicação lê é o elemento que a assinatura cobre. Um documento XML pode levar
  mais de uma asserção, e uma conferência que verifica uma e lê outra não verificou nada.

Essa última regra é o motivo de ninguém dever ler SAML com código próprio. **Use uma biblioteca de
SAML mantida do lado do provedor de serviço**, e mantenha-a atualizada: os erros deste formato
estão nos cantos dele, e há anos vêm sendo achados em bibliotecas.
