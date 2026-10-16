---
title: Gerando dados com um script curto
version: 1
---

Uma testadora que precisa de cinco contas pode se cadastrar cinco vezes à mão, e deve, uma vez: é
assim que o formulário de cadastro é testado. Na sexta vez é digitação, não teste, e lá pela
quinquagésima é na digitação que estão os erros. **Dados gerados são dados que um programa inventa
segundo uma regra que você escreve, para que saiam iguais toda vez, em qualquer quantidade, e sem
os dados de ninguém.** Esta seção dá um programa que faz isso para o boxoffice, roda-o e lê o que
ele produziu.

## O programa

Ele faz três coisas: inventa um número de contas, guarda-as num arquivo CSV para que você saiba
exatamente o que foi criado, e cadastra cada uma no boxoffice pelo mesmo formulário que um
navegador envia. Crie um arquivo novo no seu diretório `boxoffice`, cole o programa nele e salve.
Salve como `make_accounts.py`, exatamente esse nome:

```python
"""make_accounts.py: invent test accounts, save them as CSV and sign them up in boxoffice.

    python3 make_accounts.py 5        five accounts, into accounts.csv and into boxoffice
"""
import csv
import random
import re
import sys
from urllib.parse import urlencode
from urllib.request import urlopen

FIRST = ["Ana", "Bruno", "Caio", "Débora", "Enzo", "Fernanda", "Gustavo", "Helena", "Iara", "João"]
LAST = ["Almeida", "Barbosa", "Cardoso", "Duarte", "Esteves", "Farias", "Gonçalves", "Machado"]
LETTERS = "abcdefghijkmnpqrstuvwxyz23456789"

count = int(sys.argv[1]) if len(sys.argv) > 1 else 5
rng = random.Random(1)                  # the same seed makes the same accounts on every run

rows = []
for n in range(1, count + 1):
    first, last = rng.choice(FIRST), rng.choice(LAST)
    rows.append({
        "name": f"{first} {last}",
        "email": f"test{n:03d}@example.org",       # example.org belongs to nobody
        "password": "".join(rng.choices(LETTERS, k=rng.randint(8, 16))),
    })

with open("accounts.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["name", "email", "password"])
    writer.writeheader()
    writer.writerows(rows)

for row in rows:
    form = urlencode(row).encode()
    with urlopen("http://127.0.0.1:8000/signup", data=form) as answer:
        page = answer.read().decode()
    message = re.search(r'class="msg">([^<]*)', page).group(1)
    print(f"{row['email']}  {message}")
```

Nada nele está fora da biblioteca padrão do Python. **Os nomes** são sorteados de duas listas curtas
de nomes e sobrenomes brasileiros, com acento, porque um campo de nome que só viu `Test User` nunca
foi perguntado sobre `Débora` ou `Gonçalves`. **Os endereços de e-mail** são numerados, para que
nenhum colida, e estão todos em `example.org`, um domínio reservado para exemplos, onde nenhum
cliente consegue ter um endereço. **As senhas** têm de 8 a 16 caracteres de um conjunto que deixa de
fora letras fáceis de confundir com dígitos, dentro dos 8 a 64 que o R2 permite.

A linha que faz dele uma ferramenta de teste, e não um brinquedo, é `random.Random(1)`. Um gerador
aleatório que parte da mesma **semente** produz a mesma sequência toda vez, então este programa
inventa as mesmas cinco contas hoje, amanhã e na máquina do Rui. A seção 05 desta aula trata de por
que isso importa.

## Rodando

Com o boxoffice 1.1 rodando num terminal, rode o programa em outro, no diretório `boxoffice`:

```
ana@laptop:~/boxoffice$ python3 make_accounts.py 5
test001@example.org  Account created. We sent a link to test001@example.org.
test002@example.org  Account created. We sent a link to test002@example.org.
test003@example.org  Account created. We sent a link to test003@example.org.
test004@example.org  Account created. We sent a link to test004@example.org.
test005@example.org  Account created. We sent a link to test005@example.org.
```

Cada linha é um endereço e a mensagem com que o boxoffice respondeu, a mesma frase que a página de
cadastro mostra no navegador. O arquivo que ele salvou é o registro do que foi criado:

```
ana@laptop:~/boxoffice$ cat accounts.csv
name,email,password
Caio Barbosa,test001@example.org,d2rngr6nv2yi
Débora Barbosa,test002@example.org,aat8ngpahqrhh
Débora Machado,test003@example.org,7p77dwzjz69s
Gustavo Duarte,test004@example.org,j9r8n5rznxm6
Fernanda Barbosa,test005@example.org,xdf4mzrj5vuwfha
```

Nomes se repetem, três Barbosas entre cinco pessoas, porque o programa sorteia cada nome de forma
independente; os endereços nunca, porque são numerados. As duas coisas são decisões do programa, e
as duas ficam visíveis neste arquivo antes que alguém precise descobri-las no boxoffice.

Toda conta nova recebe um e-mail de confirmação, então a caixa de saída agora tem cinco. No
navegador, abra `http://127.0.0.1:8000/outbox`; no terminal, conte-os:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/outbox | grep -c '<h2>Confirm your account</h2>'
5
```

## O que dados gerados não são

**Não são dados desenhados.** Os nomes aqui são todos válidos, entre 1 e 40 caracteres, porque o
programa foi escrito para cadastrar pessoas. Os valores que acham defeitos, um nome de exatamente 40
caracteres e um de 41, um endereço sem ponto depois do `@`, são escolhidos pelas técnicas da aula 4,
e um gerador aleatório quase nunca cai neles por acaso. Um programa pode produzi-los também, mas só
depois que uma pessoa decidiu quais são.

**Não são realistas por padrão.** Clientes reais têm nomes de uma palavra e de seis, endereços em
domínios que parecem erro de digitação, e o hábito de colar um espaço no fim de um campo. Um gerador
produz exatamente a variedade que foi escrito para produzir. Quando o realismo importa, a fonte da
próxima seção, uma cópia da produção tornada segura, é a que o tem.
