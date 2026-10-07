---
title: A mesma pessoa, duas vezes
version: 1
---

**Os duplicados que mais custam são os de chaves diferentes**: uma pessoa com duas contas. Nada se
repete exatamente. O nome está escrito diferente, o e-mail mudou de domínio, o CEP perdeu o hífen.
Uma contagem de clientes sai inflada em um, as compras da pessoa ficam divididas em dois
históricos, e uma campanha de "cliente novo" mira alguém que compra há dois anos.

O primeiro passo é levar todo campo que possa identificar uma pessoa a uma forma simples, para que
diferenças que não importam parem de esconder as que importam:

```schooling-example
{
  "language": "python",
  "file": "keys.py",
  "parts": [
    {
      "code": "import unicodedata\n\nimport pandas as pd\n\n\n"
    },
    {
      "code": "def plain(text):\n",
      "note": "**Uma forma simples para qualquer texto.**"
    },
    {
      "code": "    text = unicodedata.normalize(\"NFKD\", text)\n",
      "note": "`NFKD` separa toda letra acentuada em letra e acento, então `ú` vira `u` seguido de um acento agudo combinante. A aula 6 explica as formas."
    },
    {
      "code": "    text = \"\".join(ch for ch in text if not unicodedata.combining(ch))\n",
      "note": "Os acentos, agora caracteres separados, são descartados."
    },
    {
      "code": "    return \" \".join(text.lower().split())\n\n\n",
      "note": "Minúsculas, e toda sequência de espaços reduzida a um, sem nenhum nas pontas."
    },
    {
      "code": "customers = pd.read_csv(\"raw/customers.csv\", dtype=str, keep_default_na=False,\n                        na_values=[\"\"]).drop_duplicates()\n",
      "note": "O arquivo de clientes sem as linhas duplicadas exatas."
    },
    {
      "code": "customers[\"name_key\"] = customers[\"name\"].map(plain)\n",
      "note": "O nome na forma simples."
    },
    {
      "code": "customers[\"email_key\"] = customers[\"email\"].str.strip().str.lower()\n",
      "note": "O e-mail aparado e em minúsculas. Os acentos não saem aqui: um endereço se compara exatamente ou não se compara."
    },
    {
      "code": "customers[\"cep_key\"] = customers[\"cep\"].str.replace(\"-\", \"\").str.zfill(8)\n",
      "note": "O CEP com oito dígitos, sem hífen e com os zeros à esquerda perdidos de volta, como os padrões da aula 2 pediram."
    }
  ]
}
```

```
ana@lab:~/clean$ python -c "from keys import plain; print(repr(plain('  MARIANA  Souza')), repr(plain('Mariana Souza')), repr(plain('Júlia Simões')))"
'mariana souza' 'mariana souza' 'julia simoes'
```

Maiúsculas, espaços a mais e acentos se desfazem. A aula 6 leva a padronização de texto mais longe;
isto é o mínimo para comparar.

Com chaves simples, o teste óbvio é se dois registros compartilham uma:

```
ana@lab:~/clean$ python -c "from keys import customers as c; print(c['name_key'].duplicated().sum(), c['email_key'].dropna().duplicated().sum())"
262 35
```

262 registros compartilham um nome simples com um anterior, e 35 compartilham um e-mail. **O primeiro
número não é 262 duplicados.** O nome mais comum mostra por quê:

```
ana@lab:~/clean$ python -c "from keys import customers as c; d = c[c['name_key'] == c['name_key'].value_counts().index[0]]; print(d[['customer_id', 'name', 'city', 'email']].apply(lambda col: col.str.normalize('NFC')).to_string(index=False))"
customer_id          name      city                       email
     C01000 Alice Pereira  Curitiba                         NaN
     C01380 Alice Pereira São Paulo alice.pereira33@example.net
     C01392 Alice Pereira São Paulo alice.pereira31@example.org
     C01760 Alice Pereira São Paulo alice.pereira89@example.com
     C01778 Alice Pereira São Paulo alice.pereira61@example.net
```

Cinco clientes chamadas Alice Pereira, quatro em São Paulo e uma em Curitiba, com quatro e-mails
diferentes. Nomes não são únicos, ainda menos num país em que poucos sobrenomes cobrem uma grande
parte da população. **Uma correspondência só pelo nome junta pessoas diferentes**, e cada uma dessas
junções mistura o histórico de compras de dois desconhecidos.

O e-mail é mais forte, mas incompleto: clientes das lojas muitas vezes não têm, e quem se cadastra de
novo às vezes usa outro endereço. A comparação precisa dos dois, e de um jeito de dizer quão
parecidos são dois nomes quando não são idênticos.
