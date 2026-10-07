---
title: Os requisitos do portal
version: 1
---

A ana e a carla escreveram os requisitos numa tarde, ameaça por ameaça, com o daniel respondendo às
perguntas que eram decisões e não engenharia. Quantos logins falhos são demais, de que tamanho um
exame pode ser, por quanto tempo uma conta da equipe sem uso pode ficar aberta.

| id | ameaças | requisito | verificado por |
|---|---|---|---|
| R01 | T01 | O portal só aceita um webhook de pagamento quando a assinatura do gateway sobre o corpo é válida. | teste |
| R02 | T01 | O portal só marca um agendamento como pago quando o valor e o agendamento do webhook batem com uma cobrança em aberto. | teste |
| R03 | T02 | O login do paciente permite no máximo 10 tentativas falhas por conta por hora. | teste |
| R04 | T02 | O cadastro e a troca de senha recusam senhas que aparecem em listas conhecidas de vazamentos. | teste |
| R05 | T03 | O login da equipe exige segundo fator toda vez. | teste |
| R06 | T15 | Uma conta da equipe sem uso por 30 dias é desativada automaticamente. | teste |
| R07 | T04 | A credencial de armazenamento do portal cria arquivos de exames e não consegue sobrescrevê-los nem apagá-los. | revisão |
| R08 | T05 | Toda mudança numa anotação clínica é guardada como versão nova, com autor e horário. | teste |
| R09 | T06 | Todo cancelamento registra a conta que o fez e quando. | teste |
| R10 | T07 | O portal devolve um exame só ao paciente a quem ele pertence e responde a qualquer outro pedido como se o exame não existisse. | teste |
| R11 | T08 | Um lembrete contém só a data, o horário e como cancelar. | revisão |
| R12 | T09 | O papel de recepcionista não abre anotações clínicas nem exames. | teste |
| R13 | T10 | Um upload maior que 20 MB ou que não seja PDF é recusado. | teste |
| R14 | T11 | Uma conta dispara no máximo 5 lembretes por dia. | ainda não |
| R15 | T12 | O console da equipe só responde a pedidos vindos da rede das clínicas. | revisão |
| R16 | T13 | A conta de banco do worker de lembretes lê agendamentos e nada mais. | revisão |
| R17 | T16 | Pacientes veem as sessões abertas e conseguem encerrar qualquer uma. | ainda não |
| R18 | T16, T17 | Entrar de um dispositivo novo ou mudar o telefone manda um e-mail ao paciente. | teste |
| R19 | T17 | Mudar o telefone exige um código mandado ao número antigo. | teste |

Dezenove requisitos para dezessete ameaças, e vale notar quatro coisas na lista.

**A T14 não tem nenhum.** O PDF preparado que ataca o visualizador num computador da clínica precisa
de um visualizador novo ou de uma regra de que a equipe nunca baixe exames, e nenhuma das duas coisas
pôde ser decidida numa tarde. A ameaça fica na lista sem requisito, o que é permitido, e a aula 12 é
onde ela recebe uma decisão com nome e data.

**Dois requisitos ainda não têm verificação.** O R14 limita lembretes e o R17 mostra ao paciente as
sessões abertas. Os dois são claros e testáveis; ninguém escreveu o teste, porque nenhuma das duas
funcionalidades existe ainda. Dizer "ainda não" na coluna é o estado honesto, e é o que uma aula
seguinte consegue conferir que mudou.

**Quatro são verificados por revisão, não por teste.** R07, R11, R15 e R16 tratam de uma permissão
de armazenamento, de um modelo de mensagem, de uma regra de rede e de uma conta de banco. Um teste
unitário no código do portal não enxerga nenhum deles. Uma revisão é mais fraca que um teste, porque
acontece quando alguém lembra de fazer, e a aula 15 transforma algumas delas em verificações que
rodam a cada mudança.

**O R02 veio de uma dependência, não do STRIDE.** A conferência do valor existe porque a aula 6
perguntou o que acontece se o próprio gateway for comprometido. Ela cobre a T01 de um jeito que a
assinatura não cobre, e teria passado despercebida num modelo que só perguntasse sobre o remetente
do webhook.

### Guardados no repositório

A tabela mora em `requirements.csv`, ao lado do `threats.csv`, em inglês, com as mesmas colunas. A
coluna `threats` cita um ou mais ids de ameaça separados por espaço, que é a ligação que a próxima
seção usa.
