---
title: Fazendo vários clusters agirem como um
version: 1
---

Cedo ou tarde os clusters precisam agir juntos: a mesma aplicação em duas regiões, um failover quando
uma cai. Já houve um projeto para fazer isso dentro do próprio Kubernetes. O **KubeFed** rodava um
control plane acima dos clusters e empurrava objetos "federados" para cada um. Ele foi arquivado em 2023,
e o que o substituiu é menos ambicioso e funciona melhor: cada preocupação é resolvida pela ferramenta
que já cuida dela.

| Preocupação | O que se usa hoje |
| --- | --- |
| Os mesmos objetos em todo cluster | GitOps (lição 39): um repositório, um agente por cluster, ou o ApplicationSet do Argo CD gerando uma aplicação por cluster |
| Mandar os usuários ao cluster saudável mais próximo | DNS ou um balanceador global na frente dos clusters, fora do Kubernetes |
| Um Service alcançável de outro cluster | A Multi-Cluster Services API (`ServiceExport`, `ServiceImport`), implementada por alguns provedores e plugins de rede |
| Criar e atualizar os próprios clusters | As ferramentas do provedor ou o Terraform, ou o Cluster API, que descreve clusters como objetos num cluster de gerenciamento |

A primeira linha é a que quase todo mundo precisa, e é o ciclo da lição 39 rodado mais de uma vez. **O
repositório vira o lugar onde "todo cluster" é definido**, e um cluster que se desvia é corrigido do
mesmo jeito que um Deployment.

## Duas regiões

A pergunta que decide uma estratégia de regiões não é sobre Kubernetes. **É onde os dados vivem.** Pods
sem estado podem rodar nas duas regiões ao mesmo tempo; um banco de dados não pode ser escrito em dois
lugares sem um projeto feito para isso, como a lição 28 argumentou.

- **Ativo-passivo.** Uma região serve; a outra tem as mesmas aplicações implantadas, reduzidas ou
  paradas, e uma cópia dos dados que vem atrás. Fazer o failover significa promover a cópia e mover o
  tráfego, e os dados escritos nos últimos segundos antes da falha podem se perder. É mais barato e mais
  simples, e é onde a maioria dos times começa.
- **Ativo-ativo.** As duas regiões servem ao mesmo tempo, então não há failover para ensaiar, só
  capacidade a perder. Toda escrita tem de ser aceita num lugar com que as duas regiões concordam, e isso
  é uma escolha de banco de dados primeiro e de arranjo de clusters depois.

De qualquer jeito, um failover que nunca foi praticado é uma esperança. O teste que importa é desligar
uma região de propósito, num dia calmo, e contar o que quebrou.
