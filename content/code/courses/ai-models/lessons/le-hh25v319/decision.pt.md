---
title: Decidir, e decidir de novo
version: 1
---

Agora está tudo na mesa: os limites e os custos da aula 4, e as notas desta aula. O piso da ana para
classificar era 35 de 40, e para a extração ela o põe onde um número de pedido errado seja raro o
bastante para pegar à mão: **nenhum erro de conteúdo**, e erros de formato só se um recurso de saída
estruturada os eliminar.

| tarefa | standin-large | standin-small | standin-local |
|---|---|---|---|
| piso de classificação, 35 de 40 | **passa, 38** | falha, 34 | falha, 32 |
| extração, nenhum erro de conteúdo | **passa** | passa depois de consertar o formato | falha: um número trocado |
| preço por 1.000 requisições | US$ 0,2001 | US$ 0,0167 | uma máquina |

Com esses números a escolha para as duas tarefas é o standin-large, e a 400 e-mails por dia o preço
dele é um erro de arredondamento. Com candidatos reais a tabela teria mais linhas e notas mais
próximas, e a regra que decide continua a mesma: **o candidato mais barato que passa em todos os
pisos, tarefa por tarefa**.

## A execução é uma linha de base

A execução que decidiu é guardada, com a data, os identificadores exatos dos modelos, o prompt e a
versão dos casos. Ela vira a **linha de base** com que a próxima execução é comparada, e vai haver uma
próxima. A aula 2 seção 06 listou o que dispara uma: um modelo aposentado na data do provedor, um
apelido que passa a responder com outro modelo, um candidato novo que vale testar, um prompt editado
para consertar os casos de fronteira. Cada um desses é uma mudança numa entrada da avaliação, e os
casos respondem se ela piorou as coisas.

O `evalkit gate` transforma essa verificação em algo que um programa pode recusar. Ele compara a nota
tolerante de um modelo numa execução nova com a linha de base e falha, com status de saída 1, se a
nova for pior por mais casos do que o permitido:

```
ana@desk:~/desk$ cp runs/triage.jsonl runs/baseline.jsonl
ana@desk:~/desk$ python lab/evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl standin-small; echo "exit $?"
standin-small: 34 before, 34 now, 1 allowed: pass
exit 0
ana@desk:~/desk$ python lab/evalkit.py gate runs/baseline.jsonl runs/hot-b.jsonl standin-small; echo "exit $?"
standin-small: 34 before, 32 now, 1 allowed: FAIL
exit 1
```

A primeira execução com temperatura 1 empatou com a linha de base, 34 e 34, e passou. A segunda
perdeu dois casos, além do um permitido, e **falhou com status de saída 1**, que é o que deixa um
script, uma tarefa agendada ou um pipeline de CI impedir uma mudança de sair. As duas execuções da
seção 08, passadas pelo portão: mesmo modelo, mesmos casos, e uma das duas teria sido recusada.

## O que faz desta a aula que dura

Todo modelo que este curso cita nas aulas 6 a 20 vai ser substituído. Os quarenta casos, a decisão
sobre o que conta como certo, o harness, os intervalos e o portão não vão precisar ser. Quando o
próximo modelo chegar, o trabalho de escolhê-lo é acrescentar uma linha e rodar o arquivo: **uma
tarde, porque a avaliação já estava escrita**.
