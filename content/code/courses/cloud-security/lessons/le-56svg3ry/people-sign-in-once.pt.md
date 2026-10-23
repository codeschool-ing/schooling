---
title: Pessoas entram uma vez, em outro lugar
version: 1
---

**Uma pessoa que trabalha numa conta AWS não deveria ser um usuário do IAM nela.** Ela deveria
entrar no provedor de identidade da organização e receber credenciais de curta duração para um papel
em cada conta em que trabalha. A aula 7 do curso `cloud` descreveu o mecanismo: um provedor de
identidade como o Microsoft Entra ID, o Google Workspace ou o Okta garante quem é a pessoa em SAML 2.0
ou OpenID Connect, e a AWS confia nessa declaração. Esta seção trata do que esse arranjo resolve para
quem defende, e do que não resolve.

## O que ele resolve

**Sair vira uma mudança só.** A dani, a prestadora desta aula, tinha um usuário do IAM com senha e
chave de acesso. O contrato dela terminou em março, e a conta dela no provedor de identidade da
clínica foi desativada naquela semana, pelo mesmo processo que remove todo mundo. O usuário do IAM
dela não fazia parte desse processo, porque nada liga um ao outro. Se ela entrasse por federação,
desativá-la no provedor de identidade teria fechado todas as contas de uma vez.

**Credenciais expiram.** Uma sessão de papel dura entre quinze minutos e o máximo do papel, doze
horas no máximo. Uma chave de acesso dura até alguém apagá-la. Uma sessão achada num log amanhã já
expirou; uma chave de acesso achada amanhã é aquela de que a aula 7 trata.

**O segundo fator é exigido num lugar só.** O provedor de identidade o pede a cada entrada. Vinte
usuários do IAM precisam, cada um, do próprio dispositivo de MFA configurado e conferido.

## Como a AWS organiza isso

O serviço da AWS para pessoas é o **IAM Identity Center**. As peças dele, na ordem em que uma entrada
as encontra:

| peça | o que é |
|---|---|
| fonte de identidade | onde ficam pessoas e grupos: o diretório do próprio Identity Center, o Active Directory ou um provedor externo |
| conjunto de permissões | uma coleção nomeada de políticas, como `ReadOnly` ou `ClinicDeveloper`, definida uma vez |
| atribuição | um grupo, recebendo um conjunto de permissões, numa conta |
| papel | o que o Identity Center cria em cada conta a partir da atribuição; a sessão da pessoa é uma sessão desse papel |

Então "o caio pode publicar na conta de produção" é uma atribuição: o grupo dos desenvolvedores, o
conjunto `ClinicDeveloper`, a conta de produção. Tirar o caio do grupo o tira de toda conta que o
grupo alcança. **Nada disso foi executado**: o moto responde à API do Identity Center com listas
vazias, e não há provedor de identidade neste curso.

## O que ele não resolve

**Uma sessão já emitida continua valendo até expirar.** Desativar uma pessoa no provedor de
identidade impede a próxima entrada, não a atual. Esse é o argumento a favor de sessões medidas em
horas, e não no máximo de doze, e é por isso que a AWS documenta um jeito de revogar as sessões ativas
de um papel: uma política inline que nega tudo às sessões emitidas antes de um certo horário.

**Máquinas não são pessoas.** Um processo noturno, um pipeline de CI e uma função não digitam senha
nem aprovam notificação no celular. Eles precisam de papéis que assumem pela plataforma em que rodam,
que é a federação entre cargas de trabalho da aula 4 e os papéis de execução da aula 13. Quando não
há esse caminho, alguém cria um usuário do IAM com chave de acesso, e esse usuário fica fora do
processo do provedor de identidade exatamente como o da dani ficou.

**Um usuário por conta fica fora dele de propósito.** Uma identidade de *break-glass* existe para o
dia em que o provedor de identidade cai: um usuário do IAM ou o usuário raiz, com uma chave de MFA
física guardada num cofre e credenciais que ninguém usa. É a única exceção que uma revisão espera
encontrar, e deveria ser a única, com um alarme a cada entrada.
