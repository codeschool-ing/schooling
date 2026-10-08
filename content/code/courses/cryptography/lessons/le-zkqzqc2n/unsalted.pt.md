---
title: Por que um hash simples é o jeito errado de guardar uma senha
version: 1
---

**Um sistema nunca precisa saber a senha de um usuário, só reconhecê-la.** Então ele guarda algo
derivado da senha e, no login, deriva a mesma coisa do que foi digitado e compara. O hash da aula 4
parece a ferramenta óbvia para isso, e é o começo da resposta certa, não a resposta. Esta seção
mostra os três problemas de guardar um SHA-256 simples, usando as oito contas da equipe da Vereda.

## As contas

O portal da Vereda tem oito contas de funcionários, e o primeiro arquivo desta aula são elas com as
senhas que os donos escolheram. O curso as escreveu para serem ruins dos jeitos de sempre; ninguém
as usa para nada. Os mesmos comandos criam a **pimenta** que a seção 05 usa, 32 bytes do `vcrypt
derive`:

```sh
cd ~/lab
cat > data/users.csv <<'EOF'
user,password
ana.lima,Vereda@2026
bruno.reis,fisio123
carla.souza,Vereda@2026
diego.alves,correct horse battery staple
elisa.prado,fisio123
fabio.nunes,Vereda@2026
gabi.torres,m4r3-alta-em-ub@tub@
hugo.matos,Primavera#2026
EOF
vcrypt derive pepper 32 > keys/pepper.hex
```

```
ana@lab:~/lab$ cat data/users.csv
user,password
ana.lima,Vereda@2026
bruno.reis,fisio123
carla.souza,Vereda@2026
diego.alves,correct horse battery staple
elisa.prado,fisio123
fabio.nunes,Vereda@2026
gabi.torres,m4r3-alta-em-ub@tub@
hugo.matos,Primavera#2026
```

Um sistema real nunca tem esse arquivo. Ele está aqui para você ver o que cada esquema de
armazenamento faz com as mesmas senhas.

## Cinco jeitos de guardá-las

Cada esquema desta aula é uma função num único arquivo, do pior ao que se deve usar. Só o primeiro,
`sha256`, importa nesta seção; os outros são o assunto das três seguintes, e cada seção aponta as
linhas que usa:

```py
# ~/lab/tools/passwords.py
"""Five ways to store a password, from the worst to the one to use, and the
check that goes with each. Every salt here comes from drbg.py so that your
stores match the lesson's; a real system draws each salt from os.urandom at
the moment it stores the password."""
import base64
import hashlib
import hmac

import bcrypt
from cryptography.hazmat.primitives.kdf.argon2 import Argon2id

import drbg

POLICY = {"pbkdf2": 600_000, "bcrypt": 12, "argon2id": (19456, 2, 1)}
BCRYPT_ALPHABET = "./ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"


def b64(b):
    return base64.b64encode(b).decode().rstrip("=")


def unb64(s):
    return base64.b64decode(s + "=" * (-len(s) % 4))


def salt(scheme, user):
    return drbg.stream(f"salt/{scheme}/{user}", 16)


def peppered(password, pepper):
    """With a pepper, the password is first run through an HMAC under it."""
    if pepper is None:
        return password.encode()
    return hmac.new(pepper, password.encode(), hashlib.sha256).hexdigest().encode()


def store(scheme, user, password, pepper=None, cost=None):
    pw = peppered(password, pepper)
    if scheme == "sha256":
        return hashlib.sha256(pw).hexdigest()
    if scheme == "salted-sha256":
        s = salt(scheme, user)
        return f"sha256${b64(s)}${hashlib.sha256(s + pw).hexdigest()}"
    if scheme == "pbkdf2":
        n, s = cost or POLICY["pbkdf2"], salt(scheme, user)
        return f"pbkdf2-sha256${n}${b64(s)}${b64(hashlib.pbkdf2_hmac('sha256', pw, s, n))}"
    if scheme == "bcrypt":
        c = cost or POLICY["bcrypt"]
        raw = drbg.stream(f"salt/bcrypt/{user}", 22)
        s = "".join(BCRYPT_ALPHABET[x % 64] for x in raw[:21]) + "u"
        return bcrypt.hashpw(pw, f"$2b${c:02d}${s}".encode()).decode()
    if scheme == "argon2id":
        m, t, p = cost or POLICY["argon2id"]
        return Argon2id(salt=salt(scheme, user), length=32, iterations=t, lanes=p,
                        memory_cost=m).derive_phc_encoded(pw)
    raise ValueError(scheme)


def verify(stored, password, pepper=None):
    """(the password is right, why the stored value needs redoing or None)"""
    pw = peppered(password, pepper)
    if stored.startswith("$argon2id$"):
        try:
            Argon2id.verify_phc_encoded(pw, stored)
            ok = True
        except Exception:  # the library's answer to a wrong password
            ok = False
        params = dict(kv.split("=") for kv in stored.split("$")[3].split(","))
        m, t, p = POLICY["argon2id"]
        weak = int(params["m"]) < m or int(params["t"]) < t
        return ok, (f"stored m={params['m']},t={params['t']} is below the policy m={m},t={t}" if weak else None)
    if stored.startswith("$2b$"):
        c = int(stored.split("$")[2])
        return bcrypt.checkpw(pw, stored.encode()), (
            f"stored cost {c} is below the policy {POLICY['bcrypt']}" if c < POLICY["bcrypt"] else None)
    if stored.startswith("pbkdf2-sha256$"):
        _, n, s, h = stored.split("$")
        ok = hmac.compare_digest(b64(hashlib.pbkdf2_hmac("sha256", pw, unb64(s), int(n))), h)
        return ok, (f"stored {n} iterations is below the policy {POLICY['pbkdf2']}"
                    if int(n) < POLICY["pbkdf2"] else None)
    if stored.startswith("sha256$"):
        _, s, h = stored.split("$")
        return hmac.compare_digest(hashlib.sha256(unb64(s) + pw).hexdigest(), h), "a fast hash is below every policy"
    return hmac.compare_digest(hashlib.sha256(pw).hexdigest(), stored), "a fast hash is below every policy"
```

