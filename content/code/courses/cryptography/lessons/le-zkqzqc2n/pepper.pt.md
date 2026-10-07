---
title: Uma pimenta, o segredo guardado fora do banco
version: 1
---

**Uma pimenta (*pepper*) é uma chave secreta, uma para o sistema inteiro, misturada a cada senha
antes do hash e guardada em outro lugar que não o banco de dados.** O sal e o custo supõem que o
atacante tem o banco e deixam a adivinhação lenta. A pimenta mira um caso mais estreito e comum: um
atacante que tem o banco e **mais nada**, que é o que um backup vazado ou uma injeção no banco
costuma dar. Sem a pimenta, ele não consegue testar um único palpite.

## Acrescentando uma

A pimenta do laboratório é o `keys/pepper.hex`, os 32 bytes criados no começo desta aula; uma de
verdade são 32 bytes aleatórios. O `vcrypt store --pepper` primeiro calcula um HMAC da senha com a
pimenta como chave, que é a `peppered()` do `passwords.py`, e depois entrega isso ao Argon2id
exatamente como antes:

```
ana@lab:~/lab$ vcrypt store argon2id --pepper keys/pepper.hex data/users.csv > store-peppered.txt; head -1 store-peppered.txt
ana.lima:$argon2id$v=19$m=19456,t=2,p=1$FuRufmOK/RUsaLq6VND23g$0bKIIWlMFo4QB835pvClZQ3MfzfJrRD46zCFpP6W/Rw
```

A string guardada parece qualquer outro hash Argon2id. Ela tem até o mesmo sal da linha da Ana na
seção anterior, porque o laboratório deriva os sais por usuário; o resultado é diferente porque a
entrada do Argon2id foi o valor com pimenta. Conferir uma senha é a outra metade do arquivo, a
`verify()`, e o `vcrypt verify` pergunta a ela o que um formulário de login perguntaria:

```py
# ~/lab/tools/verify.py
"""vcrypt verify STORE USER PASSWORD [--pepper KEYFILE]: what a sign-in form
does with what was typed. An unknown user gets the same answer as a wrong
password, on purpose."""
import argparse
import sys

import passwords

p = argparse.ArgumentParser(prog="vcrypt verify")
p.add_argument("store")
p.add_argument("user")
p.add_argument("password")
p.add_argument("--pepper")
a = p.parse_args()

pepper = bytes.fromhex(open(a.pepper).read().strip()) if a.pepper else None
for line in open(a.store):
    user, stored = line.rstrip("\n").split(":", 1)
    if user == a.user:
        ok, weak = passwords.verify(stored, a.password, pepper)
        if ok:
            print(f"{a.user}: password accepted" + (f"; rehash now: {weak}" if weak else ""))
            sys.exit(0)
        break
print(f"{a.user}: wrong password")
sys.exit(1)
```

Com a pimenta, a senha da Ana é aceita:

```
ana@lab:~/lab$ vcrypt verify --pepper keys/pepper.hex store-peppered.txt ana.lima 'Vereda@2026'
ana.lima: password accepted
```

Sem ela, a mesma senha é recusada, e é exatamente essa a ideia: quem tem só o
`store-peppered.txt` não consegue nem conferir um palpite certo.

```
ana@lab:~/lab$ vcrypt verify store-peppered.txt ana.lima 'Vereda@2026'
ana.lima: wrong password
```

## Onde a pimenta mora

Uma pimenta só vale alguma coisa se **não** estiver onde o banco está:

- num gerenciador de segredos ou num módulo de segurança de hardware que a aplicação lê na
  inicialização, não numa tabela do mesmo banco;
- não no repositório da aplicação, pelos motivos da aula 17;
- a mesma para todas as contas, porque é uma chave, não um sal.

O arranjo mais forte a mantém dentro de um HSM e pede ao HSM que calcule o HMAC, então a pimenta
nunca chega a existir na memória da aplicação.

## O que ela custa

Uma pimenta acrescenta uma chave para gerenciar, e chaves precisam poder ser trocadas. Trocar uma
pimenta não consegue recalcular os hashes guardados, porque ninguém conhece as senhas. A resposta de
costume é um **identificador** da pimenta em cada registro guardado: senhas novas usam a pimenta
nova, registros antigos continuam nomeando a antiga, e cada usuário passa para a pimenta nova na
próxima vez que entra, pelo mesmo mecanismo da próxima seção. Perca a pimenta e toda senha do banco
se perde junto, então ela tem backup com o cuidado do próprio banco, em separado.

A pimenta é opcional e o sal não. A OWASP a lista como defesa adicional, que vale a pena onde a
infraestrutura para guardar uma chave à parte já existe.
