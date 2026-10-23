---
title: Fronteiras, e o que desce por elas
version: 1
---

**Os três provedores vendem os mesmos tipos de bloco, e as aulas 3 e 7 do curso `cloud` já
traduziram os nomes deles. O que quem defende precisa, além disso, é saber onde cada um
desenha as suas fronteiras e o que desce de um nível para o seguinte: é isso que decide até onde
chega uma concessão ou uma proteção.** Nada nesta aula foi executado além da metade AWS
da última seção: não há Azure nem Google Cloud neste laboratório, e toda afirmação sobre eles vem da
documentação deles.

A imagem errada é a de que a tabela de tradução é a história inteira: uma conta é uma assinatura é um
projeto, uma política é uma atribuição de papel é um binding, e um controle escrito uma vez se traduz
palavra por palavra. As palavras se traduzem. **O alcance não.**

## A unidade de isolamento

Cada provedor tem um contêiner que guarda recursos, carrega uma fatura e é a linha habitual entre uma
equipe ou um ambiente e o seguinte:

| | AWS | Azure | Google Cloud |
|---|---|---|---|
| o contêiner | uma **conta** | uma **assinatura**, com **grupos de recursos** dentro | um **projeto** |
| contêineres agrupados por | unidades organizacionais (OUs) numa organização | grupos de gerenciamento num tenant | pastas numa organização |
| onde as identidades moram | em cada conta (IAM), ou centralmente no IAM Identity Center | no **Microsoft Entra ID** do tenant, compartilhado por todas as assinaturas | no Cloud Identity ou no Google Workspace, compartilhado por todos os projetos |
| uma proteção sobre um ramo inteiro | políticas de controle de serviço (SCPs) e políticas de controle de recursos | atribuições do **Azure Policy** com efeito `Deny` | restrições do **Organization Policy** |

Leia a terceira linha duas vezes. Uma conta AWS guarda os próprios usuários e papéis do IAM, e
alcançar outra conta exige uma concessão dos dois lados. **Uma assinatura do Azure e um projeto do
Google Cloud não têm identidades próprias**: as pessoas e os programas pertencem ao tenant ou à
organização, e uma assinatura ou um projeto é um lugar onde eles recebem papéis. Isso não é uma
fraqueza; é outro formato, e quer dizer que a pergunta "quem mexe neste projeto" começa num diretório
que atende também a todos os outros projetos.

## O que desce

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 375\" role=\"img\" data-fig=\"l05-hierarchy\" aria-label=\"As três hierarquias lado a lado, de cima para baixo. AWS: uma organização, unidades organizacionais, contas, recursos; a conta de gerenciamento fica à parte no topo. Azure: um tenant com o grupo de gerenciamento raiz, grupos de gerenciamento, assinaturas, grupos de recursos, recursos. Google Cloud: uma organização, pastas, projetos, recursos. As proteções descem nos três: SCPs, Azure Policy e Organization Policy. As concessões descem no Azure e no Google Cloud, onde um papel dado no alto alcança tudo abaixo dele. Na AWS uma política de identidade fica dentro da própria conta, e uma SCP nunca se aplica à conta de gerenciamento.\"><defs><marker id=\"l05-hierarchy-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-hierarchy-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">AWS</text><rect x=\"50.0\" y=\"48.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">organização</text><rect x=\"60.0\" y=\"94.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OU</text><rect x=\"70.0\" y=\"140.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conta</text><rect x=\"80.0\" y=\"186.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recurso</text><path d=\"M32.0 52.0 L32.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-amber)\"></path><text x=\"24.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">SCPs</text><text x=\"24.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">descem</text><path d=\"M42.0 144.0 L42.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-phosphor)\"></path><text x=\"24.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">concessões ficam na conta</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Azure</text><rect x=\"290.0\" y=\"48.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tenant, grupo raiz</text><rect x=\"300.0\" y=\"94.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">grupo de gerenciamento</text><rect x=\"310.0\" y=\"140.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">assinatura</text><rect x=\"320.0\" y=\"186.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">grupo de recursos</text><rect x=\"330.0\" y=\"232.0\" width=\"130.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recurso</text><path d=\"M272.0 52.0 L272.0 266.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-amber)\"></path><text x=\"264.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">Azure Policy</text><text x=\"264.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">descem</text><path d=\"M282.0 52.0 L282.0 266.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-phosphor)\"></path><text x=\"264.0\" y=\"318.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">atribuições de papel descem</text><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Google Cloud</text><rect x=\"530.0\" y=\"48.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">organização</text><rect x=\"540.0\" y=\"94.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pasta</text><rect x=\"550.0\" y=\"140.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">projeto</text><rect x=\"560.0\" y=\"186.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recurso</text><path d=\"M512.0 52.0 L512.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-amber)\"></path><text x=\"504.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">Organization Policy</text><text x=\"504.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">descem</text><path d=\"M522.0 52.0 L522.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-phosphor)\"></path><text x=\"504.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">políticas de permissão descem</text><rect x=\"36.0\" y=\"330.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"126.0\" y=\"345.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">conta de gerenciamento: sem SCP</text></svg>", "caption": "As proteções descem nos três. As concessões descem em dois deles, e é por isso que um papel dado no alto por conveniência alcança tudo abaixo dele.", "same": ["AWS", "Azure", "Azure Policy", "Google Cloud", "Organization Policy"]}
```

**No Google Cloud e no Azure, uma concessão desce.** Um papel dado numa pasta vale para todo projeto
dentro dela e todo recurso dentro deles; uma atribuição de papel num grupo de gerenciamento vale para
toda assinatura abaixo dele. Uma concessão feita no alto "por conveniência" é uma concessão sobre
tudo, inclusive os projetos criados no ano que vem. Então **a resposta para "quem lê este bucket" se
junta subindo a hierarquia**: o bucket, o projeto dele, cada pasta acima, a organização.

**Na AWS, concessões não descem pela organização.** Uma política de identidade mora numa conta e fala
por aquela conta. O que desce numa organização da AWS é a proteção: uma SCP anexada a uma OU limita
toda conta abaixo dela, e não concede nada. Uma exceção importa na prática: **uma SCP nunca se aplica
à conta de gerenciamento da organização**, então a conta que administra a organização não deve
abrigar workload nenhum.

As proteções descem nos três, e é isso que as torna proteções: o Azure Policy atribuído a um grupo de
gerenciamento e uma restrição do Organization Policy definida numa pasta alcançam tudo abaixo, do
mesmo jeito que uma SCP.

## O que a clínica conferiria

A clínica tem hoje uma única conta AWS, e os relatórios da bia moram num projeto do Google Cloud
(aula 4). As perguntas de quem defende são as mesmas dos dois lados e são respondidas em lugares
diferentes:

- **quem pode agir aqui?** Na AWS, o IAM da conta, mais qualquer papel que outra conta possa assumir
  nela. No Google Cloud, a política de permissão do projeto e toda política de pasta e de organização
  acima dele;
- **o que nunca pode acontecer aqui, seja lá o que for concedido?** Na AWS, as SCPs da conta e das
  OUs dela. No Google Cloud, as restrições do Organization Policy em vigor no projeto;
- **quem poderia mudar essas respostas?** Quem tem o topo da organização: a conta de gerenciamento da
  AWS, os administradores da organização do Google Cloud, o grupo de gerenciamento raiz do Azure.
