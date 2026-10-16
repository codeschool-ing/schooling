---
title: O que uma explicação não é
version: 1
---

Toda ferramenta desta aula responde a uma pergunta sobre **o modelo**. As perguntas que as pessoas trazem a
ela costumam ser sobre **o mundo**, e a distância entre as duas é onde explicações fazem estrago.

**Uma coluna importante não é uma causa.** As notas são a coluna mais importante por toda medida aqui, e
ninguém acredita que as notas fazem as pessoas sair. Caixas decepcionantes fazem as duas coisas: baixam a nota
e causam o cancelamento. Um gestor que lê a tabela de importância e decide subir as notas, pedindo a clientes
felizes que deem nota, por exemplo, subiria a coluna e deixaria o churn exatamente onde estava. O modelo então
daria chances menores a esses clientes e erraria sobre eles.

**Uma contribuição não é o efeito de uma ação.** O valor SHAP de +2,86 da nota de um assinante diz quanto
aquela nota mexeu na saída do modelo, sem segurar nada fixo no mundo. O que um crédito, uma ligação ou uma
caixa melhor fariam com aquele assinante é outra pergunta, e os dados deste curso não a respondem, porque
ninguém nunca recebeu um crédito ao acaso. Respondê-la pede um experimento: mande o crédito a uma metade
sorteada dos assinantes que o modelo escolhe, e compare. Os 30% da aula 11, a parte de quem sai que um
crédito segura, são exatamente o número que esse experimento mede.

**Colunas correlacionadas embaçam o crédito.** `rating_90d` e `unhappy` dizem quase a mesma coisa. Uma árvore
pode usar uma e ignorar a outra, uma regressão logística divide o peso entre elas, a importância por
permutação subestima as duas, e o SHAP dá a cada uma uma parte que depende das escolhas arbitrárias do
modelo. Antes de concluir que uma coluna não importa, confira se outra coluna a está carregando.

**Uma explicação pode estar errada do mesmo jeito que o modelo.** A seção do plano mensal achou uma
contribuição grande que vinha da codificação, não de nada sobre os assinantes. O SHAP a teria relatado com a
mesma fidelidade. Explicações valem mais quando são lidas com o ceticismo da aula 4: quando uma surpreende,
pergunte o que nos dados ou na preparação poderia tê-la produzido, antes de acreditar que diz algo sobre
clientes.

Para que as ferramentas servem é conferir, comunicar e depurar: **conferir** que o modelo aprendeu formas que
uma pessoa reconheceria, **comunicar** por que um assinante foi escolhido, e **depurar** um modelo cujo
comportamento em dados novos parece estranho, que é exatamente o que achou o artefato do plano mensal.
