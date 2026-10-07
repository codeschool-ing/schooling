---
title: Swarm, Nomad, Kubernetes e PaaS
version: 1
---

**Toda opção desta etapa roda a mesma coisa: uma imagem OCI, de preferência nomeada pelo digest.** É
para isso que o curso vinha construindo. Onde ela roda é outra decisão, e mudá-la depois não quer dizer
mudar a imagem. Nenhuma das plataformas abaixo, fora o Swarm, foi executada no laboratório.

| | o que você administra | bom em | o que custa |
| --- | --- | --- | --- |
| **Docker Swarm** | as máquinas e o swarm | clusters pequenos, arquivos do Compose como estão | um ecossistema menor; poucos recursos novos |
| **HashiCorp Nomad** | as máquinas e o cluster | containers e tarefas sem container juntos, simples de operar | menos integrações que o Kubernetes |
| **Kubernetes** | o cluster, ou só as cargas num gerenciado | quase tudo, com o maior ecossistema | muitos conceitos antes do primeiro deploy |
| **Um PaaS de containers** | a imagem e alguns ajustes | um serviço web sem servidores para cuidar | menos controle, e os preços e limites do provedor |

O **Swarm** é o que esta aula mostrou: embutido no Docker, rápido de começar, próximo do Compose. Ele
continua mantido, e serve a poucas máquinas cuidadas por uma equipe pequena; a maior parte do trabalho
novo foi para outros lugares.

O **Nomad** agenda containers e também binários simples e outras cargas, a partir de um programa
pequeno. Ele atrai equipes que querem um orquestrador que dê para entender por inteiro.

O **Kubernetes** é o padrão para rodar containers em escala, e é um curso à parte: o curso `kubernetes`
começa, na aula 1, exatamente pela pergunta que esta aula fez, o que o Compose não resolve, e compara
essas mesmas alternativas na aula 3. Os deployments dele fazem o que o `docker service update` fez, com
os ajustes que a aula 35 dele cobre, e as probes, aula 22, usam o endpoint `/health` que o `shelf` já
tem.

**Um PaaS de containers recebe a imagem e a roda**, escalando com o tráfego e muitas vezes até zero: o
Google Cloud Run (aula 8 do curso `gcp-compute`), o AWS ECS com Fargate (aulas 8 e 9 do `aws-compute`) e
o Azure Container Apps (aula 8 do `azure-compute`). Não há nó para corrigir nem cluster para atualizar;
o que você abre mão é do controle sobre a máquina, e o que você aceita é o modelo do provedor para
requisições, tempos limite e preços.

## Como escolher

- **Um serviço, uma equipe, tráfego web**: um PaaS, até precisar de algo que ele não faz.
- **Algumas máquinas que você já opera**: Compose em cada máquina, ou Swarm entre elas.
- **Muitos serviços, muitas equipes, ou um requisito que um PaaS não atende**: Kubernetes, quase sempre
  um gerenciado, e o curso `kubernetes`.

Seja qual for a escolha, o trabalho das aulas 13 a 26 vale sem mudança: uma imagem pequena, sem root,
varrida, com SBOM e proveniência, enviada por um pipeline e nomeada pelo digest.
