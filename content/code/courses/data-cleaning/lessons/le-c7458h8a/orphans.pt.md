---
title: Órfãos, e por que são órfãos
version: 1
---

Um **órfão** é uma linha cuja chave aponta para o nada: um pedido cujo cliente não está no
arquivo de clientes. A junção verificada conta esses casos de graça:

```
ana@lab:~/clean$ python -c "from when import orders; from raw_customers import customers; from joins import join; j = join(orders, customers[['customer_id', 'name']], 'customer_id')"
join on customer_id: 28526 rows in, 28526 out, 246 with no match
```

246 pedidos, de 28.526, não têm cliente. É menos de 1%, pouco o bastante para ignorar, e ignorar
seria um erro, porque **órfãos raramente são aleatórios**. Uma chave sem par quase sempre é o
rastro de algo que aconteceu com um dos dois arquivos, e o trabalho é descobrir o quê.

Duas perguntas costumam resolver: quem são, e quando? O arquivo do CRM desta empresa foi exportado
em 10 de dezembro de 2025, uma data que a pessoa que mandou o arquivo sabe dizer e o arquivo não. Os
pedidos vão até 31 de dezembro. Então o primeiro teste é ver se o primeiro pedido de cada cliente
órfão veio antes ou depois da exportação:

```schooling-example
{
  "language": "python",
  "file": "orphans.py",
  "parts": [
    {
      "code": "import pandas as pd\n\n"
    },
    {
      "code": "from raw_customers import customers\nfrom when import orders\n\n",
      "note": "Os clientes sem linhas repetidas, e os pedidos com `placed`, o horário em São Paulo, da aula 7."
    },
    {
      "code": "EXPORTED = pd.Timestamp(\"2025-12-10\")  # the CRM file's date, from the person who sent it\n",
      "note": "**A data da exportação é um fato sobre o arquivo**, e vem de quem o mandou."
    },
    {
      "code": "alone = orders[~orders[\"customer_id\"].isin(customers[\"customer_id\"])]\n",
      "note": "Os pedidos cujo cliente não está no CRM."
    },
    {
      "code": "first = alone.groupby(\"customer_id\")[\"placed\"].agg([\"min\", \"max\", \"size\"])\n",
      "note": "Por cliente órfão: primeiro pedido, último pedido, quantos."
    },
    {
      "code": "first[\"kind\"] = (first[\"min\"] >= EXPORTED).map({True: \"new since export\", False: \"left the CRM\"})\n\n",
      "note": "**O teste**: o primeiro pedido veio depois da exportação?"
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(first.groupby(\"kind\").agg(customers=(\"size\", \"size\"), orders=(\"size\", \"sum\"),\n                                    first=(\"min\", \"min\"), last=(\"max\", \"max\")).to_string())\n",
      "note": "Clientes, pedidos e datas por grupo."
    }
  ]
}
```

```
ana@lab:~/clean$ python orphans.py
                  customers  orders               first                last
kind                                                                       
left the CRM             12     216 2025-01-01 17:24:22 2025-12-28 11:10:16
new since export         20      30 2025-12-14 10:25:10 2025-12-31 18:41:51
```

Os 32 clientes caem em dois grupos que não têm nada em comum.

- **20 são novos desde a exportação.** O primeiro pedido é de 14 de dezembro ou depois, 30
  pedidos entre eles. O CRM não está errado; está velho. A correção é uma exportação mais recente,
  e até lá uma frase no relatório dizendo que os clientes novos das últimas três semanas estão sem
  cadastro.
- **12 saíram do CRM.** Fizeram pedidos o ano inteiro, o primeiro em 1º de janeiro, 216 pedidos ao todo,
  e não estão num arquivo exportado em dezembro. Clientes não somem de um CRM por acaso: são
  pessoas que pediram a eliminação dos seus dados, o que a LGPD permite a qualquer um.

O segundo grupo pede cuidado nos dois sentidos. **Os pedidos ficam**: são vendas, estão na
contabilidade, e a receita sem eles fica errada. **As pessoas continuam fora**: nada na análise
pode tentar descobrir quem eram, cruzando os endereços dos pedidos ou qualquer outra coisa. Elas
contam como pedidos de clientes cujos dados foram removidos, e só.

O gabarito do laboratório confirma a leitura:

```
ana@lab:~/clean$ python -c "import pandas as pd; from orphans import first; e = pd.read_csv('/var/lib/clean-data/truth/erased.csv'); gone = first[first['kind'] == 'left the CRM']; print(len(gone), gone.index.isin(e['customer_id']).sum(), len(e))"
12 12 12
```

Os 12 estão na lista de clientes eliminados, e a lista tem 12. No trabalho real esse arquivo não
existe; a confirmação vem de quem cuida dos pedidos de eliminação, e perguntar faz parte do
trabalho.
