---
title: Um arquivo que toda aula importa
version: 1
---

Daqui em diante, quase todo programa precisa das mesmas quatro coisas: os dados carregados do mesmo
jeito, a mesma lista de colunas que um modelo pode ler, a mesma divisão entre meses para aprender e
meses para testar, e a aritmética de créditos da aula 1. Escrevê-las em cada programa seriam vinte e
uma chances de escrever uma delas diferente, e uma diferença ali muda uma nota sem ninguém perceber
por quê.

Então elas vão num arquivo só, `feira.py`, em `~/ml`, e todo programa desta aula em diante começa
com `from feira import …`. **Este é o arquivo inteiro.** Salve uma vez; nenhuma aula depois o muda.

```schooling-example
{
  "language": "python",
  "file": "feira.py",
  "parts": [
    {
      "code": "# feira.py\n\"\"\"What every program in this course needs to know about Feira em Casa.\"\"\"\nimport pandas as pd\n",
      "note": "O arquivo diz o próprio nome na primeira linha, como todo programa deste curso."
    },
    {
      "code": "CREDIT = 40          # reais, paid for every credit sent\nKEPT = 480           # reais, what a subscriber who stays is worth\nSAVED = 0.30         # the share of leavers a credit keeps\n",
      "note": "**Os três números do negócio**, da aula 1. Eles moram aqui e em nenhum outro lugar, então mudar o preço do crédito muda a conta de todas as aulas de uma vez."
    },
    {
      "code": "NUMERIC = [\"age\", \"app_user\", \"tenure_months\", \"price_month\", \"orders_90d\", \"skips_90d\",\n           \"late_90d\", \"complaints_90d\", \"support_calls_90d\", \"rating_90d\", \"days_since_login\"]\nCATEGORICAL = [\"city\", \"payment\", \"plan\", \"box\", \"channel\"]\n",
      "note": "As colunas que um modelo pode ler. Duas colunas do `churn.csv` faltam nas duas listas de propósito, assim como o id e a data; a aula 4 diz o porquê de cada uma."
    },
    {
      "code": "\ndef load_churn(path=\"data/churn.csv\"):\n    churn = pd.read_csv(path, parse_dates=[\"snapshot\"])\n    for col in CATEGORICAL:\n        churn[col] = churn[col].astype(\"category\")\n    return churn\n",
      "note": "Lê o arquivo com as datas como datas e as colunas de texto como categorias do pandas, que alguns modelos deste curso usam sem mais trabalho."
    },
    {
      "code": "\ndef by_time(churn, first_test=\"2025-07-01\"):\n    \"\"\"The months before first_test to learn from, and the months from it on to test.\"\"\"\n    test = churn[\"snapshot\"] >= first_test\n    return churn[~test], churn[test]\n",
      "note": "**A divisão.** Tudo antes de julho de 2025 para aprender, de julho a dezembro para testar. A aula 3 é o argumento para cortar por data e não ao acaso; até lá, aceite como dado."
    },
    {
      "code": "\ndef net_value(churned, send):\n    \"\"\"Reais gained by sending the credit where send is true, against sending nobody.\"\"\"\n    churned = pd.Series(churned).to_numpy() == 1\n    send = pd.Series(send).to_numpy().astype(bool)\n    return SAVED * KEPT * (churned & send).sum() - CREDIT * send.sum()",
      "note": "**A nota que importa**: a tabela da aula 1 como função. Um verdadeiro positivo rende 0,3 × 480, todo crédito custa 40, e não mandar a ninguém é zero."
    }
  ]
}
```

Duas coisas nele merecem uma segunda olhada agora, e cada uma ganha uma aula própria depois.

**`by_time` testa nos últimos seis meses.** Os 18 meses de retratos são cortados em 1º de julho de
2025: os doze anteriores são o que qualquer método deste curso pode usar para aprender, e os seis
seguintes são onde ele é julgado. Um modelo, uma regra e uma constante recebem o mesmo corte, e é
isso que torna as notas comparáveis. A aula 3 trata de por que o corte é uma data.

**`net_value` é a nota.** Acurácia, precisão e as outras chegam na aula 10, e são úteis para
entender um modelo. Mas a pergunta da Feira em Casa é em reais, e esta é a função que responde.
Toda comparação desta aula é feita com ela.
