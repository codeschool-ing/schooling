---
title: Quando as pessoas já moram em outro diretório
version: 1
---

**A maioria das empresas tem um diretório antes de ter o Google Cloud**: o Microsoft Active Directory no
local, o Microsoft Entra ID, o Okta, ou algo parecido. Ninguém quer manter as mesmas pessoas duas vezes,
então a pergunta é como o Google Cloud fica sabendo de pessoas que já existem em outro lugar. Há três
respostas, e elas diferem em **onde as contas moram** e **onde a senha é conferida**.

| | as contas moram em | a senha é conferida por | ferramenta típica |
|---|---|---|---|
| **sincronizar** | Cloud Identity, como cópias | o Google, ou o outro diretório via single sign-on | Google Cloud Directory Sync, ou o provisionamento do próprio provedor |
| **single sign-on** por cima da sincronização | Cloud Identity, como cópias | o outro diretório, por SAML ou OIDC | Entra ID ou Okta como provedor de identidade |
| **workforce identity federation** | só no outro diretório | o outro diretório | um pool de workforce na organização |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-three-ways\" aria-label=\"Três jeitos de o diretório que a empresa já tem chegar ao Google Cloud, um por linha. Sincronizar: o GCDS copia usuários e grupos num sentido só para o Cloud Identity, e o Google confere a senha. Sincronizar com single sign-on: as mesmas cópias, mas a senha é conferida pelo provedor de identidade da empresa. Workforce identity federation: cópia nenhuma; um pool de workforce confia direto no provedor de identidade da empresa.\"><defs><marker id=\"l10-three-ways-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-three-ways-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><text x=\"20.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sincronizar</text><rect x=\"20.0\" y=\"54.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">diretório da empresa</text><rect x=\"500.0\" y=\"54.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópias no Cloud Identity</text><path d=\"M192.0 71.0 L496.0 71.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-three-ways-af-ah-paper)\"></path><text x=\"344.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">num sentido só</text><text x=\"344.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">senha: Google</text><text x=\"20.0\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sincronizar + single sign-on</text><rect x=\"20.0\" y=\"126.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">diretório da empresa</text><rect x=\"500.0\" y=\"126.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">cópias no Cloud Identity</text><path d=\"M192.0 143.0 L496.0 143.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-three-ways-af-ah-paper)\"></path><text x=\"344.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">num sentido só</text><text x=\"344.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">senha: o provedor da empresa</text><text x=\"20.0\" y=\"186.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">workforce identity federation</text><rect x=\"20.0\" y=\"198.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">diretório da empresa</text><rect x=\"500.0\" y=\"198.0\" width=\"200.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um pool de workforce</text><path d=\"M496.0 215.0 L192.0 215.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-three-ways-af-ah-amber)\"></path><text x=\"344.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">confia</text><text x=\"344.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem cópias; confiança direta</text></svg>", "caption": "Copiar as pessoas, entrar por elas, ou confiar nelas onde estão.", "same": ["workforce identity federation"]}
```

## Sincronizar, e o single sign-on por cima

O **Google Cloud Directory Sync**, o GCDS, é um programa que o Google fornece e que lê um diretório LDAP
como o Active Directory e cria, atualiza e suspende os usuários e grupos correspondentes no Cloud
Identity. Ele roda **num sentido só**, do diretório da empresa para o do Google, para que o diretório da
empresa continue sendo a fonte da verdade. O Entra ID e o Okta fazem o mesmo trabalho com os próprios
conectores de provisionamento.

Sincronizar copia as contas; não decide onde as pessoas digitam a senha. Acrescentar o **single sign-on**,
um perfil SAML ou OIDC no Cloud Identity que aponta para o provedor de identidade da empresa, manda o
login para lá: a Ana digita a senha no Entra ID, o Entra ID diz ao Google quem ela é, e o Google Cloud vê
`ana@example.com` como sempre. É o arranjo mais comum em empresas que chegaram ao Google Cloud com um
diretório próprio, e a força dele é que **uma conta desativada no diretório da empresa é uma conta
desativada em todo lugar**, desde que a sincronização rode.

## Workforce identity federation

A terceira resposta dispensa as cópias. Um **pool de workforce**, na organização, confia direto no
provedor de identidade da empresa, do jeito que o pool de workload da lição 9 confia no GitHub, e as
pessoas entram como
`principal://iam.googleapis.com/locations/global/workforcePools/staff/subject/ana@example.com`. Nada é
sincronizado e nenhuma conta do Cloud Identity existe para elas.

Ela serve a uma empresa que quer o Google Cloud e nada mais do Google, e não quer uma segunda cópia do seu
diretório. Tem custos que uma equipe deve conhecer antes de escolhê-la: as concessões nomeiam as formas
longas `principal://` e `principalSet://` da lição 5 em vez de `user:` e `group:`, e alguns produtos do
Google Cloud, quase todos os que vieram do Workspace, não aceitam identidades federadas. **A documentação
do Google mantém uma lista dos produtos que aceitam, e é a página a ler antes de decidir.**

## Escolher

Para a empresa do planner, que entra com o Entra ID e usa o Google Cloud só para o planner, tanto
sincronizar com single sign-on quanto um pool de workforce funcionariam. A pergunta que decide costuma ser
que outros produtos do Google a empresa vai usar: se um dia ela for usar o Google Workspace, o Looker ou
outro produto que precise de contas do Cloud Identity, sincronizar agora evita uma migração depois.

Nada nesta lição rodou: o GCDS, o single sign-on e os pools de workforce exigem um diretório real dos dois
lados.
