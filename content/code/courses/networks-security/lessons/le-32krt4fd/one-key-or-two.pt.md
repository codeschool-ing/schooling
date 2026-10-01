---
title: Uma chave compartilhada, ou um par
version: 1
---

A criptografia numa rede faz dois trabalhos que as pessoas costumam misturar: manter uma mensagem
**secreta** para quem a transporta, e **combinar um segredo** com alguém que você nunca encontrou. Existem
duas famílias de algoritmos porque esses são problemas diferentes.

| | simétrica | assimétrica |
|---|---|---|
| chaves | uma chave, compartilhada pelas duas pontas | um par por parte: uma chave privada guardada, uma chave pública distribuída |
| o que faz bem | cifra grandes volumes de dados, rápido | combina um segredo, e assina (aula 11), sem um segredo compartilhado de antemão |
| a parte difícil | as duas pontas precisam da chave antes de começar, e mais ninguém pode tê-la | lenta, e só vale tanto quanto saber de quem é a chave pública que você tem (aula 12) |
| algoritmos vistos neste curso | AES, ChaCha20 | X25519, RSA, ECDSA, Ed25519 |

**A imagem errada mais comum é que a criptografia assimétrica é o tipo "mais forte"** e usado para tudo
o que importa. Ela quase não é usada para volume. Todo protocolo que este curso toca — TLS, SSH,
WireGuard — usa criptografia assimétrica por alguns milissegundos no começo, para combinar uma chave
simétrica, e criptografia simétrica para cada byte depois disso. O resto desta aula mostra cada metade
no laboratório, e depois as duas juntas num túnel entre a matriz e a filial.

Uma última palavra sobre tamanhos, porque eles são comparados o tempo todo, e mal: **tamanhos de chave
só se comparam dentro de uma família**. Uma chave AES de 256 bits e uma chave de curva elíptica de 256
bits são ambas consideradas fortes; uma chave RSA de 2048 bits é mais ou menos tão forte quanto uma
chave simétrica de 112 bits, e não oito vezes mais forte que o AES.
