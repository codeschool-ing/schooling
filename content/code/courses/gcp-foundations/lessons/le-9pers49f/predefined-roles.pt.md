---
title: Papéis predefinidos, um serviço de cada vez
version: 1
---

**Um papel predefinido é um conjunto de permissões que o Google define para um serviço e um tipo de
trabalho, e mantém atualizado.** O Pub/Sub tem um punhado deles, e eles mostram o padrão que todo serviço
segue:

| papel | o que quem o tem faz |
|---|---|
| `roles/pubsub.viewer` | lista e lê tópicos e assinaturas |
| `roles/pubsub.publisher` | publica mensagens em tópicos, e mais nada |
| `roles/pubsub.subscriber` | consome mensagens de assinaturas |
| `roles/pubsub.editor` | cria, muda e apaga tópicos e assinaturas |
| `roles/pubsub.admin` | tudo acima, mais gerenciar quem pode usá-los |

O padrão é **viewer, alguns papéis de trabalho, editor, admin**, e quase todo serviço do Google Cloud tem
a mesma escada com o próprio nome no meio: `roles/compute.instanceAdmin.v1`, `roles/storage.objectViewer`,
`roles/cloudsql.client`. Os papéis de trabalho do meio são os de que um workload precisa. O serviço de
pedidos do planner publica no `orders` e tem `roles/pubsub.publisher`; o worker que processa os pedidos
os consome e tem `roles/pubsub.subscriber`; nenhum dos dois cria nem apaga tópico, que é trabalho do
Terraform que os define.

## Conceder no menor recurso que funcione

Um papel pode ser concedido na organização, numa pasta, num projeto, ou, em muitos serviços, num único
recurso. O `roles/pubsub.publisher` concedido no projeto deixa quem o tem publicar em todo tópico dele;
concedido no tópico `orders`, só no `orders`. **Quanto menor o recurso, menor o erro**, e o recurso certo
é o menor de que o trabalho precisa:

- num **recurso**, quando o trabalho toca uma coisa: um serviço que publica num tópico;
- num **projeto**, quando o trabalho cobre o que o projeto guarda: um deployer que atualiza todo serviço;
- numa **pasta**, quando o trabalho cobre projetos: uma equipe de segurança que lê todo projeto da
  produção.

Uma concessão alta na árvore alcança tudo abaixo dela, o argumento da lição 2, e é exatamente por isso
que uma concessão na organização é a que se olha duas vezes.

## Achar o papel de uma permissão

A pergunta que aparece toda semana é a inversa: um pedido foi recusado por faltar
`pubsub.topics.publish`, então que papel a tem? O Google publica a lista completa de papéis e das suas
permissões na documentação, e `gcloud iam roles describe roles/pubsub.publisher` imprime as permissões de
um papel. Esse comando pergunta à API do IAM, que o laboratório não responde, então **ele não foi rodado
aqui**; a tabela acima vem da documentação do Google sobre o controle de acesso do Pub/Sub.

Duas coisas nessa documentação valem saber antes de lê-la. Alguns papéis têm um **estágio de
lançamento**, `BETA` ou `ALPHA`, e podem mudar sem aviso; concessões em produção deveriam usar papéis
marcados `GA`. E as permissões de um papel mudam com o tempo à medida que o Google acrescenta recursos,
**sempre por adição**: um papel predefinido concedido hoje pode permitir amanhã algo que não permitia
quando foi concedido. Essa é a troca de que trata a última seção desta lição.
