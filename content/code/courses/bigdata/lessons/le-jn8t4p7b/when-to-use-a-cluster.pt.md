---
title: Quando usar um cluster
version: 1
---

**O curso começou com uma pergunta, e ela agora tem resposta.** A aula 1 perguntou quando os dados
deixam de caber numa máquina; catorze aulas depois, as medições dizem:

- **Abaixo de algumas centenas de gigabytes, uma máquina ganha.** Os 400 MB deste laboratório levaram
  um segundo no DuckDB e dezesseis num job Spark ajustado. A coordenação de um cluster, uma JVM por
  executor, um shuffle por arquivos, tarefas agendadas uma a uma, é pura sobrecarga até uma máquina não
  bastar.
- **Um cluster ganha quando os dados ou o trabalho passam de uma máquina** no tempo que há: terabytes
  para ler, um join de duas tabelas grandes, um job de uma hora que precisa levar cinco minutos. Aí tudo
  o que as aulas 2 a 13 mediram vale, e o erro de cada aula é multiplicado pelo número de máquinas.
- **A maior parte da velocidade está em ler menos.** Arquivos colunares, poda, partições e ordenação,
  aulas 6 e 10, tiraram mais tempo que qualquer configuração do cluster.
- **A maior parte do custo está em tempo que não faz nada.** Um cluster mantido ligado, executores
  segurados por horas ociosas, um job oito vezes mais lento que o necessário: cada um é pago por hora.

**O hábito que o curso tentou ensinar é medir antes de acreditar.** Cada afirmação dele veio com um
número de uma execução que você pode repetir, inclusive as que foram contra o argumento da própria
aula: as curas para desbalanceamento que foram mais lentas aqui, a especulação que não podia ajudar
numa máquina só, o cluster que perdeu para um processo único. Um guia de ajuste, este incluído, é uma
lista de coisas que vale tentar; os estágios do seu próprio job são o que diz qual tentar primeiro.
