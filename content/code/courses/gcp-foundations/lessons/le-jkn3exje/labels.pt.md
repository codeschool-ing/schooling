---
title: Rótulos, e por que eles servem para contar
version: 1
---

**Um rótulo é uma chave e um valor presos a um recurso, e o trabalho dele é ser contado.**
`team=planner` num tópico, `env=prod` num projeto, `cost-centre=cc-1040` num disco. Os rótulos viajam
para a exportação do faturamento da lição 14, onde respondem à pergunta que todo financeiro faz
primeiro: de quem é isto? Um recurso sem eles é uma linha da fatura que ninguém reclama.

As regras são rígidas e as mesmas em todo o Google Cloud: chaves e valores são letras minúsculas,
dígitos, hífens e sublinhados, letras internacionais inclusive; uma chave começa com letra; cada um tem
no máximo 63 caracteres; um recurso leva no máximo 64 rótulos. A CLI as confere antes de mandar
qualquer coisa:

```
ana@laptop:~/gcp$ gcloud pubsub topics create reminders --labels=team=planner,env=dev
Created topic [projects/planner-dev/topics/reminders].
ana@laptop:~/gcp$ gcloud pubsub topics create invoices --labels=Team=planner 2>&1 | head -2
ERROR: (gcloud.pubsub.topics.create) argument --labels: Bad value [Team]: Only hyphens (-), underscores (_), lowercase characters, and numbers are allowed. Keys must start with a lowercase character. International characters are allowed. Key length must not exceed 63 characters.
Usage: gcloud pubsub topics create TOPIC [TOPIC ...] [optional flags]
ana@laptop:~/gcp$ gcloud pubsub topics create invoices --labels=team=Planner 2>&1 | head -2
ERROR: (gcloud.pubsub.topics.create) argument --labels: Bad value [Planner]: Only hyphens (-), underscores (_), lowercase characters, and numbers are allowed. International characters are allowed.
Usage: gcloud pubsub topics create TOPIC [TOPIC ...] [optional flags]
ana@laptop:~/gcp$ gcloud pubsub topics list --filter="labels.env=dev" --format="table(name,labels)"
NAME                                   LABELS
projects/planner-dev/topics/reminders  {'env': 'dev', 'team': 'planner'}
```

**As duas recusas são do próprio `gcloud`**, feitas no notebook: uma maiúscula na chave, uma maiúscula
no valor. O primeiro comando mostra um tópico criado com dois rótulos, e o filtro mostra para que eles
servem: uma expressão separa todo tópico de um ambiente, quantos o projeto tiver, e a exportação do
faturamento da lição 14 faz o mesmo em todos os projetos de uma vez.

## Onde o emulador para

Rótulos mudam ao longo da vida de um recurso: uma equipe é renomeada, um centro de custo é dividido. O
Pub/Sub do Google aceita atualizar os rótulos de um tópico. O emulador não:

```
ana@laptop:~/gcp$ gcloud pubsub topics update reminders --update-labels=cost-centre=cc-1040
ERROR: (gcloud.pubsub.topics.update) INVALID_ARGUMENT: Invalid update_mask provided in the UpdateTopicRequest: labels is not a known Topic field. Note that field paths must be of the form 'schema_settings' rather than 'schemaSetings'.
ana@laptop:~/gcp$ gcloud pubsub topics describe reminders
labels:
  env: dev
  team: planner
name: projects/planner-dev/topics/reminders
```

**Esse `INVALID_ARGUMENT` é uma lacuna do emulador, não uma regra do Google.** O emulador implementa
parte da API, e atualizar rótulos fica fora dessa parte; o próprio banner dele disse, na lição 1, que a
implementação *may be incomplete or differ from the real system*. Contra o Google o mesmo comando
atualiza os rótulos na hora. É o tipo de diferença que o curso prometeu apontar em vez de esconder: o
comando está certo, e o laboratório não consegue mostrá-lo funcionando.

## Rótulos, tags e network tags

Três coisas no Google Cloud têm nome parecido com tag, e fazem três trabalhos diferentes:

| | o que é | quem lê |
|---|---|---|
| **rótulo** (label) | uma chave e um valor num recurso | a exportação do faturamento, filtros, o inventário de ativos |
| **tag**, do Resource Manager | uma chave e um valor definidos uma vez na organização e vinculados a recursos | condições do IAM e políticas da organização, que podem dizer "só onde `env` é `prod`" |
| **network tag** | uma palavra solta numa máquina virtual | regras de firewall e rotas, lições 16 e 17 |

A diferença que importa é **quem pode mudar**. Qualquer um que possa editar um recurso pode editar os
rótulos dele, então um rótulo nunca deve decidir acesso: um desenvolvedor que quisesse as permissões da
produção só precisaria escrever `env=prod`. Uma tag do Resource Manager é definida de forma central, e
vinculá-la exige um papel próprio, e é por isso que condições do IAM leem tags e nunca rótulos.
