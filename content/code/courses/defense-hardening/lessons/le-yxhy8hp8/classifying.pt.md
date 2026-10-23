---
title: Como os dados pessoais parecem para uma máquina
version: 1
---

**Uma ferramenta de DLP não consegue ler um documento como uma pessoa lê. Ela acha padrões e depois
os confere.** O padrão é o formato da coisa: onze dígitos para um CPF, dezesseis para um cartão. A
conferência é a conta que o emissor embutiu no número, e é ela que separa um CPF de quaisquer outros
onze dígitos numa página.

Os dois identificadores que mais importam para um escritório de contabilidade brasileiro trazem os
próprios dígitos verificadores. Um **CPF** tem nove dígitos e dois verificadores calculados a partir
deles. Um **número de cartão** termina num dígito verificador de Luhn calculado a partir de todos os
outros. Digitar um dígito errado muda a conferência, e é para isso que os emissores a puseram ali; um
scanner usa a mesma conta para separar um número com cara de verdadeiro de um número que só tem o
tamanho certo.

## Uma lista de clientes sem ninguém dentro

Para praticar, você precisa de um arquivo cheio de dados pessoais, e **dados pessoais reais nunca são
o jeito de conseguir um**: um arquivo de teste com clientes de verdade é um vazamento esperando uma
cópia descuidada. Então a aula faz o seu. Salve isto no `desk` como `fakedata.py`:

```schooling-example
{"language": "python", "file": "fakedata.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"fakedata.py: a client list for Jatobá made of invented people, with valid-looking CPFs and cards.\"\"\"\nimport random, sys\n\nrng = random.Random(2026)\nFIRST = [\"Ana\", \"Bruno\", \"Carla\", \"Diego\", \"Elisa\", \"Fábio\", \"Gabriela\", \"Heitor\", \"Iara\", \"João\"]\nLAST = [\"Souza\", \"Lima\", \"Pereira\", \"Costa\", \"Rocha\", \"Alves\", \"Gomes\", \"Ribeiro\"]", "note": "O gerador tem semente fixa, então grava a mesma lista toda vez e em qualquer computador, e o seu arquivo bate com o dos transcritos. Os nomes são combinações de nomes e sobrenomes comuns: ninguém em particular."}, {"code": "def cpf():\n    d = [rng.randrange(10) for _ in range(9)]\n    for n in (10, 11):\n        r = sum(x * w for x, w in zip(d, range(n, 1, -1))) * 10 % 11\n        d.append(0 if r == 10 else r)\n    s = \"\".join(map(str, d))\n    return f\"{s[:3]}.{s[3:6]}.{s[6:9]}-{s[9:]}\"", "note": "Um CPF tem nove dígitos e dois dígitos verificadores. O primeiro pesa os nove de 10 até 2, o segundo pesa dez dígitos de 11 até 2, e cada um é o resto de dez vezes a soma dividida por onze, com 10 escrito como 0. Um número inventado ao acaso passa nesse teste mais ou menos uma vez em cem tentativas, e é isso que um scanner vai usar."}, {"code": "def card():\n    d = [9, 9, 9, 9] + [rng.randrange(10) for _ in range(11)]\n    total = 0\n    for i, x in enumerate(reversed(d)):\n        x = x * 2 if i % 2 == 0 else x\n        total += x - 9 if x > 9 else x\n    d.append((10 - total % 10) % 10)\n    return \" \".join(\"\".join(map(str, d[i:i + 4])) for i in range(0, 16, 4))", "note": "Um número de cartão termina num dígito verificador de Luhn: da direita para a esquerda, um dígito sim, um não, é dobrado, tira-se nove do que passar de nove, e o último dígito faz o total ser múltiplo de dez. Todos estes começam com `9999`, um prefixo que nenhuma bandeira emite, então parecem números de cartão para um scanner e não são cartão de ninguém."}, {"code": "print(\"name;cpf;card\")\nfor _ in range(int(sys.argv[1]) if len(sys.argv) > 1 else 20):\n    print(f\"{rng.choice(FIRST)} {rng.choice(LAST)};{cpf()};{card()}\")", "note": "Uma linha por cliente, separada por ponto e vírgula, como uma planilha brasileira exporta. O argumento é quantos clientes; vinte se você não der nenhum."}]}
```

Rode e olhe as primeiras linhas:

```
ana@desk:~$ python3 fakedata.py > clientes.csv; head -4 clientes.csv; wc -l clientes.csv
name;cpf;card
Bruno Alves;881.399.869-41;9999 8797 3091 1410
Heitor Souza;753.645.568-24;9999 1518 8447 2940
Ana Alves;576.169.871-41;9999 6897 6846 9789
21 clientes.csv
```

Vinte clientes, todo CPF passando na conta da Receita e todo cartão na de Luhn, e nenhum deles de
ninguém. A mesma semente dá os mesmos vinte, então o seu arquivo e este transcrito batem linha por
linha.

## As conferências, à mão

O scanner da próxima seção traz as duas conferências como funções. Pergunte a ele sobre um CPF da
lista e o mesmo CPF com o último dígito trocado, e depois o mesmo com um cartão:

```
ana@desk:~$ python3 -c 'import scan; print(scan.cpf_ok("881.399.869-41"), scan.cpf_ok("881.399.869-42"))'
True False
ana@desk:~$ python3 -c 'import scan; print(scan.luhn_ok("9999 8797 3091 1410"), scan.luhn_ok("9999 8797 3091 1411"))'
True False
```

Um dígito trocado, e as duas respostas viram. É o dígito verificador fazendo o trabalho dele, e é todo
o motivo pelo qual um scanner pode ser instruído a informar só números válidos: **um número de pedido
que por acaso tem onze dígitos falha na conta do CPF umas noventa e nove vezes em cem.** A centésima
vez é o assunto da próxima seção.
