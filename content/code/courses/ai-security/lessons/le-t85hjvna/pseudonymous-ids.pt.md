---
title: Um identificador que não identifica ninguém lá fora
version: 2
---

O primeiro identificador que vem à cabeça é o que a aplicação já tem para todo mundo: o e-mail.
Enviá-lo poria um dado pessoal em cada requisição, para uma finalidade de que o fornecedor não precisa,
que é exatamente o que o princípio da necessidade da aula 12 proíbe. A segunda ideia é fazer o hash do
endereço antes, e **o hash de um e-mail pode ser revertido por qualquer um capaz de adivinhar
e-mails**.

O `guard enduser` calcula os dois tipos de identificador que esta seção compara: o hash simples, com
`--naive`, e o com chave em que ela termina. Salve-o como `~/guard/tools/enduser.py`; o botão de copiar
dá o programa inteiro, e as notas são para quando a seção chegar a cada parte:

```schooling-example
{"language": "python", "file": "tools/enduser.py", "parts": [
 {"code": "import argparse\nimport hashlib\nimport hmac\nimport os\n", "note": "Três módulos da biblioteca padrão do Python. O `hmac` é o que importa aqui."},
 {"code": "\n\ndef end_user_id(account, key):\n    digest = hmac.new(key, account.encode(), hashlib.sha256).hexdigest()\n    return \"eu-\" + digest[:20]\n", "note": "A entrada é o id interno da conta na Tarefa, não o e-mail, então o id sobrevive a uma troca de endereço. A chave é o segredo. Vinte caracteres hexadecimais são 80 bits: nenhuma de milhões de contas vai colidir, e o id ainda cabe numa linha de log."},
 {"code": "\n\ndef naive_id(email):\n    return hashlib.sha256(email.strip().lower().encode()).hexdigest()\n", "note": "A versão contra a qual esta seção argumenta, mantida para o `guard reverse` poder mostrá-la revertida."},
 {"code": "\n\nif __name__ == \"__main__\":\n    p = argparse.ArgumentParser(prog=\"guard enduser\")\n    p.add_argument(\"account\", nargs=\"?\")\n    p.add_argument(\"--provider\", default=\"provider-a\")\n    p.add_argument(\"--naive\")\n    a = p.parse_args()\n    if a.naive:\n        print(naive_id(a.naive))\n    else:\n        with open(os.path.expanduser(\"~/guard/keys/%s.key\" % a.provider), \"rb\") as f:\n            print(end_user_id(a.account, f.read().strip()))\n", "note": "O comando: `--naive` imprime o hash simples de um endereço; senão, ele lê a chave do fornecedor em `~/guard/keys/` e imprime o id com chave de uma conta."}
]}
```

Os identificadores com chave precisam de uma chave por fornecedor. Estas duas são texto fixo, para que
os seus identificadores batam com os impressos aqui; o fim da seção diz como é uma de verdade:

```sh
mkdir -p ~/guard/keys
printf 'lab-key-for-provider-a-not-secret-0001\n' > ~/guard/keys/provider-a.key
printf 'lab-key-for-provider-b-not-secret-0002\n' > ~/guard/keys/provider-b.key
```

Mais dois programas: um escreve uma lista de palpites com 400 endereços, e o outro testa cada endereço
de uma lista contra um identificador. Salve-os como `~/guard/tools/emails.py` e
`~/guard/tools/reverse.py`:

```python
# emails.py: write a guessing list of e-mail addresses, one per line.
#
#   guard emails > FILE
#
# Every first name below with every surname, at one domain: 400 addresses.
# The names are common in Brazil and the addresses invented; example.com.br
# is a domain nobody receives mail at.
FIRST = ["ana", "bruno", "carla", "diego", "elisa", "fernanda", "gustavo", "helena",
         "igor", "juliana", "karina", "lucas", "marcos", "natalia", "otavio", "paula",
         "rafael", "sofia", "tiago", "vitoria"]
LAST = ["almeida", "barros", "costa", "dias", "ferreira", "gomes", "lima", "moreira",
        "nunes", "oliveira", "prado", "ribeiro", "rocha", "santos", "silva", "souza",
        "teixeira", "vieira", "xavier", "zanetti"]
for f in FIRST:
    for s in LAST:
        print("%s.%s@example.com.br" % (f, s))
```

