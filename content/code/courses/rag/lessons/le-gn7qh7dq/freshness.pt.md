---
title: Atualidade
version: 1
---

O regulamento de devoluções da Marginalia mudou em 2 de fevereiro de 2026, de catorze dias para trinta
e de frete de devolução pago para grátis. Para um assistente de atendimento, a pergunta é quanto tempo
depois da mudança o assistente começou a dar a resposta nova.

## Com recuperação: refazer o embedding do que mudou

Num sistema de RAG o regulamento novo é um documento novo. Cortá-lo em seções e gerar seus embeddings é
a mudança inteira, e o `reindex_cost.py` conta e mede o tempo disso nesta máquina, arredondando o tempo para cima até o
segundo, porque ele muda um pouco de uma execução para outra:

```
ana@lab:~/rag$ python reindex_cost.py
the returns policy     9 sections    973 tokens  under 1 s
every document        92 sections   7855 tokens  under 7 s
```

**Menos de um segundo para o regulamento que mudou, menos de sete para o corpus inteiro**, num núcleo
de processador com um modelo pequeno, e 973 tokens contra 7.855, que é o que um provedor hospedado
cobraria. Um modelo de embeddings hospedado somaria tempo de rede e
alguns centavos; nenhum dos dois muda a ordem de grandeza. A resposta nova vale a partir da próxima
pergunta, e a antiga some no instante em que os pedaços antigos saem do índice, que é o assunto da seção
sobre apagar.

O tempo é tão curto que o gargalo nunca é o embedding. É perceber que um documento mudou. A aula 5
guarda um hash do texto de cada pedaço, para que um processo noturno refaça o embedding exatamente dos
pedaços cujo texto mudou e de nada mais.

## Com fine-tuning: treinar de novo

Um modelo ajustado conhece o regulamento antigo até que um modelo novo seja treinado sem ele. Isso quer
dizer montar um conjunto que ensine os fatos novos, com exemplos suficientes para sobrescrever os
antigos, que o modelo aprendeu com a mesma força; rodar o treinamento, que leva de minutos a horas no
serviço de um provedor; avaliar o modelo novo contra o antigo para ver se nada mais quebrou; e trocar a
produção para o nome do modelo novo.

Nenhum desses passos é difícil, e todos eles são uma versão nova. Uma equipe que reindexaria um
documento na tarde em que ele mudou vai juntar os fine-tunings por semana ou por mês, e no meio-tempo o
modelo responde com confiança a partir de uma política que não vale mais. **A defasagem de um modelo
ajustado se mede em ciclos de versão, e a de um sistema de recuperação, em minutos.**

## As perguntas em que a atualidade é tudo

Algumas respostas mudam mais depressa que qualquer ciclo de versão: preços, prazos de entrega durante
uma greve da transportadora, estoque, o status de uma pane. O runbook do armazém neste corpus pede que o
atendimento ponha um aviso de atraso na central de ajuda quando uma transportadora cai. Um assistente de
recuperação lê esse aviso a partir da próxima pergunta; um ajustado nunca fica sabendo que ele existiu.
Para respostas assim, até uma reindexação noturna pode ser lenta demais, e a aula 2 mandou a que muda
mais depressa, o status de um pedido, para uma chamada de API ao vivo em vez de qualquer documento.
