---
title: O workspace, e as duas metades em que ele se divide
version: 1
---

**O Azure Databricks é a plataforma Spark do Databricks, vendida e cobrada pelo Azure como um serviço
do Azure, e um workspace é onde tudo nela acontece.** Notebooks, jobs, clusters, SQL warehouses e o
catálogo de tabelas pertencem todos a um workspace, e um workspace é um recurso do Azure num grupo de
recursos, criado como qualquer outro. Esta seção e quase toda esta lição são ensinadas a partir da
documentação da Microsoft e do Databricks e não foram executadas; a terceira seção confere a
declaração de um workspace com o Terraform, offline.

## Dois planos

**Um workspace é dividido entre o lado do Databricks e o seu**, e saber em que metade uma coisa vive
responde à maioria das perguntas sobre segurança e custo:

- **o plano de controle** roda numa conta do Azure que o Databricks opera: a aplicação web, o texto
  dos notebooks, o agendador de jobs, o gestor de clusters e os metadados do catálogo. Você nunca vê as
  máquinas dele.
- **o plano de computação clássico** roda na sua assinatura: as máquinas virtuais de cada cluster, os
  discos e a rede delas. Os dados que os clusters leem ficam nas suas contas de armazenamento, e as
  máquinas que os leem são cobradas de você pelo Azure.
- **o plano de computação serverless** roda na conta do Databricks, na mesma região: computação que o
  Databricks liga e mantém quente para você, e cobra numa linha só, sem máquina sua por trás.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"Duas bordas tracejadas. À esquerda, a conta do Databricks no Azure guarda o plano de controle, com a aplicação web, o texto dos notebooks, o agendador de jobs, o gestor de clusters e os metadados do catálogo, e o plano de computação serverless, computação quente que o Databricks roda e cobra numa linha em DBUs. À direita, a sua assinatura guarda o plano de computação clássico, as máquinas dos clusters num grupo de recursos gerenciado ou em duas sub-redes da sua rede, cobradas pelo Azure mais DBUs, e a sua conta de armazenamento stquitandalakeprd, lida onde está por qualquer dos planos. As máquinas clássicas se conectam para fora, ao plano de controle.\" data-fig=\"l21-planes\"><defs><marker id=\"l21-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a conta do Databricks no Azure</text><rect x=\"40\" y=\"54\" width=\"290\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"185\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">plano de controle</text><text x=\"185\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">aplicação web, texto dos notebooks</text><text x=\"185\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agendador de jobs, gestor de clusters</text><text x=\"185\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">metadados do catálogo</text><rect x=\"40\" y=\"168\" width=\"290\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"185\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">plano de computação serverless</text><text x=\"185\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">computação quente que o Databricks roda</text><text x=\"185\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cobrada numa linha, em DBUs</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"382\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a sua assinatura</text><rect x=\"390\" y=\"54\" width=\"290\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"535\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">plano de computação clássico</text><text x=\"535\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">máquinas dos clusters, num grupo gerenciado</text><text x=\"535\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">ou em duas sub-redes da sua rede</text><text x=\"535\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cobradas pelo Azure, mais DBUs</text><rect x=\"390\" y=\"168\" width=\"290\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"/><text x=\"535\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o seu armazenamento</text><text x=\"535\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">stquitandalakeprd</text><text x=\"535\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lido onde está, por qualquer dos planos</text><line x1=\"535\" y1=\"150\" x2=\"535\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21-ah)\"/><line x1=\"330\" y1=\"210\" x2=\"388\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l21-ah)\"/><line x1=\"388\" y1=\"100\" x2=\"332\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\" marker-end=\"url(#l21-ah)\"/><text x=\"359\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">para fora</text></svg>", "caption": "Onde cada parte de um workspace roda. Os dados nunca vão para a conta do Databricks; o que muda entre clássico e serverless é de quem são as máquinas que os leem, e quem as cobra."}
```

**O plano de computação clássico vive num grupo de recursos gerenciado** que o workspace cria, com um
nome que você escolhe ou que o Azure inventa. Você vê as máquinas dele ali e não consegue mudá-las:
uma deny assignment impede qualquer pessoa, donos inclusive, de editar o que o Databricks gerencia. É
a primeira surpresa de um time novo no Databricks, e a certa, porque uma máquina que alguém
"consertou" à mão é um cluster que falha de um jeito que ninguém consegue explicar.

## A rede

**Por padrão um workspace cria a própria rede virtual dentro do grupo de recursos gerenciado.** Para
uma empresa que quer os clusters dentro da própria rede, ao lado de um endpoint privado da conta de
armazenamento, ou atrás do firewall dela, o Azure Databricks oferece a **VNet injection**: o workspace
recebe duas sub-redes de uma rede virtual sua, delegadas ao Databricks, e põe as máquinas dos clusters
nelas. Com a **secure cluster connectivity**, `no_public_ip` no Terraform, as máquinas não têm
endereço público nenhum, e abrem a conexão com o plano de controle para fora.

**A VNet injection é decidida quando o workspace é criado** e não pode ser acrescentada depois, e é
por isso que a próxima seção a declara desde o início. Duas sub-redes pequenas demais limitam quantas
máquinas o workspace vai poder rodar, e a documentação do Databricks tem uma tabela de tamanhos para
essa conta.

## Os tiers

Um workspace tem um tier de preço, que o Terraform chama de `sku`: `standard`, `premium` ou `trial`.
**O premium é o que esta lição assume**, porque o Unity Catalog, assunto da sexta seção, e os
controles de acesso mais finos sobre clusters, jobs e notebooks precisam dele. O tier muda o preço de
cada DBU, a unidade a que a quinta seção põe preço.
