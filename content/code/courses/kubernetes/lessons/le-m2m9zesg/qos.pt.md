---
title: Três classes, decididas pelo que você escreveu
version: 1
---

Ninguém define a classe de qualidade de serviço de um pod. **O Kubernetes a deriva dos requests e
limits, e a escreve no status do pod**, onde ela decide quem sofre primeiro quando falta recurso num
nó:

```
ana@laptop:~/shop$ kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
NAME     QOS
capped   Guaranteed
free     Burstable
hungry   Burstable
probe    BestEffort
```

As regras são curtas:

| classe | quando | aqui |
|---|---|---|
| `Guaranteed` | todo container tem limits de CPU e memória, e requests iguais a eles | `capped` |
| `Burstable` | ao menos um request ou limit, mas não Guaranteed | `free`, `hungry` |
| `BestEffort` | nenhum request e nenhum limit em lugar nenhum | `probe` |

**`hungry` é o que merece uma segunda olhada.** O request de memória dele é igual ao limit de memória,
o que parece uma garantia, mas ele não diz nada sobre CPU, então é `Burstable`. Guaranteed precisa dos
dois recursos, em todo container, definidos iguais.

A classe importa em dois lugares. Quando falta memória num nó, o kubelet despeja pods para salvar o
nó, e começa por pods que usam mais do que pediram, o que exclui um pod Guaranteed que fica dentro dos
seus limits; a lição 32 assiste a isso acontecer. E o OOM killer do kernel, quando age pelo nó inteiro
e não por um container, prefere processos BestEffort a Burstable, e Burstable a Guaranteed.

Um ponto de partida comum, não uma regra: defina request e limit de memória iguais, porque ficar sem
memória mata; defina um request de CPU e muitas vezes nenhum limit de CPU, porque ficar sem CPU só faz
esperar, e um limit desaceleraria o pod mesmo quando o nó tem CPU sobrando. A lição 21 é como escolher
os números.
