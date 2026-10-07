---
title: Quantos bits bastam
version: 1
---

**Tamanhos de chave são comparados pelo nível de segurança: grosso modo, o número de operações de
que um atacante precisaria, escrito como uma potência de dois.** Um nível de segurança de 128 bits
significa cerca de 2¹²⁸ operações, e essa é a meta para qualquer coisa que precise continuar
secreta por décadas. O porém é que as três famílias chegam lá com números de bits muito
diferentes, então "256", sozinho, não significa nada até você saber de que família ele é.

## A tabela que responde à pergunta

A recomendação de gestão de chaves do NIST, a SP 800-57, alinha as famílias por nível de
segurança:

| nível de segurança | simétrica (AES) | curva elíptica | módulo RSA |
|---|---|---|---|
| 112 bits | (3DES, aposentado) | 224 | 2048 |
| **128 bits** | **AES-128** | **256 (P-256, X25519)** | **3072** |
| 192 bits | AES-192 | 384 (P-384) | 7680 |
| 256 bits | AES-256 | 512 (P-521) | 15360 |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Barras mostrando o tamanho de chave de que cada família precisa para um nível de segurança de 128 bits: AES 128 bits, uma curva elíptica 256 bits, RSA 3072 bits. A barra do RSA é doze vezes a da curva e vinte e quatro vezes a do AES.\"><text x=\"20\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tamanho de chave para segurança de 128 bits</text><text x=\"20\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES-128</text><rect x=\"120\" y=\"50\" width=\"23.333333333333332\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"151.33333333333334\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">128 bits</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">P-256</text><rect x=\"120\" y=\"106\" width=\"46.666666666666664\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"174.66666666666666\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">256 bits</text><text x=\"20\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">RSA-3072</text><rect x=\"120\" y=\"162\" width=\"560.0\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"670.0\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3072 bits</text></svg>", "caption": "O mesmo nível de segurança de 128 bits, em três famílias."}
```

Três coisas decorrem dela, e cada uma é uma decisão que as pessoas erram:

- **AES-128, P-256 e RSA-3072 são igualmente fortes.** Escolher RSA-4096 ao lado de AES-128 não
  compra nada, porque o atacante vai no mais fraco.
- **O RSA cresce mal.** Cada degrau acima custa ao RSA muito mais bits do que custa a uma curva, e
  o trabalho do RSA cresce mais depressa que seu tamanho: assinar com uma chave de 15360 bits é
  lento a ponto de ser impraticável, e é por isso que ninguém faz isso e as curvas ganharam os
  níveis mais altos.
- **O RSA-2048 fica um nível abaixo dos outros**, em 112 bits. Ele ainda é aceitável hoje, e é o
  piso: o plano de transição do NIST (IR 8547, um rascunho publicado em 2024) propõe descontinuar a
  segurança de 112 bits depois de 2030. Qualquer coisa emitida agora com vida longa deveria ser
  RSA-3072 ou uma curva.

## O que o tamanho custa na rede

Chaves maiores viajam em todo handshake e em todo certificado. As chaves públicas do laboratório,
na forma binária em que um certificado as carrega:

```
ana@lab:~/lab$ for k in rsa-2048 rsa-3072 p256 ed25519-ana; do printf "%-12s %4s bytes\n" $k $(openssl pkey -pubin -in keys/$k.pub -outform DER | wc -c); done
rsa-2048      294 bytes
rsa-3072      422 bytes
p256           91 bytes
ed25519-ana    44 bytes
```

E assinaturas da mesma carta, feitas com cada chave privada:

```
ana@lab:~/lab$ for k in rsa-2048 rsa-3072; do openssl dgst -sha256 -sign keys/$k.key -out $k.sig data/referral.txt; done
ana@lab:~/lab$ openssl pkeyutl -sign -rawin -inkey keys/ed25519-ana.key -in data/referral.txt -out ed25519-ana.sig
ana@lab:~/lab$ wc -c rsa-2048.sig rsa-3072.sig ed25519-ana.sig
256 rsa-2048.sig
384 rsa-3072.sig
 64 ed25519-ana.sig
704 total
```

Uma assinatura RSA tem exatamente o tamanho do módulo: 256 bytes a 2048 bits, 384 a 3072. Uma
assinatura Ed25519 tem 64 bytes, seja o que for assinado. Num handshake TLS que leva uma cadeia de
dois certificados, cada um com uma chave e uma assinatura, essa diferença é de várias centenas de
bytes por conexão nova, e esse é um dos motivos de as curvas serem o padrão em certificados novos.

## Contra o que o tamanho não protege

Cada número da tabela supõe que o algoritmo é usado corretamente e que a chave foi gerada com boa
aleatoriedade. Nada disso ajuda quando:

- **a chave vaza.** Uma chave RSA de 15360 bits copiada para um repositório público não protege
  nada. A aula 17 trata disso, e é muito mais comum do que alguém fatorar alguma coisa;
- **o gerador aleatório era fraco.** Em 2008, o pacote OpenSSL do Debian só conseguia produzir
  32.768 chaves diferentes por tipo e tamanho por causa de uma alteração no seu gerador aleatório,
  então toda chave SSH e TLS feita naquelas máquinas durante dois anos teve de ser substituída,
  qualquer que fosse o tamanho;
- **existe um computador quântico grande.** O algoritmo de Shor quebraria o RSA e as curvas
  elípticas em todos os tamanhos da tabela, enquanto apenas reduz pela metade a força efetiva do
  AES (o AES-256 ainda daria 128 bits). Essa máquina ainda não existe, mas dados gravados hoje
  poderiam ser decifrados no dia em que ela existir, e é por isso que a aula 7 termina com os
  algoritmos pós-quânticos que o NIST padronizou em 2024.

A regra de trabalho, então: **AES-256 ou AES-128 para dados, X25519 ou P-256 para combinar chaves,
Ed25519, P-256 ou RSA-3072 para assinaturas, e RSA-2048 só onde algo antigo exigir.**
