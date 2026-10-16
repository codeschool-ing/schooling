---
title: Por que árvores vencem em tabelas
version: 1
---

A tabela de câncer é amigável a um modelo linear. A maioria das tabelas de negócio não é: **o que
decide o resultado é uma regra com limiar**, um tipo de contrato, uma faixa de tarifa, um limite que
alguém definiu, e várias colunas que no fim não significam nada. O programa abaixo gera uma tabela
com esse formato, então as regras são conhecidas e as notas podem ser lidas contra elas. Salve como
`~/dl/table.py`:

```schooling-example
{
  "language": "python",
  "file": "table.py",
  "parts": [
    {
      "code": "\"\"\"table: a made-up customer table with the shape most business data has.\"\"\"\nimport numpy as np\n\n# The columns, in order: tenure, charge, calls, contract, age, noise1 to noise5.",
      "note": "Dez colunas: meses como cliente, a conta mensal, chamados de suporte no ano, o tipo de contrato, a idade e cinco colunas de puro ruído. Tabelas reais carregam colunas que não significam nada, e ninguém sabe de antemão quais."
    },
    {
      "code": "def make(n=3000, seed=0):\n    rng = np.random.default_rng(seed)\n    tenure = rng.integers(0, 73, n)\n    charge = rng.uniform(20, 120, n).round(2)\n    calls = rng.poisson(1.5, n)\n    contract = rng.integers(0, 3, n)\n    age = rng.integers(18, 80, n)\n    noise = rng.normal(size=(n, 5))",
      "note": "Cada coluna na sua própria escala: meses até 72, dinheiro de 20 a 120, uma contagem pequena, um código 0, 1 ou 2 para contratos mensais, anuais e de dois anos."
    },
    {
      "code": "    leaves = ((contract == 0) & (tenure < 24)) | ((calls >= 3) & (charge > 70)) \\\n        | ((contract == 0) & (age > 65) & (charge > 100))",
      "note": "Quem sai é decidido por regras com limiares: clientes novos em contrato mensal, quem ligou três vezes e paga mais de 70, clientes mais velhos pagando mais de 100 num plano mensal. É assim que uma regra de negócio, uma tarifa ou uma política moldam dados reais."
    },
    {
      "code": "    flipped = rng.random(n) < 0.1\n    y = (leaves ^ flipped).astype(np.int64)\n    X = np.column_stack([tenure, charge, calls, contract, age, noise]).astype(np.float64)\n    return X, y",
      "note": "Um rótulo em cada dez é trocado ao acaso, então nenhum modelo pode ser perfeito; algo perto de 0,9 é o teto."
    }
  ]
}
```

As regras fazem mais ou menos um cliente em cada quatro sair, e as trocas aleatórias limitam qualquer
modelo a perto de 0,9. Rode a mesma bancada nela. Salve como `~/dl/churn.py`:

```schooling-example
{
  "language": "python",
  "file": "churn.py",
  "parts": [
    {
      "code": "\"\"\"churn: the made-up customer table through the same three models.\"\"\"\nimport bench\nimport table\n\nX, y = table.make()\nprint(X.shape[0], \"rows,\", X.shape[1], \"columns,\", f\"{y.mean():.0%} left\")\nbench.run(X, y)",
      "note": "O mesmo `bench.py`, então as mesmas dobras, os mesmos três modelos e o mesmo relógio, em 3.000 clientes gerados."
    }
  ]
}
```

```
ana@vm:~/dl$ python churn.py
3000 rows, 10 columns, 24% left
logistic regression  accuracy 0.801  worst fold 0.782    0.03 s
gradient boosting    accuracy 0.883  worst fold 0.877    1.10 s
MLP, PyTorch         accuracy 0.799  worst fold 0.788    5.77 s
```

**O boosting chega a 0,883, a poucos pontos do teto, e os outros dois param perto de 0,80.** Um
modelo que sempre respondesse "fica" marcaria 0,76, então a regressão logística e a rede acharam só
uma pequena parte das regras. As piores dobras contam a mesma história: boosting 0,877, os outros dois
abaixo de 0,79. A rede é de novo a mais lenta, com 5,77 segundos contra 1,10 do boosting.

## Três razões, cada uma uma propriedade da tabela

Em 2022, Léo Grinsztajn, Edouard Oyallon e Gaël Varoquaux compararam árvores e redes em 45 conjuntos
de dados tabulares de uns dez mil registros cada, incluindo redes projetadas para tabelas, e
perguntaram por que as árvores continuavam vencendo. **As três respostas deles aparecem no
`table.py`.**

**O alvo é irregular.** Se um cliente sai ou não muda de repente aos 24 meses, nos três chamados, numa
conta de 70. Uma árvore põe um corte exatamente nesse valor e pronto. Uma rede monta a resposta com
somas de ReLUs, que dobram um pouco de cada vez, e aproximar um degrau nítido e um `and` de dois
limiares exige muitas unidades e muitos exemplos. Redes têm viés para funções suaves, o que é uma
força em imagens e uma desvantagem aqui.

**Metade das colunas é ruído.** Uma árvore testa um corte em cada coluna, descobre que `noise3` nunca
ajuda e a deixa de lado. A rede dá a cada coluna um peso para cada uma das 64 unidades da primeira camada. Ela precisa
aprender a zerar esses 320 pesos a partir de 2.400 linhas de treino, o que deixa espaço para ajustar o
ruído no lugar.

**Cada coluna significa algo por si só.** Meses, dinheiro e um código de contrato não são
intercambiáveis. Uma árvore olha uma coluna por vez. A primeira camada de uma rede mistura as dez em somas ponderadas antes de qualquer outra coisa. É o
movimento certo para pixels, em que qualquer combinação de vizinhos pode importar, e o errado para
uma tabela, cujas colunas foram escolhidas por alguém que sabia o que cada uma queria dizer.

Nada disso diz que uma rede não consegue chegar a 0,88 aqui. Ela poderia ser ajustada: mais unidades,
dropout (aula 7), outra taxa (aula 5), uma busca sobre tudo isso (aula 9 de `machine-learning`).
**Cada uma dessas é uma tarde, e o boosting chegou a 0,883 com os padrões.** Essa é a comparação que
importa num dia de trabalho.
