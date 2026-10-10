---
title: O que é vazamento
version: 1
---

**Vazamento é informação nos dados de treino que não vai existir no momento em que o modelo for
usado.** O modelo aprende com ela, como aprende com tudo, e a nota de validação o premia por isso,
porque as linhas de validação carregam a mesma informação. Depois o modelo é usado, a informação
não está lá, e a nota era a descrição de um mundo que não existe.

A imagem de costume é um descuido: alguém deixou a resposta na tabela. Isso acontece, e é o caso
fácil, porque a nota fica tão boa que todo mundo desconfia. **Os vazamentos que custam dinheiro são
os que deixam um modelo um pouco melhor**: alguns pontos numa nota que ninguém esperava perfeita,
por uma coluna com nome sensato e um motivo sensato para estar ali.

Há quatro portas de entrada, e esta aula tem um exemplo de cada:

| a porta | o que a carrega | onde está neste curso |
|---|---|---|
| **o alvo, disfarçado** | uma coluna escrita por causa do resultado | `cancel_reason`, seção 03 |
| **o futuro** | uma coluna calculada depois do momento da previsão | `days_since_last_order`, seção 04 |
| **a preparação** | uma etapa ajustada em todas as linhas antes da divisão | escolher colunas, seção 05 |
| **a divisão** | parentes ou linhas posteriores dos dois lados | aula 3, retomada na seção 06 |

As quatro têm o mesmo teste, e ele é a segunda pergunta de enquadramento da aula 1 feita a cada
coluna e a cada etapa: **no dia 1º, antes de o crédito sair, isto seria conhecido, e teria este
valor?**

## Por que a validação não pega

A validação protege contra um modelo que decora as linhas de treino. Ela não protege contra uma
informação que os dois lados compartilham, porque um vazamento não é uma diferença entre treino e
validação; é uma diferença entre **os dados e o mundo**. As duas metades de uma divisão vêm da mesma
exportação, escrita pelos mesmos sistemas no mesmo dia, e uma coluna que sabe o futuro sabe dos dois
lados. Por isso a única defesa confiável é perguntar de onde vem cada coluna, que é a seção 08, e é
por isso que duas colunas do `churn.csv` ficaram fora das listas do `feira.py` na aula 2.
