---
title: A família 27000
version: 1
---

A **ISO** é a Organização Internacional de Normalização, e a **IEC**, a Comissão Eletrotécnica
Internacional. Juntas, elas publicam uma família de normas de segurança da informação numeradas a partir
de 27000, e as duas mais usadas são o assunto desta aula. No Brasil, a ABNT as publica em português como
ABNT NBR ISO/IEC 27001 e 27002.

A família é grande, e só alguns membros importam para um iniciante:

| norma | o que é | como se usa |
|---|---|---|
| **27000** | visão geral e vocabulário | as definições de que as outras dependem |
| **27001** | requisitos para um sistema de gestão de segurança da informação | **a norma contra a qual uma organização se certifica** |
| **27002** | orientações sobre os controles de segurança | o catálogo de controles e como implementar cada um |
| **27005** | orientações sobre gestão de riscos de segurança da informação | como fazer o trabalho da aula 3 do jeito da 27001 |
| **27701** | uma extensão da 27001 para privacidade | usada junto com a LGPD da aula 17 |
| **27017** e **27018** | orientações para serviços em nuvem e para dados pessoais na nuvem | para provedores e seus clientes |

### Requisitos contra orientações

A distinção mais importante da família é entre **requisitos** e **orientações**. A 27001 diz o que uma
organização **deve** fazer, e só a 27001 pode ser certificada. A 27002 diz o que uma organização **deveria
considerar** ao implementar cada controle; ninguém se certifica na 27002, e ninguém é obrigado a seguir
os conselhos dela ao pé da letra.

As edições atuais são a **ISO/IEC 27001:2022** e a **ISO/IEC 27002:2022**. A edição anterior da 27001 era
de 2013, e organizações certificadas nela tiveram até outubro de 2025 para migrar para a nova, então todo
certificado em vigor hoje é contra a edição de 2022. A estrutura dos controles mudou bastante entre as
duas, o que vale saber ao ler uma política antiga que cita números de controle como "A.9.2.6": esses são
números de 2013 e não existem em 2022.

### O que a certificação diz, e o que não diz

Um certificado diz que um organismo acreditado auditou o sistema de gestão da organização contra a 27001
e o achou conforme, **para um escopo declarado**. O escopo é a parte que as pessoas pulam. Uma empresa
pode certificar só o datacenter, ou só uma linha de produtos, e o certificado é honesto sobre isso na
declaração de escopo. Quando um cliente pede o certificado da loja, a pergunta útil de volta é "para qual
escopo vocês precisam?", e quando você ler o de outra empresa, leia o escopo primeiro.
