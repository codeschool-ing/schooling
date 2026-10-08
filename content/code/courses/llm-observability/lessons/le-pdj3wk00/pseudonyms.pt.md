---
title: Um nome para o usuário que não é o id dele
version: 2
---

As aulas 3 e 5 contam por usuário: os usuários que mais usam, as pessoas que deram polegar para baixo
duas vezes. Isso exige o mesmo valor em todo pedido de uma pessoa. Não exige que seja o id da conta
dela, e não deveria ser, porque o id da conta leva a qualquer lugar a que a conta leva.

A resposta de costume é um **pseudônimo**: um valor derivado do id, sempre o mesmo, do qual o id não
pode ser lido. O jeito óbvio de derivá-lo, um hash, não funciona:

```python
"""pseudo.py: why a user id is hashed with a key, and never without one."""
import hashlib
import time

import redact

guesses = [f"u{i:03d}" for i in range(1000)]          # the shape anyone can see the ids have
unkeyed = hashlib.sha256(b"u021").hexdigest()[:16]
t = time.perf_counter()
back = [g for g in guesses if hashlib.sha256(g.encode()).hexdigest()[:16] == unkeyed]
print(f"unkeyed {unkeyed}: {len(guesses)} guesses in {(time.perf_counter() - t) * 1000:.1f} ms find {back}")
keyed = redact.pseudonym("u021")
back = [g for g in guesses if hashlib.sha256(g.encode()).hexdigest()[:16] == keyed]
print(f"keyed   {keyed}: the same {len(guesses)} guesses find {back}")
```

```
ana@dev:~/obs$ python pseudo.py
unkeyed cc5487e17071feac: 1000 guesses in 0.6 ms find ['u021']
keyed   5735c1a8554810c6: the same 1000 guesses find []
```

**Um hash de algo adivinhável é a própria coisa, com um passo no meio.** Ids de usuário têm forma, `u`
e três dígitos aqui, um endereço de e-mail ou um número sequencial em outros lugares, e qualquer um
com o trace consegue fazer o hash de cada candidato e comparar. Mil palpites levaram menos de um
milissegundo. Endereços de e-mail levam mais tempo e caem do mesmo jeito, porque os palpites saem de
listas de endereços reais.

O `redact.pseudonym()` usa **HMAC**: um hash misturado com uma chave secreta. Sem a chave, os palpites
não levam a nada, como mostra a segunda linha; com ela, o mesmo usuário recebe sempre o mesmo valor,
então contar por usuário continua funcionando. A chave mora com os outros segredos da aplicação,
nunca no armazém de traces e nunca no código.

## O que a chave compra, e o que não compra

O pseudônimo pode ser revertido por quem tem a chave, fazendo o hash de cada id de usuário até um
bater, então nos termos da LGPD isto ainda é dado pessoal: **pseudonimizado, não anonimizado**. Trate o
armazém de traces de acordo. O que a chave compra é que as pessoas que leem traces, e qualquer um que
consiga uma cópia deles, não vão de uma linha a uma pessoa sem pedir a alguém que tem a chave.

Ela também compra uma saída. **Jogue a chave fora, e todo pseudônimo já escrito perde o sentido**, e é
assim que traces antigos podem ser desligados das pessoas que estão neles sem reescrever um único
span. Troque a chave todo mês, e os pseudônimos de cada mês se ligam entre si e não com os do mês
seguinte: contagens por usuário dentro de um mês continuam funcionando, e não dá para seguir uma
pessoa ao longo de um ano. Se essa é a troca certa depende de para que servem as contagens; o ponto é
que é uma configuração, decidida uma vez, e não uma propriedade de todo trace já escrito.

E sem chave, sem pseudônimo:

```
ana@dev:~/obs$ PSEUDONYM_KEY= python assistant.py --user u021 "How long is a gift card valid?"
Traceback (most recent call last):
  File "/home/ana/obs/assistant.py", line 149, in <module>
    reply, sources, trace_id = ask(a.question, user=a.user, feature=a.feature)
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/obs/assistant.py", line 115, in ask
    "user.hash": redact.pseudonym(user), "session.id": session or "",
                 ^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/obs/redact.py", line 38, in pseudonym
    raise RuntimeError("PSEUDONYM_KEY is not set: refusing to record a user id unkeyed")
RuntimeError: PSEUDONYM_KEY is not set: refusing to record a user id unkeyed
```

A função se recusa em vez de recorrer a um hash sem chave. Um recurso alternativo aqui funcionaria,
passaria em todo teste que não olha os valores, e escreveria um id reversível em todo span dali em
diante, em silêncio. Um pedido que falha alto é o resultado melhor.
