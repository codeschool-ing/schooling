---
title: Sistemas reais combinam os dois tipos de chave
version: 1
---

**Todo sistema prático cifra os dados com uma chave simétrica e usa a criptografia assimétrica só
para levar essa chave ao lugar certo.** O RSA não consegue cifrar mais que algumas centenas de bytes
e é lento; o AES cifra qualquer coisa depressa, mas exige que os dois lados tenham a mesma chave.
Juntos, um cobre a lacuna do outro, e a combinação se chama **cifragem híbrida**.

## Enviando o arquivo de agendamentos ao serviço de prontuários

O arquivo de agendamentos é grande demais para o RSA, como a primeira seção desta aula mostrou. A
Ana o envia mesmo assim, em três passos.

**Primeiro, cifrar os dados com uma chave simétrica nova.** O `aes-256-b.hex` do laboratório faz o
papel de uma chave gerada só para esta mensagem, a *chave de sessão*:

```
ana@lab:~/lab$ vcrypt seal --key keys/aes-256-b.hex --nonce 0000000000000000000000a1 data/slots.dat slots.gcm
sealed data/slots.dat: 12-byte nonce + 512 bytes of ciphertext + 16-byte tag -> slots.gcm
```

**Segundo, cifrar a chave de sessão com a chave pública do destinatário.** A chave tem 32 bytes,
bem abaixo do limite do RSA:

```
ana@lab:~/lab$ xxd -r -p keys/aes-256-b.hex > session.key; wc -c session.key
32 session.key
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in session.key -out session.rsa; rm session.key
```

A cópia em claro da chave é apagada. O que viaja são dois arquivos:

```
ana@lab:~/lab$ wc -c slots.gcm session.rsa
540 slots.gcm
384 session.rsa
924 total
```

540 bytes de dados cifrados com AES-GCM, e 384 bytes de RSA protegendo a chave de 32 bytes que os
abre. Um arquivo de 5 gigabytes viajaria com os mesmos 384 bytes de RSA ao lado.

**Terceiro, o destinatário desfaz tudo.** O serviço decifra a chave de sessão com sua chave
privada e depois abre os dados com a chave de sessão:

```
ana@lab:~/lab$ openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in session.rsa | xxd -p -c 32 > recovered.hex
ana@lab:~/lab$ vcrypt open --key recovered.hex slots.gcm | head -2
room1 free     
room1 BOOKED   
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Cifragem híbrida em três passos. A Ana cifra o arquivo de agendamentos de 512 bytes com uma chave de sessão nova de 32 bytes usando AES-GCM, o que dá 540 bytes. Ela cifra a chave de sessão com a chave pública RSA do serviço de prontuários, o que dá 384 bytes. Os dois viajam. O serviço decifra a chave de sessão com sua chave privada e depois abre o arquivo com ela.\"><defs><marker id=\"hyb-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"hyb-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"hyb-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><text x=\"560\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">serviço de prontuários</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">slots.dat, 512</text><rect x=\"20\" y=\"140\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de sessão, 32</text><polyline points=\"170,60 268,60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-wire)\"></polyline><text x=\"220\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">AES-GCM</text><polyline points=\"95,140 95,92 268,70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#hyb-ah-amber)\"></polyline><polyline points=\"170,160 268,160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-phosphor)\"></polyline><text x=\"220\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">RSA pub</text><rect x=\"270\" y=\"40\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">slots.gcm, 540</text><rect x=\"270\" y=\"140\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">session.rsa, 384</text><polyline points=\"440,160 538,160\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-phosphor)\"></polyline><text x=\"490\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">RSA priv</text><rect x=\"540\" y=\"140\" width=\"160\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">chave de sessão</text><polyline points=\"620,140 620,92\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#hyb-ah-amber)\"></polyline><polyline points=\"440,60 538,60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hyb-ah-wire)\"></polyline><rect x=\"540\" y=\"40\" width=\"160\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"620\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">slots.dat</text><text x=\"360\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">só as duas caixas do meio atravessam a rede</text></svg>", "caption": "O AES leva os dados; o RSA leva só a chave.", "same": ["Ana"]}
```

## Onde você encontra isso

Isso não é uma curiosidade de laboratório. É a estrutura de quase tudo o que este curso cobre:

- **o e-mail S/MIME e OpenPGP** cifra a mensagem com uma chave de sessão e anexa essa chave cifrada
  com a chave pública de cada destinatário, uma vez por destinatário (aula 13);
- **backups e imagens de disco cifrados** com uma chave de recuperação fazem o mesmo, para que a
  chave dos dados possa ser desembrulhada por uma chave guardada em outro lugar (aula 14);
- **o TLS** obtém sua chave de sessão de outro jeito, por uma troca em vez de cifrá-la com a chave
  do servidor, por um motivo que a aula 7 explica. Mas o resultado é o mesmo: criptografia
  assimétrica para combinar, AES ou ChaCha20 para levar os dados.

## A assinatura também entra

O esquema híbrido dá confidencialidade. Nada nele diz que o arquivo veio da Ana: qualquer um
consegue cifrar uma chave de sessão com a chave pública do serviço. Quando as duas propriedades
importam, a Ana também **assina** os dados com a chave privada dela, e o destinatário confere essa
assinatura depois de decifrar. A maioria dos formatos que fazem as duas coisas assina primeiro e
cifra depois, para que a assinatura fique escondida junto com o conteúdo e um observador não
consiga saber quem assinou.
