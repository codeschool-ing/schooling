---
title: O que cada identidade pode fazer
version: 1
---

**A rotação encurta o tempo em que uma credencial roubada funciona. O menor privilégio encolhe
aquilo para que ela funciona.** As duas coisas são independentes, e a segunda costuma ser a mais
barata: uma identidade que pode ler um caminho do Vault, ou escrever num namespace do cluster, é uma
perda pequena quando vaza, qualquer que seja a sua duração.

Toda identidade deste curso pode ouvir a mesma pergunta, *qual o máximo que ela conseguiria fazer?*,
e as respostas são desiguais:

| identidade | pode | o máximo que conseguiria fazer |
|---|---|---|
| `bulletin` em produção, pelo role do Vault | ler `secret/data/bulletin/production` | ler um token |
| a conta do Flux no Gitea | ler `fleet` | ler o estado desejado |
| `image-bot` | escrever em `fleet`, nunca fazer merge na `main` | abrir um pull request enganoso |
| os controladores do Flux | tudo no cluster, como `cluster-admin` | qualquer coisa que um commit aprovado peça |
| o token root do Vault | tudo no Vault | qualquer coisa |

As três primeiras foram estreitadas de propósito em aulas anteriores. **A quarta é o padrão do
Flux**: os controladores kustomize e helm rodam com um ClusterRoleBinding para `cluster-admin`,
então um commit em qualquer caminho que o Flux aplica pode criar qualquer coisa em qualquer lugar,
um ClusterRole, um webhook, um pod no `kube-system`. A revisão é a única coisa entre um pull request
e o cluster inteiro.

Isso é razoável para a Kustomization da própria plataforma, `flux-system`, que instala controladores
e CRDs e precisa desse poder. Não é razoável para os ambientes de uma aplicação, que deveriam poder
mudar o próprio namespace e nada mais, e a próxima seção os estreita. A quinta é o último passo da
aula 12: o token root serve para configurar o Vault, e um Vault em uso não deixa um desses largado.
