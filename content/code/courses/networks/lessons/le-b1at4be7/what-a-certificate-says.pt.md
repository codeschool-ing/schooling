---
title: O que um certificado diz
version: 1
---

Um certificado é uma chave pública com uma declaração junto: "esta chave pertence a estes nomes, até
esta data", assinada por alguém que conferiu. O `openssl s_client` busca o que `www.example.com` manda,
e o `openssl x509` imprime os campos que importam:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates -ext subjectAltName,basicConstraints,extendedKeyUsage
subject=CN = www.example.com
issuer=O = Example Trust Services, CN = Example Issuing CA 1
notBefore=Sep 25 17:03:48 2026 GMT
notAfter=Dec 24 17:03:48 2026 GMT
X509v3 Subject Alternative Name: 
    DNS:www.example.com, DNS:example.com, DNS:shop.example.com
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
X509v3 Basic Constraints: critical
    CA:FALSE
```

- **`subject`**: sobre quem é o certificado, `CN = www.example.com`. O *common name* é o lugar antigo
  do nome, mantido para pessoas lerem.
- **`issuer`**: quem assinou, `Example Issuing CA 1`. A seção 03 o segue.
- **`notBefore` e `notAfter`**: a validade, em GMT. Este vale por 90 dias, de setembro a dezembro.
- **`Subject Alternative Name`**: os nomes para os quais ele vale, e **o campo que os clientes de fato
  conferem**. Um certificado aqui cobre três nomes: `www.example.com`, `example.com` e
  `shop.example.com`. Um nome fora dessa lista falha, diga o que disser o subject.
- `Extended Key Usage: TLS Web Server Authentication` o limita a identificar servidores, e `CA:FALSE`
  diz que ele não pode assinar outros certificados.

A **chave privada** que corresponde ao certificado nunca sai do servidor. O certificado é público, e é
mandado a todo mundo que conecta; a chave é o que prova que o servidor é o dono dele, no
`CertificateVerify` do handshake da aula 5. Uma chave vazada quer dizer que outra pessoa pode ser este
servidor, e o único conserto é uma chave nova e um certificado novo.
