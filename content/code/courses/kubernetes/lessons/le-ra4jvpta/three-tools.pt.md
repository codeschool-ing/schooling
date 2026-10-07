---
title: Três jeitos de ter um cluster na sua própria máquina
version: 1
---

**Um cluster de estudo não precisa ser pequeno no que ensina.** A API, os objetos, o escalonador e o
kubelet são os mesmos programas que um cluster de produção roda; o que falta a um laptop é hardware,
não Kubernetes. Três ferramentas gratuitas montam um, e elas diferem principalmente no que é feito
um "nó".

| | um nó é | feito por | melhor em |
|---|---|---|---|
| **kind** | um container Docker | o projeto Kubernetes, para testar o próprio Kubernetes | vários nós, rápido, igual em todo lugar |
| minikube | uma máquina virtual ou um container | o projeto Kubernetes | um nó com complementos ligados pelo nome |
| k3d | um container Docker rodando k3s | a comunidade do k3d, em torno do k3s da SUSE | uma distribuição leve, com menos peças |

**Este curso usa o kind, e toda transcrição dele foi gravada com o kind.** Os nós são containers,
então criar um cluster leva segundos em vez dos minutos de que uma máquina virtual precisa, e um
cluster de três nós é um arquivo de configuração de uma dúzia de linhas. É nele que roda a própria
bateria de testes do Kubernetes, então a versão que você pede é a versão que recebe, sem
modificações. minikube e k3d aparecem aqui para você reconhecê-los nas instruções de outra pessoa;
eles não foram rodados para este curso.

O Docker Desktop também pode ligar um cluster próprio, nas configurações. É o caminho mais curto no
Windows e no macOS, e é um cluster só, com um nome só, o que limita na lição 48.

## Qual caminho

A aula 1 já fez essa escolha: Docker, `kind` e `kubectl` numa máquina virtual Ubuntu, ou direto num
computador que roda Linux, com um playground no navegador citado como terceiro caminho e sem depender
dele. Nada aqui muda isso. A próxima seção monta um cluster à mão, chamado `study`, a partir do mesmo
tipo de arquivo que o `up.sh` usa, e mede quanto ele custa em memória. A seção seguinte quebra a montagem de propósito, porque é ali que a maioria das pessoas desiste, e quase
sempre é um de quatro erros.
