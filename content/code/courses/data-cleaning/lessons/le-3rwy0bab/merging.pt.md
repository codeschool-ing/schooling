---
title: Juntar: quem sobrevive, e o que vai junto
version: 1
---

**Uma correspondência é uma decisão sobre identidade; uma junção é uma decisão sobre dado.** Depois
que dois registros são a mesma pessoa, sobram três perguntas: qual id sobrevive, que valor de cada
campo ele mantém, e o que acontece com tudo que apontava para o outro id.

As regras de Ana são curtas:

- **o id mais antigo sobrevive.** Os ids aqui seguem a ordem de cadastro, então o menor é a primeira
  conta, e a história dela é a mais longa;
- **os valores ainda não se juntam.** Escolher o e-mail mais novo, o nome mais longo ou o endereço
  mais completo é **sobrevivência de atributos**, e cada escolha é uma regra a escrever, campo por
  campo. Por ora, o sobrevivente mantém os próprios valores;
- **nada é apagado.** A decisão vai para um arquivo que mapeia cada id absorvido no que sobrevive, e
  é aplicada onde quer que os ids apareçam.

```schooling-example
{
  "language": "python",
  "file": "merge.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom keys import customers\nfrom match import pairs\n\n"
    },
    {
      "code": "same = pairs[(pairs[\"name\"] >= 85) & (pairs[\"email\"] | pairs[\"cep\"])]\n",
      "note": "A regra escolhida na seção anterior: nome parecido e um identificador em comum."
    },
    {
      "code": "keep = {}\nfor a, b in zip(same[\"a\"], same[\"b\"]):\n    keep[max(a, b)] = min(a, b)\n",
      "note": "**O id mais antigo sobrevive.** Os ids seguem a ordem de cadastro, então o menor é a primeira conta."
    },
    {
      "code": "survivor = pd.Series(keep, name=\"kept_id\").rename_axis(\"customer_id\").reset_index()\nsurvivor.to_csv(\"survivors.csv\", index=False)\n",
      "note": "**A decisão, como arquivo**: uma linha por id absorvido e o id que ele passa a significar."
    },
    {
      "code": "print(f\"{len(survivor)} records point at an earlier one; first lines of survivors.csv:\")\nprint(survivor.head(3).to_string(index=False))\n\n"
    },
    {
      "code": "orders = pd.read_csv(\"raw/orders.csv\", dtype=str).drop_duplicates()\n",
      "note": "Os pedidos, lidos como texto e sem as repetições."
    },
    {
      "code": "moved = orders[\"customer_id\"].isin(survivor[\"customer_id\"])\nprint(f\"orders that change owner: {moved.sum()}\")\n",
      "note": "Quantos pedidos pertenciam a um id absorvido."
    },
    {
      "code": "before = orders[\"customer_id\"].nunique()\norders[\"customer_id\"] = orders[\"customer_id\"].replace(dict(zip(survivor[\"customer_id\"],\n                                                                survivor[\"kept_id\"])))\nprint(f\"customers with orders: {before} before, {orders['customer_id'].nunique()} after\")\n",
      "note": "O mapeamento aplicado: todo id absorvido trocado pelo sobrevivente, e o número de clientes distintos antes e depois."
    }
  ]
}
```

```
ana@lab:~/clean$ python merge.py
49 records point at an earlier one; first lines of survivors.csv:
customer_id kept_id
     C02450  C00519
     C02414  C00409
     C02436  C00388
orders that change owner: 2
customers with orders: 2273 before, 2272 after
```

49 registros agora apontam para um anterior: os 48 duplicados reais e o par que o dado não consegue
separar. Só 2 pedidos mudam de dono. A maioria das segundas contas foi aberta e nunca usada, o que é
típico — alguém se cadastra de novo porque esqueceu a primeira conta, e depois a encontra.

**O `survivors.csv` é a saída mais importante desta aula.** É pequeno, é legível, e é a decisão
inteira num arquivo: qualquer um confere uma linha, desfaz uma junção errada apagando-a, ou aplica o
mesmo mapeamento aos pedidos do mês seguinte. Uma junção feita sobrescrevendo ids no lugar teria o
mesmo efeito hoje e não deixaria como responder, no ano que vem, por que dois clientes viraram um.

## Em SQL

O mesmo mapeamento, carregado como tabela, se aplica com uma junção e `COALESCE`: cada pedido pega o
id do sobrevivente quando há um e mantém o seu nos outros casos. A aula 11 constrói as junções de que
isso precisa, e a aula 17 põe o arquivo de mapeamento junto do resto da limpeza para ele rodar toda
vez.
