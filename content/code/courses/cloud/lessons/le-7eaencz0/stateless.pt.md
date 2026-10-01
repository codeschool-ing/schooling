---
title: Instâncias que você pode jogar fora
version: 1
---

Tudo na segunda metade desta aula supõe uma coisa sobre as instâncias de um grupo: **qualquer uma
pode ser encerrada a qualquer momento, e nada se perde.** O grupo as encerra quando falham numa
verificação, quando a carga cai e quando reequilibra entre zonas. Um programa que guarda algo na
instância funciona perfeitamente numa máquina e quebra, em silêncio, em várias.

## Quatro coisas que quebram

**Sessões em memória.** Um programa que guarda o login de um usuário na própria memória, ou num
arquivo no próprio disco, só conhece esse usuário naquela instância. Com duas instâncias atrás de um
balanceador, a próxima requisição do usuário pode cair na outra e encontrá-lo deslogado. Quando o
grupo reduz, a sessão some para todo mundo que estava na máquina encerrada.

**Uploads no disco local.** Uma foto salva em `/var/www/uploads` existe numa instância. O próximo
pedido por ela pode cair numa instância que nunca a teve, e quando a máquina é substituída a foto se
perde, como a seção sobre discos disse.

**Tarefas agendadas.** Um cron que manda as faturas da noite foi escrito para uma máquina. Coloque-o
na imagem de um grupo de três e três máquinas mandam as faturas, toda noite. Escale para sete numa
noite movimentada e são sete.

**Logs locais.** Arquivos de log escritos no disco da instância vão embora com ela, e costuma ser
justamente a instância cujos logs você mais queria ler: a que falhou na verificação de saúde.

## Para onde vai o estado

A correção é a mesma em todos os casos: **o estado sai da instância** e vai para algum lugar que
sobrevive a todas elas, e que todas alcançam.

| o quê | para onde vai |
|---|---|
| uploads, arquivos que os usuários criam | armazenamento de objetos, aula 5 |
| sessões | um banco de dados ou um cache gerenciado, compartilhado por todas as instâncias |
| os dados da própria aplicação | um banco de dados gerenciado, operado pelo provedor, com backups próprios |
| logs e métricas | enviados para fora da instância à medida que são escritos; o curso `observability` |
| uma tarefa que precisa rodar uma vez | um agendador fora do grupo, ou uma trava que toda instância respeita |

O que sobra na instância é o programa e a configuração dele, que vieram da imagem e do user data. É
isso que **stateless** quer dizer aqui: não que a aplicação não tenha estado, mas que nada dele mora
na máquina que a roda. Uma instância assim pode ser trocada por uma cópia do template sem ninguém
perceber, e é o único tipo de instância que um grupo consegue administrar.

## A mesma ideia, num pacote menor

::: track dba devops devsecops
Você já construiu imagens de contêiner no curso `docker`, e a palavra *imagem* agora quer dizer duas
coisas. Uma imagem nesta aula é uma imagem de máquina: um disco inteiro, com sistema operacional,
kernel e tudo o que foi instalado neles. Uma imagem de contêiner é um sistema de arquivos para um
processo, que roda numa máquina como as desta aula e compartilha o kernel dela. As duas são a mesma
ideia: algo construído uma vez e iniciado muitas vezes, cada cópia descartável. As regras desta seção
são as regras sob as quais um contêiner já vive, e valem um nível abaixo, para as máquinas embaixo
dele.
:::

::: track cloud-engineering data
O curso `docker` vem depois deste, e empacota a mesma ideia num tamanho menor. Em vez da imagem de uma
máquina inteira, com sistema operacional e kernel, uma imagem de contêiner guarda o sistema de arquivos de uma aplicação. Muitos contêineres rodam lado a lado numa máquina como as desta aula. As regras
desta seção valem sem mudança: um contêiner é jogado fora e substituído com ainda mais facilidade que
uma instância, então também não pode guardar nada.
:::

::: track *
Os contêineres levam a mesma ideia a um nível menor. Uma imagem de máquina é um disco inteiro com
sistema operacional; uma imagem de contêiner empacota uma aplicação e os arquivos dela, e muitos
contêineres rodam lado a lado numa máquina como as desta aula. A ideia é a mesma: algo construído uma
vez e iniciado muitas vezes, cada cópia descartável, com o estado guardado em outro lugar.
:::
