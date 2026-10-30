---
title: O que o inventário registra
version: 1
---

**O Cloud Asset Inventory é o próprio registro do Google do que existe num ambiente**: todo recurso, com os
metadados dele, e toda política sobre ele, na organização, nas pastas e nos projetos, mantido em dia pelo Google
conforme as coisas mudam. É a resposta a uma pergunta que nenhuma outra ferramenta deste curso responde bem: *o
que de fato está lá?* O Terraform sabe o que fez, o gcloud lista um tipo de coisa num projeto de cada vez, e o
console mostra aquilo em que alguém clica. O inventário vê tudo isso do topo da árvore da lição 2.

Ele registra quatro tipos de coisa, e cada um é uma busca própria:

| conteúdo | o que é | uma pergunta de exemplo |
|---|---|---|
| **recursos** | todo recurso e os metadados dele: tipo, nome, localização, rótulos, estado, data de criação | que tópicos não têm rótulo `team`? |
| **políticas do IAM** | as políticas de permissão em todo nó e recurso, lição 7 | onde `roles/owner` é concedido, e a quem? |
| **políticas da organização** | as restrições em vigor, lição 4 | que projetos permitem endereços IP externos? |
| **relações e histórico** | como os recursos se ligam, e como cada um mudou nas últimas cinco semanas | quem mudou esta regra de firewall na terça passada? |

Todo recurso tem um **tipo**, escrito como o serviço e a espécie: `pubsub.googleapis.com/Topic`,
`compute.googleapis.com/Firewall`, `cloudresourcemanager.googleapis.com/Project`. As buscas nomeiam tipos do
mesmo jeito, e é assim que uma consulta cobre os tópicos de todos os projetos de uma vez.

## Os comandos do gcloud para ele

```
ana@laptop:~/gcp$ gcloud asset --help | sed -n "/^GROUPS/,/^NOTES/p" | grep -E "^     [a-z]"
     feeds
     operations
     saved-queries
     analyze-iam-policy
     analyze-iam-policy-longrunning
     analyze-move
     analyze-org-policies
     analyze-org-policy-governed-assets
     analyze-org-policy-governed-containers
     export
     get-effective-iam-policy
     get-history
     list
     query
     search-all-iam-policies
     search-all-resources
```

Três grupos e os comandos. Os que esta lição usa são **`search-all-resources`** e **`search-all-iam-policies`**,
que respondem perguntas sobre uma organização inteira em segundos. O `export` escreve um retrato completo no Cloud
Storage ou no BigQuery, para perguntas grandes demais para uma busca. O `get-history` devolve os estados passados
de um recurso. E os **feeds** publicam toda mudança num tópico do Pub/Sub, que é a maquinaria da lição 12
apontada para o ambiente em vez da fatura.

Ler o inventário exige um papel onde a busca começa: `roles/cloudasset.viewer` na organização lê tudo, e o mesmo
papel numa pasta lê aquele galho. O planner dá esse papel à equipe de segurança e à conta de serviço da equipe de
plataforma que roda as verificações noturnas da última seção.
