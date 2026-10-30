---
title: A conta de faturamento, e as pessoas em volta dela
version: 1
---

**Uma conta do Cloud Billing é o que paga.** Ela guarda a forma de pagamento, recebe as faturas, e é onde
todo custo de todo projeto vinculado a ela é somado. Ela **não faz parte da hierarquia de recursos**: uma
conta de faturamento fica ao lado da árvore da lição 2 em vez de dentro dela, e uma conta pode pagar
projetos em qualquer pasta, ou em mais de uma organização.

| tipo | como paga | para quem serve |
|---|---|---|
| **self-serve**, também chamada online | um cartão ou uma conta bancária, cobrados automaticamente todo mês, ou quando o gasto passa de um limite | a maioria das contas, e toda conta nova |
| **faturada**, também chamada offline | uma fatura mensal, paga por transferência a prazo | empresas maiores, depois de análise de crédito e de um pedido ao Google |

O id de uma conta de faturamento tem a forma `012345-6789AB-CDEF01`: três grupos de seis caracteres. É o
número a dar ao suporte, e o que o Terraform nomeia.

## Os papéis, que não são papéis de projeto

O faturamento tem papéis próprios, concedidos **na conta de faturamento**, e eles são separados de
propósito do Owner e do Editor:

| papel | o que deixa quem o tem fazer |
|---|---|
| `roles/billing.admin` | tudo: formas de pagamento, papéis na conta, fechá-la |
| `roles/billing.user` | **vincular projetos a esta conta**, o que é gastar o dinheiro dela |
| `roles/billing.costsManager` | orçamentos e exportações, lições 12 e 14 |
| `roles/billing.viewer` | ler custos e faturas |

Do lado do projeto, `roles/billing.projectManager` deixa quem o tem vincular e desvincular o projeto, e
mais nada. **Vincular exige os dois lados**: um papel na conta que permita associar recursos a ela, e um
papel no projeto que permita criar o vínculo de faturamento dele. O Owner de um projeto tem o segundo,
então um Owner com `billing.user` numa conta consegue apontar o projeto para ela.

Essa divisão é o controle que vale notar. **Quem tem `billing.user` na conta da empresa decide que
projetos a empresa paga.** Um desenvolvedor que consegue criar projetos e vinculá-los consegue rodar
qualquer coisa no cartão da empresa, e o papel a manter escasso é esse, mais que o Owner de qualquer
projeto.

## A visão de quem cuida das finanças

As pessoas que leem faturas quase nunca precisam de papel de projeto nenhum. O `billing.viewer` na conta
mostra todo custo e toda fatura, em todo projeto, sem deixar quem o tem ver um recurso sequer dentro de
qualquer um deles. Essa é a concessão certa para uma contadora: ela vê o dinheiro e nada do que o dinheiro
pagou.

Nada nesta seção rodou. A API do Cloud Billing só responde a quem está autenticado, e o laboratório
pergunta a ela uma vez na próxima seção, para ser recusado.
