---
title: O modo decide o que os blocos entregam
version: 1
---

O AES cifra um bloco. Um **modo de operação** decide como um arquivo de muitos blocos é cifrado
com ele, e essa escolha importa mais do que o tamanho da chave: **com o modo errado, um texto
cifrado mostra a estrutura do texto claro a alguém que não tem chave nenhuma.**

## ECB: cada bloco por conta própria

O modo óbvio é cifrar cada bloco separadamente com a mesma chave. Ele se chama ECB, *electronic
codebook*, porque funciona como um livro de códigos: um mesmo bloco vira sempre o mesmo bloco
cifrado. O `vcrypt blocks --letters` desenha uma letra por bloco, a mesma letra para o mesmo bloco,
quatro horários por hora. Primeiro o texto claro, depois o mesmo arquivo cifrado com ECB:

```
ana@lab:~/lab$ vcrypt blocks --letters data/slots.dat
ABAA BABA BAAA BAAA AABB AAAA BAAA BABA
ana@lab:~/lab$ openssl enc -aes-256-ecb -K $(cat keys/aes-256.hex) -in data/slots.dat | vcrypt blocks --letters -
ABAA BABA BAAA BAAA AABB AAAA BAAA BABA C
```

As duas linhas são iguais. A era um horário livre e B um reservado, então o texto cifrado conta a
quem o tiver que a segunda-feira tem reservas às 08:15, 09:00, 09:30, 10:00 e 11:00, duas seguidas
a partir de 13:30 e mais três a partir de 15:00. Ninguém quebrou o AES para saber disso. Cada bloco
está perfeitamente cifrado, e **o modo publicou quais blocos são iguais**. (O C extra no fim é o
bloco de preenchimento da seção anterior.)

A imagem famosa disso é um bitmap de um pinguim cifrado com ECB, no qual o pinguim continua
perfeitamente visível. O arquivo de agendamentos é a mesma coisa sem a imagem: qualquer repetição
nos dados sobrevive à cifragem.

## CBC: cada bloco depende do anterior

O CBC, *cipher block chaining*, elimina a repetição misturando cada bloco de texto claro com o
bloco cifrado anterior antes de cifrá-lo. O primeiro bloco não tem anterior, então é misturado com
um **vetor de inicialização**, dezesseis bytes que viajam junto com o texto cifrado:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois modos lado a lado. No ECB, três blocos de texto claro P1, P2 e P3 passam cada um pelo AES com a chave k por conta própria; P1 e P3 são iguais, então C1 e C3 saem iguais. No CBC, P1 é primeiro combinado por XOR com o IV, depois cada bloco seguinte é combinado com o bloco cifrado anterior antes do AES, então C1 e C3 são diferentes embora P1 seja igual a P3.\"><defs><marker id=\"mode-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mode-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"mode-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ECB</text><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">CBC</text><rect x=\"5\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P1 = free</text><polyline points=\"45,66 45,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"15\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"45,142 45,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"5\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"45\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C1 = 7f3a…</text><rect x=\"95\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P2 = BOOKED</text><polyline points=\"135,66 135,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"105\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"135,142 135,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"95\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C2 = 91c0…</text><rect x=\"185\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P3 = free</text><polyline points=\"225,66 225,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"195\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"225,142 225,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"185\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C3 = 7f3a…</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">C1 e C3 são iguais: o padrão sobrevive.</text><rect x=\"370\" y=\"74\" width=\"40\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">IV</text><rect x=\"405\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P1 = free</text><polyline points=\"445,66 445,78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><text x=\"445\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">XOR</text><polyline points=\"445,95 445,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"415\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"445,142 445,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"405\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C1 = 2b81…</text><polyline points=\"445,166 500,166 500,86 532,86\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-phosphor)\"></polyline><rect x=\"505\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P2 = BOOKED</text><polyline points=\"545,66 545,78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><text x=\"545\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">XOR</text><polyline points=\"545,95 545,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"515\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"545,142 545,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"505\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C2 = e04d…</text><polyline points=\"545,166 600,166 600,86 632,86\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-phosphor)\"></polyline><rect x=\"605\" y=\"40\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P3 = free</text><polyline points=\"645,66 645,78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><text x=\"645\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">XOR</text><polyline points=\"645,95 645,106\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"615\" y=\"108\" width=\"60\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">AES k</text><polyline points=\"645,142 645,190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-wire)\"></polyline><rect x=\"605\" y=\"192\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C3 = 5a17…</text><polyline points=\"410,86 437,86\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#mode-ah-amber)\"></polyline><text x=\"380\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Cada bloco também depende de tudo o que veio antes.</text><text x=\"380\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Valores hexadecimais encurtados e ilustrativos.</text></svg>", "caption": "O ECB cifra cada bloco sozinho; o CBC injeta cada bloco cifrado no seguinte.", "same": ["ECB", "CBC"]}
```

Blocos iguais de texto claro agora encontram entradas diferentes, porque o que veio antes deles é
diferente, e o padrão desaparece:

```
ana@lab:~/lab$ openssl enc -aes-256-cbc -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -
ABCD EFGH IJKL MNOP QRST UVWX YZab cdef g
```

Trinta e três blocos e trinta e três letras. Dois horários cifrados agora só são iguais por acaso,
e com 2¹²⁸ blocos possíveis essa chance é nula.

## CTR: o AES como um fluxo de bytes

O CTR, *counter mode*, usa o AES de outro jeito. Ele nunca cifra os dados. Cifra um contador, o
vetor seguido de 1, 2, 3 e assim por diante, e combina o resultado com os dados byte a byte usando
XOR. O AES vira um gerador de **fluxo de chave** (*keystream*), e os dados são misturados com esse
fluxo:

```
ana@lab:~/lab$ openssl enc -aes-256-ctr -K $(cat keys/aes-256.hex) -iv $(cat keys/iv-a.hex) -in data/slots.dat | vcrypt blocks --letters -
ABCD EFGH IJKL MNOP QRST UVWX YZab cdef
```

Trinta e dois blocos desta vez, não trinta e três: o CTR não precisa de preenchimento, porque o
fluxo é cortado no tamanho exato dos dados. Ele também é paralelo nos dois sentidos, já que o bloco
20 pode ser cifrado ou decifrado sem tocar no bloco 19, o que o CBC não consegue fazer ao cifrar.

O preço é uma regra sem exceções: **um valor de contador nunca pode ser usado duas vezes com a
mesma chave.** Duas mensagens cifradas com a mesma chave e o mesmo valor inicial são misturadas com
o mesmo fluxo, e isso vaza informação sobre os dois textos claros ao mesmo tempo. A seção 07 desta
aula trata de escolher esse valor inicial, e a aula 17 trata de como os sistemas erram nisso.

## Qual modo, então

- **ECB**: nunca, para nada maior que um bloco. O arquivo de agendamentos é o motivo.
- **CBC**: legado. Correto quando o vetor é aleatório e uma verificação separada protege o texto
  cifrado. Nenhuma das duas coisas acontece por padrão, e a última seção desta aula mostra por que
  a verificação importa.
- **CTR**: rápido e simples, mas sozinho também não detecta nenhuma alteração no texto cifrado.
- **GCM**: CTR com uma verificação embutida. É o que o TLS 1.3, a maioria dos formatos de disco e a
  maioria das bibliotecas usam por padrão, e é onde esta aula termina.

O ChaCha20-Poly1305 é a outra escolha autenticada do TLS 1.3. É uma cifra de fluxo, não AES, e é
preferida em processadores sem instruções de AES, tipicamente celulares. As duas são escolhas
corretas; a decisão importante é usar uma das autenticadas.
