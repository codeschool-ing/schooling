---
title: Classificação, com um classificador nosso
version: 1
---

**Uma classificação é um rótulo que o Purview põe numa coluna ou num arquivo, como "esta coluna guarda
números de CPF".** O Purview vem com um grande conjunto de **classificações de sistema**, mais de
duzentas segundo a documentação da Microsoft, para coisas como números de cartão de crédito, números de
passaporte, endereços de e-mail e identificadores nacionais de muitos países, o do Brasil entre eles.
Uma varredura as aplica à amostra de dados que lê. Quando as embutidas não cobrem alguma coisa, como
os ids de cliente da própria Quitanda, uma **regra de classificação personalizada** acrescenta uma: um
padrão para o nome da coluna, um padrão para os dados, ou os dois, e uma parcela mínima dos valores da
amostra que precisa casar.

Como o Purview decide por dentro é assunto da Microsoft e não é algo que um laptop consiga executar.
O que dá para executar é a ideia, e um classificador pequeno o bastante para ser lido mostra os seus
dois modos de falha melhor que qualquer descrição. **O que vem a seguir é um programa escrito para este
curso. Não é o Purview**, e as regras, os nomes e o limite dele são dele próprio.

## A exportação da Quitanda, gerada

A exportação tem as colunas que uma exportação de clientes costuma ter, e duas que são armadilhas para
um classificador: um número de rastreio da transportadora de onze dígitos, o tamanho de um CPF, e uma
observação em texto livre em que o CPF de um cliente foi digitado por um operador. As linhas são
feitas por um programa, então você tem o mesmo arquivo sem copiar dados pessoais de lugar nenhum; os
nomes são inventados, os e-mails usam o domínio `example.com`, reservado para documentação, e os CPFs
são números aleatórios construídos para passar nos dígitos verificadores, que de propósito não são de
ninguém. Salve como `make_export.py`:

`make_export.py`:

```python
import csv
import random
import sys
import unicodedata

rng = random.Random(2026)
FIRST = ["Ana", "Bruno", "Carla", "Diego", "Elisa", "Fábio", "Gabi", "Hugo", "Iara", "João"]
LAST = ["Souza", "Lima", "Alves", "Rocha", "Pires", "Costa", "Melo", "Dias", "Nunes", "Reis"]

def cpf():
    d = [rng.randrange(10) for _ in range(9)]
    for n in (10, 11):
        s = sum(x * w for x, w in zip(d, range(n, 1, -1)))
        d.append(0 if s % 11 < 2 else 11 - s % 11)
    s = "".join(map(str, d))
    return f"{s[:3]}.{s[3:6]}.{s[6:9]}-{s[9:]}"

out = csv.writer(sys.stdout, lineterminator="\n")
out.writerow(["order_id", "customer", "cpf", "email", "phone", "tracking", "notes", "total_cents"])
for i in range(10):
    name = f"{FIRST[i]} {LAST[i]}"
    mail = unicodedata.normalize("NFKD", name.lower().replace(" ", ".")).encode("ascii", "ignore").decode()
    note = f"nota fiscal com CPF {cpf()}" if i == 3 else rng.choice(["", "deixar na portaria", "sem cebola"])
    out.writerow([f"o-{401 + i}", name, cpf(), f"{mail}@example.com",
                  f"+55 11 9{rng.randrange(1000, 9999)}-{rng.randrange(1000, 9999)}",
                  "".join(str(rng.randrange(10)) for _ in range(11)), note, rng.randrange(1500, 30000)])
```

Gere o arquivo, olhe as primeiras linhas e ponha-o no Azurite, onde a exportação noturna chegaria:

```
ana@laptop:~/azure$ python make_export.py > customers.csv && head -4 customers.csv
order_id,customer,cpf,email,phone,tracking,notes,total_cents
o-401,Ana Souza,588.139.986-27,ana.souza@example.com,+55 11 99975-9042,97309114170,,28198
o-402,Bruno Lima,753.645.568-24,bruno.lima@example.com,+55 11 92250-6577,18844729405,sem cebola,13412
o-403,Carla Alves,616.987.168-77,carla.alves@example.com,+55 11 99045-7523,84697880932,deixar na portaria,28308
ana@laptop:~/azure$ az storage container create -n quitanda-raw -o none && az storage blob upload -c quitanda-raw -n exports/2026-10-29/customers.csv -f customers.csv --no-progress -o none
```

## O classificador

Salve como `classify.py`:

