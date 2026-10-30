---
title: Uma landing zone é uma assinatura que já começa certa
version: 1
---

**Uma landing zone não é um produto que se compra nem um botão no portal. É uma assinatura que chega
já governada**: posicionada no grupo de gerenciamento certo, debaixo das políticas certas, com
orçamento, logs, uma rede ligada à da empresa e os papéis de que a equipe precisa, antes de a equipe
implantar o primeiro recurso. A imagem errada é um template de máquina virtual. A certa é o terreno
com água, luz e regras de construção já no lugar.

O nome vem do **Cloud Adoption Framework** da Microsoft, o CAF, um conjunto grande de orientações
sobre como uma organização passa para o Azure. A parte *Ready* dele é sobre landing zones, e divide
uma em duas metades:

- **a platform landing zone**: o que é construído uma vez, por uma equipe central de plataforma, para
  todos. A árvore de grupos de gerenciamento, as políticas nela, a configuração de identidade, a rede
  hub que liga ao escritório, o workspace central de logs. A assinatura `shop-shared` da lição 2 é a
  semente de uma;
- **as workload landing zones**: uma ou mais assinaturas por aplicação, entregues à equipe que a
  opera, dentro das barreiras que a plataforma definiu. `shop-prod` e `shop-staging` são as da loja.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l05-platform-workload\" aria-label=\"Uma landing zone em duas metades. Em cima, a platform landing zone, construída uma vez pela equipe de plataforma: a árvore de grupos de gerenciamento e as políticas dela, identidade, a rede hub ligada ao escritório, e os logs centrais. Embaixo, duas workload landing zones, as assinaturas shop-prod e shop-staging, cada uma entregue à equipe da loja dentro das barreiras da plataforma.\"><defs><marker id=\"l05-platform-workload-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">platform landing zone: construída uma vez, para todos</text><rect x=\"40.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">árvore e políticas</text><rect x=\"205.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identidade</text><rect x=\"370.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rede hub</text><rect x=\"535.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">logs centrais</text><path d=\"M220.0 132.0 L220.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-platform-workload-af-ah-paper-dim)\"></path><rect x=\"110.0\" y=\"160.0\" width=\"220.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workload landing zone</text><text x=\"220.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-prod</text><path d=\"M500.0 132.0 L500.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-platform-workload-af-ah-paper-dim)\"></path><rect x=\"390.0\" y=\"160.0\" width=\"220.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workload landing zone</text><text x=\"500.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-staging</text></svg>", "caption": "A plataforma é decidida uma vez; cada carga de trabalho ganha uma assinatura que já chega dentro dela.", "same": ["workload landing zone"]}
```

## Oito coisas a decidir, com antecedência

O CAF lista **oito áreas de design**, as decisões que uma platform landing zone precisa ter
respondido:

| área de design | a pergunta | neste curso |
|---|---|---|
| cobrança e tenant do Entra | qual tenant, e quem paga | lições 2 e 13 |
| gestão de identidade e acesso | quem pode fazer o quê, e como prova | lições 6 a 12 |
| organização de recursos | grupos de gerenciamento, assinaturas, nomes, tags | lições 2, 3 e 15 |
| topologia de rede e conectividade | hub e spokes, o caminho até o escritório, DNS | lições 16 a 23 |
| segurança | proteções, detecção, as ferramentas centrais de segurança | lições 10 e 11 |
| gestão | logs, monitoramento, backups | além deste curso |
| governança | as políticas que mantêm tudo dentro das linhas | lição 4 |
| automação da plataforma e DevOps | a própria plataforma descrita em código | lições 25 e 26 |

**Essa tabela é a maior parte deste curso.** Uma landing zone não é um assunto à parte; é o lugar
onde todos os outros são decididos uma vez, juntos, e não por projeto e cada vez de um jeito.

## Venda de assinaturas

A segunda ideia que o CAF acrescenta é como uma carga de trabalho ganha a sua assinatura: a
**subscription vending**, um mecanismo da plataforma que emite uma assinatura nova sob pedido, já
posicionada no grupo de gerenciamento certo, com orçamento, rede e papéis. Um pedido, uma aprovação, e
um pipeline que faz o resto. **A ideia é que ninguém crie uma assinatura à mão**, porque uma
assinatura criada à mão começa debaixo do grupo raiz do tenant, governada por quase nada, até alguém
lembrar de movê-la.

Esse último detalhe é documentado e vale saber por si só: **uma assinatura nova é colocada debaixo do
grupo de gerenciamento raiz, a não ser que haja um padrão definido.** As configurações de hierarquia
do tenant deixam nomear um grupo de gerenciamento padrão para assinaturas novas, e o CAF recomenda um,
o grupo sandbox dele, para que uma assinatura criada fora do processo caia num lugar inofensivo e não
num lugar sem governo. Nada disso foi executado aqui: cada passo é um pedido ao Resource Manager ou ao
serviço de cobrança.

## Aceleradores, ou à mão

A Microsoft publica **aceleradores** para a platform landing zone, em Bicep e em Terraform, que
implantam o desenho de referência do CAF com as suas políticas. O próprio conselho do CAF é que a
maioria das organizações comece de um deles em vez de escrever o seu. Este curso faz o contrário de
propósito, pelo mesmo motivo que um mecânico aprende num motor sem a tampa. A próxima seção monta a
árvore à mão, pequena o bastante para ser lida. Um acelerador passa então a ser algo que você
reconhece em vez de algo em que confia.
