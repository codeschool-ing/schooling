---
title: Valores faltantes, direito
version: 1
---

Duas colunas do `churn.csv` têm lacunas: `rating_90d` está vazia em 4.977 linhas e `days_since_login`
em 15.912. A aula 3 as preencheu com −1 para a árvore ter um número, e a aula 5 com a mediana do treino
para uma soma poder incluí-las. As duas foram provisórias. Fazer direito é perguntar, para cada coluna,
**por que o valor falta**, porque o motivo decide o que preencher.

- **Falta porque não existe.** `days_since_login` está vazia para todo assinante que não usa o
  aplicativo. Não há número de dias a descobrir; o assinante nunca entrou.
- **Falta porque ninguém registrou.** `rating_90d` está vazia quando o assinante não deu nota a nenhuma
  caixa em noventa dias. A nota existe no sentido de que ele gostou mais ou menos das caixas, mas
  ninguém perguntou.
- **Falta por acidente.** Um campo de formulário que não salvou, uma carga que perdeu um dia. Aqui a
  lacuna não carrega informação, e preenchê-la com um valor típico é o certo.

Os dois primeiros tipos podem ser **informação em si**. Um assinante que nunca dá nota pode ser um que
não liga, ou um feliz demais para se dar ao trabalho. Por isso o `with_gaps` da seção anterior
acrescentou uma coluna de 0 ou 1 para cada, `no_rating` e `no_login`, ao lado do valor preenchido com a
mediana. O scikit-learn faz o mesmo com `SimpleImputer(strategy="median", add_indicator=True)`, que o
pipeline da aula 15 usa.

E na tabela essas duas colunas **não mudaram nada**: de R$ 16.424 para R$ 16.360 na regressão logística,
uma AUC que não se mexeu. As duas têm motivos, e os dois valem saber:

- `no_login` é a mesma coluna que `app_user`, de ponta-cabeça. Todo não usuário não tem login e todo
  usuário tem, então a marca repetiu algo que o modelo já tinha.
- `no_rating` separa sim dois grupos, 4,2% contra 5,8% cancelando, nos meses de treino. Mas com a
  mediana preenchida, uma nota faltante já fica no meio da escala, onde a taxa de churn é mais ou menos
  a mesma, então a reta tinha pouco a aprender com a marca.

É um resultado normal, e o hábito continua valendo: uma marca custa uma coluna, e num conjunto de dados
em que as lacunas não são aleatórias ela pode carregar muito. **O erro é o contrário**: preencher uma
lacuna que quer dizer algo com um valor que a esconde, e depois concluir pelo modelo que a coluna não
importava.

Duas regras sobre o preenchimento em si. **Calcule o valor de preenchimento nas linhas de treino**, nunca
em todas, que é o vazamento de preparação da aula 4. E **para árvores, deixe as lacunas como estão**: o
`HistGradientBoostingClassifier` aprende em cada corte para que lado vão os valores faltantes, então usa a
lacuna como informação sem que ninguém diga. Preenchê-la antes joga isso fora.