```schooling-example
{"language": "python", "file": "classify.py", "parts": [{"code": "import csv\nimport io\nimport re\nimport sys\n\nfrom azure.storage.blob import BlobClient\n\nTHRESHOLD = 0.6\n\n", "note": "**`THRESHOLD` é a parcela das linhas de uma coluna que precisa casar antes de a coluna inteira ganhar o rótulo.** As regras de classificação personalizadas do Purview têm a mesma ideia, um limite mínimo de correspondência, e os 60 por cento deste programa são um valor dele próprio."}, {"code": "def cpf_digits_ok(value):\n    d = [int(c) for c in re.sub(r\"\\D\", \"\", value)]\n    if len(d) != 11 or len(set(d)) == 1:\n        return False\n    for n in (9, 10):\n        s = sum(x * w for x, w in zip(d[:n], range(n + 1, 1, -1)))\n        if d[n] != (0 if s % 11 < 2 else 11 - s % 11):\n            return False\n    return True\n\n", "note": "**Um CPF carrega dois dígitos verificadores**, calculados a partir dos nove anteriores com pesos de 10 a 2 e depois de 11 a 2. Uma sequência de onze dígitos que falha nessa conta não é um CPF, pareça o que parecer. Onze dígitos iguais passam na conta e são recusados mesmo assim, como as regras da Receita Federal os recusam."}, {"code": "RULES = {\n    \"Brazil CPF\": (re.compile(r\"\\b\\d{3}\\.?\\d{3}\\.?\\d{3}-?\\d{2}\\b\"), cpf_digits_ok),\n    \"Email address\": (re.compile(r\"\\b[\\w.+-]+@[\\w-]+\\.[\\w.]+\\b\"), None),\n    \"Brazil phone\": (re.compile(r\"\\+55 ?\\d{2} ?9?\\d{4}-?\\d{4}\"), None),\n}\n\n", "note": "Três regras, cada uma um padrão e, para o CPF, um validador. O padrão encontra o que parece certo; o validador joga fora o que só parece. Os nomes são deste programa, não do Purview."}, {"code": "blob = BlobClient.from_connection_string(\"UseDevelopmentStorage=true\", sys.argv[1], sys.argv[2])\nrows = list(csv.DictReader(io.StringIO(blob.download_blob().readall().decode())))\nprint(f\"{len(rows)} rows sampled from {sys.argv[1]}/{sys.argv[2]}\")\n\n", "note": "A exportação é lida do Azurite com a string de conexão curta, que esta biblioteca entende. Uma varredura de verdade lê uma amostra de cada arquivo em vez do arquivo inteiro; dez linhas são este arquivo todo."}, {"code": "for column in rows[0]:\n    values = [r[column] for r in rows if r[column]]\n    found = []\n    for label, (pattern, check) in RULES.items():\n        hits = [v for v in values if pattern.search(v)]\n        valid = [v for v in hits if check is None or check(pattern.search(v).group())]\n        if hits:\n            share = len(valid) / len(rows)\n            verdict = label if share >= THRESHOLD else \"-\"\n            found.append(f\"{label}: {len(hits)} look like it, {len(valid)} pass, {share:.0%} -> {verdict}\")\n    print(f\"{column:<12} \" + (\"; \".join(found) if found else \"nothing\"))\n", "note": "Para cada coluna, cada regra: quantos valores parecem casar, quantos passam no validador, que parcela de todas as linhas isso é, e o veredito contra o limite. Uma regra que não casa com nada numa coluna não é impressa."}]}
```

```
ana@laptop:~/azure$ python classify.py quitanda-raw exports/2026-10-29/customers.csv
10 rows sampled from quitanda-raw/exports/2026-10-29/customers.csv
order_id     nothing
customer     nothing
cpf          Brazil CPF: 10 look like it, 10 pass, 100% -> Brazil CPF
email        Email address: 10 look like it, 10 pass, 100% -> Email address
phone        Brazil phone: 10 look like it, 10 pass, 100% -> Brazil phone
tracking     Brazil CPF: 10 look like it, 0 pass, 0% -> -
notes        Brazil CPF: 1 look like it, 1 pass, 10% -> -
total_cents  nothing
```

**Três colunas rotuladas, corretamente, e duas decisões que valem um olhar.** A coluna `tracking`
parecia CPF dez vezes em dez, onze dígitos cada, e **nenhum passou nos dígitos verificadores**, então
ela não foi rotulada. Um classificador que parasse no padrão teria marcado os números da
transportadora como dado pessoal, e quem revisa o catálogo aprenderia a ignorar os rótulos dele, que é
a pior coisa que um classificador pode ensinar. O validador é o que mantém o padrão honesto.

**A coluna `notes` guardava um CPF de verdade e não foi rotulada.** Uma linha em dez, 10 por cento,
fica abaixo do limite de 60. É o limite fazendo o seu trabalho, já que uma coluna em que um valor em
dez parece CPF em geral não é uma coluna de CPFs, e é também como dados pessoais se escondem num
catálogo que parece completo: o campo de texto livre, o comentário, o blob JSON, onde uma pessoa
digitou o que não devia. Baixe o limite e veja o que muda:

```
ana@laptop:~/azure$ sed 's/^THRESHOLD = 0.6/THRESHOLD = 0.1/' classify.py > classify_low.py && python classify_low.py quitanda-raw exports/2026-10-29/customers.csv | grep -E 'cpf|tracking|notes'
cpf          Brazil CPF: 10 look like it, 10 pass, 100% -> Brazil CPF
tracking     Brazil CPF: 10 look like it, 0 pass, 0% -> -
notes        Brazil CPF: 1 look like it, 1 pass, 10% -> Brazil CPF
```

**A `notes` agora está rotulada, e assim estaria qualquer coluna com uma correspondência perdida.**
Nenhum limite pega o único CPF num campo de observações sem também rotular toda coluna em que um
número por acaso passa na conta. O Purview enfrenta a mesma troca, e é por isso que as regras
personalizadas dele expõem o limite, e por isso que a descrição honesta da saída de uma varredura é
"as colunas que são em sua maioria isto", nunca "todo lugar onde isto aparece". Campos de texto livre
que podem guardar dados pessoais são mais bem tratados na origem, não deixando os operadores da loja
digitarem isso ali, do que encontrados depois.

**O que o programa não fez também é o que o Purview não faz por você**: decidir o que o rótulo
significa. Uma coluna rotulada como CPF ainda precisa de alguém que decida quem pode lê-la, por quanto
tempo é guardada e se deve ser mascarada, que são os rótulos da próxima seção e os assuntos de
`data-governance`.
