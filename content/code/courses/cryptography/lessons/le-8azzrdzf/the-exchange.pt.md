---
title: Diffie-Hellman com números que dá para conferir
version: 1
---

**Numa troca Diffie-Hellman, duas partes guardam cada uma um número secreto, mandam uma à outra um
valor calculado a partir dele e chegam ambas ao mesmo segredo compartilhado, que nunca atravessa a
rede.** Ninguém recebe uma chave. Nada é cifrado para ninguém. O segredo é *combinado*, e um
bisbilhoteiro que viu todas as mensagens ainda assim não consegue calculá-lo. Whitfield Diffie e
Martin Hellman publicaram a ideia em 1976, e ela é o primeiro passo de toda conexão TLS, SSH e
WireGuard feita hoje.

## A troca, pequena o bastante para fazer à mão

O `vcrypt toydh` roda o exemplo clássico dos livros com o primo 23, e a troca inteira são seis
linhas de aritmética:

```py
# ~/lab/tools/toydh.py
"""vcrypt toydh: Diffie-Hellman with numbers small enough to follow by hand."""
p, g = 23, 5
a, b = 6, 15  # Ana's secret and Bruno's
A, B = pow(g, a, p), pow(g, b, p)
print(f"public:  p = {p}, g = {g}")
print(f"Ana   picks a = {a} (secret), sends A = g^a mod p = {A}")
print(f"Bruno picks b = {b} (secret), sends B = g^b mod p = {B}")
print(f"Ana   computes B^a mod p = {pow(B, a, p)}")
print(f"Bruno computes A^b mod p = {pow(A, b, p)}")
print(f"on the wire: p, g, A = {A}, B = {B}; never a, b or the result")
```


```
ana@lab:~/lab$ vcrypt toydh
public:  p = 23, g = 5
Ana   picks a = 6 (secret), sends A = g^a mod p = 8
Bruno picks b = 15 (secret), sends B = g^b mod p = 19
Ana   computes B^a mod p = 2
Bruno computes A^b mod p = 2
on the wire: p, g, A = 8, B = 19; never a, b or the result
```

Passo a passo:

1. Os dois lados combinam dois números **públicos**, o primo `p = 23` e uma base `g = 5`. Eles podem
   ser publicados; na prática são fixados por um padrão.
2. A Ana escolhe um segredo `a = 6` e manda `A = 5⁶ mod 23 = 8`.
3. O Bruno escolhe um segredo `b = 15` e manda `B = 5¹⁵ mod 23 = 19`.
4. A Ana eleva o que recebeu ao próprio segredo: `19⁶ mod 23 = 2`.
5. O Bruno faz o mesmo com o dele: `8¹⁵ mod 23 = 2`.

Os dois chegam a 2, porque os dois calcularam `5^(6×15) mod 23`, cada um a partir de uma metade
diferente. A última linha da saída é o ponto: o que viajou foi `23`, `5`, `8` e `19`. Para chegar a
2 a partir disso, um bisbilhoteiro precisa recuperar o 6 de `8 = 5^a mod 23`, que é o **problema do
logaritmo discreto**. Com 23 leva um instante; com um primo de 2048 bits, ou numa curva elíptica de
256 bits, é o mesmo tipo de problema que a aula 2 disse que ninguém sabe resolver.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Diffie-Hellman com p = 23 e g = 5. A Ana guarda a = 6 e manda A = 8. O Bruno guarda b = 15 e manda B = 19. A rede carrega só 23, 5, 8 e 19. A Ana calcula 19 elevado a 6 mod 23 e o Bruno calcula 8 elevado a 15 mod 23; os dois chegam a 2.\"><defs><marker id=\"dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ana</text><text x=\"610\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Bruno</text><text x=\"360\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">a rede</text><rect x=\"260\" y=\"36\" width=\"200\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">p = 23, g = 5</text><rect x=\"30\" y=\"40\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">segredo a = 6</text><rect x=\"530\" y=\"40\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">segredo b = 15</text><polyline points=\"190,100 530,100\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dh-ah-phosphor)\"></polyline><text x=\"360\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">A = 5^6 mod 23 = 8</text><polyline points=\"530,140 190,140\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#dh-ah-phosphor)\"></polyline><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">B = 5^15 mod 23 = 19</text><rect x=\"30\" y=\"196\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">19^6 mod 23 = 2</text><rect x=\"530\" y=\"196\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8^15 mod 23 = 2</text><text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mesmo segredo, nunca enviado</text></svg>", "caption": "Duas metades de um mesmo expoente; a rede não vê nenhuma das duas.", "same": ["Ana", "Bruno"]}
```

## O que uma troca dá, e o que não dá

O resultado é um **segredo compartilhado** que só os dois participantes conhecem. Ele não é usado
diretamente como chave. Os dois lados o passam por uma função de derivação de chaves, no TLS 1.3 a
**HKDF**, para produzir as chaves AES ou ChaCha20 de fato, uma para cada sentido. A próxima seção
faz esse passo com chaves reais.

Duas coisas que a troca não faz, e cada uma é uma seção desta aula:

- ela não diz **quem** está do outro lado. A Ana sabe que combinou um segredo com *alguém* que
  mandou 19. A seção 05 trata de por que isso importa e de como os protocolos resolvem;
- ela não sobrevive a um **computador quântico grande**, que resolveria o logaritmo discreto com
  eficiência. A seção 06 trata do que a substitui.
