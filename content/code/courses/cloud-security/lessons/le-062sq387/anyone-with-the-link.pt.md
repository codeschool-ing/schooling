---
title: Qualquer pessoa com o link
version: 1
---

**Um link que abre um arquivo para qualquer um que o tenha é uma chave escrita como endereço.** Quem
tem o endereço tem o arquivo, e um endereço é copiado, encaminhado, colado num chat e guardado num
arquivo de e-mails sem ninguém pensar nisso como entregar uma chave. Todo serviço do título desta
aula oferece um link assim, e cada um deixa um administrador restringi-lo, se a conta tiver
administrador.

A ideia errada é a de que um link que ninguém publica é privado porque ninguém consegue adivinhá-lo.
O endereço é longo e aleatório, então adivinhar não é o risco. **O risco são todos a quem ele é dado,
e todos a quem essas pessoas o dão**, enquanto ele funcionar. Um link mandado ao contador em março
ainda abre o arquivo em outubro, do notebook do estagiário do contador.

## As duas perguntas a fazer a qualquer link compartilhado

1. **Quem consegue abri-lo?** Pessoas nomeadas que precisam entrar com login, qualquer pessoa da
   organização, ou qualquer pessoa.
2. **Até quando?** Uma data depois da qual ele para de funcionar, ou nunca.

E uma terceira, para quem defende: **consigo ver que ele existe, e retirá-lo?** Numa conta da empresa
a resposta é sim. Numa conta pessoal a empresa nem é consultada.

## Como os serviços chamam os públicos

Esta tabela foi tirada da documentação de cada provedor e **não foi executada aqui**: nenhum destes
serviços tem imitação no laboratório, e os nomes mudam a cada redesenho das telas. O formato é o que
dura, e é o mesmo em todo lugar: uma escolha restrita, uma da organização inteira e uma aberta.

| serviço | a escolha aberta | as escolhas mais restritas | o que um administrador da empresa pode fazer |
|---|---|---|---|
| OneDrive e SharePoint | links *Qualquer pessoa*, sem login | pessoas da organização; pessoas com acesso existente; pessoas específicas | limitar o tenant a compartilhamento só na organização ou com convidados, e exigir que links *Qualquer pessoa* expirem depois de um número de dias |
| Google Drive | *Qualquer pessoa com o link* | restrito a pessoas adicionadas pelo nome; a organização do Workspace | desligar o compartilhamento fora da organização, ou permiti-lo só para domínios listados |
| Dropbox | um link compartilhado que qualquer um abre | nos planos de equipe, só membros da equipe | nos planos de equipe, restringir links à equipe; senha e data de expiração em links são recursos pagos |
| Box | *Pessoas com o link* | pessoas da empresa; só pessoas convidadas | desativar links abertos para a empresa inteira |
| iCloud Drive | *Qualquer pessoa com o link* | só pessoas que você convidar | nada: uma Conta Apple pessoal não tem administrador da empresa |

**Leia a última coluna duas vezes.** Todo controle nela pertence ao tenant da própria empresa. O
Google Drive pessoal da bia é uma conta diferente do Google Workspace da clínica, e nenhuma
configuração do tenant da clínica chega até ele. Por isso a primeira linha de defesa contra o
armazenamento paralelo é dar às pessoas um serviço da empresa tão fácil quanto o delas, e não uma
regra contra o delas.

## O que o link não conta

Um link aberto também apaga o registro. Quando um arquivo é compartilhado com pessoas nomeadas que
fazem login, o provedor consegue dizer ao dono quem o abriu. Quando é compartilhado com *qualquer
pessoa*, o máximo que um log diz é que alguém com o link o abriu de algum endereço. **Quem defende e
não consegue distinguir o contador de um estranho precisa tratar toda abertura como a de um
estranho.** A aula 15 diz o mesmo dos logs da própria clínica: um registro vale o que vale a
identidade que está nele.
