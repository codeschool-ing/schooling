---
title: scrypt
version: 1
---

**O scrypt, de 2009, faz cada hash encher um bloco de memória e lê-lo de volta numa ordem que depende
da senha.** Tempo sozinho se compra barato com mais chips rodando lado a lado. Memória não, porque
cada palpite em andamento precisa do próprio bloco, e por isso o scrypt é **memory-hard**: o custo de
um palpite é tempo e memória juntos.

Ele tem três parâmetros:

| | nome | o que define |
|---|---|---|
| `N` | custo | quantos blocos, uma potência de dois; dobrá-lo dobra a memória e o tempo |
| `r` | tamanho do bloco | cada bloco tem `128 × r` bytes; `r=8` dá 1024 |
| `p` | paralelismo | quantas execuções independentes, cada uma precisando da memória de novo, uma de cada vez |

A memória que um hash precisa é `128 × r × N` bytes. A primeira configuração da OWASP,
`N=2^17, r=8, p=1`, dá 128 MiB. O Python tem scrypt no `hashlib`, e pedir essa configuração falha:

```
ana@api:~/shelf$ python3 -c 'import hashlib, os; print(hashlib.scrypt(b"correct horse battery staple", salt=os.urandom(16), n=2**17, r=8, p=1).hex())'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ValueError: [digital envelope routines] memory limit exceeded
```

É o OpenSSL recusando, e é a exigência de memória ficando visível: o teto padrão dele para uma chamada
de scrypt é 32 MiB, muito abaixo do que a configuração pede. Suba-o com `maxmem`, em bytes, e a mesma
chamada funciona; `dklen` é quantos bytes de hash devolver:

```
ana@api:~/shelf$ python3 -c 'import hashlib, os; print(hashlib.scrypt(b"correct horse battery staple", salt=os.urandom(16), n=2**17, r=8, p=1, maxmem=2**28, dklen=32).hex())'
15138593db714e1e35b06840f0e8aee87051114838f86079c91ac73d6b6824f9
```

A memória é de verdade. O pico de memória do processo inteiro para quatro valores de `N`, cada um o
dobro do anterior:

```
ana@api:~/shelf$ for e in 14 15 16 17; do python3 -c "import hashlib, resource; hashlib.scrypt(b'x', salt=bytes(16), n=2**$e, r=8, p=1, maxmem=2**28); print('N=2^$e', resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024, 'MiB')"; done
N=2^14 29 MiB
N=2^15 45 MiB
N=2^16 77 MiB
N=2^17 141 MiB
```

De 29 a 141 MiB, e cada passo soma o dobro do que o anterior somou. Tire os 13 MiB que são o próprio
Python e o que sobra é exatamente `128 × 8 × N`: 16, 32, 64 e 128 MiB.

**A folha da OWASP lista cinco configurações do scrypt que dão um nível mínimo parecido**, trocando
memória por execuções paralelas:

| N | r | p | memória por execução |
|---|---|---|---|
| 2^17 | 8 | 1 | 128 MiB |
| 2^16 | 8 | 2 | 64 MiB |
| 2^15 | 8 | 3 | 32 MiB |
| 2^14 | 8 | 5 | 16 MiB |
| 2^13 | 8 | 10 | 8 MiB |

## O que o hashlib não entrega

O `hashlib.scrypt` devolve bytes e nada mais: nem salt, nem parâmetros, nem formato. Para guardá-lo
você precisa manter o salt, o `N`, o `r` e o `p` ao lado e inventar um jeito de escrevê-los. A
comparação também fica com você, com `hmac.compare_digest`, que leva o mesmo tempo seja o primeiro
byte o diferente, seja o último; o `==` para na primeira diferença. Cada um desses é um lugar para um erro
que nenhum teste com a senha correta pegaria.

Esse, mais que a velocidade, é o argumento prático contra ele num sistema novo: o bcrypt e o Argon2id
vêm com uma biblioteca que sorteia o salt, escreve o texto e confere, e o scrypt do `hashlib` não. A
linha dele no `hashrate.py` também foi a mais lenta das seis, com 524,392 ms. Isso não diz nada de
ruim sobre o scrypt e diz algo sobre as configurações da OWASP: elas são um nível mínimo de defesa,
não um tempo, e a seção sobre a escolha dos parâmetros mede o que isso significa.
