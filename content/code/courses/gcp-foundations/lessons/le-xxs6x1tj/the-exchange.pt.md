---
title: Trocar o token de outra pessoa por um do Google
version: 1
---

**Um programa fora do Google Cloud quase sempre já tem uma declaração assinada de quem ele é.** Um job do
GitHub Actions pode pedir ao GitHub um token que diz *este job roda no repositório `example/planner`, na
branch `main`*. Um workload em outra nuvem tem o token do próprio provedor. Um servidor no Active Directory
pode obter um do provedor de identidade da empresa. O Workload Identity Federation é o Google Cloud
aceitando **confiar nessa declaração**, nas condições que você escreve, e devolvendo um token do Google em
troca. Nenhuma chave é criada, guardada ou girada, porque nada duradouro atravessa.

A troca tem três partes e quatro passos:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-exchange\" aria-label=\"A troca, em quatro passos entre três partes. À esquerda, um job do GitHub Actions. No alto, o provedor de identidade do GitHub, que assina um token OIDC para o job, passo 1. No meio, o Security Token Service do Google, que recebe o token com o pool e o provider nomeados, confere a assinatura, o mapeamento de atributos e a condição, e devolve um token federado, passo 2. À direita, o IAM Credentials, que troca o token federado por um token da conta de serviço deployer, passo 3. Por fim, o job chama as APIs do Google com esse token, passo 4. Uma nota: nenhuma chave atravessa em passo nenhum.\"><defs><marker id=\"l09-exchange-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l09-exchange-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"120.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"143.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um job do</text><text x=\"90.0\" y=\"156.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">GitHub Actions</text><rect x=\"20.0\" y=\"14.0\" width=\"140.0\" height=\"54.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"90.0\" y=\"34.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">provedor de</text><text x=\"90.0\" y=\"47.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identidade do GitHub</text><path d=\"M90.0 70.0 L90.0 116.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-paper)\"></path><text x=\"98.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1. um token OIDC assinado</text><rect x=\"250.0\" y=\"110.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"340.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sts.googleapis.com</text><text x=\"340.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura, mapeamento,</text><text x=\"340.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">condição</text><path d=\"M162.0 140.0 L246.0 140.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-paper)\"></path><text x=\"204.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M246.0 162.0 L162.0 162.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-phosphor)\"></path><text x=\"204.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">federado</text><rect x=\"520.0\" y=\"110.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"610.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">iamcredentials</text><text x=\"610.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">token federado pelo</text><text x=\"610.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do deployer</text><path d=\"M90 182 C 90 240, 610 240, 610 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-exchange-af-ah-paper)\"></path><text x=\"350.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3. trocar pelo token do deployer, e 4. chamar as APIs do Google</text><text x=\"360.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">nenhuma chave atravessa em passo nenhum</text></svg>", "caption": "Um token de fora entra, um token do Google sai, e nada duradouro no meio."}
```

1. **O provedor de identidade de fora assina um token.** No GitHub é um token OIDC, um JWT, válido por
   minutos, levando afirmações (claims): `repository`, `ref`, `actor`, `workflow` e outras.
2. **O workload o manda ao Security Token Service do Google**, `sts.googleapis.com`, nomeando o **pool** e
   o **provider** a que o apresenta. O STS confere a assinatura contra as chaves publicadas do emissor,
   aplica o **mapeamento de atributos** e a **condição** do provider, e, se passarem, devolve um **token
   federado** de vida curta.
3. **O token federado é usado direto**, em recursos onde os principals do pool receberam papéis, **ou
   trocado mais uma vez** com a API IAM Credentials da lição 8 por um token de uma conta de serviço que o
   pool pode personificar.
4. **O workload chama as APIs do Google** com o resultado, que dura uma hora.

## Pools, providers e a condição

Um **pool de identidade de workload** é um contêiner para identidades de fora, num projeto: `ci-pool`. Um
**provider** dentro dele diz em quem confiar: o endereço do emissor,
`https://token.actions.githubusercontent.com` no GitHub, e como ler as afirmações dele. Duas peças do
provider fazem o trabalho de segurança de verdade:

- o **mapeamento de atributos** transforma as afirmações do token em atributos que o Google entende. O
  `google.subject` é o obrigatório: a identidade deste workload em particular. Outros, como
  `attribute.repository = assertion.repository`, viram nomes pelos quais o `principalSet://` da lição 5
  pode selecionar.
- a **condição de atributo** é uma expressão em CEL que todo token precisa satisfazer, ou a troca é
  recusada antes de qualquer papel ser considerado: `assertion.repository_owner == 'example'`.

**A condição é a tranca da porta.** O GitHub assina tokens para todo repositório do GitHub, milhões deles,
com o mesmo emissor. Um provider que confia no emissor e não tem condição aceita o token do repositório de
qualquer um, e a única coisa entre o workflow de um estranho e o seu projeto é se algum papel por acaso foi
concedido a um principal que bata com ele. A documentação do Google insiste numa condição para todo
provider cujo emissor é compartilhado assim, exatamente por isso. Escrever uma que nomeie a organização, e
uma concessão que nomeie o repositório, são duas trancas em vez de uma.

Nada nesta seção rodou: a troca exige um pool real, um provider real e um token real do GitHub. As duas
próximas seções escrevem o pool e o planejam, montam o arquivo de credencial que um workload usa, e mandam
ao Google uma troca que é recusada por um motivo que vale ler.
