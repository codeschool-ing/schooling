---
title: Documentos, coleções e subcoleções
version: 1
---

**O Firestore guarda documentos, e um documento é um pequeno mapa de campos com um nome.** Os
documentos moram em coleções, uma coleção não é nada além dos documentos nela, e um documento pode ter
coleções próprias, chamadas subcoleções. Então todo documento tem um caminho que alterna as duas
coisas, `customers/c-17/orders/o-10001`: a coleção `customers`, o documento `c-17`, a subcoleção
`orders` dele e o documento `o-10001` dentro dela. Não há schema, nem tabela para criar, nem coluna
para declarar. Uma coleção existe enquanto tem um documento e some quando não tem nenhum.

**A ideia errada é que uma coleção é uma tabela e uma subcoleção, um join.** Uma subcoleção não fica
guardada dentro do pai e não é lida com ele: ler `customers/c-17` devolve os dois campos do cliente e
nada dos pedidos, por mais que sejam. O que o caminho dá é um nome e um escopo. Os pedidos debaixo de
`c-17` são uma coleção que se lê sozinha, barato, porque o caminho diz exatamente onde eles estão, que
é a mesma ideia da chave da aula 9, alcançada pelo outro lado.

**Esta aula é praticada no emulador do Firestore**, que a aula 1 instalou como
`cloud-firestore-emulator`. É um programa Java que fala a API do Firestore no seu laptop, guarda tudo
em memória e é mais fraco que o Firestore num ponto que esta aula vai procurar na terceira seção.

## O emulador, num terminal só dele

```sh
cd ~/gcp && export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
gcloud emulators firestore start --host-port=localhost:8080
```

**O cliente Python o acha por `FIRESTORE_EMULATOR_HOST`**, uma das variáveis da aula 1, e não manda
credencial nenhuma quando ela está definida. Deixe-o rodando e digite o resto no outro terminal.

## Vinte clientes e os pedidos deles

```schooling-example
{"language": "python", "file": "seed.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Write Quitanda's customers, each with a subcollection of orders, into Firestore.\n\n    python3 seed.py        # 20 customers, c-17 to c-36\n\nThe same run always writes the same documents.\n\"\"\"\nimport random\n\nfrom google.cloud import firestore\n\n", "note": "A docstring diz como rodar. A biblioteca é a que a aula 1 instalou, `google-cloud-firestore`."}, {"code": "NAMES = ['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fábio', 'Gabi', 'Heitor']\nDISTRICTS = ['Pinheiros', 'Mooca', 'Lapa', 'Tatuapé', 'Santana', 'Butantã']\nPRODUCTS = {'banana': 690, 'tomato': 899, 'rice-5kg': 2790, 'coffee-500g': 3450, 'eggs-12': 1590}\nSTATUSES = ['delivered', 'delivered', 'delivered', 'pending', 'cancelled']\n\n", "note": "Aquilo de que o gerador tira os valores. Os preços são centavos inteiros, e três status em cinco são `delivered`, como a maioria dos pedidos."}, {"code": "db = firestore.Client(project='planner-dev')\nrnd = random.Random(17)\nbatch, written, order_no = db.batch(), {'customers': 0, 'orders': 0}, 10000\n\n", "note": "**O cliente acha o emulador por `FIRESTORE_EMULATOR_HOST`.** Um `Random` com semente faz toda execução gravar os mesmos documentos, e um `batch` junta todas as escritas para mandá-las juntas."}, {"code": "for n in range(20):\n    cid = f'c-{17 + n}'\n    customer = db.collection('customers').document(cid)\n    district = rnd.choice(DISTRICTS)\n    batch.set(customer, {'name': rnd.choice(NAMES), 'district': district})\n    written['customers'] += 1\n", "note": "**Um documento é nomeado pelo caminho**: coleção `customers`, id de documento `c-17`. `set` grava o documento inteiro, criando-o se não existe e substituindo-o se existe."}, {"code": "    for day in sorted(rnd.sample(range(1, 31), rnd.randint(1, 5))):\n        order_no += 1\n        products = rnd.sample(sorted(PRODUCTS), rnd.randint(1, 3))\n        batch.set(customer.collection('orders').document(f'o-{order_no}'), {\n            'day': f'2026-10-{day:02d}',\n            'status': rnd.choice(STATUSES),\n            'district': district,\n            'products': products,\n            'total_cents': sum(PRODUCTS[p] * rnd.randint(1, 3) for p in products),\n        })\n        written['orders'] += 1\n", "note": "**Cada pedido é um documento na subcoleção `orders` do próprio cliente**, `customers/c-17/orders/o-10001`. Ele repete o bairro, porque uma consulta lê um collection group e não faz join com o cliente; `products` é um array, que ganha um índice próprio."}, {"code": "batch.commit()\nprint(f\"{written['customers']} customers, {written['orders']} orders\")\n", "note": "`commit` manda o lote. Nada foi gravado antes desta linha, e tudo é gravado por ela, ou nada é."}]}
```

