---
title: O workflow, linha a linha
version: 1
---

Este é o workflow de deploy da loja com federação. Ele **não foi executado**: precisa dos runners do GitHub e
de um tenant real. Leia-o pelo que cada linha contribui para a troca da figura acima.

```yaml
# .github/workflows/deploy.yml
name: deploy
on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-24.04
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
      - run: |
          az webapp config container set \
            --resource-group rg-shop --name app-shop-api --slot staging \
            --container-image-name crshop.azurecr.io/shop/api:${{ github.sha }}
```

**`permissions: id-token: write`** é o que deixa o job pedir um token OIDC ao GitHub. Sem isso, a action de
login falha antes de o Azure sequer entrar na história. Conceder no nível do job em vez do workflow é ainda
mais apertado, quando o workflow tem jobs que não implantam. `contents: read` está ali porque declarar uma
permissão explicitamente desliga as outras, e o checkout ainda precisa ler o código.

**`environment: production`** faz duas coisas de uma vez. Põe o job atrás das proteções do ambiente do GitHub
e muda o subject para `...:environment:production`, que é o único subject em que a credencial
`shop-production` confia.

**`client-id`, `tenant-id` e `subscription-id` não são segredos.** Eles nomeiam uma identidade; não a provam.
Ficam em `vars`, e não em `secrets`, para dizer isso com clareza, e vazá-los não deixa ninguém entrar. Compare
com o blob `creds` do jeito antigo, em que os mesmos três ids viajavam ao lado da única string que provava a
identidade.

**`azure/login@v2`** pede ao GitHub o token com a audiência `api://AzureADTokenExchange`, o envia ao Entra ID e
deixa a linha de comando logada pelo resto do job. O passo seguinte é um comando `az` comum, rodado como
`shop-production`, com o que o papel em `rg-shop` permite e nada além.

Dois hábitos completam. **Fixe as actions num commit** em vez de numa tag quando o workflow alcança a
produção, porque uma tag é o repositório de outra pessoa decidindo o que roda com a sua identidade; a loja
escreve tags aqui pela legibilidade. E **mantenha o papel pequeno**: a federação tira o segredo, não as
permissões, e um workflow que implanta o app não deveria conseguir atribuir papéis.
