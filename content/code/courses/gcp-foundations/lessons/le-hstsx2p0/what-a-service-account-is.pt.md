---
title: Uma identidade que também é um recurso
version: 1
---

**Uma conta de serviço é duas coisas ao mesmo tempo: um principal que tem papéis, e um recurso em que
outros têm papéis.** A lição 5 viu a primeira metade: `serviceAccount:reports@planner-dev.iam.gserviceaccount.com`
pode receber `roles/pubsub.subscriber` como qualquer pessoa. Esta lição é sobre a segunda metade, que é
onde as contas de serviço ficam perigosas: **quem pode agir como ela?**

Ter um papel numa conta de serviço é como alguém, ou algo, passa a usar os papéis que a conta tem. Dois
papéis na conta decidem isso:

| papel na conta de serviço | o que quem o tem pode fazer |
|---|---|
| `roles/iam.serviceAccountUser` | **anexar** a conta a algo que cria: uma máquina virtual, uma função, um serviço do Cloud Run, que então roda como a conta |
| `roles/iam.serviceAccountTokenCreator` | **personificar** a conta: pedir ao Google um token de vida curta em nome dela, e fazer pedidos como ela |

**Qualquer um dos dois equivale a todo papel que a conta tem.** Um desenvolvedor sem papel nenhum na
produção, mas com `serviceAccountUser` numa conta de serviço da produção que tem Editor, consegue criar
uma máquina que roda como essa conta e fazer tudo que o Editor faz. É o jeito mais comum de um desenho
estreito de IAM vazar, e é por isso que uma revisão de quem tem o quê precisa ler as políticas das contas
de serviço, não só as dos projetos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l08-act-as\" aria-label=\"Como uma concessão estreita vaza. À esquerda, um desenvolvedor sem papel nenhum na produção. No meio, a conta de serviço prod-runner, que tem Editor no planner-prod. O desenvolvedor tem serviceAccountUser nessa conta, desenhado como uma seta até ela. Então o desenvolvedor consegue criar uma máquina que roda como prod-runner, e por ela fazer tudo que o Editor permite na produção, desenhado como uma seta tracejada do desenvolvedor, pela conta, até o projeto.\"><defs><marker id=\"l08-act-as-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-act-as-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um desenvolvedor</text><text x=\"100.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nenhum papel na produção</text><rect x=\"270.0\" y=\"80.0\" width=\"180.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">prod-runner@</text><text x=\"360.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma conta de serviço</text><rect x=\"540.0\" y=\"70.0\" width=\"160.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"620.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-prod</text><text x=\"620.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tudo que o Editor</text><text x=\"620.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pode fazer</text><path d=\"M182.0 115.0 L266.0 115.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l08-act-as-af-ah-amber)\"></path><text x=\"224.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--amber)\">serviceAccountUser</text><path d=\"M452.0 115.0 L536.0 115.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#l08-act-as-af-ah-phosphor)\"></path><text x=\"494.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">roles/editor</text><path d=\"M100 152 C 100 220, 620 220, 620 164\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l08-act-as-af-ah-amber)\"></path><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">agir como a conta é ter todo papel que ela tem</text><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leia as políticas das contas de serviço, não só as dos projetos</text></svg>", "caption": "Um papel numa conta de serviço é um caminho para todo papel que a conta tem."}
```

## Conceda na conta, não no projeto

Os dois papéis podem ser concedidos num projeto, onde valem para **toda** conta de serviço dele, ou numa
conta de serviço. A concessão no projeto inteiro é a que vaza: alguém que recebeu `serviceAccountUser` no
projeto para fazer o deploy de uma função agora pode rodar qualquer coisa como qualquer conta do projeto,
a conta padrão do Compute Engine com Editor inclusive. A concessão fica na conta de que o trabalho
precisa, que os recursos autoritativos ou aditivos da lição 7 escrevem como
`google_service_account_iam_member`.

## Contas anexadas, e de onde vem o token

Quando uma máquina ou um serviço do Cloud Run roda como uma conta anexada, **nenhuma chave existe em
lugar nenhum**. O código na máquina pede um token ao **servidor de metadados**, um endereço que só a
máquina alcança, `169.254.169.254`, e o Google devolve um que dura cerca de uma hora e é renovado sob
demanda. As bibliotecas cliente da lição 24 fazem isso sozinhas; a aplicação nunca vê uma credencial para
vazar, guardar ou girar. É o arranjo a buscar onde quer que o código rode dentro do Google Cloud, e o
`gcp-compute` o usa em toda máquina que monta.

Nada nesta seção rodou: anexar uma conta exige o Compute Engine ou o Cloud Run, que o laboratório não
responde. A próxima seção consegue mostrar a personificação, porque a primeira coisa que ela faz é pedir
um token ao Google, e o Google responde.
