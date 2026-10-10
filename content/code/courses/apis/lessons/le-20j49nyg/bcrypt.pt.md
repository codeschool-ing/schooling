---
title: bcrypt
version: 1
---

**O bcrypt é o mais antigo dos três, de 1999, e foi desenhado desde o início para ficar mais lento
conforme os computadores ficam mais rápidos.** Ele tem um parâmetro só, o **custo**, e escreve tudo o
que precisa para conferir uma senha depois no texto que devolve.

```
ana@api:~/shelf$ python3 -c 'import bcrypt; print(bcrypt.hashpw(b"correct horse battery staple", bcrypt.gensalt(12)).decode())'
$2b$12$bxn1iU7qxqWf6kP97SJxK.5XHQsQk1G1YXILs7rJqQnOs8xPZz1p.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 170\" role=\"img\" aria-label=\"O texto do bcrypt $2b$12$bxn1iU7qxqWf6kP97SJxK.5XHQsQk1G1YXILs7rJqQnOs8xPZz1p. cortado em quatro campos: $2b$ nomeia o algoritmo e a versão, 12$ é o custo, os 22 caracteres seguintes são o salt e os últimos 31 são o hash.\"><rect x=\"30\" y=\"40\" width=\"112\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"86.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$2b$</text><line x1=\"86.0\" y1=\"74\" x2=\"86.0\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"86.0\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">algoritmo</text><text x=\"86.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">bcrypt, versão 2b</text><rect x=\"148\" y=\"40\" width=\"112\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"204.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12$</text><line x1=\"204.0\" y1=\"74\" x2=\"204.0\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"204.0\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">custo</text><text x=\"204.0\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2^12 rodadas</text><rect x=\"266\" y=\"40\" width=\"159.2\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"345.6\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bxn1iU7qxqWf6kP97SJxK.</text><line x1=\"345.6\" y1=\"74\" x2=\"345.6\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"345.6\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">salt</text><text x=\"345.6\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">22 caracteres, 16 bytes</text><rect x=\"431.2\" y=\"40\" width=\"218.6\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"540.5\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5XHQsQk1G1YXILs7rJqQnOs8xPZz1p.</text><line x1=\"540.5\" y1=\"74\" x2=\"540.5\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"540.5\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash</text><text x=\"540.5\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">31 caracteres, 23 bytes</text></svg>", "caption": "Tudo o que a verificação precisa está no mesmo texto: a versão, o custo e o salt viajam com o hash.", "same": ["hash", "salt"]}
```

Esse texto é o que um banco guarda, numa coluna de texto. Conferir uma senha lê o custo e o salt de
dentro dele, calcula o hash do que foi digitado com eles e compara; nada sobre os parâmetros precisa
ser guardado em outro lugar. O `bcrypt.gensalt()` do Python escolheu o custo 12 quando não recebeu
número, e esse é o `$2b$12$` dos dois textos da seção sobre salt.

## O custo dobra o tempo

O custo é um expoente: o bcrypt executa o passo caro 2^custo vezes, então **um a mais é o dobro do
trabalho**. As três linhas do bcrypt no `hashrate.py` mostram isso: 62,651 ms por hash no custo 10,
127,267 no 11, 256,682 no 12. O Password Storage Cheat Sheet da OWASP pede custo de pelo menos 10, e
tão alto quanto o tempo de verificação do servidor permitir. Como o custo fica em cada texto guardado,
subi-lo depois muda só os hashes novos, e os antigos continuam conferindo com o custo com que foram
feitos.

## O limite de 72 bytes

O bcrypt lê no máximo **72 bytes** da senha e ignora o resto. O bcrypt 3.2.2 do Python, o que o
Ubuntu 24.04 empacota, faz isso sem avisar. Duas senhas que concordam nos primeiros 72 bytes e
diferem depois deles:

```
ana@api:~/shelf$ python3 -c 'import bcrypt; h = bcrypt.hashpw(b"a" * 72 + b"X", bcrypt.gensalt()); print(bcrypt.checkpw(b"a" * 72 + b"Y", h))'
True
```

`True`: uma senha terminada em `Y` foi aceita contra o hash de uma terminada em `X`. Tudo o que um
usuário digita depois do 72º byte não protege nada.

A leitura comum é que são 72 caracteres, o que basta para qualquer um. São 72 **bytes**, e em UTF-8
uma letra acentuada ocupa dois:

```
ana@api:~/shelf$ python3 -c 'p = "canção"; print(len(p), len(p.encode()))'
6 8
```

Uma frase-senha em português chega ao limite bem antes de 72 letras, e frase-senha é exatamente o que
as regras do fim desta lição incentivam. Três saídas, da folha da OWASP:

| escolha | o que significa |
|---|---|
| recusar senhas acima de 72 bytes | avisar no cadastro, e contar bytes, não caracteres |
| fazer um pré-hash com HMAC e uma chave secreta, depois base64 | a fórmula da folha é `bcrypt(base64(hmac-sha384(password, pepper)))`; um SHA-256 simples antes não é seguro |
| usar Argon2id em tudo o que for novo | ele não tem esse limite |

A última, com o mesmo par de senhas:

```
ana@api:~/shelf$ python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); h = ph.hash("a" * 72 + "X"); print(ph.verify(h, "a" * 72 + "Y"))'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/lib/python3/dist-packages/argon2/_password_hasher.py", line 188, in verify
    return verify_secret(
           ^^^^^^^^^^^^^^
  File "/usr/lib/python3/dist-packages/argon2/low_level.py", line 206, in verify_secret
    raise VerifyMismatchError(error_to_str(rv))
argon2.exceptions.VerifyMismatchError: The password does not match the supplied hash
```

O Argon2id recusa a segunda senha, que é o certo. O erro é o jeito da biblioteca de dizer "não
confere"; o `passwords.py`, no fim desta lição, o captura e o transforma num login que falhou.

**O bcrypt não exige muita memória.** O estado de trabalho dele tem alguns kilobytes, então um
hardware que roda muitos palpites ao mesmo tempo os acomoda sem dificuldade. Isso, junto com os 72
bytes, é o motivo de a folha da OWASP reservá-lo para sistemas que já o usam e recomendar o Argon2id
para todo o resto.
