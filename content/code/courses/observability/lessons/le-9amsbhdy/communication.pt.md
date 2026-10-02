---
title: Comunicação: dizendo o que se sabe, num ritmo combinado
version: 1
---

Durante um incidente, quem não está consertando quer três coisas: **saber que ele está sendo tratado,
saber o que isso significa para si, e saber quando vai ouvir mais.** O silêncio não responde a nenhuma,
e as pessoas preenchem o silêncio com mensagens para os engenheiros, que é o pior lugar para elas irem.

Uma atualização tem uma forma, e manter essa forma é o que torna as atualizações rápidas de escrever e
de ler:

| parte | exemplo |
|---|---|
| o que é afetado, do lado do usuário | Alguns clientes não conseguem concluir o checkout; os pagamentos falham com um erro. |
| desde quando | Desde as 17:46 (horário de Brasília). |
| o que estamos fazendo | Revertemos uma versão do payments lançada às 17:46 e estamos acompanhando a recuperação. |
| o que os usuários devem fazer | Os clientes podem tentar de novo em alguns minutos; nenhum cartão foi cobrado duas vezes. |
| próxima atualização | Em 15 minutos, ou antes se algo mudar. |

Regras que fazem a forma funcionar:

- **Diga o que se sabe, não o que se supõe.** *Identificamos a causa* na primeira atualização costuma
  estar errado, e uma correção custa mais confiança que a espera. *Estamos investigando uma falha no
  payments* é verdade e basta.
- **Cumpra a promessa da próxima atualização**, mesmo sem novidade; *sem mudança, próxima atualização em
  15 minutos* diz às pessoas que o incidente ainda está sendo tratado.
- **Um canal para a resposta, outro para as atualizações.** Engenheiros trabalhando no incidente não
  deveriam ter de ler perguntas, e quem pergunta não deveria ter de ler engenheiros pensando alto.
- **A página de status é para clientes**, nas palavras deles: sem nomes de serviço, sem códigos de erro,
  sem culpar um fornecedor.

O líder de comunicação as escreve, o IC as aprova, e o escriba registra quando cada uma foi mandada. No
laboratório não há ninguém para atualizar, então as marcas do incidente no Grafana fazem as vezes do
canal interno; a forma acima é o que cada uma delas teria dito.
