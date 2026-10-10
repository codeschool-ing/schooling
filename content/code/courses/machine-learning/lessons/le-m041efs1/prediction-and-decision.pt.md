---
title: Uma previsão não é uma decisão
version: 1
---

O primeiro pedido chega à Ana numa frase: *"faz um modelo de churn para nós"*. Parece uma
especificação, e não é. **Um modelo produz um número; uma empresa faz alguma coisa.** Enquanto
ninguém disser o que será feito com o número, não há como distinguir um modelo bom de um ruim,
porque "bom" quer dizer "leva a ações melhores", e ninguém disse qual é a ação.

Então o primeiro trabalho é transformar a frase numa decisão. Na Feira em Casa fica assim. A equipe
de retenção pode mandar a um assinante um crédito de **R$ 40** na próxima caixa. Enviado a quem
estava para sair, segura parte dessas pessoas. Enviado a quem ia ficar de qualquer jeito, são R$ 40
dados de presente. A equipe quer saber **para quem mandar, no começo de cada mês**. Essa é a decisão,
e o modelo existe para informá-la.

## Quatro perguntas que transformam um pedido num problema

**1. O que é uma linha?** A unidade que o modelo avalia. Aqui é *um assinante no primeiro dia de um
mês*, não um assinante: a mesma pessoa é avaliada de novo todo mês, com o que mudou desde então. Um
modelo que avaliasse cada pessoa uma vez só estaria respondendo outra pergunta.

**2. Quando a previsão é feita, e o que se sabe nesse momento?** O momento da previsão é o dia 1º,
antes de o crédito sair. **Nada que não se saiba nesse momento pode ser entrada**, por melhor que
preveja. A aula 4 trata inteira de colunas que quebram essa regra sem parecer.

**3. O que exatamente se prevê, em que horizonte?** *Cancela durante o mês que segue o retrato.* Não
"um dia vai cancelar", o que vale para todo mundo em algum momento, e não "cancelou mês passado",
que é história. O horizonte tem de combinar com a ação: um crédito mandado hoje só muda o que
acontece nas próximas semanas.

**4. O que será feito com cada resposta?** Mandar o crédito, ou não. Duas ações, então este é um
problema de **classificação**: o trabalho do modelo é separar quem merece um crédito do resto.
Quando o que se prevê é uma quantidade, como os minutos que uma entrega vai levar, é um problema de
**regressão**, e a aula 5 começa pelos dois.

## O que os dados dizem sobre a decisão

O arquivo já responde às três primeiras perguntas, porque foi feito para esta. Um programa curto
mostra a forma dele. Salve-o como `frame.py` em `~/ml`:

```python
# frame.py
import pandas as pd

churn = pd.read_csv("data/churn.csv", parse_dates=["snapshot"])
print(f"{len(churn):,} rows, {churn['customer_id'].nunique():,} subscribers, "
      f"{churn['snapshot'].nunique()} monthly snapshots")
print(f"cancelled in the month after the snapshot: {churn['churned'].mean():.1%}")
months = churn.groupby("snapshot")["churned"].agg(subscribers="size", cancelled="sum")
print(months.tail(3).to_string())
```

```
ana@lab:~/ml$ python frame.py
62,885 rows, 7,583 subscribers, 18 monthly snapshots
cancelled in the month after the snapshot: 5.9%
            subscribers  cancelled
snapshot                          
2025-10-01         4098        281
2025-11-01         4137        284
2025-12-01         4146        248
```

**62.885 linhas e 7.583 pessoas**: cada assinante aparece, em média, mais de oito vezes. Em dezembro
de 2025 a equipe teria avaliado 4.146 assinantes, e 248 deles acabaram cancelando, que são os 5,9%
da segunda linha, com a variação de um mês para outro.

Leia essa taxa como o tamanho do palheiro. **Mais ou menos uma linha em dezessete é um
cancelamento**, então um modelo que diz "ninguém cancela" acerta cerca de 94% das vezes e é inútil
todas as vezes. A aula 2 faz esse modelo de propósito, como a coisa a superar, e a aula 13 trata do
que uma classe rara faz com cada número que mede um modelo.

## As palavras que este curso usa

- **Variáveis** (*features*) são as colunas que o modelo lê: `skips_90d`, `city`, `tenure_months` e
  assim por diante. Outros livros dizem entradas, preditores ou atributos.
- **O alvo**, ou **rótulo**, é a coluna que ele prevê: `churned`.
- **Um positivo** é uma linha cujo rótulo é 1, aqui um cancelamento. É positivo no sentido de "a
  coisa procurada", e por isso um positivo é má notícia para a empresa.
- **Ajustar** ou **treinar** é a etapa em que os números do modelo são escolhidos a partir dos dados,
  e **escorar** ou **prever** é usá-los em linhas que ele não viu.
