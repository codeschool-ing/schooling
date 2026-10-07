---
title: Um sim escrito de dez jeitos
version: 1
---

O consentimento de marketing é a coluna com mais grafias no arquivo. Cada sistema escreveu a sua:

```
ana@lab:~/clean$ python -c "from raw_customers import customers as c; print(c['marketing_opt_in'].value_counts(dropna=False).to_string())"
marketing_opt_in
true     568
false    459
1        391
0        344
sim      116
S        107
Sim      106
não       89
nao       76
N         63
NaN       57
```

Dez grafias e um vazio. **Converter isso com `astype(bool)` seria um desastre que roda sem erro**:
em Python toda string não vazia é verdadeira, então `"false"`, `"0"` e `"não"` virariam
consentimento, e 1.031 pessoas que disseram não passariam a receber ofertas. O vazio não é melhor,
porque `NaN` também conta como verdadeiro. Contado neste arquivo:

```
ana@lab:~/clean$ python -c "from raw_customers import customers as c; print(len(c), c['marketing_opt_in'].astype(bool).sum())"
2376 2376
```

Todos os 2.376 clientes teriam consentido.

A conversão segura nomeia os dois lados e recusa todo o resto:

```schooling-example
{
  "language": "python",
  "file": "consent.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom raw_customers import customers\n\n"
    },
    {
      "code": "YES = {\"true\", \"1\", \"s\", \"sim\"}\nNO = {\"false\", \"0\", \"n\", \"não\", \"nao\"}\n",
      "note": "**Os dois lados escritos**, em minúsculas."
    },
    {
      "code": "key = customers[\"marketing_opt_in\"].str.strip().str.lower()\n",
      "note": "Espaços e maiúsculas removidos antes de qualquer comparação."
    },
    {
      "code": "unknown = key.notna() & ~key.isin(YES | NO)\nif unknown.any():\n    raise ValueError(f\"unmapped consent values: {sorted(key[unknown].unique())}\")\n",
      "note": "Um valor presente que não está em nenhuma das listas interrompe o script, dizendo a grafia."
    },
    {
      "code": "customers[\"opt_in\"] = key.map(lambda v: True if v in YES else False if v in NO else pd.NA)\n",
      "note": "Cada grafia para `True` ou `False`; o vazio continua `pd.NA`."
    },
    {
      "code": "customers[\"opt_in\"] = customers[\"opt_in\"].astype(\"boolean\")\n",
      "note": "O booleano anulável, que guarda `<NA>` ao lado das duas respostas."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from consent import customers as c; print(c['opt_in'].value_counts(dropna=False).to_string()); print(c['opt_in'].dtype)"
opt_in
True     1288
False    1031
<NA>       57
boolean
```

Três coisas nela são de propósito.

- **As duas listas estão escritas.** Mapear os sins e chamar todo o resto de não transformaria a
  próxima grafia nova, talvez um `yes` vindo de um formulário em inglês, numa recusa que ninguém
  escolheu.
- **Uma grafia desconhecida interrompe o script.** Ele nomeia os valores, então pôr um deles na
  lista certa é uma mudança de uma linha que alguém revisa, e não um padrão silencioso.
- **O vazio continua vazio.** As 57 pessoas sem resposta registrada não são nem sim nem não, e o
  tipo `boolean`, o booleano anulável do pandas, guarda `<NA>` ao lado de `True` e `False`. Para
  consentimento isso importa juridicamente além de estatisticamente: pela LGPD, ausência de
  resposta não é permissão.

Maiúsculas e espaços são removidos antes da comparação, então `Sim`, `sim` e ` SIM ` são um valor
só. Acentos não, de propósito: `não` e `nao` estão os dois na lista, e quem lê o código vê que os
dois foram vistos.