```python
# reverse.py: a dictionary attack on an end-user id, to show which ids resist one.
#
#   guard reverse ID --list FILE
#
# It hashes every address in FILE the way naive_id() does and compares. Exit
# status 0 if it found the address, 1 if not.
import argparse
import sys

from enduser import naive_id

p = argparse.ArgumentParser(prog="guard reverse")
p.add_argument("id")
p.add_argument("--list", required=True)
a = p.parse_args()

with open(a.list, encoding="utf-8") as f:
    guesses = [line.strip() for line in f if line.strip()]
for n, guess in enumerate(guesses, 1):
    if naive_id(guess) == a.id:
        print("found after %d guesses: %s" % (n, guess))
        sys.exit(0)
print("not found in %d guesses" % len(guesses))
sys.exit(1)
```

Agora faça o hash simples do endereço de um cliente, e tente recuperá-lo:

```
ana@lab:~/guard$ guard emails > data/emails.txt
ana@lab:~/guard$ guard enduser --naive marcos.teixeira@example.com.br
e99036a63befa4e2995bd6ba388d0586cfbc78dd4eb31af863f558d7fd630894
ana@lab:~/guard$ head -3 data/emails.txt; wc -l data/emails.txt
ana.almeida@example.com.br
ana.barros@example.com.br
ana.costa@example.com.br
400 data/emails.txt
ana@lab:~/guard$ guard reverse e99036a63befa4e2995bd6ba388d0586cfbc78dd4eb31af863f558d7fd630894 --list data/emails.txt
found after 257 guesses: marcos.teixeira@example.com.br
```

Um SHA-256 não pode ser invertido, e não precisa ser. O `guard reverse` faz o hash de cada endereço de
uma lista e compara, e a lista aqui é só cada primeiro nome comum com cada sobrenome comum, num domínio.
O endereço foi o 257º palpite. Atacantes de verdade usam listas de milhões de endereços de vazamentos
anteriores, e um computador moderno calcula milhões de SHA-256 por segundo. O hash acrescenta um
passo, e nenhum segredo.

## Um hash com chave

O conserto é fazer o hash depender de algo que o atacante não tem. Um **HMAC** é um hash calculado com
uma chave secreta misturada, de modo que calculá-lo, e portanto conferir um palpite, exige a chave. Esse é o
`end_user_id` do programa acima: uma chamada a `hmac.new`, com a chave do fornecedor.

Três execuções mostram as propriedades que importam:

```
ana@lab:~/guard$ guard enduser ac-7Q2M
eu-fe47aa8e7cd5e1b6f8bc
ana@lab:~/guard$ guard enduser ac-9D4H
eu-ac8948151bbc5139ccb1
ana@lab:~/guard$ guard enduser ac-7Q2M --provider provider-b
eu-4805e698e5809587d84d
ana@lab:~/guard$ guard reverse eu-fe47aa8e7cd5e1b6f8bc --list data/emails.txt; echo "exit $?"
not found in 400 guesses
exit 1
```

- **Estável.** `ac-7Q2M` dá `eu-fe47aa8e7cd5e1b6f8bc` em toda chamada, então o fornecedor consegue ver
  que quarenta requisições ruins vieram de uma pessoa, e a Tarefa consegue ligar o identificador à
  conta calculando-o de novo.
- **Diferente por fornecedor.** Com a chave do `provider-b`, a mesma conta vira
  `eu-4805e698e5809587d84d`. Se a Tarefa usa dois fornecedores e os dois vazam, ou os dois têm os
  registros requisitados, os dois conjuntos de identificadores não podem ser cruzados.
- **Irreversível sem a chave.** O dicionário que achou o hash simples não acha nada.

As chaves que você salvou são texto fixo, para que estas capturas imprimam os mesmos identificadores
toda vez. Uma chave de verdade é aleatória, tem pelo menos 32 bytes e fica no mesmo
cofre de segredos que a própria chave de API, nunca num arquivo ao lado do código.

## O que a chave decide

Duas consequências práticas vêm de o identificador depender de uma chave.

**Trocar a chave muda todo identificador.** Depois de uma troca, o fornecedor vê um conjunto novo de
usuários, e qualquer histórico de abuso que ele tenha atribuído aos identificadores antigos fica
solto. Às vezes é o que você quer, depois de a chave vazar, e em geral não é. Troque quando a chave
puder estar comprometida, e não por calendário.

**O identificador ainda é dado pessoal na Tarefa**, pelo raciocínio da aula 12: a Tarefa tem a chave,
então para ela o dado é pseudonimizado. Ele vai nos logs da aula 11 no lugar do e-mail. E, depois que
uma conta é eliminada, os identificadores que o fornecedor guarda apontam para uma conta que não existe
mais, então não identificam ninguém, nem para a Tarefa nem para outra pessoa.
