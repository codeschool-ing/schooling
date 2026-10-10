---
title: Caixas hospedadas, e coletores que você mesmo roda
version: 1
---

A caixa de saída funciona porque o boxoffice foi feito com uma. A maioria das aplicações não é: elas
entregam cada mensagem a um servidor de e-mail por SMTP, o protocolo que os servidores de e-mail
falam, e dali ela sai para o mundo. Testar o e-mail delas significa decidir **para onde as mensagens
vão em vez disso**, e há três tipos de resposta. Um coletor que você mesmo roda, uma caixa pública que
qualquer um usa e uma caixa real que um teste lê por você. Nenhuma das ferramentas abaixo foi
executada para este curso, e o curso não cita preços, porque as duas coisas mudam mais depressa do
que uma aula.

## Um coletor que você mesmo roda

**MailHog** e **Mailpit** são a mesma ideia da caixa de saída do boxoffice, para aplicações que falam
SMTP. Cada um é um programa pequeno que você inicia na sua máquina ou no servidor de teste. Ele finge
ser um servidor de e-mail, aceita toda mensagem que a aplicação manda, guarda e mostra as mensagens
numa página web; nada é entregue a lugar nenhum. As configurações de e-mail da aplicação, que fazem
parte do ambiente dela, são apontadas para o coletor em vez do servidor real. O Mailpit é o mais novo
dos dois.

É a mais segura das três respostas, e para um ambiente de teste costuma ser a certa: nenhuma mensagem
chega a uma pessoa real, toda mensagem fica onde o time consegue ver e os dados nunca saem das
máquinas que você controla. O limite dela é o mesmo da caixa de saída. **Ela prova que a aplicação
mandou a mensagem certa, não que um servidor de e-mail real a entregaria**, e os defeitos raros que
moram na entrega, uma mensagem marcada como spam, um link quebrado por um programa de e-mail, ficam
invisíveis para ela.

## Uma caixa pública: Mailinator

O **Mailinator** é um serviço de caixas de entrada públicas e descartáveis. Qualquer nome no domínio
dele recebe e-mail sem conta e sem senha: um formulário de cadastro que recebe
`vila-test-4471@mailinator.com` manda a confirmação para lá, e a mensagem pode ser lida no site do
Mailinator digitando o nome. As mensagens são apagadas depois de pouco tempo. A empresa também vende
versões privadas do serviço para times, que este curso não examinou.

A conveniência é real quando você testa um site de homologação que manda e-mail de verdade e precisa
de um endereço novo para cada caso. **O preço é que uma caixa pública é pública.** Qualquer um que
digite o mesmo nome lê as mesmas mensagens, inclusive um link de confirmação que confirma a conta de
alguém, ou um link de troca de senha que toma a conta. Então as regras são absolutas:

- nunca o nome, o endereço ou os dados de uma pessoa real em nada enviado para lá;
- nunca uma conta que importe, em produto nenhum, atrás de um desses endereços;
- nunca produção. Uma caixa pública é para dados de teste e nada mais.

Há um teste escondido aí também. Muitos produtos recusam de propósito, no cadastro, endereços de
domínios descartáveis conhecidos. Se o seu deve recusar, essa recusa é um requisito e um caso
próprio; se não deve, um time que testa com Mailinator vai descobrir no dia em que o produto começar
a recusá-lo.

## Uma caixa real lida por um teste: Gmail Tester

O **Gmail Tester** é um pacote de código aberto para Node.js. Ele entra numa conta real do Gmail pela
API do Gmail do Google, com credenciais criadas para ele no console de desenvolvedor do Google, para
que um teste automatizado possa esperar uma mensagem chegar, ler o assunto e o corpo dela e tirar dali
um link de confirmação. Ele pertence à automação, não ao teste manual; os cursos de automação que vêm
depois deste na trilha `qa` são onde esse tipo de teste é escrito. Ele está aqui porque a existência
dele responde a uma pergunta que testadores manuais fazem: um teste consegue conferir uma caixa real?
Consegue.

**Uma caixa real é dado real.** Use uma conta criada só para teste, nunca a de uma pessoa, e mantenha
as credenciais fora de tudo que é compartilhado, como os próprios arquivos de teste. O Gmail entrega
e-mail endereçado a `nome+qualquercoisa@gmail.com` na caixa de `nome@gmail.com`, então uma conta de
teste pode receber em `ana.tests+case4@gmail.com` e `ana.tests+case5@gmail.com` e manter separadas as
mensagens de cada caso.

## Escolhendo

| | para onde vão as mensagens | quem pode lê-las | o que prova |
|---|---|---|---|
| a caixa de saída, MailHog, Mailpit | um coletor nas suas próprias máquinas | o time | a aplicação compôs a mensagem certa |
| Mailinator | uma caixa pública na internet | qualquer um que digite o nome | uma mensagem saiu e chegou |
| Gmail Tester | uma conta real do Gmail | quem tiver as credenciais | uma mensagem chegou a uma caixa real |

A maioria dos times usa a primeira linha para quase tudo e uma das outras duas para um punhado de
verificações na homologação. A verificação em produção que o plano da aula 1 deixou para depois da
versão, de que um e-mail real chega a uma caixa real, é uma pessoa se cadastrando com um endereço que
o teatro possui e lendo a mensagem.
