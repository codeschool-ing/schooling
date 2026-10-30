---
title: O índice da tarefa, e como cortar o trabalho
version: 1
---

Quando uma execução sobe várias tarefas, todas rodam a mesma imagem com as mesmas configurações.
**A única coisa que muda são três variáveis de ambiente, e o programa precisa usá-las para decidir
qual parte do trabalho é dele.** Nada mais vai dividir: o Cloud Run sobe os contêineres e conta as
saídas, e não faz ideia do que seja um pedido.

## As três variáveis

| variável | o que ela guarda |
|---|---|
| `CLOUD_RUN_TASK_INDEX` | o número desta tarefa, de 0 até a contagem menos um |
| `CLOUD_RUN_TASK_COUNT` | quantas tarefas esta execução tem |
| `CLOUD_RUN_TASK_ATTEMPT` | quantas vezes esta tarefa foi tentada de novo, 0 na primeira |

Em casa ninguém as define, então você mesmo define e **faz o papel do Cloud Run**: três
contêineres, cada um informado do seu índice. No Cloud Run eles rodariam ao mesmo tempo, até o
paralelismo do job; aqui rodam um depois do outro, para os logs não se misturarem:

```
ana@laptop:~/gcp$ for i in 0 1 2; do docker run --rm -e CLOUD_RUN_TASK_INDEX=$i -e CLOUD_RUN_TASK_COUNT=3 invoices:1; done
{"severity": "INFO", "message": "task 0 of 3, attempt 0: orders [1001, 1004, 1007, 1010]"}
{"severity": "INFO", "message": "invoice for order 1001 written"}
{"severity": "INFO", "message": "invoice for order 1004 written"}
{"severity": "INFO", "message": "invoice for order 1007 written"}
{"severity": "INFO", "message": "invoice for order 1010 written"}
{"severity": "INFO", "message": "task 1 of 3, attempt 0: orders [1002, 1005, 1008]"}
{"severity": "INFO", "message": "invoice for order 1002 written"}
{"severity": "INFO", "message": "invoice for order 1005 written"}
{"severity": "INFO", "message": "invoice for order 1008 written"}
{"severity": "INFO", "message": "task 2 of 3, attempt 0: orders [1003, 1006, 1009]"}
{"severity": "INFO", "message": "invoice for order 1003 written"}
{"severity": "INFO", "message": "invoice for order 1006 written"}
{"severity": "INFO", "message": "invoice for order 1009 written"}
```

**Todo pedido foi faturado exatamente uma vez, e nenhuma tarefa soube das outras.** A tarefa 0
pegou os pedidos 1001, 1004, 1007 e 1010, a tarefa 1 o passo seguinte, a tarefa 2 o último. É essa
a propriedade que o corte precisa ter, e `ORDERS[index::count]` a dá de graça: as fatias não se
sobrepõem e juntas cobrem a lista, seja qual for a contagem.

## Jeitos de cortar, e quanto cada um custa

**Por passo**, como aqui, espalha o trabalho por igual quando os itens se parecem, e precisa que a
lista inteira seja a mesma em toda tarefa. Isso vale para uma lista no código; para uma lista lida
de um banco, só vale se toda tarefa a ler na mesma ordem, então a consulta precisa de um
`ORDER BY`.

**Por faixa**, a tarefa 0 com o primeiro décimo, a tarefa 1 com o seguinte, mantém itens
relacionados juntos, o que importa quando os vizinhos de um item dividem um arquivo ou um cache. Ela
espalha mal quando os itens diferem de tamanho.

**Por hash**, o id do item módulo a contagem, é o passo sem a lista: cada tarefa decide sozinha se
um item é dela, o que funciona para itens que chegam de uma fila. Mudar a contagem muda toda
atribuição, o que serve para um job cujo estado começa do zero toda noite e é errado para um que
lembra qual tarefa fez o quê.

## Quantas tarefas, e quantas ao mesmo tempo

Dois números, que a ajuda do gcloud define com precisão:

```
ana@laptop:~/gcp$ gcloud run jobs create --help | grep -E -A3 '^     --(tasks|parallelism|max-retries|task-timeout)='
     --max-retries=MAX_RETRIES
        Number of times a task is allowed to restart in case of failure before
        being failed permanently. This applies per-task, not per-job. If set to
        0, tasks will only run once and never be retried on failure.
--
     --parallelism=PARALLELISM
        Number of tasks that may run concurrently. Must be less than or equal
        to the number of tasks. Set to 0 to unset.

--
     --task-timeout=TASK_TIMEOUT
        Set the maximum time (deadline) a job task attempt can run for. In the
        case of retries, this deadline applies to each attempt of a task. If
        the task attempt does not complete within this time, it will be killed.
--
     --tasks=TASKS; default=1
        Number of tasks that must run to completion for the execution to be
        considered done.
```

`--tasks` é quantos pedaços, `--parallelism` quantos rodam ao mesmo tempo. **Trezentas tarefas com
paralelismo dez são umas trinta rodadas**, e o segundo número é em geral o que protege alguma coisa:
o banco em que o job escreve tem limite de conexões, e um job de trezentas tarefas subindo todas de
uma vez pode esgotá-lo. As linhas de novas tentativas e tempo limite são o assunto da seção 04.
