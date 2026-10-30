---
title: Como a revisão funciona, e quanto tempo leva
version: 1
---

**A revisão de uma loja é uma checagem de que o seu release faz o que a ficha diz e não quebra
nenhuma regra da loja, feita antes que o release chegue a alguém.** Ela não é um teste de
qualidade do app, e passar nela não diz nada sobre o app ser bom. Ela decide quando as pessoas o
recebem, então entra no plano de release como qualquer outro passo com duração. *Lido nas páginas
de App Review da Apple, outubro de 2026, e na Central de Ajuda do Play Console como publicada em
2025; não rodado.*

## Apple

Todo app novo e toda atualização são revisados, e a Apple diz que **o App Review costuma revisar
pelo menos metade dos envios em menos de 24 horas e 90% em menos de 48 horas.** Uma pessoa instala o
build, faz login com a conta que você fornece e percorre o app com as diretrizes ao lado. Uma
versão pode ser enviada, aprovada e então liberada à mão ou automaticamente; aprovação e liberação
são passos separados, e é isso que deixa uma equipe aprovar na quinta e liberar na segunda.

**Uma revisão acelerada** pode ser pedida para a correção de um bug crítico ou para um evento com
data marcada. A Apple pede os passos para reproduzir o bug, e concede a seu critério. É um favor, e
uma equipe que pede um todo mês para de recebê-los.

## Google

O Google Play revisa apps novos e atualizações com uma mistura de checagens automáticas e
pessoas. A ajuda dele em 2025 avisava que **uma revisão pode levar até sete dias, e mais em alguns
casos**, principalmente num app novo ou numa conta de desenvolvedor nova; a maioria das atualizações
de apps estabelecidos passa bem mais rápido. O Google também confere a ficha, as respostas de
Segurança dos dados e as permissões declaradas, então uma mudança em qualquer uma delas também é
revisada.

A **publicação gerenciada** é a versão do Google para a liberação manual da Apple: as mudanças são
revisadas e depois ficam paradas até você apertar publicar, e o tempo de revisão deixa de decidir
a hora do lançamento.

## O que o relógio significa para um release

| o que você planeja | quanto reservar |
|---|---|
| uma atualização comum, Apple | dois dias de revisão antes do dia em que você a quer no ar |
| uma atualização comum, Google | alguns dias, mais para um app ou uma conta novos |
| um lançamento em data marcada | enviar uma semana antes, aprovar e liberar à mão no dia |
| a correção de um crash em produção | primeiro uma liberação em etapas interrompida, lição 8, depois um pedido de aceleração |

**O relógio da revisão corre de novo a cada envio**, inclusive o que corrige uma recusa. Um release
recusado duas vezes antes de passar custou três revisões, e é por isso que as próximas seções
tratam de não ser recusado, e não de ser recusado rápido.
