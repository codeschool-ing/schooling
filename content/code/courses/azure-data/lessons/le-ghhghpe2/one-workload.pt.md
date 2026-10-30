---
title: Uma carga, com três preços
version: 1
---

**A tela "meus pedidos" do app da Quitanda é uma carga com um formato claro**: um cliente a abre, o app
pede os últimos dez pedidos daquele cliente, e a tela tem que aparecer bem antes de um segundo. Três
milhões de aberturas por mês, seiscentos mil pedidos novos por mês, cinquenta gigabytes de pedidos
guardados. O padrão de acesso é poucos itens por uma chave, que a árvore de duas seções atrás manda
para o Cosmos DB, e o objetivo desta seção é ver quanto os outros ramos teriam custado, com aritmética
e não com opinião.

A aritmética é um programa, para que as suposições fiquem escritas e possam ser mudadas. **Ele roda no
seu computador só com o Python, e não pergunta nada ao Azure**: todo preço nele é um número redondo
ilustrativo, identificado como tal, e toda estimativa da carga está marcada como estimativa. Salve-o
como `compare.py`:

```schooling-example
{"language": "python", "file": "compare.py", "parts": [{"code": "LOOKUPS = 3_000_000          # \"my orders\" opened, per month\nWRITES = 600_000             # new orders, per month\nSTORED_GB = 50\n\n", "note": "**A carga em números**: a tela aberta três milhões de vezes por mês, seiscentos mil pedidos novos, cinquenta gigabytes guardados."}, {"code": "# Illustrative prices, round numbers for the arithmetic: not Azure's.\nCOSMOS_PER_MILLION_RU = 0.25\nCOSMOS_PER_GB = 0.25\nSQL_PER_VCORE_HOUR = 0.25\nSQL_PER_GB = 0.12\nSERVERLESS_PER_TB = 5.00\n\n", "note": "**Todo preço aqui é ilustrativo**, um número redondo para a conta e não o do Azure. A tabela de preços da lição 1 dá os reais, com as unidades e as datas."}, {"code": "# Assumptions about the workload, to be replaced by measurements.\nRU_PER_LOOKUP = 3            # one in-partition query returning ten small orders\nRU_PER_WRITE = 6             # one 1 KB document, indexed by default\nSQL_VCORES = 2\nMIN_MB_PER_QUERY = 10\n\n", "note": "**E as suposições sobre a carga, escritas onde podem ser contestadas.** Três unidades de requisição por consulta e seis por gravação são estimativas para documentos pequenos; no Azure, a cobrança de requisição que toda resposta do Cosmos DB traz, lição 13, as substitui por medições. Os 10 MB são o mínimo que a Microsoft documenta que um pool SQL serverless cobra por consulta."}, {"code": "def cosmos():\n    ru = LOOKUPS * RU_PER_LOOKUP + WRITES * RU_PER_WRITE\n    return {\"request units\": ru / 1e6 * COSMOS_PER_MILLION_RU, \"storage\": STORED_GB * COSMOS_PER_GB}\n\n", "note": "**Cosmos DB, serverless**: unidades de requisição por milhão, e armazenamento. Os pedidos são particionados pelo cliente, então cada consulta fica dentro de uma partição."}, {"code": "def sql_database():\n    return {\"compute\": SQL_VCORES * 730 * SQL_PER_VCORE_HOUR, \"storage\": STORED_GB * SQL_PER_GB}\n\n", "note": "**Azure SQL Database**: dois vCores em cada hora do mês, usados ou não, e armazenamento. As consultas são uma consulta indexada cada, e a máquina fica quase toda ociosa."}, {"code": "def synapse_serverless():\n    tb = LOOKUPS * MIN_MB_PER_QUERY / 1e6\n    return {f\"{tb:.0f} TB processed\": tb * SERVERLESS_PER_TB}\n\n", "note": "**O pool SQL serverless do Synapse**: cobrado por dados processados, pelo menos 10 MB por consulta, por menos que a consulta leia."}, {"code": "for name, bill in [(\"Cosmos DB, serverless\", cosmos()), (\"Azure SQL Database, 2 vCores\", sql_database()),\n                   (\"Synapse serverless SQL pool\", synapse_serverless())]:\n    lines = \"  \".join(f\"{k} {v:,.2f}\" for k, v in bill.items())\n    print(f\"{name:<30} {sum(bill.values()):>8,.2f} USD   {lines}\")\n", "note": "Uma linha por armazenamento: o total do mês e do que ele é feito."}]}
```

```
ana@laptop:~/azure$ python compare.py
Cosmos DB, serverless             15.65 USD   request units 3.15  storage 12.50
Azure SQL Database, 2 vCores     371.00 USD   compute 365.00  storage 6.00
Synapse serverless SQL pool      150.00 USD   30 TB processed 150.00
```

## O que os três números dizem

**O Cosmos DB fica em uns quinze dólares, e o armazenamento é a maior parte.** As requisições custam
3,15 porque cada consulta é uma consulta barata dentro de uma partição, o padrão para o qual o
armazenamento foi construído; os 50 GB custam 12,50. Se a estimativa de três unidades de requisição por
consulta estiver errada por um fator de três, o total anda uns seis dólares, e é por isso que a
suposição pode ser um chute hoje e uma medição no mês que vem.

**O Azure SQL Database fica em 371, e quase tudo são os dois vCores**, cobrados a cada hora, abra-se a
tela ou não. A consulta em si seria rápida com um índice no cliente e na data; o preço é a máquina.
Esse número se lê de outro jeito se os pedidos já moram nesse banco por causa do checkout, como a
seção anterior os pôs: aí a tela quase não custa nada a mais, porque a máquina já está paga. **O
armazenamento mais barato para uma carga nova muitas vezes é o que já está rodando**, desde que a carga
caiba no ramo dele.

**O pool serverless do Synapse fica em 150, e é o formato errado a qualquer preço.** Cada consulta paga
por pelo menos 10 MB, então três milhões de consultas pagam por 30 TB de leitura para devolver alguns
kilobytes cada, e cada uma leva segundos para ser planejada e executada, o que uma tela não consegue
esperar. Um motor de lake usado como banco de dados é lento e, neste volume, nem barato é.

**Nenhum destes números é do Azure.** Rode a tabela de preços da lição 1 para preços reais, troque o
primeiro bloco de constantes e rode o programa de novo; a ordem só muda se os preços reais diferirem
destes por mais de uma ordem de grandeza, que é o que vale saber sobre uma comparação antes de confiar
nela.
