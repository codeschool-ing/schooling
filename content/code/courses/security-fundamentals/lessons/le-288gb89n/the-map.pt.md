---
title: O mapa
version: 1
---

Segurança não é um emprego só. É uma família de empregos que compartilham o vocabulário deste curso e
diferem no que fazem o dia inteiro. Cinco famílias cobrem a maior parte da área, e cada uma nasce de aulas
específicas:

```schooling-figure
{"svg": "<svg id=\"sf-career-map\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"As cinco famílias do trabalho em segurança, em volta deste curso como base comum. SOC e resposta a incidentes, ensinadas em soc-response. Segurança ofensiva, ensinada em pentest. Governança, risco e conformidade, ensinadas em threat-modeling. Forense, em soc-response. Segurança de aplicações, ensinada em secure-code e threat-modeling.\"><defs><marker id=\"sf-career-map-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"260\" y=\"120\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">este curso</text><text x=\"360\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">security-fundamentals</text><rect x=\"20\" y=\"20\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SOC e resposta</text><text x=\"120\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">soc-response</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">segurança ofensiva</text><text x=\"600\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pentest</text><rect x=\"20\" y=\"222\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">GRC</text><text x=\"120\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">threat-modeling</text><rect x=\"500\" y=\"222\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">AppSec</text><text x=\"600\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">secure-code</text><rect x=\"260\" y=\"222\" width=\"200\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">forense</text><text x=\"360\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">soc-response</text><path d=\"M260 130 L220 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M460 130 L500 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M260 168 L220 222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M460 168 L500 222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path><path d=\"M360 176 L360 222\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#sf-career-map-ah-wire)\"></path></svg>", "caption": "Uma base, cinco direções. Os nomes de curso em cada família são onde o catálogo a ensina.", "same": ["GRC", "AppSec"]}
```

| família | o que faz | nasceu das aulas | o curso que a ensina |
|---|---|---|---|
| **SOC e resposta a incidentes** | vigia ataques, faz triagem de alertas, responde | 10, 11, 12 | `soc-response` |
| **segurança ofensiva** (pentest, time vermelho) | ataca sistemas, com permissão, para mostrar o que um atacante conseguiria | 4, 8, 10 | `pentest` |
| **GRC** (governança, risco e conformidade) | gere risco, política e evidência; trabalha com auditores | 3, 13, 14, 15, 16, 17 | `threat-modeling` |
| **forense** | reconstrói o que aconteceu depois de um incidente, a partir de evidências | 10, 12 | aulas 16 a 18 de `soc-response` |
| **AppSec** (segurança de aplicações) | torna o software seguro antes e enquanto ele é entregue | 6, 8 | `secure-code`, `threat-modeling` |

As fronteiras são macias. Um analista de SOC que faz uma investigação forense, um pentester que vai para
AppSec, um especialista de GRC que antes cuidava de firewall: as pessoas transitam entre elas, e a base
comum é o que torna isso possível. A base é este curso.

::: track security
Na trilha de segurança você está no começo deste mapa, e os cursos da trilha o seguem. `networks`,
`cryptography` e `attacks-threats` preparam o terreno em que toda família se apoia; `secure-code`,
`networks-security` e `defense-hardening` são o ofício do defensor; `soc-response`, `cloud-security` e
`pentest` levam às duas primeiras famílias. O resultado que a trilha nomeia é analista de segurança da
informação, um papel que começa no SOC e pode crescer em qualquer das cinco direções.
:::

::: track devsecops
Na trilha de DevSecOps, segurança faz parte de construir e entregar software, o que aponta para a última
linha do mapa. Depois de `networks`, `cryptography` e `attacks-threats` vêm `secure-code` e
`threat-modeling`, depois contêineres, `testing-cicd` e `secure-pipeline`, onde as verificações da aula
16 rodam sozinhas a cada mudança. `cloud-security` e `soc-response` fecham a trilha, porque quem entrega o
sistema também precisa vigiá-lo.
:::

::: track qa
Na trilha de QA, este curso fica ao lado dos testes, e `testing-cicd` vem a seguir. Um testador que
entendeu a aula 8 é a pessoa que tenta `/payslips/bruno` logado como ana antes que um cliente tente. Teste
de segurança é uma especialização natural para QA, e leva às famílias ofensiva e de AppSec: um teste de
invasão é, entre outras coisas, um plano de teste muito minucioso.
:::

::: track dba
Na trilha de administração de banco de dados, os dados que você vai administrar são o ativo que quase todo
este curso protege, e `cryptography` vem a seguir. Menor privilégio nas contas do banco (aula 6), backups e
testes de restauração (aula 12) e a LGPD (aula 17) fazem parte do trabalho comum de um DBA, e um DBA que os
conhece é a primeira pessoa que as equipes de GRC e de resposta a incidentes chamam.
:::

::: track *
Neste catálogo, a trilha `security` segue este mapa desde o primeiro curso, e a trilha `devsecops` segue a
linha de AppSec. As duas são uma porta de entrada; também é chegar vindo de desenvolvimento,
infraestrutura ou suporte, que é como muita gente da área chegou. O vocabulário deste curso é o que todos
esses caminhos têm em comum.
:::

As próximas seções percorrem as famílias uma a uma: qual é o trabalho, como é um dia e qual costuma ser o
primeiro emprego.
