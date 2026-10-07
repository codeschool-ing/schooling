---
title: Verificações escritas como código
version: 1
---

Toda aula terminou a sua limpeza com uma verificação: uma contagem antes e depois, uma chave que
precisa ser única, uma soma que não pode se mexer. Num pipeline, essas verificações são reunidas num
arquivo e rodadas depois de toda construção, para não dependerem de alguém se lembrar delas:

```schooling-example
{
  "language": "python",
  "file": "checks.py",
  "parts": [
    {
      "code": "\"\"\"Checks on the clean tables. Each one is a promise the pipeline makes.\"\"\"\nimport sys\n\nimport pandas as pd\n\n"
    },
    {
      "code": "customers = pd.read_csv(\"out/customers.csv\", dtype={\"customer_id\": str, \"birth_year\": \"Int64\"})\norders = pd.read_csv(\"out/orders.csv\", dtype={\"order_id\": str, \"customer_id\": str})\nchanges = pd.read_csv(\"out/changes.csv\", dtype=str)\n\n",
      "note": "**As tabelas limpas, lidas de volta do disco** com os seus tipos, como qualquer outra pessoa as leria."
    },
    {
      "code": "checks = {\n    \"customer_id is unique\": customers[\"customer_id\"].is_unique,\n    \"birth years are blank or between 1920 and 2010\":\n        customers[\"birth_year\"].dropna().between(1920, 2010).all(),\n    \"order_id is unique\": orders[\"order_id\"].is_unique,\n    \"no total is negative\": (orders[\"total\"] >= 0).all(),\n    \"every order has at least one line\": (orders[\"items\"] >= 1).all(),\n    \"every change names its rule\": changes[\"rule\"].notna().all(),\n}\n",
      "note": "**Cada verificação é uma frase e um teste.** A frase é o que uma falha imprime."
    },
    {
      "code": "failed = [name for name, ok in checks.items() if not ok]\nfor name in failed:\n    print(f\"FAILED: {name}\")\nprint(f\"{len(checks) - len(failed)} of {len(checks)} checks passed\")\n",
      "note": "Nomeia toda verificação que falhou, e depois conta."
    },
    {
      "code": "sys.exit(1 if failed else 0)\n",
      "note": "**Uma falha termina com status de saída 1**, para que um agendador ou alguém rodando isso num script veja."
    }
  ]
}
```

```
ana@lab:~/clean$ python checks.py
6 of 6 checks passed
```

Cada verificação é uma promessa que as tabelas limpas fazem a quem as usa, escrita como uma frase e
um teste. Uma verificação só vale a pena se falhar quando a promessa for quebrada, então aqui está
uma quebrada de propósito: a última linha dos pedidos limpos duplicada, como faria um acréscimo
descuidado ou uma exportação repetida.

```
ana@lab:~/clean$ cp out/orders.csv /tmp/orders.csv && tail -1 /tmp/orders.csv >> out/orders.csv
ana@lab:~/clean$ python checks.py; echo exit status $?
FAILED: order_id is unique
5 of 6 checks passed
exit status 1
ana@lab:~/clean$ python run.py > /dev/null 2>&1; python checks.py
6 of 6 checks passed
```

A verificação diz qual promessa foi quebrada, e o script termina com **status de saída 1**. Esse
número é o que torna a verificação útil para máquinas: um processo agendado, uma regra de `make` ou
um passo de integração contínua podem parar nele, e uma tabela quebrada nunca é publicada. O último
comando reconstrói `out/` a partir dos brutos e roda as verificações de novo, e elas passam, porque o
estrago foi numa saída, que é descartável, e não numa entrada, que não é.

Boas verificações têm três coisas em comum:

- **Testam promessas, não números.** "order_id é único" sobrevive aos dados do mês que vem; "há
  28.526 pedidos" falha no primeiro pedido novo. Contagens ficam no log, onde uma pessoa as lê.
- **Leem as saídas como um estranho leria**, do disco, com os tipos declarados, não dos objetos que
  o pipeline ainda tem na memória.
- **Cada uma está lá por causa de um defeito que este curso encontrou.** Uma verificação para um
  problema que ninguém viu é barata de escrever e fácil de errar; uma para um que aconteceu é
  evidência.
