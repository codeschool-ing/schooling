---
title: Por que ninguém cria um pod à mão
version: 1
---

```
ana@laptop:~/shop$ kubectl delete pod web
pod "web" deleted from default namespace
ana@laptop:~/shop$ kubectl get pods
No resources found in default namespace.
```

**Esse é o problema inteiro de um pod solto**: depois que ele some, nada sabe que ele deveria existir.
Ninguém criou um ReplicaSet para ele, então nenhum controlador está contando, e o cluster considera o
assunto encerrado. Um pod é apagado por muitos motivos além de alguém digitar o comando (o nó dele é
esvaziado para manutenção na lição 32, o nó falha, o pod é despejado porque falta memória no nó) e
cada um deles termina do mesmo jeito para um pod solto.

Então pods quase sempre são escritos como um **modelo dentro de um controlador**, que cria os pods e os
substitui:

| você quer | escreva | lição |
|---|---|---|
| um número de cópias idênticas de um programa sem estado | um Deployment | 10 |
| cópias com nome estável e um disco cada | um StatefulSet | 11 |
| uma cópia em cada nó | um DaemonSet | 12 |
| uma tarefa que roda até terminar | um Job, ou um CronJob para um horário | 12 |

Tudo o que está no pod do arquivo desta lição (o container de inicialização, o sidecar, o volume
compartilhado) vai sem mudança para o `template:` de qualquer um deles; o controlador só acrescenta a
promessa de que o pod vai existir.

Ainda há dois bons motivos para criar um pod solto: **um pod descartável para olhar em volta**, como os
pods `probe` que lições seguintes usam para fazer perguntas de dentro do cluster, e um pod estático
escrito pela própria configuração do nó, como o plano de controle da lição 4. Nenhum dos dois deveria
sobreviver.
