---
title: Pessoas, grupos e as duas palavras que querem dizer todo mundo
version: 1
---

**Um principal é a quem um papel é concedido.** O IAM do Google Cloud nunca concede nada a uma senha, a
um notebook ou a um endereço; ele concede um papel a um principal, num recurso, e o principal é escrito
com um prefixo e um identificador. O prefixo é a parte que as pessoas esquecem, e é a parte que diz que
tipo de coisa está recebendo confiança.

| escrito como | o que é |
|---|---|
| `user:ana@example.com` | uma conta Google: uma pessoa, logada |
| `group:planner-devs@example.com` | um grupo do Google, e todo mundo nele no momento do pedido |
| `domain:example.com` | toda conta de um domínio do Cloud Identity ou do Workspace |
| `allAuthenticatedUsers` | qualquer um logado em qualquer conta Google, em qualquer lugar |
| `allUsers` | qualquer um, logado ou não |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l05-principals\" aria-label=\"De onde vem cada tipo de principal, em três colunas. Do diretório Google da empresa, Cloud Identity ou Workspace: user, group e domain. Feitos no Google Cloud: contas de serviço que você cria, contas de serviço padrão e agentes de serviço. Do diretório de outra pessoa, por federação: principal e principalSet, de um pool de workforce para pessoas ou de um pool de workload para programas. Embaixo das três, uma regra: um papel é concedido a qualquer um deles do mesmo jeito, num recurso. À parte, os dois que querem dizer todo mundo: allAuthenticatedUsers e allUsers.\"><defs><marker id=\"l05-principals-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o diretório Google</text><rect x=\"40.0\" y=\"60.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">user:</text><rect x=\"40.0\" y=\"98.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">group:</text><rect x=\"40.0\" y=\"136.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">domain:</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">feitos no Google Cloud</text><rect x=\"280.0\" y=\"60.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">serviceAccount:</text><rect x=\"280.0\" y=\"98.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">contas padrão</text><rect x=\"280.0\" y=\"136.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">agentes de serviço</text><rect x=\"500.0\" y=\"20.0\" width=\"200.0\" height=\"160.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">outro diretório</text><rect x=\"520.0\" y=\"60.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">principal://</text><rect x=\"520.0\" y=\"98.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">principalSet://</text><rect x=\"520.0\" y=\"136.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">workforce / workload</text><path d=\"M120.0 182.0 L120.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-principals-af-ah-paper-dim)\"></path><path d=\"M360.0 182.0 L360.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-principals-af-ah-paper-dim)\"></path><path d=\"M600.0 182.0 L600.0 206.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-principals-af-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"208.0\" width=\"680.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um papel é concedido a qualquer um deles do mesmo jeito, num recurso</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">à parte: allAuthenticatedUsers e allUsers, que querem dizer todo mundo</text></svg>", "caption": "Três origens, um jeito só de conceder.", "same": ["workforce / workload"]}
```

## Uma pessoa é uma conta, e a conta pertence a outro

`user:` nomeia uma **conta Google**, e o Google Cloud não é o dono dela. A conta mora no Cloud Identity ou
no Google Workspace, para o pessoal da própria empresa, o assunto da lição 10, ou é um Gmail pessoal para
todo o resto. O Google Cloud só confia que quem entra como `ana@example.com` é a pessoa que o diretório
diz; se o diretório suspende a conta, todo papel concedido a ela para de funcionar na hora, sem ninguém
mexer no IAM.

Isso faz do **diretório parte da segurança de todo projeto**, e é por isso que uma empresa concede papéis
às contas do próprio domínio e de ninguém mais. Uma política da lição 4, `iam.allowedPolicyMemberDomains`,
recusa a concessão a qualquer conta fora dos domínios que ela lista, para que
`user:ana.personal@gmail.com` não possa ser adicionado à produção por um colega com pressa.

## Grupos são a unidade das concessões

**Conceda a grupos, não a pessoas.** Um papel concedido a `group:planner-devs@example.com` vale para todo
mundo no grupo, e entrar ou sair do grupo é uma mudança no diretório, feita por quem cuida do diretório,
sem mudança nenhuma em política do IAM. A diferença aparece no dia em que alguém sai: com grupos,
tirá-lo de três grupos termina todo papel; com concessões diretas, alguém precisa achar todo projeto,
pasta e bucket onde um `user:` o nomeou, e o que escapa é justamente o que importa.

Grupos também tornam as políticas legíveis. Um projeto cuja política diz que `planner-devs` pode fazer
deploy e `planner-oncall` pode reiniciar diz o que a equipe é; uma política listando quarenta endereços
diz quem por acaso pediu.

## As duas palavras que querem dizer todo mundo

`allAuthenticatedUsers` soa restritivo e não é: **quer dizer toda conta Google do mundo**, inclusive um
Gmail criado cinco minutos atrás. `allUsers` acrescenta quem nem está logado. Os dois têm um uso
legítimo, um bucket público de imagens de um site, e os dois são a causa mais comum de dados que não
deveriam ser públicos virarem públicos. A política de restrição de domínio acima recusa os dois, e um
ambiente que precisa de um bucket público isenta aquele projeto em vez de levantar a política para todo
mundo.

Nada nesta seção rodou no laboratório: não há diretório nem IAM a quem perguntar. A última seção desta
lição escreve todo tipo de principal num arquivo do Terraform e faz o provider conferir como cada um é
escrito.
