---
title: Formato e filtro
version: 1
---

**Todo comando do gcloud que imprime um recurso pode imprimi-lo em qualquer forma**, e todo comando que lista
recursos pode filtrá-los. As duas coisas são opções comuns a todos os comandos, `--format` e `--filter`, e são o
que transforma o gcloud de algo lido por uma pessoa em algo lido por um script. O emulador dá a esta seção algo
para listar. Faça quatro tópicos, três deles rotulados com a equipe dona:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders invoices --labels=team=planner
Created topic [projects/planner-dev/topics/orders].
Created topic [projects/planner-dev/topics/invoices].
ana@laptop:~/gcp$ gcloud pubsub topics create metrics --labels=team=data
Created topic [projects/planner-dev/topics/metrics].
ana@laptop:~/gcp$ gcloud pubsub topics create scratch
Created topic [projects/planner-dev/topics/scratch].
```

## Formato

O padrão de uma lista é uma tabela com o que os autores do comando escolheram. O `--format` escolhe no lugar:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --format="table(name.basename(), labels.team)"
NAME      TEAM
invoices  planner
metrics   data
orders    planner
scratch
```

`table(...)` nomeia as colunas, e cada coluna é uma **projeção**: um campo do recurso, `labels.team`, ou um campo
com uma transformação aplicada, `name.basename()`, que guarda o que vem depois da última barra. Um tópico sem
rótulo mostra uma célula vazia, e não um erro. As outras formas que importam:

| formato | dá | para |
|---|---|---|
| `json`, `yaml` | o recurso inteiro, como a API o devolveu | ler todo campo, ou um programa |
| `value(...)` | os campos projetados, separados por tabulação, sem cabeçalho | um laço de shell |
| `csv(...)` | os campos projetados com cabeçalho | uma planilha |
| `table(...)` | colunas alinhadas | uma pessoa |

O `gcloud topic formats` lista todos, com as transformações.

## Filtro

```
ana@laptop:~/gcp$ gcloud pubsub topics list --filter="labels.team=planner" --format="value(name)"
projects/planner-dev/topics/invoices
projects/planner-dev/topics/orders
```

**Um filtro é uma expressão sobre os mesmos campos que um formato projeta**: `labels.team=planner`,
`name:invoices` para *contém*, `NOT labels.team:*` para *não tem rótulo team*, unidos com `AND` e `OR`. O gcloud
manda para a API o que a API consegue filtrar, e aplica o resto ele mesmo sobre o que volta, então um filtro
sempre funciona e nem sempre é barato: contra uma API que não filtra, a lista inteira é buscada antes.

Os dois juntos são como um script faz uma pergunta precisa. Os tópicos que ninguém reivindicou:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --filter="NOT labels.team:*" --format="value(name.basename())"
scratch
```

E o recurso inteiro, só o primeiro, para ver que campos há para projetar e filtrar:

```
ana@laptop:~/gcp$ gcloud pubsub topics list --format=json --limit=1
[
  {
    "labels": {
      "team": "planner"
    },
    "name": "projects/planner-dev/topics/invoices"
  }
]
```

**Um script que lê a tabela padrão do gcloud é um script que quebra** no dia em que a tabela ganhar uma coluna.
`--format=json` ou `value(...)` é um contrato que o script escolheu; o padrão é uma exibição que outra pessoa
fez.
