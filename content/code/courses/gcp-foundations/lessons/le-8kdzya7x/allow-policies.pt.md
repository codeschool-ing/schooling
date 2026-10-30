---
title: Uma política de permissão, lida de cima a baixo
version: 1
---

**Todo recurso que aceita concessões leva uma política de permissão, e a política é uma lista de
vinculações.** Uma vinculação (binding) junta um papel aos principals que o têm, e pode levar uma
condição. Essa é a estrutura de dados inteira, e ler uma é a primeira habilidade de IAM que vale ter.
Assim é a política de um projeto no formato documentado pelo Google, escrita para este curso em vez de
lida de um projeto:

```json
{
  "version": 3,
  "etag": "BwYdKxXQ0aU=",
  "bindings": [
    {
      "role": "roles/pubsub.publisher",
      "members": [
        "serviceAccount:orders@planner-dev.iam.gserviceaccount.com"
      ]
    },
    {
      "role": "roles/viewer",
      "members": [
        "group:planner-devs@example.com",
        "user:ana@example.com"
      ]
    },
    {
      "role": "roles/pubsub.editor",
      "members": [
        "group:planner-oncall@example.com"
      ],
      "condition": {
        "title": "during the incident",
        "expression": "request.time < timestamp('2026-11-01T00:00:00Z')"
      }
    }
  ]
}
```

| campo | o que diz |
|---|---|
| `bindings` | uma entrada por papel; um papel aparece uma vez, com todo principal que o tem |
| `members` | os principals da lição 5, cada um com o seu prefixo |
| `condition` | quando a vinculação vale: aqui, o grupo de plantão tem Editor do Pub/Sub até 1º de novembro |
| `version` | `3` quando alguma vinculação tem condição; um cliente que manda a versão 1 descarta as condições em silêncio |
| `etag` | a versão da política em que esta cópia foi lida, de que trata o próximo parágrafo |

## Ler, mudar, gravar, e o etag

**Uma política é mudada substituindo-a inteira.** Não existe chamada de API que acrescente um membro; um
cliente lê a política, acrescenta o membro à sua cópia, e grava a cópia de volta. O
`gcloud ... add-iam-policy-binding` faz exatamente isso num comando, e o laboratório mostra a primeira
metade. O emulador responde pelo Pub/Sub mas não pelo IAM, e diz isso:

```
ana@laptop:~/gcp$ gcloud pubsub topics create orders
Created topic [projects/planner-dev/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics get-iam-policy orders
ERROR: (gcloud.pubsub.topics.get-iam-policy) HttpError accessing <http://localhost:8085/v1/projects/planner-dev/topics/orders:getIamPolicy?alt=json>: response: <{'content-type': 'application/json', 'content-length': '47', 'status': 501}>, content <{"error":{"code":501,"status":"UNIMPLEMENTED"}}>
This may be due to network connectivity issues. Please check your network settings, and the status of the service you are trying to reach.
ana@laptop:~/gcp$ gcloud pubsub topics add-iam-policy-binding orders --member=group:planner-devs@example.com --role=roles/pubsub.publisher
ERROR: (gcloud.pubsub.topics.add-iam-policy-binding) HttpError accessing <http://localhost:8085/v1/projects/planner-dev/topics/orders:getIamPolicy?alt=json>: response: <{'content-type': 'application/json', 'content-length': '47', 'status': 501}>, content <{"error":{"code":501,"status":"UNIMPLEMENTED"}}>
This may be due to network connectivity issues. Please check your network settings, and the status of the service you are trying to reach.
```

**Os dois comandos falharam no `getIamPolicy`**, a leitura, com `501 UNIMPLEMENTED`: a palavra do próprio
emulador para um método que ele não tem. O segundo comando mostra a ordem das operações, porque é uma
gravação que começou lendo. A frase sobre conectividade de rede é a CLI chutando; a causa é a que o
banner do emulador deu na lição 1, `IAM integration is disabled`.

O `etag` é o que torna seguro o ler-mudar-gravar. Duas pessoas leem a política no mesmo `etag`, cada uma
acrescenta um membro, cada uma grava de volta. Sem o etag, a segunda gravação substituiria a mudança da
primeira sem ninguém perceber. Com ele, **o Google recusa uma gravação cujo etag não é mais o atual**, e
o cliente da segunda pessoa lê de novo e tenta outra vez. Um script que monta uma política à mão e deixa o
etag de fora perde essa proteção, e pode remover as concessões que outra pessoa acrescentou um segundo
antes.

## Condições

A condição de uma vinculação é escrita em **CEL**, a Common Expression Language, e pode testar a hora do
pedido, o nome e o tipo do recurso, e as tags do Resource Manager da lição 3. Dois usos aparecem em todo
ambiente: uma **concessão temporária**, como a do plantão acima, que termina sozinha sem ninguém lembrar
de removê-la; e uma **concessão em parte de um projeto**, como editor do Pub/Sub só em tópicos cujo nome
começa com `projects/planner-dev/topics/reports-`. Uma concessão que expira é o jeito mais barato de dar
acesso a alguém durante um incidente e ter certeza de que ele termina.

Nada nesta seção veio do Google: a política acima é um arquivo no formato do Google, e a única resposta
de IAM do laboratório é a recusa do emulador.
