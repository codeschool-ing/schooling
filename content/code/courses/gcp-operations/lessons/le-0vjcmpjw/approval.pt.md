---
title: Barreiras de aprovação, rollback e quem pode promover
version: 1
---

**Um alvo com `requireApproval: true` não faz deploy de um release promovido até que uma pessoa o
aprove.** A promoção cria um rollout no estado `PENDING_APPROVAL`, o Cloud Deploy publica uma mensagem
dizendo isso, e o rollout espera. Aprovar ou rejeitar é uma permissão separada de promover, e essa
separação é a barreira. Nada aqui pôde rodar no seu computador; é ensinado pela documentação do Google,
e os comandos não foram executados.

## Promover, depois aprovar

```sh
gcloud deploy releases promote --release=rel-a1b2c3d \
  --delivery-pipeline=shop-api --region=southamerica-east1 --to-target=prod
gcloud deploy rollouts approve rel-a1b2c3d-to-prod-0001 \
  --release=rel-a1b2c3d --delivery-pipeline=shop-api --region=southamerica-east1
```

Os dois comandos precisam de dois papéis diferentes. `roles/clouddeploy.releaser` pode criar releases e
promovê-los; `roles/clouddeploy.approver` pode aprovar ou rejeitar rollouts. **Quem tem os dois pode
aprovar a própria promoção**, o que é uma barreira com uma pessoa só dos dois lados. Num time de duas
pessoas, como o desta plataforma, isso às vezes é inevitável; o que o registro mostra então é quem fez e
quando, o que ainda é mais do que um deploy a partir de um laptop mostra.

Uma aprovação é um julgamento sobre evidências, então as evidências devem existir antes de alguém ser
consultado: o release rodou em `dev`, os testes da lição 1 passaram no build dele, e a varredura da lição
2 não tem achado crítico corrigível no digest dele. Uma aprovação pedida antes disso existir é uma
assinatura numa página em branco.

## Rollback é uma promoção para trás

Fazer rollback de `prod` implanta o release que rodava ali antes, que já existe, renderizado e fixado por
digest:

```sh
gcloud deploy targets rollback prod --delivery-pipeline=shop-api --region=southamerica-east1
```

Ele cria um rollout novo do release anterior para `prod`. **Nada é reconstruído**, então o rollback não
pode falhar porque uma ferramenta de build mudou durante a noite, e ele cai exatamente na imagem que
rodava antes. Ele também passa pela barreira: um rollback para um alvo com `requireApproval` espera uma
aprovação como qualquer outro rollout, o que vale saber antes da noite em que for preciso.

## Canário, em resumo

Um stage também pode dizer como fazer o deploy, não só onde. Com a estratégia de canário, um alvo do
Cloud Run move uma parte do tráfego para a revisão nova em passos que você lista, `percentages: [10, 50]`,
e pausa depois de cada um até o rollout avançar. A lição 9 de `gcp-compute` trata da divisão de tráfego
em si; o que o Cloud Deploy acrescenta é a ordem, as pausas, e a mesma aprovação e o mesmo rollback em
volta delas.

| palavra do Cloud Deploy | o que é |
|---|---|
| delivery pipeline | a lista ordenada de stages |
| target (alvo) | um lugar para deploy: uma região do Cloud Run, um cluster do GKE |
| release | os manifestos para cada alvo, renderizados uma vez, imagens por digest |
| rollout | um release indo para um alvo |
| promoção | criar o rollout para o alvo seguinte |
