---
title: Permissões, papéis, e os três papéis grandes demais
version: 1
---

**Uma permissão é uma coisa que uma API deixa você fazer; um papel é um conjunto de permissões com
nome; e só um papel pode ser concedido.** Essa última parte é a regra que as pessoas tentam quebrar
primeiro. Não há como conceder `pubsub.topics.publish` sozinha a ninguém; ela tem de chegar dentro de um
papel, e a escolha de qual papel é todo o ofício do IAM.

Uma permissão se escreve `serviço.recurso.verbo`, e lê-la em voz alta diz o que ela faz:

| permissão | o que permite |
|---|---|
| `pubsub.topics.publish` | publicar uma mensagem num tópico |
| `pubsub.topics.create` | criar um tópico |
| `resourcemanager.projects.delete` | apagar um projeto |
| `iam.serviceAccounts.actAs` | rodar algo como uma conta de serviço, lição 8 |

Um papel se escreve `roles/NOME`, e uma concessão junta três coisas: **um principal, um papel, e o
recurso em que ele é concedido**. `group:planner-devs` com `roles/pubsub.publisher` no tópico `orders`
pode publicar no `orders` e em nenhum outro tópico.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l06-chain\" aria-label=\"Como uma concessão se monta, da esquerda para a direita. Permissões, como pubsub.topics.publish, são reunidas num papel, roles/pubsub.publisher. Uma concessão liga esse papel a um principal, group:planner-devs, e ao recurso em que é concedido, o tópico orders. Embaixo, uma nota: uma permissão nunca pode ser concedida sozinha, só dentro de um papel.\"><defs><marker id=\"l06-chain-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">permissões</text><rect x=\"32.0\" y=\"64.0\" width=\"166.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pubsub.topics.publish</text><rect x=\"32.0\" y=\"104.0\" width=\"166.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">pubsub.topics.get</text><path d=\"M212.0 95.0 L256.0 95.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-chain-af-ah-paper)\"></path><rect x=\"260.0\" y=\"66.0\" width=\"180.0\" height=\"58.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"350.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um papel</text><text x=\"350.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">roles/pubsub.publisher</text><path d=\"M442.0 95.0 L486.0 95.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-chain-af-ah-paper)\"></path><rect x=\"490.0\" y=\"20.0\" width=\"210.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"595.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">uma concessão</text><text x=\"595.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quem</text><text x=\"595.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">group:planner-devs</text><text x=\"595.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">que papel</text><text x=\"595.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">roles/pubsub.publisher</text><text x=\"595.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em quê</text><text x=\"595.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">topics/orders</text><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma permissão nunca é concedida sozinha, só dentro de um papel</text></svg>", "caption": "Permissões formam um papel; uma concessão liga o papel a um principal, num recurso."}
```

## Owner, Editor e Viewer

Três papéis são mais antigos que todo o resto do Google Cloud e continuam sendo os primeiros que as
pessoas encontram. O Google os chama de **papéis básicos**:

- **Viewer**, `roles/viewer`, lê quase tudo no projeto;
- **Editor**, `roles/editor`, muda quase tudo: cria e apaga máquinas, redes, bancos de dados, tópicos,
  em todo serviço que o projeto tem habilitado;
- **Owner**, `roles/owner`, é o Editor mais o gerenciamento do próprio IAM: pode conceder qualquer papel
  a qualquer um, o Owner inclusive.

**Os três são grandes demais para quase todo trabalho**, e a própria documentação do Google diz para
evitá-los em produção. O motivo é o que eles contêm. O Editor tem as permissões de milhares de ações em
centenas de serviços, e ele cresce: todo serviço novo que o Google lança acrescenta as suas permissões
ao Editor. Um papel concedido para "fazer deploy do site" que também deixa quem o tem apagar o banco de
dados é um papel que alguém um dia vai usar para a segunda coisa por acidente. O Viewer tem uma versão
mais discreta do mesmo problema: ele lê coisas que não são para todo mundo que pode olhar um projeto,
como a configuração de todo serviço nele.

O Owner merece uma frase só dele. **Quem tem Owner pode se tornar qualquer coisa**, porque conceder
papéis faz parte dele. O número de owners de um projeto de produção é o número de pessoas que podem
tomá-lo, e uma boa resposta é dois, por meio de um grupo, usados raramente.

## O que conceder em vez disso

A resposta são os **papéis predefinidos** da próxima seção: papéis que o Google define por serviço, do
tamanho de um trabalho. Os papéis básicos guardam dois usos honestos: Viewer para uma pessoa explorando
um projeto sandbox, e Owner num projeto que existe para ser jogado fora. Tudo que roda em produção
recebe papéis predefinidos, ou personalizados feitos das mesmas permissões.
