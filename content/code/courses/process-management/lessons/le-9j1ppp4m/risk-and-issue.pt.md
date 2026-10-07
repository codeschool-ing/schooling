---
title: Um risco ainda não é um problema
version: 1
---

A palavra *risco* é usada de forma frouxa para qualquer coisa que preocupa as pessoas, e essa frouxidão torna o gerenciamento de riscos mais difícil do que precisa ser. A definição do Guia PMBOK é precisa e vale adotá-la: **um risco é um evento ou condição incerta que, se ocorrer, tem efeito positivo ou negativo sobre um ou mais objetivos do projeto.**

Três partes dessa frase fazem o trabalho.

## Incerto

Um risco **pode acontecer ou não**. Algo que já aconteceu, ou que certamente vai acontecer, não é risco; é uma **questão** (issue), e é tratada lidando com ela agora, não estimando sua probabilidade. O provedor de pagamento *pode* mudar a API no próximo trimestre: isso é um risco. O provedor de pagamento *anunciou* que vai aposentar a API atual em junho: isso é uma questão, com data, e entra no backlog como trabalho.

A distinção importa porque as duas pedem respostas diferentes. Um risco recebe uma probabilidade, um dono e um plano do que fazer se acontecer; uma questão recebe uma tarefa e um prazo. Um projeto cujo registro de riscos está cheio de questões não está gerenciando risco; está mantendo uma lista de problemas conhecidos que não agendou.

## Positivo ou negativo

Um risco pode ser boa notícia. O time Agenda suspeita que uma biblioteca de calendário de código aberto já trate as consultas recorrentes das clínicas, o que pouparia vários dias. Esse evento incerto é uma **oportunidade**, e merece a mesma atenção que uma ameaça: alguém deveria descobrir, cedo, se é verdade. Muitos times só acompanham ameaças e perdem oportunidades que teriam pago várias delas.

## Objetivos

Um risco é definido pelo efeito sobre o que o projeto quer alcançar — prazo, custo, escopo, qualidade, os benefícios para os quais foi criado. "O banco pode ficar lento" ainda não é uma declaração de risco. "O tempo de resposta da tela de agendamento pode passar de dois segundos com a carga de segunda de manhã, o que violaria o nível de serviço da aula 8" é, porque diz o que seria afetado e como.

## Escrevendo um risco

Uma forma útil é **causa, evento, efeito**: *como* a integração de faturamento é entendida por um único desenvolvedor, *ele pode sair* durante o projeto, *o que* atrasaria o trabalho de pagamento em cerca de quatro semanas. Cada parte aponta para uma resposta diferente. A causa pode ser removida (espalhar o conhecimento), o evento pode ficar menos provável (conversar com o desenvolvedor) e o efeito pode ser reduzido (documentar a integração). Um risco escrito como um substantivo solto — "rotatividade" — não aponta para nenhuma.
