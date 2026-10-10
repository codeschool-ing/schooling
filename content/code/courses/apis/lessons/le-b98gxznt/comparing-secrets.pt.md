---
title: Comparando segredos
version: 1
---

**`==` é a ferramenta errada para comparar um segredo, porque o tempo que ele leva depende da
resposta.** Para comparar duas strings, o `==` as percorre desde o começo e para no primeiro caractere
diferente. É o que faz sentido em qualquer outra comparação de um programa, e, para um segredo, revela
quanto de um palpite estava certo.

O efeito é fácil de medir na sua própria máquina. Duas strings de cem mil caracteres, diferentes no
primeiro caractere da primeira vez e no último da segunda:

```
ana@api:~/shelf$ python3 -m timeit -s 'a = "x" * 100_000; b = "y" + "x" * 99_999' 'a == b'
20000000 loops, best of 5: 19.8 nsec per loop
ana@api:~/shelf$ python3 -m timeit -s 'a = "x" * 100_000; b = "x" * 99_999 + "y"' 'a == b'
100000 loops, best of 5: 3.25 usec per loop
```

Nanossegundos contra microssegundos: a comparação que achou a diferença logo de cara foi mais de cem
vezes mais rápida. Reduza isso a uma chave de 43 caracteres e a diferença encolhe para quase nada, mas
**quase nada, medido muitos milhares de vezes, é um sinal**. Um servidor cuja recusa demora um pouco mais
quando os primeiros caracteres de um palpite estão certos conta a quem chama com paciência, um caractere
de cada vez, quais caracteres estão certos. A rede acrescenta ruído, e ruído se tira na média
perguntando mais vezes. Isso é um **canal lateral de tempo** (*timing side channel*): a resposta estava
certa, e o tempo que ela levou disse mais do que a resposta.

O `hmac.compare_digest` existe para não dizer nada. Ele olha todos os caracteres, encontre o que
encontrar, então o tempo depende do tamanho das strings e não de onde elas diferem:

```
ana@api:~/shelf$ python3 -m timeit -s 'import hmac; a = "x" * 100_000; b = "y" + "x" * 99_999' 'hmac.compare_digest(a, b)'
5000 loops, best of 5: 73.7 usec per loop
ana@api:~/shelf$ python3 -m timeit -s 'import hmac; a = "x" * 100_000; b = "x" * 99_999 + "y"' 'hmac.compare_digest(a, b)'
5000 loops, best of 5: 73.4 usec per loop
```

Os dois tempos são iguais dentro do ruído da máquina. **Mais lento, e de propósito**: para um segredo, a
comparação que leva o mesmo tempo toda vez é a correta.

## Onde o `keys.py` usa

Duas vezes, nos dois pontos em que algo enviado é conferido contra algo guardado:

| onde | o que é comparado |
|---|---|
| `check_password` | o scrypt do que foi enviado contra o scrypt guardado |
| `by_key` | o SHA-256 da chave enviada contra o SHA-256 guardado |

O token é o terceiro caso e é tratado de outro jeito: o `by_token` procura no banco o hash do que foi
enviado, em vez de comparar strings ele mesmo. Uma diferença de tempo ali seria sobre quanto de um
SHA-256 bateu, e quem chama não consegue escolher os primeiros caracteres de um hash mudando o token,
então isso não lhe ensina nada. **Comparar hashes em vez de segredos é a outra metade da mesma
defesa**, e o `keys.py` faz as duas onde compara.

Toda linguagem tem sua versão dessa função: `crypto.timingSafeEqual` no Node.js,
`MessageDigest.isEqual` no Java, `subtle.ConstantTimeCompare` no Go. Seja qual for a sua, um segredo
nunca é comparado com o operador de igualdade comum.
