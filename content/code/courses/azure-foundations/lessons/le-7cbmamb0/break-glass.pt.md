---
title: Contas de emergência, e a política que tranca todo mundo para fora
version: 1
---

**O jeito mais comum de perder um tenant não é um atacante. É uma política de acesso condicional que
tranca para fora as pessoas que poderiam consertá-la.** Um bloqueio para "todos os usuários fora do
Brasil" no dia em que o único administrador está numa conferência em Lisboa; uma exigência de
dispositivo gerenciado antes de o notebook de alguém estar cadastrado; um serviço de segundo fator fora
do ar durante a manhã. Em cada caso a política funciona exatamente como escrita, e ninguém que poderia
mudá-la consegue fazer login para isso.

A resposta da Microsoft, na documentação, são as **contas de acesso de emergência**, chamadas de contas
break-glass por causa da caixa na parede com um alarme atrás do vidro. **Nada disto foi executado**; é
o procedimento como a Microsoft o descreve.

## O que é uma conta de emergência

- **Duas ou mais**, para que uma chave perdida não seja o fim.
- **Só na nuvem, no domínio `onmicrosoft.com` do próprio tenant**, nunca sincronizadas do diretório de
  um escritório nem federadas a outro sistema. A lição 12 explica essas duas ligações; uma conta de
  emergência não pode depender de nenhuma delas, porque qualquer uma pode ser o que quebrou.
- **Global Administrator**, mantido permanente e ativo, que a lição 10 citou como a exceção à elevação
  just-in-time: uma conta que existe para o dia em que o próprio PIM não pode ser alcançado.
- **Login com um método resistente a phishing que não seja o que todo mundo usa**, como uma chave de
  segurança FIDO2, guardada num cofre em lugar conhecido. A documentação da Microsoft cita passkeys e
  autenticação baseada em certificado, e as duas cumprem o MFA obrigatório da primeira seção, que vale
  para estas contas como para qualquer outra.

## Onde elas ficam nas políticas

**Exclua-as de toda política de acesso condicional que bloqueia ou restringe o login.** O jeito usual é
o que a política da seção anterior usou: pôr as contas de emergência num grupo, e excluir o grupo, para
que uma política nova precise de uma linha e não de uma lembrança de quais contas existem. Uma política
em somente relatório não precisa de exclusão, porque não impõe nada.

Essa exclusão é um buraco de propósito, e um buraco precisa ser vigiado. **Uma conta de emergência que
faz login é um evento de que alguém precisa saber no mesmo minuto**: a Microsoft recomenda alertar em
todo login dessas contas, a partir dos logs de login. Se o login foi uma emergência de verdade, o alerta
confirma. Se não foi, o alerta é o único aviso que o tenant recebe.

## Testando se elas ainda funcionam

Uma conta de emergência que não é usada há dois anos é uma chave que ninguém experimentou na fechadura.
A Microsoft recomenda conferi-las com regularidade e depois de mudanças: que a chave do cofre ainda faz
login, que a conta ainda tem o papel, e que as pessoas que devem saber onde fica o cofre ainda sabem.

## O arranjo da loja

| | o que a loja decidiu |
|---|---|
| contas | duas, `breakglass1@shop.onmicrosoft.com` e `breakglass2@shop.onmicrosoft.com` |
| papel | Global Administrator, ativo e permanente |
| login | uma chave FIDO2 cada, em dois cofres, em dois lugares diferentes |
| políticas | o grupo `sg-emergency-access` é excluído de toda política imposta |
| vigilância | todo login de qualquer das duas contas levanta um alerta para a equipe de plataforma |
| testes | a cada trimestre, e depois de qualquer mudança no acesso condicional |

**A ordem importa tanto quanto a tabela.** As contas de emergência são criadas, testadas e excluídas
antes da primeira política imposta, e a primeira política roda em somente relatório por uma semana antes
de ser ligada. Um tenant que liga um bloqueio primeiro e cria o caminho de volta depois pode não chegar
ao segundo passo.
