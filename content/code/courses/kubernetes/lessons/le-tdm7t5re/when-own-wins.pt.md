---
title: Quando rodar o seu ainda vence
version: 1
---

A aritmética da seção anterior favorece um control plane gerenciado para a maioria das equipes numa
nuvem. **Ela deixa de valer onde não há provedor para gerenciá-lo**, ou onde os termos do provedor são o
problema:

| situação | por que o seu |
|---|---|
| hardware próprio, no seu data center | não existe serviço gerenciado em máquinas suas; alguém roda o kubeadm ou uma distribuição |
| dados que não podem sair de um país, ou de um provedor | a lei decide o lugar, e o lugar pode não ter Kubernetes gerenciado |
| muitos clusters pequenos na borda, em lojas ou fábricas | uma taxa por cluster se multiplica, e distribuições leves como o k3s são feitas para isso |
| um control plane configurado além do que o provedor permite | plugins de admissão, flags do API server ou um arranjo do etcd que o serviço gerenciado não oferece |
| uma equipe de plataforma que já faz isso como trabalho | as horas já estão sendo gastas; a questão é só onde |

**O meio-termo é comum**: clusters gerenciados na nuvem e clusters próprios no local, publicados e
governados do mesmo jeito, pelo GitOps da lição 39 e pelos vários contextos da lição 48. Distribuições
como o OpenShift e o Rancher vendem exatamente essa uniformidade.

E existe o caso deste próprio curso. Rodar o kind num laptop é rodar o seu cluster, e tudo o que se
aprende fazendo isso, os static pods, os certificados, o etcd, é o que torna o comportamento de um
serviço gerenciado compreensível quando ele dá errado. **Saber operar um é o melhor motivo para deixar
outra pessoa operá-lo**, porque aí você sabe pelo que está pagando.
