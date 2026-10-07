---
title: Toda mudança, com a sua regra
version: 1
---

O log diz quantos valores mudaram. Uma auditoria precisa saber quais, então o `run.py` também grava
`out/changes.csv`, uma linha por valor mudado:

```
ana@lab:~/clean$ python -c "import pandas as pd; c = pd.read_csv('out/changes.csv', dtype=str); print(c.groupby(['table', 'column', 'rule']).size().to_string()); print(c[c['rule'].str.startswith('typed')].head(3).to_string(index=False))"
table      column       rule                         
customers  birth_year   century rule, lesson 10          105
                        placeholder, lesson 4            338
orders     customer_id  same person, lesson 5              2
           total        coupon above basket, lesson 9    137
                        typed total, lesson 9              7
 table    key column before  after                  rule
orders 100592  total 2516.0  251.6 typed total, lesson 9
orders 106842  total  458.5  45.85 typed total, lesson 9
orders 111955  total 2721.5 272.15 typed total, lesson 9
```

589 mudanças em cinco grupos, e cada grupo nomeia a aula cuja regra a fez. As primeiras linhas dos
totais digitados mostram o formato: tabela, chave, coluna, o valor antes, o valor depois, e a
regra.

Um registro de mudanças responde perguntas que de outro jeito não têm resposta:

- **"Por que o pedido 106842 está em R$ 45,85 se o sistema diz R$ 458,50?"** Porque os itens dele
  somam R$ 45,85, pela regra da aula 9, e a linha diz isso.
- **"Quanto a limpeza mudou a receita?"** Some `after` menos `before` nos totais dos pedidos.
- **"Em que clientes mexemos?"** Toda chave está listada. Se um deles perguntar, pela LGPD, o que
  foi feito com os seus dados, a resposta é um filtro, não uma investigação.

Três escolhas o tornam confiável:

- **As mudanças são achadas por comparação, não por memória.** O `run.py` compara cada total bruto
  com o decidido e registra toda diferença, então uma regra que mudou mais do que se esperava
  aparece aqui mesmo que ninguém tenha planejado.
- **Só valores que mudaram são registrados.** Uma marca como `corporate` acrescenta uma coluna e não
  muda valor nenhum, então mora na tabela, não no registro.
- **A regra é escrita em palavras que apontam para a decisão**, aqui uma aula; numa empresa, o
  chamado, o e-mail ou a reunião em que foi combinada.

É a mesma ideia das marcas da aula 9, na escala de um pipeline inteiro: **nada muda em silêncio, e
nada muda sem um motivo que alguém consiga ler**.
