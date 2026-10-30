---
title: Os três nomes de um projeto, e o nome de tudo que há dentro dele
version: 1
---

**Um projeto tem três identificadores, e eles são para três leitores diferentes.** Confundi-los é o
pequeno erro mais comum do Google Cloud, porque dois deles se parecem e o console mostra os três numa
linha só.

| | exemplo | quem escolhe | pode mudar |
|---|---|---|---|
| **id do projeto** | `planner-dev` | você, na criação | nunca |
| **número do projeto** | `415104041262` | o Google, na criação | nunca |
| **nome do projeto** | `Planner development` | você | a qualquer hora |

O **id** é o que você digita: no `gcloud --project`, no Terraform, no endereço de todo recurso. Ele é
único em todo o Google Cloud, então `planner-dev` só pode pertencer a um cliente, e depois que um
projeto é apagado o id dele nunca é entregue de novo. `planner-dev`, o id que o laboratório deste curso
usa, pode muito bem pertencer ao projeto real de alguém; o laboratório nunca o alcança, porque o Google
recusa o token placeholder antes de procurar qualquer projeto. O **número** é o que o Google usa por
dentro: ele aparece nos nomes das contas de serviço que o Google cria para um projeto, em algumas
mensagens de erro e nos dados de faturamento. O número acima foi inventado para este curso. O **nome**
é um rótulo para pessoas, mostrado no seletor de projetos do console; nada se liga a ele, então
renomeie à vontade.

## O projeto faz parte de todo nome

O nome de todo recurso começa pelo projeto em que ele mora. Um tópico não se chama `orders`; ele se
chama `projects/planner-dev/topics/orders`. Peça ao emulador, que segue essa regra à risca, dois
tópicos com o mesmo nome curto em dois projetos:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders --project planner-dev
Created topic [projects/planner-dev/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics create orders --project planner-prod
Created topic [projects/planner-prod/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics list --project planner-prod --format="value(name)"
projects/planner-prod/topics/orders
ana@laptop:~/gcp$ gcloud pubsub topics list --format="value(name)"
projects/planner-dev/topics/orders
```

**Dois tópicos, os dois chamados `orders`, e nenhum sabe do outro**, porque o projeto na frente do nome
faz deles dois nomes diferentes. O emulador aceitou `planner-prod` sem perguntar se o projeto existe, o
que o Google não faria; o que ele mantém é a nomenclatura, e a nomenclatura é o que interessa. O
`--project` num comando sobrepõe a propriedade `core/project` só naquele comando, e a segunda lista,
sem ele, mostra o `planner-dev` de novo.

## O nome completo de recurso

Dentro de uma API, a forma curta basta. **Entre APIs**, numa condição do IAM, no inventário de ativos
da lição 25, num log de auditoria, o Google usa o **nome completo de recurso**, que acrescenta o
serviço na frente:

| nome curto, dentro do Pub/Sub | nome completo de recurso, em todo lugar |
|---|---|
| `projects/planner-dev/topics/orders` | `//pubsub.googleapis.com/projects/planner-dev/topics/orders` |
| `projects/planner-dev` | `//cloudresourcemanager.googleapis.com/projects/planner-dev` |
| `folders/345678901234` | `//cloudresourcemanager.googleapis.com/folders/345678901234` |

O serviço dono do próprio projeto é o **Resource Manager**, `cloudresourcemanager.googleapis.com`. É a
API que cria projetos e pastas e os move de lugar, e nenhum emulador responde por ela. Pergunte à API
real pelo `planner-dev` sem credencial, e a recusa nomeia o método que teria rodado:

```
ana@laptop:~/gcp$ curl -sS https://cloudresourcemanager.googleapis.com/v3/projects/planner-dev
{
  "error": {
    "code": 401,
    "message": "Request is missing required authentication credential. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.",
    "status": "UNAUTHENTICATED",
    "details": [
      {
        "@type": "type.googleapis.com/google.rpc.ErrorInfo",
        "reason": "CREDENTIALS_MISSING",
        "domain": "googleapis.com",
        "metadata": {
          "method": "google.cloud.resourcemanager.v3.Projects.GetProject",
          "service": "cloudresourcemanager.googleapis.com"
        }
      }
    ]
  }
}
```

`google.cloud.resourcemanager.v3.Projects.GetProject` é o método, na forma em que a API é definida. Que
um projeto chamado `planner-dev` existe, e de quem ele é, é algo que só quem pergunta autenticado e com
papel nele pode saber; quem pergunta sem credencial só aprende que precisa entrar. A lição 24 volta ao
formato dessa resposta.
