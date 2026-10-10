---
title: Escolhendo os parâmetros
version: 1
---

**Os parâmetros são um orçamento, não uma constante.** Você os escolhe medindo na máquina que vai
rodá-los, partindo de um mínimo publicado e subindo até um hash custar o que um login pode pagar.
Depois os escreve num lugar só, porque eles vão mudar de novo.

A regra tentadora é "quanto maior, melhor". Ela falha duas vezes. Cada login segura a memória dele
enquanto o hash roda, então vinte pessoas entrando ao mesmo tempo precisam de vinte vezes o `m`. E
cada login custa ao servidor o que custa a um atacante por palpite, então uma configuração que leva
segundos transforma a rota de login no jeito mais barato de esgotar o servidor. A folha da OWASP avisa
exatamente sobre isso, e a aula 12 limita quantas vezes um cliente pode pedir.

O `hashrate.py argon2` mede as cinco configurações da OWASP, o padrão da biblioteca e duas maiores:

```
ana@api:~/shelf$ python3 hashrate.py argon2
algorithm settings              hashes/s   ms each    a million
Argon2id  m=7168 t=5 p=1            35.3    28.368        7.9 h
Argon2id  m=9216 t=4 p=1            34.1    29.326        8.1 h
Argon2id  m=12288 t=3 p=1           30.6    32.691        9.1 h
Argon2id  m=19456 t=2 p=1           25.0    40.003       11.1 h
Argon2id  m=47104 t=1 p=1            9.8   102.377     1.2 days
Argon2id  m=65536 t=2 p=1            5.2   192.576     2.2 days
Argon2id  m=102400 t=2 p=8           5.5   181.533     2.1 days
Argon2id  m=262144 t=2 p=1           1.1   871.884    10.1 days
```

**As cinco linhas da OWASP dão o mesmo nível de defesa, e nesta máquina não levam o mesmo tempo**:
28,368 ms em `m=7168 t=5` e 102,377 ms em `m=47104 t=1`. Memória também custa tempo, porque precisa
ser preenchida. O padrão da biblioteca, oito faixas sobre 100 MiB, levou 181,533 ms, menos que uma
faixa sobre 64 MiB, porque as faixas dele rodam lado a lado em núcleos separados.

Ponha a memória ao lado do tempo e a escolha vira aritmética. Os milissegundos são desta execução; a
memória sai do `m`:

| configuração | ms por hash, nesta execução | memória por login | vinte logins ao mesmo tempo |
|---|---|---|---|
| `m=19456 t=2 p=1` | 40,003 | 19 MiB | 380 MiB |
| `m=47104 t=1 p=1` | 102,377 | 46 MiB | 920 MiB |
| `m=65536 t=2 p=1` | 192,576 | 64 MiB | 1,25 GiB |
| `m=262144 t=2 p=1` | 871,884 | 256 MiB | 5 GiB |

O procedimento, em ordem:

1. Parta do mínimo da OWASP, que para o Argon2id é `m=19456 t=2 p=1`.
2. Meça numa máquina como a que atende os logins, e não no seu notebook.
3. Suba primeiro o `m`, depois o `t`, até um hash levar o que um login pode gastar. A regra da folha é
   que leve menos de um segundo.
4. Multiplique a memória pelos logins que você espera no mesmo instante e confira se o servidor a tem.
5. Escreva o resultado num lugar só do código e deixe os hashes antigos se atualizarem conforme as
   pessoas entram.

O último passo é o que a próxima seção constrói. Uma configuração escolhida hoje fica errada em alguns
anos, porque o hardware barateia, e são os textos guardados que tornam a troca indolor.
