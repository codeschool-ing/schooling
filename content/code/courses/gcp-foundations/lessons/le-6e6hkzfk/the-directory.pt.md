---
title: O diretório em que o Google Cloud confia
version: 1
---

**O Google Cloud não guarda uma lista de pessoas.** Todo `user:` e `group:` da lição 5 mora num diretório
em outro lugar, e o Google Cloud confia nele. Para uma empresa, esse diretório é um de dois produtos da
mesma família:

| | o que é | quanto custa |
|---|---|---|
| **Cloud Identity Free** | contas, grupos e login, para quem precisa do Google Cloud e de mais nada | nada, até um número de usuários que o Google define |
| **Cloud Identity Premium** | o mesmo, mais gestão de dispositivos, relatórios de segurança avançados e mais controles | por usuário por mês |
| **Google Workspace** | o Cloud Identity **mais** Gmail, Drive, Meet e o resto | por usuário por mês, por edição |

Os três dão à empresa a mesma coisa no que toca ao Google Cloud: **contas sob o próprio domínio**, como
`ana@example.com`, que a empresa cria, suspende e apaga, e que pertencem à empresa e não a quem as usa.
Uma empresa que já está no Workspace tem um diretório; uma empresa que escreve código e lê e-mail em
outro lugar costuma acrescentar o Cloud Identity Free exatamente para isso.

## Verificar o domínio, e a organização que aparece

Assinar qualquer um começa por **provar que a empresa é dona do seu domínio**, acrescentando ao DNS do
domínio um registro TXT que o Google fornece. A lição 19 é sobre registros de DNS; aqui, o registro é o
que transforma `example.com` de uma string em algo que o Google deixa um cliente reivindicar. Verificado
o domínio, **o Google cria para ele o nó de organização da lição 2**, `organizations/123456789012` na
história deste curso, e a partir daí projetos podem morar sob ele.

A primeira conta é **super administradora** do diretório. É um poder diferente de qualquer coisa do IAM,
e maior: um super administrador pode trocar a senha de qualquer usuário, inclusive a de quem é Owner da
produção. **Trate as contas de super administrador como as chaves do ambiente inteiro**: duas, usadas só
para trabalho no diretório, cada uma com uma chave de segurança física como segundo fator, e nunca usadas
no trabalho do dia a dia no Google Cloud.

## A conta é da pessoa, o acesso é do diretório

Esse arranjo é o que faz do **desligamento** um ato só. Quando alguém sai, o diretório suspende a conta, e
nesse momento todo papel do Google Cloud concedido a `user:` desse endereço, ou a um grupo em que ele
estava, para de funcionar, em todo projeto, sem ninguém ler uma política do IAM. Quando um terceirizado
entra por três meses, o diretório cria a conta e a põe no `planner-devs`, e as políticas do IAM ficam como
estavam.

É também por isso que **contas pessoais do Gmail não deveriam ter papéis no ambiente de uma empresa**.
Ninguém na empresa consegue suspender `ana.personal@gmail.com`; quando a Ana sai, a conta vai com ela, e
com ela toda concessão que alguém esqueceu de remover. A política de restrição de domínio da lição 5 é a
barreira que transforma isso numa regra em vez de uma esperança.

Nada nesta seção rodou: o diretório é um serviço do Google sem emulador e sem sandbox gratuito sem conta.
A próxima seção escreve os grupos do planner em Terraform, que a API do Cloud Identity criaria.
