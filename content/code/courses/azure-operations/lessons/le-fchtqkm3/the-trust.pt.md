---
title: Federação: confiar num token em vez de guardar um segredo
version: 1
---

**A federação de identidade de carga de trabalho troca o segredo guardado por uma regra sobre em quem
acreditar.** O GitHub mantém um serviço de tokens OpenID Connect. Toda execução de workflow que pede, e tem
permissão, recebe um token de vida curta **assinado pelo GitHub** que diz, em campos padronizados, a que
repositório, branch, ambiente e execução ele pertence. O Microsoft Entra ID pode ser instruído a aceitar esse
token em troca de um token do Azure, mas só um cujos campos batam com uma **credencial federada** que você
anexou ao app registration antes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma sequência entre três partes. Um: a execução do workflow pede ao serviço de tokens do GitHub um token OIDC. Dois: o GitHub devolve um token assinado por ele, válido por minutos, que nomeia o repositório e o ambiente no subject. Três: a execução envia esse token ao Microsoft Entra ID. Quatro: o Entra ID confere emissor, subject e audiência com a credencial federada do app registration. Cinco: o Entra ID devolve um token de acesso do Azure para o service principal, válido por cerca de uma hora.\"><defs><marker id=\"ah-exchange\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"180\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">serviço de tokens do GitHub</text><rect x=\"270\" y=\"20\" width=\"180\" height=\"50\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a execução do workflow</text><rect x=\"520\" y=\"20\" width=\"180\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Microsoft Entra ID</text><path d=\"M110 70 L110 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M360 70 L360 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M610 70 L610 280\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M355 100 L116 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"235\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 pede um token OIDC</text><path d=\"M116 135 L355 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"235\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2 token assinado, minutos</text><path d=\"M366 170 L604 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"485\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 apresenta o token</text><rect x=\"380\" y=\"185\" width=\"220\" height=\"40\" rx=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"490\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4 emissor, subject, audiência?</text><path d=\"M604 250 L366 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-exchange)\"></path><text x=\"485\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 token do Azure, cerca de 1 hora</text></svg>", "caption": "Nada na troca foi guardado antes, só a confiança: qual emissor, qual subject, qual audiência.", "same": ["Microsoft Entra ID"]}
```

A credencial federada são três fatos:

```json
{
  "name": "shop-production",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:example-shop/shop-api:environment:production",
  "audiences": ["api://AzureADTokenExchange"]
}
```

O `issuer` é o serviço de tokens do GitHub, e o Entra ID busca lá as chaves públicas para conferir a
assinatura. O valor de `audiences` é o que a documentação do Azure fixa para esta troca, e a action de login
pede ao GitHub um token com essa audiência. O `subject` é a parte que você projeta, e a próxima seção não
fala de outra coisa.

Ela é criada pela linha de comando ou com Bicep e Terraform; esta é a forma da linha de comando, **não
executada**, porque precisa de um tenant real:

```sh
az ad app federated-credential create --id "$APP_ID" --parameters @shop-production.json
```

O que mudou foi onde mora o risco. **Não há nada para vazar**: o token do GitHub vale por minutos e só para a
audiência para a qual foi emitido, e o token do Azure que ele compra dura cerca de uma hora. Não há nada para
girar. E a revogação é exata: apague a credencial federada, e aquele repositório e ambiente não entram mais,
sem afetar nada além.

As service connections do Azure Pipelines usam o mesmo mecanismo, com o Azure DevOps como emissor, e por isso
a lição 1 pôde dizer que a connection não guarda segredo.
