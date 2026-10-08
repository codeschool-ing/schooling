---
title: Playbooks e runbooks
version: 1
---

Dois tipos de procedimento escrito apoiam o plano, e as palavras são usadas com folga suficiente para causar
confusão.

Um **playbook** cobre **um tipo de incidente**, da detecção ao encerramento: o que conferir, o que decidir,
quem envolver. O playbook automatizado da aula 5 era uma fatia estreita, executada por máquina, de um deles.
Um **runbook** cobre **uma tarefa técnica**, passo a passo, qualquer que seja o incidente: como isolar um host
nesta rede, como gerar a imagem de um disco com esta ferramenta, como trocar uma senha neste diretório.
Playbooks chamam runbooks.

Um playbook para o tipo de incidente que se encaixa na quinta, *conta comprometida com acesso remoto*, em
esboço:

| fase | o playbook diz |
|---|---|
| identificar | confirmar com o dono da conta, por um canal que não seja aquela conta; listar cada host e cada sessão que a conta tocou |
| conter | bloquear o endereço de origem; revogar as sessões e as chaves da conta; desativá-la se o dono não puder ser alcançado (runbook: desativar uma conta) |
| preservar | copiar os logs de cada host tocado antes de mudar qualquer coisa; gerar imagem dos hosts se dados podem ter saído (o runbook da aula 16) |
| erradicar | remover o que o invasor acrescentou: chaves, contas, tarefas agendadas (runbook: auditar o `authorized_keys`) |
| recuperar | senha nova, chaves novas, autenticação multifator; monitorar a conta de perto por duas semanas |
| notificar | se dados pessoais podem ter sido acessados, informar o encarregado e o jurídico na hora (aula 21) |

**Um playbook só é tão bom quanto os runbooks por trás dele**, e um runbook só é bom se já foi executado. O
comando que isola um servidor, escrito num documento que ninguém testou, falha na pior hora porque a interface
foi renomeada no ano passado. Teste os runbooks quando forem escritos, e de novo quando o sistema mudar.
