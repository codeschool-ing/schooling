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

## Três caminhos, e quanto cada um custa ao seu computador

| caminho | o que você instala | quanto custa | quando escolher |
|---|---|---|---|
| **na sua máquina** (recomendado) | Docker, `kind`, `kubectl` | cerca de 0,8 GiB de memória para três nós, medido na próxima seção | quase sempre |
| numa máquina virtual Linux | uma VM com 4 GiB ou mais, e depois os mesmos três | a memória da VM por cima, e o disco dela | sua máquina roda algo que conflita com o Docker, ou você quer o laboratório separado |
| on-line, no navegador | nada | nada, e a sessão é apagada depois de mais ou menos uma hora | uma máquina em que você não pode instalar nada; nada sobrevive entre sessões |

O caminho do navegador é um playground como o Killercoda, que entrega um cluster novo numa aba. É um
bom jeito de testar um comando e um jeito ruim de acompanhar um curso, porque toda lição começa
reconstruindo o que a anterior deixou.

As duas próximas seções montam o recomendado e depois o quebram, porque a instalação é onde a
maioria das pessoas desiste, e quase sempre é um de quatro erros.
