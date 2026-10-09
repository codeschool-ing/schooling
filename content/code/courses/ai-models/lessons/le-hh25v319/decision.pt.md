---
title: Decidir, e decidir de novo
version: 1
---

Agora está tudo na mesa: os limites da aula 4 e as notas desta aula. O piso da ana para
classificação era 35 de 40, e para extração ela o põe onde um número de pedido errado é raro o
bastante para pegar à mão: **nenhum número inventado ou alterado**, e perdas só se forem raras.

| tarefa | llama3.2:3b | qwen2.5:3b | llama3.2:1b |
|---|---|---|---|
| piso de classificação, 35 de 40 | falha, 19 | falha, 30 | falha, 5 |
| extração, nenhum número errado | falha: dois inventados, um alterado | falha: um alterado, 14 perdidos | falha |
| na memória, pela aula 1 | 2,6 GB | não medido aqui | 1,5 GB |

**Nenhum candidato passa em nenhum dos pisos.** Isso não é a avaliação falhando; é a avaliação
fazendo a única coisa para que serve, antes de a Lantern Books depender de qualquer um deles. Ela
também diz o que tentar em seguida, e em que ordem, que é a escada da aula 1 seção 11:

1. **O prompt e os exemplos.** Os erros de classificação do qwen2.5:3b são fronteiras traçadas em
   outro lugar, que exemplos rotulados movem, e os do llama3.2:3b são listas, que uma instrução ou
   um recurso de saída estruturada removem. As duas coisas são horas de trabalho e uma nova execução
   deste arquivo.
2. **Um modelo maior.** Três bilhões de parâmetros é pouco; a aula 3 calculou o que um maior pede de
   uma máquina, e a matriz da aula 4 lista modelos hospedados que uma chave alcança. Cada um é uma
   linha nova na mesma execução.
3. **Por tarefa, não por loja.** Se a nova execução puser o qwen2.5:3b acima do piso de
   classificação e o llama3.2:3b acima do de extração, a resposta é dois modelos, e a aula 1 seção
   03 já tinha dois carregados ao mesmo tempo.

A regra que decide continua a mesma, sejam quais forem as linhas: **o candidato mais barato que
passa em todos os pisos, por tarefa**. Aqui o resultado honesto é "nenhum ainda", com os motivos
escritos.

## A execução é uma linha de base

A execução que decidiu é guardada, com a data, os identificadores exatos dos modelos, o prompt e a
versão dos casos. Ela vira a **linha de base** com que a próxima execução é comparada, e vai haver
uma próxima. A aula 2 seção 06 listou o que dispara uma: um modelo aposentado na data do provedor,
um alias que começa a responder com outro modelo, um candidato novo que vale tentar, um prompt
editado para consertar os casos de fronteira. Cada um desses é a mudança de uma entrada da
avaliação, e os casos respondem se ela piorou as coisas.

O `evalkit gate` transforma essa conferência em algo que um programa pode recusar. Ele compara a
nota frouxa de um modelo numa execução nova com a linha de base e falha, com status de saída 1, se a
nova for pior por mais casos do que o permitido, um a menos que lhe digam outro número:

```
ana@desk:~/desk$ cp runs/triage.jsonl runs/baseline.jsonl
ana@desk:~/desk$ python evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl qwen2.5:3b; echo "exit $?"
qwen2.5:3b: 30 before, 29 now, 1 allowed: pass
exit 0
ana@desk:~/desk$ python evalkit.py gate runs/baseline.jsonl runs/hot-b.jsonl qwen2.5:3b; echo "exit $?"
qwen2.5:3b: 30 before, 30 now, 1 allowed: pass
exit 0
```

As duas execuções com temperatura 1 da seção 08 passam: 29 e 30 contra uma linha de base de 30, com
um caso permitido. Não permita nenhum, e a primeira é recusada:

```
ana@desk:~/desk$ python evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl qwen2.5:3b 0; echo "exit $?"
qwen2.5:3b: 30 before, 29 now, 0 allowed: FAIL
exit 1
```

**O status de saída 1** é o que deixa um script, um job agendado ou um pipeline de CI barrar uma
mudança. Quantos casos permitir é uma decisão com o mesmo formato do piso: a seção 08 viu quatro
respostas mudarem entre duas execuções de um modelo, então um portão que não permite nada com
temperatura 1 recusa mudanças que não mudaram nada.

## O que faz desta a aula que dura

Todo modelo que este curso cita nas aulas 6 a 20 vai ser substituído. Os quarenta casos, a decisão
sobre o que conta como certo, o harness, os intervalos e o portão não vão precisar ser. Quando o
próximo modelo chegar, o trabalho de escolhê-lo é acrescentar uma linha e rodar o arquivo: **uma
tarde, porque a avaliação já estava escrita**.
