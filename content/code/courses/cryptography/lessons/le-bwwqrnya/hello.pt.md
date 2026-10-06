---
title: Os hellos: o que cada lado oferece e escolhe
version: 1
---

**Um handshake TLS 1.3 leva uma ida e volta: o cliente manda um voo de mensagens, o servidor
responde com um, e o cliente já pode mandar dados no seguinte.** Tudo o que veio das aulas 1 a 9
acontece dentro dele: uma troca de chaves (aula 7), uma cadeia de certificados (aulas 8 e 9), uma
assinatura (aula 3), a HKDF (aula 7) e o AES-GCM (aula 1). Esta aula o observa no portal da
Vereda.

## O handshake no laboratório

O laboratório roda o `openssl s_server` em `127.0.0.1:8443` com o certificado do portal e sua AC
emissora. O `openssl s_client` se conecta, confiando na raiz da Vereda, e o `-trace` imprime cada
mensagem. Um trace é longo e cheio de bytes aleatórios que mudam a cada conexão, então ele passa
pelo `vcrypt tls-flow`, que mantém os nomes das mensagens e os campos que esta aula discute:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -trace 2>&1 | vcrypt tls-flow
client -> server  ClientHello
    offers 31 cipher suites
    server_name: portal.vereda.example
    offers versions: TLS 1.3, TLS 1.2
    key_share: ecdh_x25519
server -> client  ServerHello
    chosen cipher suite: TLS_AES_256_GCM_SHA384
    chosen version: TLS 1.3
    key_share: ecdh_x25519
server -> client  ChangeCipherSpec
---- everything below is encrypted with the handshake keys ----
server -> client  EncryptedExtensions
server -> client  Certificate
    certificate: portal.vereda.example
    certificate: Vereda Issuing CA 1
server -> client  CertificateVerify
    signed with: ecdsa_secp256r1_sha256
server -> client  Finished
client -> server  ChangeCipherSpec
client -> server  Finished
client -> server  application data (encrypted)
client -> server  Alert: warning, close notify
result: New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
result: Verify return code: 0 (ok)
```

O resto desta seção lê as duas primeiras mensagens. A próxima lê o resto.

## ClientHello

O cliente abre com tudo o que o servidor precisa para escolher:

- as **suítes de cifras** que ele aceita, 31 aqui. No TLS 1.3 uma suíte nomeia só o AEAD e o hash,
  como `TLS_AES_256_GCM_SHA384`. As outras 28 são suítes antigas do TLS 1.2, oferecidas para o caso
  de o servidor ser antigo;
- as **versões aceitas**, TLS 1.3 e TLS 1.2. O campo de versão no cabeçalho do registro ainda diz
  1.2, ou até 1.0, por compatibilidade com equipamentos intermediários antigos que descartariam
  qualquer coisa desconhecida; a negociação de verdade acontece nesta extensão;
- o **server_name**, o nome de host que o cliente quer, `portal.vereda.example`. Isso é o **SNI**, e
  ele permite que um endereço IP sirva muitos sites, cada um com seu certificado. Ele viaja em texto
  claro no ClientHello, e essa é a principal coisa que um observador do TLS 1.3 ainda descobre. (O
  Encrypted Client Hello, ECH, está sendo implantado para escondê-lo.)
- o **key_share**: a chave pública X25519 efêmera do cliente, 32 bytes. O cliente não espera ser
  perguntado; ele aposta que o servidor aceita X25519, e quase todos aceitam. Essa aposta é o que
  economiza uma ida e volta em relação ao TLS 1.2.

## ServerHello

O servidor escolhe um de cada:

- **versão** TLS 1.3, **suíte de cifras** `TLS_AES_256_GCM_SHA384`;
- **key_share**: a chave pública X25519 efêmera dele.

Neste ponto cada lado tem a própria chave privada efêmera e a chave pública do outro, que é
exatamente a troca da aula 7. Os dois calculam o mesmo segredo compartilhado, rodam a HKDF sobre ele
e derivam as **chaves do handshake**. Tudo depois do ServerHello é cifrado com elas, e é essa a
linha que o `vcrypt tls-flow` desenha. Um observador da rede vê os dois hellos e depois só registros
cifrados: nem o certificado fica visível no TLS 1.3, diferente do TLS 1.2.

As mensagens `ChangeCipherSpec` da lista não carregam nada. O TLS 1.3 só as manda porque alguns
equipamentos intermediários quebram conexões que não se parecem o bastante com o TLS 1.2.
