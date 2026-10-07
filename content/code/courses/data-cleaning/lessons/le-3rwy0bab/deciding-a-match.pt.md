---
title: Decidir uma correspondência, e contar os erros
version: 1
---

**Toda regra de correspondência comete dois tipos de erro**: junta registros que são pessoas
diferentes, e deixa passar registros que são a mesma pessoa. Apertar uma regra troca o primeiro pelo
segundo. No trabalho real, você estima os dois conferindo à mão uma amostra de pares. Aqui o arquivo
de verdade do laboratório lista as 58 pessoas que realmente se cadastraram duas vezes, então toda
regra recebe uma nota exata:

```schooling-example
{
  "language": "python",
  "file": "score.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom match import pairs\n\n"
    },
    {
      "code": "truth = pd.read_csv(\"~/clean-data/truth/duplicates.csv\")\nreal = {frozenset(p) for p in zip(truth[\"customer_id\"], truth[\"same_as\"])}\n",
      "note": "**A resposta do laboratório**: os 58 pares que ele plantou, cada um como par sem ordem, para `a, b` e `b, a` serem o mesmo."
    },
    {
      "code": "pairs[\"real\"] = [frozenset(p) in real for p in zip(pairs[\"a\"], pairs[\"b\"])]\n",
      "note": "Cada par comparado, marcado como real ou não."
    },
    {
      "code": "rules = [\n    (\"name 100\", pairs[\"name\"] == 100),\n    (\"name >= 85\", pairs[\"name\"] >= 85),\n    (\"name >= 85 and email or cep\", (pairs[\"name\"] >= 85) & (pairs[\"email\"] | pairs[\"cep\"])),\n    (\"email or cep, any name\", pairs[\"email\"] | pairs[\"cep\"]),\n]\n\n",
      "note": "Quatro regras, da regra de nome mais estrita a um identificador sozinho."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(f\"real duplicates: {len(real)}, of which in a compared block: {pairs['real'].sum()}\")\n    for rule, chosen in rules:\n        found = pairs[chosen]\n        print(f\"{rule:30} matched {len(found):4}  right {found['real'].sum():3}  \"\n              f\"wrong {(~found['real']).sum():4}\")\n",
      "note": "Para cada regra, quantos pares ela casou, e quantos desses são reais."
    }
  ]
}
```

```
ana@lab:~/clean$ python score.py
real duplicates: 58, of which in a compared block: 52
name 100                       matched  300  right  41  wrong  259
name >= 85                     matched  539  right  48  wrong  491
name >= 85 and email or cep    matched   49  right  48  wrong    1
email or cep, any name         matched   53  right  52  wrong    1
```

Leia as linhas de cima para baixo:

- **Nomes idênticos** acha 41 duplicados reais e junta 259 pares de pessoas diferentes. Seis vezes
  mais errado do que certo.
- **Nomes pelo menos 85 parecidos** acha 48 e junta 491 errado. Afrouxar o limite achou mais sete
  duplicados e somou mais 232 desconhecidos.
- **Um nome parecido mais um identificador em comum**, o mesmo e-mail ou o mesmo CEP: 48 certos e 1
  errado. O nome estreita o campo e o identificador confirma.
- **O identificador sozinho**, qualquer que seja o nome: 52 certos e 1 errado. Dentro de um bloco de
  sobrenome, um e-mail ou CEP em comum é evidência suficiente, e pega os duplicados cujo nome mais se
  afastou.

Uma das 259 junções erradas, para ver a cara de um homônimo:

```
ana@lab:~/clean$ python -c "from score import pairs; from keys import customers as c; w = pairs[(pairs['name'] == 100) & ~pairs['real']].iloc[0]; print(c[c['customer_id'].isin([w['a'], w['b']])][['customer_id', 'name', 'city', 'cep', 'signed_up']].to_string(index=False))"
customer_id           name         city       cep  signed_up
     C00007 Daniel Almeida   SÃ£o Paulo 08399-108 2023-02-24
     C01610 Daniel Almeida B. Horizonte 30010-991 2025-06-06
```

Mesmo nome, cidade diferente, CEP diferente, dois anos e meio de distância. Ninguém que lesse as duas
linhas as chamaria de uma pessoa, e uma regra só de nomes chamou.

**A única correspondência errada que sobrevive a toda regra** é um par com o mesmo nome e o mesmo
e-mail que o arquivo de verdade lista como duas pessoas. Nada no dado conseguiria separá-las; um
casal que divide um endereço pareceria exatamente assim. Todo sistema de correspondência tem um
resíduo assim, e a resposta honesta é mantê-lo pequeno, medi-lo e tornar as junções reversíveis — o
que é a próxima seção.
