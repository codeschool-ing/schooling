---
title: O que o Recommender propõe, e o que ele sabe
version: 1
---

**O Recommender do Google observa como os recursos são usados e propõe mudanças: um tipo de máquina menor, uma
máquina ociosa para parar, um disco que ninguém anexou, um endereço que ninguém usa.** Cada recomendação vem com a
janela de evidência, a mudança de custo esperada e um estado que você pode marcar como assumida, concluída ou
descartada. É gratuito, e acerta mais vezes que a intuição das pessoas sobre as próprias máquinas. Também é calculado
a partir do passado e não sabe nada da semana que vem. Nada nesta seção foi executado: o Recommender precisa de um
projeto com uso real. Ela é ensinada pela documentação do Google.

## Os recomendadores que importam para custo

| recomendador | o que propõe |
|---|---|
| `google.compute.instance.MachineTypeRecommender` | um tipo de máquina que caiba na CPU e na memória observadas |
| `google.compute.instance.IdleResourceRecommender` | parar ou apagar uma máquina quase sem atividade |
| `google.compute.disk.IdleResourceRecommender` | apagar um disco persistente que não está anexado a nada |
| `google.compute.address.IdleResourceRecommender` | liberar um IP estático que nada usa |
| `google.compute.commitment.UsageCommitmentRecommender` | o compromisso da lição 21 |

Listando um tipo, para a zona da loja:

```sh
gcloud recommender recommendations list \
  --project=planner-dev --location=southamerica-east1-a \
  --recommender=google.compute.instance.MachineTypeRecommender \
  --format='table(description, primaryImpact.costProjection.cost.units, stateInfo.state)'
```

Não executado. Cada linha diria algo como "Save cost by changing machine type from e2-standard-8 to e2-standard-4", a
mudança mensal projetada de custo (negativa é economia) e o estado, `ACTIVE` para uma em que ninguém agiu.

## O que ele observa, e o que não consegue

Uma recomendação de tipo de máquina olha **CPU e memória dos últimos oito dias**, e memória só se o Ops Agent estiver
instalado e relatando; sem o agente, o Recommender dimensiona só pela CPU e pode propor uma máquina pequena demais para
o que está na memória. Uma recomendação de máquina ociosa procura CPU e rede muito baixas numa janela parecida.

O que nenhum deles vê:

- **um job mensal**: a máquina ociosa por 29 dias e ocupada no dia 1º;
- **uma máquina mantida aquecida de propósito**, uma reserva que precisa estar pronta em segundos;
- **quem é o dono**, e se ele pretendia mantê-la.

Então uma recomendação é o começo de uma pergunta ao dono, nunca uma ação tomada sozinha. A próxima seção escreve a
regra à mão, para ver o que uma regra como a do Recommender decide e por quê.
