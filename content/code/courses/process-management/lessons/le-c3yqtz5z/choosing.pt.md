---
title: Escolhendo uma aposta para um trabalho
version: 1
---

Nenhuma organização escolhe um método uma vez e o aplica a tudo. Um banco toca o relatório regulatório de um jeito e o aplicativo de outro, e o mesmo arquiteto pode trabalhar nos dois na mesma semana. A pergunta útil não é *qual método é o melhor*, e sim **que suposição o trabalho à sua frente sustenta**.

## Quatro perguntas que separam quase todo trabalho

| pergunta | se sim, puxa para | se não |
|---|---|---|
| Os requisitos são fixados por algo de fora do time — uma lei, uma máquina, um contrato assinado? | um plano feito na frente | ciclos curtos |
| Uma mudança tardia é muito cara — hardware, certificação, uma migração de dados sem volta? | um plano feito na frente | ciclos curtos |
| Um usuário consegue testar uma versão parcial e reagir? | ciclos curtos | um plano feito na frente |
| A tecnologia é nova para quem vai construir? | ciclos curtos, com a parte arriscada primeiro | qualquer um |

As respostas raramente concordam. Uma funcionalidade nova de agendamento para uma rede de clínicas pode ter usuários capazes de testar uma versão parcial, uma integração de pagamento fixada pelo contrato do provedor e uma migração de dados que não pode ser desfeita. **Misturar é normal.** A integração e a migração ganham um plano com datas; as telas ganham ciclos curtos com as recepcionistas que vão usá-las.

## Complicado e complexo

O framework Cynefin, de Dave Snowden, dá nome à distinção por trás dessas perguntas. Um problema **complicado** tem uma resposta certa que um especialista consegue encontrar de antemão: o plano pode ser feito antes do trabalho. Um problema **complexo** tem uma resposta que só aparece tentando, porque o sistema reage ao que você faz: o plano tem de ser uma série de experimentos. Software costuma ter os dois tipos dentro de um mesmo projeto, e o erro é tratar uma parte complexa como se só análise resolvesse.

## O que o contrato diz

O método muitas vezes é decidido antes de o time chegar, pelo contrato. Um contrato de **preço fixo** fixa escopo, custo e data juntos, então empurra para um plano feito na frente e transforma cada mudança numa negociação. Um contrato por **tempo e material** paga pelo esforço gasto, o que torna mudar de rumo barato para o fornecedor e arriscado para o cliente, que carrega a incerteza. Contratos que fixam orçamento e data e deixam o escopo aberto — às vezes chamados de preço fixo com escopo variável — são uma tentativa de escrever a aposta ágil num documento jurídico.

Um arquiteto lendo uma proposta deveria verificar qual desses é o contrato antes de decidir quanto do projeto precisa estar resolvido no primeiro mês.
