---
title: As chaves que um handshake produz
version: 1
---

**Um handshake TLS 1.3 não produz uma chave. Ele roda a HKDF sobre o segredo compartilhado para
produzir uma pequena família de segredos, cada um para um sentido e uma etapa, e deriva deles as
chaves AES de fato.** Vê-los é útil para depurar, e o jeito de vê-los é um recurso que nunca pode ser
ligado em produção.

## O registro de chaves

O OpenSSL, os navegadores e a maioria das bibliotecas TLS conseguem gravar os segredos de cada
conexão num arquivo, o *key log*, num formato que o Wireshark lê para decifrar uma captura. O
`s_client -keylogfile` faz isso para a conexão do laboratório:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -keylogfile session.keys >/dev/null 2>&1; grep -v '^#' session.keys | cut -d' ' -f1 | sort
CLIENT_HANDSHAKE_TRAFFIC_SECRET
CLIENT_TRAFFIC_SECRET_0
EXPORTER_SECRET
SERVER_HANDSHAKE_TRAFFIC_SECRET
SERVER_TRAFFIC_SECRET_0
```

Cinco segredos, um por linha, cada um marcado com o valor aleatório do ClientHello para que uma
ferramenta consiga ligá-lo à sua conexão:

| segredo | protege |
|---|---|
| `CLIENT_HANDSHAKE_TRAFFIC_SECRET` | as mensagens cifradas do handshake do cliente, o Finished dele |
| `SERVER_HANDSHAKE_TRAFFIC_SECRET` | o EncryptedExtensions, o Certificate, o CertificateVerify e o Finished do servidor |
| `CLIENT_TRAFFIC_SECRET_0` | os dados da aplicação do cliente para o servidor |
| `SERVER_TRAFFIC_SECRET_0` | os dados da aplicação do servidor para o cliente |
| `EXPORTER_SECRET` | chaves que uma aplicação deriva da conexão para uso próprio |

Cada um tem o tamanho do hash da suíte, SHA-384 aqui:

```
ana@lab:~/lab$ grep CLIENT_TRAFFIC_SECRET_0 session.keys | awk '{print length($3)/2 " bytes"}'
48 bytes
```

O `_0` conta: uma conexão longa pode atualizar suas chaves, dando `_1`, `_2` e assim por diante, para
que uma única chave nunca cifre uma quantidade ilimitada de dados. E os sentidos do cliente e do
servidor têm chaves separadas, então um registro mandado num sentido não pode ser refletido de volta
no outro.

## O que o registro significa para a segurança

O registro de chaves é exatamente o que o sigilo futuro (aula 7) promete que ninguém jamais terá: os
segredos de uma sessão passada. Com ele, uma gravação dessa sessão se decifra. Então:

- ele é uma **ferramenta de depuração para o seu próprio tráfego**, na sua própria máquina, pelo
  tempo de achar um defeito;
- a variável de ambiente `SSLKEYLOGFILE` o liga em navegadores, no curl e em muitas bibliotecas, o
  que significa que uma variável esquecida no ambiente de um servidor ou numa imagem de contêiner
  registra em silêncio as chaves de toda sessão. Procurar por ela faz parte da revisão de qualquer
  configuração de produção;
- o arquivo é apagado quando a depuração termina.

O sigilo futuro vale porque as chaves efêmeras e esses segredos só existem na memória, durante a
vida da conexão. Gravá-los em disco desfaz isso de propósito, o que serve num laboratório e é um
incidente grave num servidor.
