---
title: O curso, olhando para trás
version: 1
---

Doze lições atrás, a pergunta de Ana era por que os relatórios da loja não deveriam rodar no banco que recebe os
pedidos. Cada lição desde então foi uma parte da resposta, e juntas elas formam um warehouse em que se pode confiar,
que se pode explicar e que se pode mudar:

- **Lições 1 e 2**: duas cargas de trabalho, dois formatos de banco; fatos, dimensões, e como cada medida se soma.
- **Lições 3 e 4**: a estrela e o floco de neve, dimensões conformadas e de papéis, o grão, chaves
  substitutas, membros desconhecidos e tabelas ponte.
- **Lição 5**: histórico, em cada tipo de dimensão que muda devagar, construído a partir de um log de mudanças.
- **Lição 6**: onde parar de normalizar, medido em linhas gravadas e bytes guardados, e as três escolas.
- **Lições 7 e 8**: por que um warehouse é paralelo e colunar, e quanto custa cada coisa.
- **Lições 9 e 10**: a mesma estrela em três warehouses na nuvem e num lakehouse de tabelas Delta.
- **Lições 11 e 12**: quem é dono do modelo, como seus números passam a bater, e como o que ele significa é escrito.

Uma ideia atravessou as doze. **O modelo é um conjunto de decisões sobre significado**: o que é uma linha, o que um
cliente era no dia em que comprou, o que a receita inclui. Cada tecnologia do curso, de uma dimensão tipo 2 a um log
Delta, é um jeito de manter essas decisões intactas enquanto os dados se movem e crescem. Os produtos mudam a cada
poucos anos; as decisões, não.

O que vem a seguir é manter tudo carregado. `pipelines-etl` toma este modelo como destino: extrair de forma incremental
em vez de inteira, carregar dimensões tipo 2 toda noite, agendar, tentar de novo, testar, e os contratos e a
documentação que esta lição começou, montados num pipeline que roda sem ninguém olhando.
