---
title: Escolhendo a chave, medindo
version: 1
---

**A chave de partição é escolhida a partir das perguntas que a aplicação faz e do jeito como as
escritas chegam, não do que parece a identidade natural do item.** Todo candidato é uma troca entre as
três propriedades da seção anterior, e a troca pode ser medida antes de existir um único contêiner, com
os dados que você já tem, ou com dados no formato deles.

O app da Quitanda faz uma pergunta muito mais do que qualquer outra: mostre a este cliente os pedidos
dele. Os candidatos são o próprio `id` do pedido, o cliente, o dia em que o pedido foi feito e o status.
Este programa mede os quatro sobre um ano de pedidos no formato dos da Quitanda. Ele não precisa de
emulador. Salve-o como `~/azure/spread.py`:

```schooling-example
{"language": "python", "file": "spread.py", "parts": [{"code": "\"\"\"How four candidate partition keys would spread a year of Quitanda's orders.\"\"\"\nimport collections, random\n\nrng = random.Random(7)\nHOURS = [1, 1, 1, 1, 1, 2, 4, 6, 8, 8, 9, 10, 12, 10, 8, 8, 9, 11, 12, 10, 7, 4, 2, 1]\norders = []\nfor n in range(100_000):\n    day = n * 365 // 100_000\n    orders.append({\n        \"id\": f\"o-{n}\",\n        \"customerId\": f\"c-{int(7000 * rng.random() ** 3)}\",\n        \"placedDate\": f\"2026-{day:03}\",\n        \"hour\": rng.choices(range(24), weights=HOURS)[0],\n        \"status\": \"delivered\" if day < 364 else rng.choice([\"placed\", \"paid\", \"delivered\"]),\n    })\n", "note": "**Um ano de pedidos inventado pelo programa, igual em toda execução** porque o gerador aleatório tem semente. Cem mil pedidos, espalhados por igual pelos 365 dias e de forma desigual pelas horas, com os picos do almoço e da noite. Os clientes são enviesados de propósito: elevar um número aleatório ao cubo amontoa os sorteios nos ids baixos, então alguns clientes, restaurantes, pedem muito mais que o resto. Todo pedido, menos os do último dia, está entregue."}, {"code": "\nevening = [o for o in orders if o[\"placedDate\"] == \"2026-200\" and o[\"hour\"] == 19]\n\n\ndef report(key):\n    sizes = collections.Counter(o[key] for o in orders)\n    largest = sizes.most_common(1)[0][1]\n    hot = collections.Counter(o[key] for o in evening).most_common(1)[0][1]\n    question = \"one\" if key == \"customerId\" else \"every\"\n    print(f\"/{key:<12}{len(sizes):>9,}{largest:>9,}{100 * largest / len(orders):>7.1f}%\"\n          f\"{100 * hot / len(evening):>9.0f}%{question:>8}\")\n", "note": "**Três medidas para cada chave, uma por propriedade de uma boa chave.** Quantos valores distintos existem, e quão grande é a maior partição lógica, em pedidos e como fração de todos. Que fração das escritas de uma hora movimentada da noite cai num valor só. E quantas partições a pergunta mais comum do app, os pedidos de um cliente, precisa visitar."}, {"code": "\n\nprint(f\"{'key':<13}{'values':>9}{'largest':>9}{'share':>8}{'hot hour':>10}{'visits':>8}\")\nfor key in (\"id\", \"customerId\", \"placedDate\", \"status\"):\n    report(key)\n", "note": "Os quatro candidatos: o próprio `id` do pedido, o cliente, o dia em que foi feito e o status."}]}
```

```
ana@laptop:~/azure$ python spread.py
key             values  largest   share  hot hour  visits
/id            100,000        1    0.0%        4%   every
/customerId      6,983    5,206    5.2%        8%     one
/placedDate        365      274    0.3%      100%   every
/status              3   99,822   99.8%      100%   every
```

Cada linha é uma decisão, lida de ponta a ponta:

- **`/id` espalha perfeitamente e não responde nada.** Cem mil valores, um pedido cada, e nenhuma hora
  movimentada esquenta nenhum deles. Mas "os pedidos de um cliente" não nomeia nenhum `id`, então
  visita toda partição, toda vez. Uma chave em `id` serve para um contêiner lido só por leituras
  pontuais, como um cache de documentos buscados pelo nome.
- **`/customerId` responde à pergunta numa partição**, com quase sete mil valores e as escritas da
  noite bem espalhadas. A maior partição é o viés: o cliente mais ativo tem 5,2% de todos os pedidos,
  o que dá uns poucos MB neste ano e fica longe do limite de 20 GB mesmo com mil vezes o volume. É a
  chave que a Quitanda escolhe.
- **`/placedDate` falha no momento da escrita.** 365 valores, cada um com modestos 274 pedidos,
  parecem inofensivos ao longo do ano. Mas todo pedido escrito esta noite leva a data desta noite,
  então todas as escritas daquela hora caem num valor só, 100%, o que é uma partição física levando a
  carga inteira enquanto as outras ficam paradas. Uma chave na data é a partição quente clássica.
- **`/status` falha em tudo.** Três valores, um deles com 99,8% dos pedidos, uma hora quente de 100%, e
  a pergunta de todo cliente visitando os três. Pior, um status muda: um pedido passa de `paid` para
  `delivered`, e um item não pode mudar de valor de chave de partição; ele precisa ser apagado e escrito
  de novo com o valor novo.

**Então o desenho começa pela pergunta e confere as escritas**: `/customerId` porque o app pergunta
por cliente, mantido porque as escritas de qualquer hora se espalham por milhares de clientes e nenhum
cliente se aproxima do limite.

## E não dá para mudar de ideia

**A chave de partição de um contêiner é fixada quando o contêiner é criado**, e a documentação da
Microsoft diz que ela não pode ser mudada; escolher outra significa um contêiner novo e uma cópia de
cada item para ele. O emulador concorda, do jeito dele. Salve isto como `~/azure/rekey.py`:

`rekey.py`:

```python
from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
db = CosmosClient("http://localhost:8081", KEY).get_database_client("quitanda")
orders = db.get_container_client("orders")

print("before:", orders.read()["partitionKey"]["paths"])
db.replace_container(orders, PartitionKey("/placedDate"))
print("replace_container returned without an error")
print("after: ", orders.read()["partitionKey"]["paths"])
```

```
ana@laptop:~/azure$ python rekey.py
before: ['/customerId']
replace_container returned without an error
after:  ['/customerId']
```

**O emulador aceitou um pedido para mudar a chave e manteve a antiga**, sem uma palavra. Essa é a
falha de que a lição 1 avisou, na forma mais simples: um sucesso que não fez nada. O que o Azure
responde ao mesmo pedido não foi rodado aqui. A regra da documentação é que a chave não muda, e um
programa que acredita no sucesso acima tem um contêiner ainda particionado por cliente enquanto quem o
escreveu acha que não.
