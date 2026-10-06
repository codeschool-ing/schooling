---
title: Argo CD e Flux
version: 1
---

Tudo nas duas seções anteriores foi uma pessoa rodando dois comandos. **O Argo CD e o Flux são esses
dois comandos rodando dentro do cluster, para sempre**: cada um observa um ou mais repositórios,
renderiza o que está lá (manifestos simples, Kustomize ou Helm), compara com o cluster, e aplica a
diferença. Nenhum dos dois foi instalado neste laboratório, então o que segue os descreve e não foi
rodado.

::: track devops
O curso `gitops`, que vem mais adiante na sua trilha, instala e roda os dois: o Argo CD na lição 3 e o
Flux na lição 4. O que segue é só o bastante para reconhecê-los.
:::

::: track *
O curso `gitops` instala e roda os dois, o Argo CD na lição 3 e o Flux na lição 4. O que segue é só o
bastante para reconhecê-los.
:::

| | Argo CD | Flux |
|---|---|---|
| a unidade que gerencia | uma `Application`: um caminho de repositório e um cluster e namespace de destino | uma fonte `GitRepository` mais uma `Kustomization` ou `HelmRelease` que a aplica |
| como você o vê | uma interface web mostrando sincronização e saúde de cada aplicação | `kubectl` e a linha de comando `flux`; interfaces são extras |
| forma | um conjunto de componentes com interface e usuários próprios | um conjunto de controllers pequenos, um por trabalho |
| comum aos dois | puxa do git, compara, aplica, informa desvio, pode podar o que foi removido | |

**Os dois puxam; nada empurra.** O pipeline que monta uma imagem não guarda credenciais do cluster: ele
faz commit de uma tag nova no repositório, e a ferramenta dentro do cluster a pega. Isso tira a
credencial mais poderosa do sistema mais exposto, o servidor de CI.

O ciclo à mão desta lição tinha uma lacuna que uma ferramenta fecha: o `kubectl apply` nunca apaga o
que foi removido do repositório, como mostrou o ConfigMap que sobrou na lição 38. As duas ferramentas
conseguem podar, apagando objetos que o repositório não contém mais, e as duas tornam isso uma
configuração, porque apagar é a única ação que a próxima sincronização não desfaz.
