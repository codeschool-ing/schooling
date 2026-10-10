---
title: Argon2id
version: 1
---

**O Argon2 venceu a Password Hashing Competition em 2015 e está especificado na RFC 9106.** Ele exige
memória como o scrypt, e seus três custos são parâmetros separados. Vem em três variantes, e o
**Argon2id** é a que se usa. O Argon2d lê a memória numa ordem que depende da senha, o que resiste
melhor ao hardware e pode vazar pelo tempo. O Argon2i a lê numa ordem fixa, que não vaza nada e é mais
fraca contra hardware. O Argon2id faz a primeira metade da primeira passada como o Argon2i, e tudo o
que vem depois como o Argon2d.

Os três parâmetros, com os nomes que o texto guardado usa:

| | o que define | unidade |
|---|---|---|
| `m` | memória, preenchida e lida a cada hash | KiB |
| `t` | passadas sobre essa memória | uma contagem |
| `p` | faixas em que a memória é dividida, que podem rodar em núcleos separados | uma contagem |

**O `p` não é um multiplicador.** Dobrar o `m` dobra a memória, e dobrar o `t` dobra o tempo, mas
`p=8` divide o mesmo `m` em oito faixas; não usa oito vezes mais. A folha da OWASP diz isso com essas
palavras, porque é o parâmetro mais lido errado.

A biblioteca `argon2` do Python escreve o hash como um **texto PHC**, a mesma ideia do bcrypt, com
nomes nos campos:

```
ana@api:~/shelf$ python3 -c 'from argon2 import PasswordHasher; print(PasswordHasher(memory_cost=19456, time_cost=2, parallelism=1).hash("correct horse battery staple"))'
$argon2id$v=19$m=19456,t=2,p=1$a/RjYqg2aPC6PMMVzqVVbQ$40Wj1p8F++dmvFO0JQq0vg
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 190\" role=\"img\" aria-label=\"O texto do Argon2id $argon2id$v=19$m=19456,t=2,p=1$a/RjYqg2aPC6PMMVzqVVbQ$40Wj1p8F++dmvFO0JQq0vg cortado em cinco campos separados por cifrões: a variante argon2id, a versão v=19, os parâmetros m=19456,t=2,p=1, o salt e o hash, os dois em base64 sem preenchimento.\"><rect x=\"20\" y=\"40\" width=\"71.4\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"55.7\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$argon2id</text><line x1=\"55.7\" y1=\"74\" x2=\"55.7\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"55.7\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">variante</text><text x=\"55.7\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">id: Argon2id</text><rect x=\"96.4\" y=\"40\" width=\"45.0\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"118.9\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$v=19</text><line x1=\"118.9\" y1=\"74\" x2=\"118.9\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"118.9\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">versão</text><text x=\"118.9\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">19 = 0x13</text><rect x=\"146.4\" y=\"40\" width=\"117.6\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"205.2\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$m=19456,t=2,p=1</text><line x1=\"205.2\" y1=\"74\" x2=\"205.2\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"205.2\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">parâmetros</text><text x=\"205.2\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">KiB, passadas, faixas</text><rect x=\"269.0\" y=\"40\" width=\"163.79999999999998\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.9\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$a/RjYqg2aPC6PMMVzqVVbQ</text><line x1=\"350.9\" y1=\"74\" x2=\"350.9\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"350.9\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">salt</text><text x=\"350.9\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">16 bytes, base64</text><rect x=\"437.79999999999995\" y=\"40\" width=\"163.79999999999998\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"519.6999999999999\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">$40Wj1p8F++dmvFO0JQq0vg</text><line x1=\"519.6999999999999\" y1=\"74\" x2=\"519.6999999999999\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"519.6999999999999\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash</text><text x=\"519.6999999999999\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">16 bytes, base64</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">m: memória em KiB</text><text x=\"210\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">t: passadas sobre ela</text><text x=\"400\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">p: faixas em que se divide</text></svg>", "caption": "O formato de texto PHC: campos entre cifrões, os parâmetros em pares nome=valor.", "same": ["16 bytes, base64", "19 = 0x13", "hash", "id: Argon2id", "salt"]}
```

Leia campo por campo: a variante, `argon2id`; a versão do algoritmo, `v=19`; os três custos,
`m=19456,t=2,p=1`; o salt; o hash. Como o do bcrypt, é tudo o que uma conferência posterior precisa,
e é isso que deixa os parâmetros mudarem sem ninguém perder a senha: cada linha diz com quais foi
feita.

Os padrões da própria biblioteca, quando você chama `PasswordHasher()` sem argumentos, são maiores
que os desse texto:

```
ana@api:~/shelf$ python3 -c 'from argon2 import PasswordHasher; ph = PasswordHasher(); print(ph.memory_cost, ph.time_cost, ph.parallelism)'
102400 2 8
```

100 MiB, duas passadas, oito faixas. A memória é ocupada de verdade, como no scrypt: o pico do
processo inteiro para três valores de `m`, em que uns 13 MiB são o próprio Python:

```
ana@api:~/shelf$ for m in 19456 47104 102400; do python3 -c "import resource; from argon2 import PasswordHasher; PasswordHasher(memory_cost=$m, time_cost=2, parallelism=1).hash('x'); print('m=$m', resource.getrusage(resource.RUSAGE_SELF).ru_maxrss // 1024, 'MiB')"; done
m=19456 29 MiB
m=47104 56 MiB
m=102400 110 MiB
```

## As configurações da OWASP

O Password Storage Cheat Sheet da OWASP dá cinco configurações **mínimas** para o Argon2id e diz que
elas oferecem o mesmo nível de defesa, trocando memória por passadas:

| m | memória | t | p |
|---|---|---|---|
| 47104 | 46 MiB | 1 | 1 |
| 19456 | 19 MiB | 2 | 1 |
| 12288 | 12 MiB | 3 | 1 |
| 9216 | 9 MiB | 4 | 1 |
| 7168 | 7 MiB | 5 | 1 |

A folha acrescenta que as duas primeiras não servem para o Argon2i, e que as configurações devem ser
medidas no sistema que vai rodá-las, e não copiadas. O texto acima usa a segunda linha, e o
`passwords.py` também. Escolher entre elas, ou acima delas, é a próxima seção.
