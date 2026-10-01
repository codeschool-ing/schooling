---
title: Quanto custa cada metade
version: 1
---

O motivo de os protocolos não usarem criptografia assimétrica para tudo é mensurável. O `openssl speed`
executa cada operação durante um segundo no `laptop` e informa quantas conseguiu. Primeiro a simétrica,
AES-256 em modo GCM, em blocos de 16 KiB:

```
ana@laptop:~$ openssl speed -seconds 1 -bytes 16384 -evp aes-256-gcm 2>/dev/null | tail -2
type          16384 bytes
AES-256-GCM   12552994.82k
```

**12.552.994,82 milhares de bytes por segundo**, cerca de 12,5 gigabytes, num único núcleo de
processador com as instruções AES que os processadores modernos trazem. Depois RSA com chave de 2048
bits, e X25519:

```
ana@laptop:~$ openssl speed -seconds 1 rsa2048 2>/dev/null | tail -2
                  sign    verify    sign/s verify/s
rsa 2048 bits 0.000302s 0.000017s   3313.0  57718.2
ana@laptop:~$ openssl speed -seconds 1 ecdhx25519 2>/dev/null | tail -2
                              op      op/s
 253 bits ecdh (X25519)   0.0000s  29568.7
```

**3.313 assinaturas RSA por segundo** contra 57.718 verificações, e **29.568,7 acordos de chaves
X25519**. Lado a lado:

| operação | por segundo no `laptop` | para que é usada |
|---|---|---|
| AES-256-GCM, blocos de 16 KiB | cerca de 766.000 blocos (12,5 GB) | cada byte de uma conexão |
| acordo de chaves X25519 | 29.568,7 | uma vez por conexão, para combinar a chave |
| assinatura RSA-2048 | 3.313 | uma vez por conexão, pelo servidor, para provar sua identidade |

Cifrar um bloco de 16 KiB é umas vinte e cinco vezes mais rápido que um acordo X25519, e há milhares de
blocos numa conexão contra um único acordo. **Esse é o projeto de todo protocolo seguro numa tabela
só**: as operações lentas rodam uma vez, no começo, e a rápida carrega os dados.

Os números pertencem a esta máquina nesta tarde; rode `openssl speed` em outra e eles mudam. O que
viaja são as proporções. Elas também explicam por que um servidor TLS ocupado sente primeiro as suas
assinaturas RSA, e por que a mudança para chaves de curva elíptica, muito mais baratas para assinar, foi
bem recebida por quem paga pelos servidores.
