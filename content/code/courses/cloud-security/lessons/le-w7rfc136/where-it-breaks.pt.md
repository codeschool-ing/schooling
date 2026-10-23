---
title: Onde quebra, e de que lado
version: 1
---

**A maioria dos incidentes de nuvem começa acima da linha, numa configuração que o cliente escolheu.
Alguns começam abaixo dela, e esses você não consegue impedir, só detectar.** As duas metades dessa
frase mudam aquilo em que um engenheiro de segurança gasta o tempo.

## O lado do cliente, na maior parte das vezes

Em 2019 a Gartner previu que **até 2025, 99% das falhas de segurança em nuvem seriam culpa do
cliente**. Foi uma previsão e não uma contagem, e ninguém publicou o placar depois, então trate o
número como a opinião de quem vê muitos incidentes. O que se sustenta é a direção: as falhas que
enchem o noticiário são aquelas para as quais este curso tem uma aula.

| o que deu errado | qual camada | aula |
|---|---|---|
| um bucket respondendo a qualquer pessoa na internet | os dados, e quem os alcança | 9 |
| uma chave copiada para um repositório ou um notebook, e ainda válida | identidade e acesso | 7 |
| um usuário ou papel com muito mais permissão que o trabalho pede | identidade e acesso | 6 |
| uma regra de rede aberta ao mundo numa porta administrativa | rede virtual | 8 |
| uma máquina que nunca recebeu correção | sistema operacional | 3 |

**O Capital One, em 2019**, é o caso costumeiramente citado, e ele fica inteiro do lado do cliente.
Um firewall de aplicação web que o banco rodava numa máquina própria na AWS estava mal configurado.
Por ele, alguém de fora obteve as credenciais temporárias do papel que aquela máquina carregava, e esse
papel conseguia ler um armazenamento com os dados de cerca de 100 milhões de pessoas que pediram cartão
de crédito nos Estados Unidos e uns 6 milhões no Canadá. Duas configurações do próprio banco se
combinaram: um firewall que podia ser convencido a fazer requisições para estranhos, e um papel com
permissão de ler muito mais do que o firewall precisava. A metade do provedor fez o que prometia o
tempo todo. A aula 6 trata da segunda configuração, e a ideia dela é a que teria limitado o estrago.

## O lado do provedor, às vezes

A linha não torna o provedor infalível, e o caso recente mais claro é o da Microsoft. Em **2023**,
um intruso usou uma chave de assinatura roubada da Microsoft para forjar tokens de login e ler e-mails
guardados no Exchange Online por cerca de vinte e cinco organizações, entre elas agências do governo
dos Estados Unidos. Nenhuma configuração de cliente causou isso, e nenhuma poderia ter impedido: a
chave, o serviço de assinatura e a verificação dos tokens estavam todos abaixo da linha.

**O que o achou estava acima da linha.** O Departamento de Estado americano percebeu e-mails sendo
lidos num padrão que não combinava com os próprios usuários, em registros de auditoria que ele tinha
escolhido coletar, e avisou a Microsoft. É o máximo que um cliente pode fazer diante de uma falha na
metade do provedor, e é uma coisa real a fazer: **você não consegue consertar a metade do provedor,
mas os seus próprios logs muitas vezes são como alguém fica sabendo que ela quebrou.** A aula 15 trata
de guardar esses registros.

## O que isso diz sobre o seu tempo

Gaste-o na proporção certa. A metade do provedor recebe uma leitura do relatório dele, um contrato
que diz como ele vai avisar você de um incidente, e logs seus que mostrariam a falha dele. A sua
metade recebe todo o resto: o inventário, as configurações, as permissões, a prova, porque é ali que
as evidências dizem que os incidentes começam.