```
ana@laptop:~/gcp$ python3 seed.py
20 customers, 53 orders
```

**Setenta e três documentos, gravados num lote e criados só por serem gravados.** Nem `customers` nem
`orders` foram criadas antes; o primeiro `set` em cada uma a fez existir. Um lote confirma todas as
escritas juntas ou nenhuma.

## Ler um documento, e o que ele não traz

```
ana@laptop:~/gcp$ python3 -c "from google.cloud import firestore; print(firestore.Client(project='planner-dev').document('customers/c-17').get().to_dict())"
{'name': 'Gabi', 'district': 'Santana'}
ana@laptop:~/gcp$ python3 -c "from google.cloud import firestore; print([c.id for c in firestore.Client(project='planner-dev').document('customers/c-17').collections()])"
['orders']
```

**A leitura de um documento devolve os campos dele e mais nada.** `c-17` tem uma subcoleção, e a
leitura não a incluiu; listar as coleções debaixo do documento é outra chamada, e lê-las é outra. No
Google Cloud cada uma delas é cobrada como leituras, uma por documento devolvido, que a última seção
desta aula põe preço.

**O valor de um campo tem um tipo, e o tipo decide como ele é ordenado.** Strings, inteiros, números de
ponto flutuante, booleanos, timestamps, mapas, arrays, referências a outros documentos e pontos
geográficos são valores que um campo pode ter, e o mesmo campo pode ter tipos diferentes em documentos
diferentes. O Firestore ordena valores de tipos diferentes por uma ordem fixa de tipos, documentada
como "the value type ordering", antes de ordenar os valores dentro de um tipo. Isso importa na
primeira vez que um campo tem `"100"` num documento e `100` em outro e uma consulta ordenada por ele os
põe longe um do outro. O `seed.py` grava o dia como string, `2026-10-06`, que ordena certo porque o
formato põe o ano primeiro; dinheiro é um inteiro de centavos, como em todo o curso.

## Um documento tem limite de tamanho

**Um documento guarda no máximo 1 MiB**, o limite documentado do Firestore, nomes de campo e valores
incluídos, e o valor de um campo no máximo 1 MiB menos 89 bytes. O emulador impõe o segundo:

```
ana@laptop:~/gcp$ python3 -c "from google.cloud import firestore; firestore.Client(project='planner-dev').document('customers/c-17').set({'notes': 'x' * 1100000})" 2>&1 | tail -1
google.api_core.exceptions.InvalidArgument: 400 The value of property "notes" is longer than 1048487 bytes.
```

**1.048.487 bytes é exatamente 1 MiB menos 89**, o limite que o Firestore documenta para o valor de um
campo. Esse limite é uma regra de projeto tanto quanto um número: um pedido pertence a um documento
próprio debaixo do cliente, não a um array dentro do documento do cliente, que cresceria a cada pedido
até o dia em que deixasse de aceitá-los. Uma subcoleção não tem limite de tamanho nenhum, e é para
isso que ela existe.

## Onde um pedido deve morar

**O caminho é a única decisão de projeto que o Firestore pede logo de início**, e há três lugares onde
um pedido poderia ficar. Cada um responde barato a uma pergunta e dificulta outra:

| um pedido como | a pergunta barata | a mais difícil |
|---|---|---|
| um elemento de um array no documento do cliente | o cliente com todos os pedidos, uma leitura | qualquer coisa acima de 1 MiB, e todo pedido regrava o cliente |
| um documento em `customers/{id}/orders` | os pedidos de um cliente, pelo caminho | todo pedido de um dia, que exige uma consulta de collection group |
| um documento numa coleção `orders` de primeiro nível, com um campo `customer` | todo pedido de um dia, numa coleção | os pedidos de um cliente, que exigem um índice em `customer` |

**A Quitanda escolhe a subcoleção**, porque a tela que o app mais mostra são os pedidos do próprio
cliente, e um caminho chega a eles sem índice próprio. As perguntas dos analistas sobre todos os
clientes passam por consultas de collection group, o assunto das duas próximas seções, e as mais
pesadas pertencem ao data warehouse da aula 13, não ao Firestore. **Uma referência entre documentos é
um valor, não uma restrição**: o pedido poderia guardar o caminho de um documento de produto, e nada
impediria esse produto de ser apagado. Não há chave estrangeira no Firestore, e a integridade que o
schema impunha na aula 9 aqui é trabalho do programa.