O `vcrypt store` roda um desses esquemas sobre todas as contas do arquivo e mostra o que um sistema
guardaria:

```py
# ~/lab/tools/store.py
"""vcrypt store SCHEME USERS.csv [--pepper KEYFILE] [--cost C]: print one line
user:stored-value for every account, stored with SCHEME (sha256,
salted-sha256, pbkdf2, bcrypt or argon2id). --cost is the iterations for
pbkdf2, the cost for bcrypt, and m,t,p for argon2id."""
import argparse

import passwords

p = argparse.ArgumentParser(prog="vcrypt store")
p.add_argument("scheme", choices=("sha256", "salted-sha256", "pbkdf2", "bcrypt", "argon2id"))
p.add_argument("users")
p.add_argument("--pepper")
p.add_argument("--cost")
a = p.parse_args()

pepper = bytes.fromhex(open(a.pepper).read().strip()) if a.pepper else None
cost = None
if a.cost:
    cost = tuple(int(x) for x in a.cost.split(",")) if a.scheme == "argon2id" else int(a.cost)
for line in open(a.users):
    user, password = line.rstrip("\n").split(",", 1)
    if user != "user":  # the header line
        print(f"{user}:{passwords.store(a.scheme, user, password, pepper, cost)}")
```

## Problema um: senhas iguais ficam visíveis

Guardadas como SHA-256 simples, um valor por conta:

```
ana@lab:~/lab$ vcrypt store sha256 data/users.csv > store-sha256.txt; head -3 store-sha256.txt
ana.lima:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
bruno.reis:3bec5774e1c543e4f58b467da1a227fe3b4c20d9138a43d5735ae73fb1b5d698
carla.souza:9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21
```

Ana e Carla têm o mesmo valor guardado, e o Fábio também, mais abaixo. Uma auditoria que lê só o
arquivo guardado, como qualquer um que o copiasse poderia, diz isso numa linha. Ela inteira é isto:

```py
# ~/lab/tools/audit.py
"""vcrypt audit STORE: how many accounts share one stored value. It reads
only the store, as anybody who copied it could."""
import sys

groups = {}
for line in open(sys.argv[1]):
    user, stored = line.rstrip("\n").split(":", 1)
    groups.setdefault(stored, []).append(user)
shared = [users for users in groups.values() if len(users) > 1]
print(f"{sum(len(u) for u in groups.values())} accounts, {len(groups)} different stored values")
for users in shared:
    print(f"  {len(users)} accounts share one value: {', '.join(users)}")
if not shared:
    print("  no two accounts share a stored value")
```


```
ana@lab:~/lab$ vcrypt audit store-sha256.txt
8 accounts, 5 different stored values
  3 accounts share one value: ana.lima, carla.souza, fabio.nunes
  2 accounts share one value: bruno.reis, elisa.prado
```

Ninguém reverteu nada para descobrir que três pessoas compartilham uma senha e outras duas
compartilham outra. Quem obtém esse arquivo sabe que adivinhar uma delas dá três contas, e que as
compartilhadas provavelmente são as mais fáceis, porque as pessoas convergem para as mesmas
escolhas fáceis.

## Problema dois: o mesmo valor em toda parte

O SHA-256 não tem chave nem segredo, então o resumo de uma senha é o mesmo em todo sistema do
mundo:

```
ana@lab:~/lab$ printf 'Vereda@2026' | sha256sum
9df16d40776efb5be78608628c9b10db311fa65aea35b8c05717df169e83aa21  -
```

Esse é o valor guardado da Ana, calculado na linha de comando só a partir da senha. Isso significa
que uma lista dos resumos de senhas comuns, calculada uma vez, serve contra **todo** banco sem sal
que já vazou. Essas listas pré-calculadas, e a forma comprimida delas chamada *rainbow tables*,
existem há décadas. Contra um hash simples, uma boa parte das senhas reais é achada por uma
consulta, não por cálculo nenhum.

## Problema três: ele é rápido

O SHA-256 foi projetado para ser rápido, porque calcula o hash de downloads e discos. Aqui isso é
exatamente o errado. Uma única GPU moderna calcula **bilhões** de resumos SHA-256 por segundo, então
mesmo uma senha que ninguém pré-calculou é testada contra bilhões de candidatas por segundo. Uma
senha de oito letras minúsculas tem cerca de 200 bilhões de possibilidades, o que dá minutos de
trabalho.

A defesa tem três partes, e elas são o resto desta aula:

| problema | correção | seção |
|---|---|---|
| senhas iguais visíveis, listas pré-calculadas funcionam | um **sal** único por conta | 03 |
| bilhões de palpites por segundo | uma função deliberadamente **lenta**: bcrypt, Argon2id | 04 |
| o banco sozinho basta para começar a adivinhar | uma **pimenta** guardada fora do banco | 05 |

Nenhuma delas torna forte uma senha fraca. O que elas fazem é deixar cada palpite caro e obrigar o
atacante a adivinhar cada conta separadamente, o que transforma o vazamento do banco inteiro num
ataque lento e caro a poucas contas, e compra o tempo de redefini-las.
