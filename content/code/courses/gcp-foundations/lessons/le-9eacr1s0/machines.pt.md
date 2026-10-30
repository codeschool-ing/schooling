---
title: Contas de serviço, e as que o Google cria para si
version: 1
---

**Um programa que chama uma API do Google precisa de uma identidade própria, e no Google Cloud essa
identidade é uma conta de serviço.** Ela é um principal como uma pessoa, escrito `serviceAccount:...`, e
é também um recurso, morando num projeto, com uma política do IAM própria dizendo quem pode usá-la. Essa
natureza dupla é a lição 8 inteira; aqui, os nomes.

| escrito como | o que é |
|---|---|
| `serviceAccount:reports@planner-dev.iam.gserviceaccount.com` | uma conta que você cria, no projeto `planner-dev` |
| `serviceAccount:415104041262-compute@developer.gserviceaccount.com` | a **conta padrão do Compute Engine**, criada junto com a API |
| `serviceAccount:service-415104041262@gcp-sa-pubsub.iam.gserviceaccount.com` | um **agente de serviço**: a identidade do próprio Pub/Sub, agindo dentro do seu projeto |

## As que você cria

Uma conta de serviço que você cria se chama `NOME@ID_DO_PROJETO.iam.gserviceaccount.com`, e o nome diz
para que ela serve: `reports`, `deployer`, `backup-job`. **Uma conta por workload** é a regra que faz todo
o resto funcionar: se o job de relatórios e o site dividem uma, um papel de que o job precisa é um papel
que o site tem, e o vazamento de qualquer um é o vazamento dos dois.

Uma conta de serviço **não tem senha**. Algo prova que é a conta de um de três jeitos, que as lições 8 e
9 tratam em sequência: o Google a empresta a uma máquina ou função a que ela está anexada, uma pessoa
com o papel certo a personifica por um tempo, ou um arquivo de chave baixado é apresentado. O terceiro é
o que este curso não para de chamar de último recurso.

## As que o Google cria

Dois tipos aparecem num projeto sem ninguém pedir, e os dois surpreendem quem lê uma política pela
primeira vez.

- **Contas de serviço padrão.** Habilitar o Compute Engine cria
  `NÚMERO_DO_PROJETO-compute@developer.gserviceaccount.com`, e toda máquina virtual criada sem nomear
  outra conta roda como ela. Em organizações mais antigas que as políticas seguras por padrão da lição
  4, ela recebia o papel **Editor** no projeto automaticamente, o que fazia de toda máquina um editor de
  tudo. A cura é a mesma nos dois casos: criar uma conta por workload e nomeá-la.
- **Agentes de serviço.** Quando o Pub/Sub entrega uma mensagem a um endpoint, ou o Cloud Build grava uma
  imagem, o serviço age no seu projeto com uma identidade própria, chamada
  `service-NÚMERO_DO_PROJETO@gcp-sa-SERVIÇO.iam.gserviceaccount.com`. O Google lhe concede o papel de
  que ela precisa, papéis de **Service Agent** como `roles/pubsub.serviceAgent`, quando a API é
  habilitada. Remover um quebra o serviço de jeitos que parecem um bug dele; deixe-os em paz, a não ser
  que a documentação daquele serviço diga outra coisa.

Os dois levam o **número do projeto**, não o id, que é o argumento da lição 2 sobre para quem é cada
identificador: são nomes que o Google fez, então usam o número do Google.

## Principals apagados

Um principal apagado continua nas políticas que o nomeavam, reescrito como
`deleted:serviceAccount:reports@planner-dev.iam.gserviceaccount.com?uid=104729...`. O `uid` está lá para
que uma conta nova, criada depois com o mesmo nome, **não herde os papéis da antiga**, que seria o jeito
de uma concessão velha voltar à vida. Uma política com entradas `deleted:` é uma que ninguém arrumou, e
arrumá-la é seguro.
