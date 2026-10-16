---
title: Escolhendo onde rodar
version: 1
---

**Quatro jeitos de rodar o mesmo job Spark, e o curso já rodou três deles.**

| | standalone | YARN | Kubernetes | gerenciado |
|---|---|---|---|---|
| quem roda o cluster | você | você, ou a equipe de plataforma | a equipe de plataforma | o provedor |
| o que mais o divide | nada | outros jobs Hadoop, por fila | todo outro serviço, por namespace | outros jobs da sua conta |
| um driver Python no modo cluster | não | sim | sim | sim |
| executores acrescentados e removidos enquanto um job roda | com cuidado | sim | sim | sim |
| onde os dados costumam morar | nas mesmas máquinas | no HDFS das mesmas máquinas | num object store | num object store |
| quando é a resposta certa | uma equipe, poucas máquinas, aprendizado | um parque Hadoop que já existe | uma organização que já roda Kubernetes | a maior parte do trabalho novo na nuvem |

**A escolha raramente é feita por causa do Spark.** Uma organização que já roda tudo no Kubernetes
acrescenta o Spark a ele; uma com dez anos de HDFS e YARN continua rodando o Spark lá; uma equipe nova
na nuvem começa num serviço gerenciado e nunca encontra um NodeManager. O que o Spark precisa de
qualquer um deles é o mesmo: um lugar para iniciar um driver, um lugar para iniciar executores, e um
caminho até os dados.

**O que importa mais que o gerenciador é onde estão os dados.** Toda opção além do standalone e do
YARN lê de um object store, pela rede, que é a localidade perdida da aula 3. As aulas 6 e 10 são como
isso se paga de volta: ler menos colunas, pular row groups e partições, e manter os arquivos grandes.
Um job que lê tudo é mais lento em qualquer um deles.
