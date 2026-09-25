---
title: O que o TLS acrescenta, e como começa
version: 1
---

O TLS dá a uma conexão três coisas que o HTTP puro não tem:

- **Confidencialidade**: ninguém no caminho consegue ler.
- **Integridade**: ninguém no caminho consegue alterar sem que a alteração seja percebida.
- **Autenticação**: o servidor prova que é quem o nome diz, com um certificado, aula 6.

Ele começa com um handshake, depois do handshake do TCP e antes do primeiro byte de HTTP. O `curl -v`
dá nome a cada mensagem, e, filtrado para essas linhas:

```
ana@laptop:~$ curl -sv -o /dev/null https://www.example.com/ 2>&1 | grep -E '^\* (TLSv1.3|SSL connection|ALPN)'
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
* ALPN: server accepted h2
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" aria-label=\"O handshake do TLS 1.3 entre o curl no laptop e o nginx no www. Às claras: ClientHello, levando o nome www.example.com, os protocolos h2 e http/1.1 e uma parte da chave; ServerHello, levando a parte da chave do servidor, depois do que os dois lados têm o mesmo segredo. Criptografado daqui em diante: EncryptedExtensions, h2 aceito; Certificate, CN www.example.com e a cadeia; CertificateVerify, prova de que o servidor tem a chave do certificado; o Finished do servidor; o Finished do cliente; e então o pedido, GET / HTTP/2, criptografado.\"><defs><marker id=\"t13-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">laptop, curl</text><text x=\"680\" y=\"20\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">www, nginx</text><path d=\"M40 32 L40 386\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M680 32 L680 386\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">legível por qualquer um no caminho</text><path d=\"M42 72 L676 80\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ClientHello</text><text x=\"214\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nome www.example.com, h2 ou http/1.1, uma parte da chave</text><path d=\"M678 110 L44 118\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"102\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ServerHello</text><text x=\"214\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a parte dele: os dois lados agora têm o mesmo segredo</text><path d=\"M40 134 L680 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">criptografado daqui em diante</text><path d=\"M678 170 L44 178\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"162\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EncryptedExtensions</text><text x=\"214\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">h2 aceito</text><path d=\"M678 208 L44 216\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"200\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Certificate</text><text x=\"214\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CN = www.example.com, e a cadeia</text><path d=\"M678 246 L44 254\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"238\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CertificateVerify</text><text x=\"214\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">prova de que tem a chave do certificado</text><path d=\"M678 284 L44 292\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"276\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Finished</text><text x=\"214\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o lado do servidor terminou</text><path d=\"M42 322 L676 330\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"314\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Finished</text><text x=\"214\" y=\"314\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o lado do cliente terminou</text><path d=\"M42 360 L676 368\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#t13-ah)\"></path><text x=\"200\" y=\"352\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET / HTTP/2</text><text x=\"214\" y=\"352\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o pedido, criptografado</text></svg>", "caption": "O TLS 1.3 precisa de uma ida e volta antes de o pedido poder ir. Só as duas primeiras mensagens são legíveis no fio, e o nome na primeira é a parte que um observador sempre vê.", "same": ["laptop, curl", "www, nginx"]}
```

**O TLS 1.3 precisa de uma ida e volta.** O **Client hello** do cliente leva o nome do site (o *SNI*,
*server name indication*, para um servidor com muitos sites saber qual certificado mandar), os
protocolos que ele fala (`h2,http/1.1`, a lista *ALPN*) e a sua metade de uma troca de chaves. O
**Server hello** leva a metade do servidor, e a partir desse momento os dois lados dividem um segredo
que ninguém no caminho viu. Tudo depois dele é criptografado, inclusive o certificado. O `Change cipher
spec` é uma sobra que o TLS 1.3 manda só para passar por equipamentos antigos no caminho, e os dois
`Newsession Ticket` deixam a próxima conexão pular parte disto. O `openssl s_client` resume o
resultado:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -brief </dev/null 2>&1
CONNECTION ESTABLISHED
Protocol version: TLSv1.3
Ciphersuite: TLS_AES_256_GCM_SHA384
Peer certificate: CN = www.example.com
Hash used: SHA256
Signature type: ECDSA
Verification: OK
Server Temp Key: X25519, 253 bits
DONE
```

**`Verification: OK`** é a linha que importa aqui, e a aula 6 trata do que ela conferiu. `X25519` é a
troca de chaves, e `TLS_AES_256_GCM_SHA384` é a cifra com que todo o resto foi criptografado.
