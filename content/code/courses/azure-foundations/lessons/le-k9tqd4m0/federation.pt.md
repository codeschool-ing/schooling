---
title: Um pipeline que implanta sem segredo guardado
version: 1
---

**As implantações da loja rodam no GitHub Actions, e o jeito antigo de deixá-las chegar ao Azure era
um client secret guardado nas configurações do repositório.** Funcionava, foi copiado para outros três
repositórios, e ninguém sabia quais deles ainda o usavam quando ele expirou. A federação de identidade
de carga de trabalho o substitui por uma troca de tokens:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l07-federation\" aria-label=\"A troca de tokens em quatro passos entre três partes. 1: o GitHub emite para o job um token do repositório shop-example/storefront no branch main. 2: o job manda esse token e o client id do shop-deploy ao token endpoint do Entra ID. 3: o Entra ID compara issuer, subject e audience com a credencial federada do registro. 4: o Entra ID devolve um access token, que o job usa com o Resource Manager.\"><defs><marker id=\"l07-federation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-federation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"16.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">GitHub</text><path d=\"M110.0 51.0 L110.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"280.0\" y=\"16.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o job</text><path d=\"M360.0 51.0 L360.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"530.0\" y=\"16.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Entra ID</text><path d=\"M610.0 51.0 L610.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M114.0 89.0 L356.0 89.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-federation-af-ah-phosphor)\"></path><text x=\"235.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  um token do repo e do branch</text><path d=\"M364.0 144.0 L606.0 144.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-federation-af-ah-phosphor)\"></path><text x=\"485.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  esse token, com o client id</text><circle cx=\"610.0\" cy=\"185.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"596.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3  issuer, subject e audience batem?</text><path d=\"M606.0 249.0 L364.0 249.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l07-federation-af-ah-amber)\"></path><text x=\"485.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  um access token, cerca de uma hora</text></svg>", "caption": "Nada na troca fica guardado em lugar nenhum, então nada nela pode vazar depois.", "same": ["Entra ID", "GitHub"]}
```

1. **o GitHub emite um token próprio para o job**, assinado por
   `https://token.actions.githubusercontent.com`, dizendo de qual repositório e de qual branch o job é;
2. o job manda esse token ao token endpoint do Entra ID, **no lugar de um segredo**, junto com o client
   id do `shop-deploy`;
3. **o Entra ID o compara com a credencial federada** do registro: o issuer, o subject e a audience
   precisam bater exatamente;
4. se batem, o Entra ID devolve um access token do `shop-deploy`, válido por cerca de uma hora, e o job
   o usa com o Resource Manager como qualquer outro.

A credencial do `main.tf` é essa comparação, por escrito:

| campo | valor | diz |
|---|---|---|
| `issuer` | `https://token.actions.githubusercontent.com` | o token precisa vir do emissor do GitHub, que o Entra ID confere contra as chaves públicas desse emissor |
| `subject` | `repo:shop-example/storefront:ref:refs/heads/main` | só jobs daquele repositório, no branch `main` |
| `audiences` | `api://AzureADTokenExchange` | o token precisa ter sido feito para o Entra ID, e para nada mais |

**É no subject que está a segurança.** Um subject `repo:shop-example/storefront:ref:refs/heads/main`
deixa o branch main implantar e recusa um job em qualquer outro branch, um pull request vindo de um
fork, ou outro repositório do mesmo dono. Amplie-o sem cuidado e um pull request consegue implantar em
produção. Uma credencial separada com o subject
`repo:shop-example/storefront:environment:production` amarra a implantação a um environment do GitHub,
que pode exigir uma aprovação antes de o job começar.

**Nada que possa vazar fica guardado.** Não há segredo no GitHub, nenhuma data de validade para
lembrar, e o token que o GitHub emitiu vale por minutos e só para aquele job. O que sobra para proteger
é o próprio registro, e quem pode mudar as credenciais federadas dele, que é uma permissão de
diretório, do tipo que a lição 6 separou dos papéis do Azure.

## O que o laboratório conferiu, e o resto

```
ana@laptop:~/azure/deploy$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer: could not configure AzureCli Authorizer: obtaining subscription ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azuread"],
│   on main.tf line 10, in provider "azuread":
│   10: provider "azuread" {
│ 
╵
```

O `validate` já tinha aceitado os três campos da credencial, e o `plan` parou no login, como todo plan
daqui. **Nenhuma troca de tokens foi executada**: ela precisa de um job do GitHub, de um tenant de
verdade e de um registro de verdade, e o curso não tem nenhum dos três. Os passos acima são o fluxo
documentado da Microsoft e do GitHub. O arquivo de workflow do lado do GitHub pede o token com
`permissions: id-token: write` e usa a action `azure/login` da Microsoft, recebendo o client id, o id
do tenant e o id da assinatura, nenhum dos quais é segredo.
