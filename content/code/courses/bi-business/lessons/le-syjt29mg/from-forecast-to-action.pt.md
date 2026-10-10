---
title: Da previsão à ação
version: 1
---

A aula 8 terminou com uma previsão e uma faixa. Uma previsão não muda nada sozinha: alguém ainda
precisa decidir quantos carretéis de mangueira pedir, se baixa o preço de um jogo de jardim, que loja
ampliar. **A análise prescritiva é a parte do BI que recomenda o que fazer**, e é a mais fácil de
errar sem que ninguém perceba, porque a opção que não foi escolhida não deixa números para comparar.

## O formato de uma pergunta prescritiva

A ideia errada é que a análise prescritiva é uma previsão melhor, ou um algoritmo mais esperto. É uma
pergunta diferente, com três partes, e nenhuma delas é uma previsão:

| parte | o que pergunta | para o carretel de mangueira no depósito da Varanda |
|---|---|---|
| opções | o que poderíamos fazer? | pedir agora ou depois; pedir mais ou menos |
| restrições | o que limita a escolha? | o fornecedor leva sete dias; o depósito comporta uns mil carretéis; o fornecedor vende em caixas de 30 |
| objetivo | o que queremos alcançar, e a que custo? | nunca ficar sem, mantendo o mínimo possível de dinheiro parado em estoque |

**A previsão é uma entrada, o objetivo é uma escolha.** Duas pessoas com a mesma previsão e objetivos
diferentes vão fazer recomendações diferentes, e as duas podem estar certas. "Nunca ficar sem" e
"manter o mínimo de estoque" puxam para lados opostos, e alguém precisa dizer quanto de um vale
quanto do outro. Isso é uma decisão de negócio, e um analista que a toma calado dentro de uma fórmula
tomou uma decisão que não era dele.

## De uma regra à otimização

O trabalho prescritivo vem em tamanhos, e a maior parte do trabalho de um analista de BI vem no
menor:

- uma regra: "repor quando o estoque chegar a este nível", calculada uma vez e escrita. A próxima
  seção monta uma numa planilha;
- uma comparação de poucas opções: três descontos possíveis para dezembro, cada um com as vendas e o
  lucro estimados, lado a lado para alguém escolher. A seção seguinte faz essa;
- um software de otimização: um solver que testa milhares de combinações de uma vez, como quanto de
  4.000 produtos mandar para nove lojas dentro dos limites dos caminhões. Isso é trabalho de pesquisa
  operacional e de cientistas de dados, e se apoia nas mesmas três partes.

**O tamanho não muda o formato.** Um solver com o objetivo errado acha a melhor resposta para a
pergunta errada, mais rápido e com mais casas decimais do que uma pessoa acharia.

## Recomendar, ou automatizar

A última pergunta é quem age sobre a resposta. Algumas respostas vão direto para um sistema: a regra
de reposição pode emitir um pedido de compra sem ninguém olhar. Outras vão para uma reunião: o
desconto de dezembro é uma recomendação que a Renata e a Helena vão discutir. **O que decide para
onde ela vai é o custo de errar, e não a sofisticação do método**, e a última seção desta aula é
sobre onde fica essa linha.
