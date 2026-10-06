---
title: Como se faz um código de seis dígitos
version: 1
---

O segundo fator mais comum é um app autenticador que mostra seis dígitos e os troca a cada trinta
segundos. Parece mágica, já que o celular não precisa de conexão com o servidor, e é um pedacinho de
aritmética padronizado como **TOTP**, *time-based one-time password* (senha de uso único baseada em
tempo), na RFC 6238.

Quando a ana liga o MFA, o servidor gera um **segredo** aleatório, em geral mostrado como QR code, e o
app dela o guarda. Daí em diante os dois lados têm o mesmo segredo, e nenhum dos dois o manda de novo.
Para fazer um código, cada lado pega o segredo e a hora atual e calcula a mesma coisa:

```schooling-figure
{"svg": "<svg id=\"sf-totp\" viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Como um código TOTP é feito, no celular e no servidor ao mesmo tempo. Os dois guardam o mesmo segredo. Os dois pegam a hora, 13:00:00 UTC, dividem em passos de 30 segundos para obter o contador 59709720, calculam um HMAC do contador com o segredo e cortam em seis dígitos: 593771. O servidor compara o resultado dele com o que a pessoa digitou. Só os seis dígitos atravessam a rede.\"><defs><marker id=\"sf-totp-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sf-totp-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"sf-totp-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">celular (app)</text><rect x=\"20\" y=\"70\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hora ÷ 30 s</text><rect x=\"190\" y=\"70\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">59709720</text><rect x=\"340\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">HMAC</text><rect x=\"340\" y=\"14\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">segredo</text><rect x=\"600\" y=\"70\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">593771</text><path d=\"M160 90 L190 90\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M310 90 L340 90\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M450 90 L600 90\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M395 50 L395 70\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-amber)\"></path><text x=\"20\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">servidor</text><rect x=\"20\" y=\"170\" width=\"140\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hora ÷ 30 s</text><rect x=\"190\" y=\"170\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">59709720</text><rect x=\"340\" y=\"170\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">HMAC</text><rect x=\"340\" y=\"226\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"395.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">segredo</text><rect x=\"600\" y=\"170\" width=\"100\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">593771</text><path d=\"M160 190 L190 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M310 190 L340 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M450 190 L600 190\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-wire)\"></path><path d=\"M395 226 L395 210\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#sf-totp-ah-amber)\"></path><path d=\"M650 110 L650 170\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#sf-totp-ah-phosphor)\"></path><text x=\"640\" y=\"134.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a pessoa digita</text><text x=\"640\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o servidor compara</text><text x=\"470\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Mesmo segredo, mesmo passo → mesmos dígitos.</text></svg>", "caption": "Os dois lados calculam o mesmo código separados. Só o código viaja; o segredo nunca."}
```

1. Divida o tempo desde 1º de janeiro de 1970 por 30 segundos e descarte a fração. Esse número, o
   **contador**, é o mesmo para todo mundo durante o mesmo passo de trinta segundos.
2. Calcule um HMAC do contador com o segredo: um hash com chave que ninguém sem o segredo consegue
   reproduzir (aula 6 de `cryptography`).
3. Corte o resultado em seis dígitos decimais.

Aqui está o `oathtool`, um programa que faz a mesma conta de um app autenticador, mostrando o
raciocínio. O segredo é público, o segredo de exemplo da própria RFC, então não protege nada e pode ser
impresso:

```
ana@laptop:~$ oathtool --totp -b -v --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
Hex secret: 3132333435363738393031323334353637383930
Base32 secret: GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
Digits: 6
Window size: 0
TOTP mode: SHA1
Step size (seconds): 30
Start time: 1970-01-01 00:00:00 UTC (0)
Current time: 2026-10-06 13:00:00 UTC (1791291600)
Counter: 0x38F1918 (59709720)

593771
```

Está tudo da receita ali: o segredo escrito de dois jeitos, seis dígitos, SHA-1 como hash, um passo de
30 segundos contado desde 1970. Às 13:00:00 UTC de 6 de outubro de 2026 o contador é `59709720`, e o
código é `593771`.

Como o código depende do passo, e não do segundo exato, ele dura o passo inteiro:

```
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 13:00:00 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
593771
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 13:00:29 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
593771
ana@laptop:~$ oathtool --totp -b --now '2026-10-06 13:00:30 UTC' GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ
124813
```

Às `13:00:00` e às `13:00:29` o código é o mesmo; às `13:00:30` começa um passo novo e o código vira
`124813`. Um código capturado por um atacante não serve para nada trinta segundos depois, que é o **uso
único** do nome.

Uma variante chamada **HOTP**, na RFC 4226, usa um contador que sobe de um a cada uso em vez do relógio.
O TOTP é o HOTP com o tempo como contador, e é o que quase todo app autenticador usa.
