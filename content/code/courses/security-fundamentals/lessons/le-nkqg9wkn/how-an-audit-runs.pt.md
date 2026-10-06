---
title: Como uma auditoria acontece
version: 1
---

Uma **auditoria** é um exame sistemático e independente de se algo cumpre os critérios dele. Em
segurança, os critérios em geral são uma norma (ISO 27001), uma lei, um contrato ou as próprias
políticas da organização, e o "algo" é um conjunto de controles.

### Interna e externa

Uma **auditoria interna** é feita por gente da própria organização, mas independente da área auditada:
quem opera o firewall não audita o firewall. O objetivo é achar problemas antes que outra pessoa ache, e
contar à gestão com honestidade como as coisas estão.

Uma **auditoria externa** é feita por um organismo de fora. Uma auditoria de certificação ISO 27001 (aula
14) é externa, feita por um organismo certificador acreditado. Também é a auditoria que um cliente
grande exige dos fornecedores dele, e uma inspeção de um regulador. A conclusão dela é para terceiros, e
por isso a independência pesa ainda mais.

### As etapas

| etapa | o que acontece |
|---|---|
| **planejamento** | combina-se o escopo: quais sistemas, quais locais, qual período, contra quais critérios |
| **trabalho de campo** | o auditor reúne evidência: entrevistas, documentos, amostras, observação |
| **constatações** | cada falha é escrita, com a exigência, o que se encontrou e a evidência |
| **relatório** | as constatações, a gravidade delas e a conclusão geral vão para a gestão |
| **resposta** | a gestão aceita cada constatação e se compromete com uma ação corretiva e uma data |
| **acompanhamento** | na auditoria seguinte, as ações corretivas são conferidas |

### Como é uma constatação

As constatações têm graus. As palavras variam entre normas; em auditorias ISO 27001 costumam ser:

- **não conformidade maior**: uma exigência não é cumprida de jeito nenhum, ou um controle falhou de um
  jeito que compromete o sistema, por exemplo nunca se fez uma revisão de acesso. Precisa ser corrigida
  antes de um certificado ser emitido ou mantido;
- **não conformidade menor**: uma exigência é cumprida em parte ou de forma inconsistente, por exemplo
  duas das vinte e cinco contas da amostra eram de pessoas que tinham saído. Precisa de um plano
  corretivo;
- **observação** ou **oportunidade de melhoria**: nada está errado ainda, mas o auditor vê um risco.

Uma constatação não é um julgamento sobre a pessoa que opera o controle. É informação, e a resposta
certa a uma constatação é a mesma de um exercício roxo na aula 10: entender por quê, corrigir a causa,
conferir que a correção funcionou. Discutir com a evidência, ou corrigir só a conta que caiu na amostra
e não o processo que a deixou acontecer, é como a mesma constatação volta no ano seguinte.

### Trabalhando com auditores

Responda o que foi perguntado, com exatidão, e mostre a evidência. Não chute, e não ofereça
especulação: "não sei, vou descobrir e mando o registro" é uma resposta melhor que uma inventada. E não
esconda um problema que você conhece. Um auditor que acha um problema escondido para de confiar em todo
o resto; um que é avisado dele, com um plano, em geral registra a organização como gerindo os próprios
riscos, que é exatamente o que um sistema de gestão deveria fazer.
