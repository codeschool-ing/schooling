---
title: Uma aplicação, e o seu service principal
version: 1
---

**Um programa que chama o Azure precisa de uma identidade própria, e no Entra ID essa identidade vem
em duas metades.** As pessoas esperam um objeto só, chamado algo como "a conta do app". São dois, e
confundi-los é o motivo de metade das dúvidas sobre este assunto existirem:

- **o objeto de aplicação**, ou **registro de aplicativo**, é a definição do programa: o nome, quem
  pode entrar nele, que credenciais ele aceita, que permissões ele pede. Ele mora num tenant, o seu
  **tenant de origem**, e é o mesmo para quem quer que o use;
- **o service principal** é a identidade do programa **dentro de um tenant**: o objeto que faz login,
  que recebe papéis, que aparece nos logs. O portal os lista como *Enterprise applications*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l07-app-and-sp\" aria-label=\"Uma aplicação registrada no seu tenant de origem, com um client id, e um service principal dela em cada tenant que a usa: um no tenant de origem e um no tenant de um cliente. Cada service principal tem o seu próprio object id e recebe os seus próprios papéis; o client id é o mesmo em todo lugar.\"><defs><marker id=\"l07-app-and-sp-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tenant de origem</text><rect x=\"50.0\" y=\"60.0\" width=\"270.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aplicação (registro)</text><text x=\"185.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">client id 00001111-…</text><text x=\"185.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um só, onde quer que seja usada</text><rect x=\"50.0\" y=\"170.0\" width=\"270.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">service principal</text><text x=\"185.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o seu próprio object id</text><text x=\"185.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">papéis neste tenant</text><path d=\"M185.0 131.0 L185.0 169.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-app-and-sp-af-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"20.0\" width=\"330.0\" height=\"250.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"386.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o tenant de um cliente</text><rect x=\"400.0\" y=\"170.0\" width=\"270.0\" height=\"76.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">service principal</text><text x=\"535.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outro object id</text><text x=\"535.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">papéis que o cliente dá</text><path d=\"M321.0 95.0 L535.0 95.0 L535.0 169.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l07-app-and-sp-af-ah-paper-dim)\"></path><text x=\"535.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">criado com o consentimento</text></svg>", "caption": "O registro diz o que o programa é; cada service principal diz o que ele pode fazer num tenant.", "same": ["service principal"]}
```

Para o programa de implantação da própria loja, o `shop-deploy`, a distinção parece preciosismo: um
registro no tenant da loja, um service principal ao lado dele. Deixa de ser preciosismo no dia em que
uma aplicação é usada por mais de um tenant. Um produto vendido a outras empresas é registrado uma
vez, no tenant do fornecedor, e cada cliente que concorda em usá-lo ganha **um service principal
próprio**, no seu próprio diretório, a que os administradores dele dão papéis e que eles podem apagar.
O registro diz o que o programa é; cada service principal diz o que ele pode fazer num lugar.

Dois ids decorrem disso, e os dois aparecem em toda mensagem de erro sobre aplicações:

| id | nomeia | onde é o mesmo |
|---|---|---|
| **application (client) id** | o registro, e portanto o programa | em todo tenant: é o que o programa manda para fazer login |
| **object id** | um objeto num diretório | em nenhum outro lugar: o registro tem um, e cada service principal tem o seu |

**Um papel é dado ao object id do service principal**, nunca ao client id. Um script que dá um papel
ao client id é recusado ou, pior, acha um objeto que não tem nada a ver.

## Quem pode entrar nela

Um registro declara a sua **audiência**: de quem são as contas que podem usá-lo. O programa de
implantação da loja é só da loja. Crie o diretório da lição:

```sh
mkdir -p ~/azure/deploy && cd ~/azure/deploy
```

e salve isto como `main.tf`:

```hcl
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "3.10.0"
    }
  }
}

provider "azuread" {
  tenant_id = "aaaabbbb-0000-cccc-1111-dddd2222eeee"
}

resource "azuread_application" "deploy" {
  display_name     = "shop-deploy"
  sign_in_audience = "AzureADMyOrg"
}

resource "azuread_service_principal" "deploy" {
  client_id = azuread_application.deploy.client_id
}

resource "azuread_application_federated_identity_credential" "main" {
  application_id = azuread_application.deploy.id
  display_name   = "github-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:shop-example/storefront:ref:refs/heads/main"
}
```

O registro, o service principal dele construído a partir do client id do registro, e uma credencial
federada que a terceira seção desta lição explica. Confira, e depois tente a audiência que alguém
chutou em vez de consultar:

```
ana@laptop:~/azure/deploy$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azuread versions matching "3.10.0"...
- Installing hashicorp/azuread v3.10.0...
- Installed hashicorp/azuread v3.10.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/deploy$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/deploy$ sed -i 's/AzureADMyOrg/AzureADMyTenant/' main.tf && terraform validate
╷
│ Error: expected sign_in_audience to be one of ["AzureADMyOrg" "AzureADMultipleOrgs" "AzureADandPersonalMicrosoftAccount" "PersonalMicrosoftAccount"], got AzureADMyTenant
│ 
│   with azuread_application.deploy,
│   on main.tf line 16, in resource "azuread_application" "deploy":
│   16:   sign_in_audience = "AzureADMyTenant"
│ 
╵
ana@laptop:~/azure/deploy$ sed -i 's/AzureADMyTenant/AzureADMyOrg/' main.tf
```

O `init` baixou o provider de novo, embora a lição 6 o tenha deixado no cache que o `env.sh`
configurou. **O Terraform só tira um provider do cache para um diretório que já tem um arquivo de
lock**, o `.terraform.lock.hcl`, que registra o provider exato com que uma configuração foi conferida e
que o `init` acabou de escrever. Um segundo `init` no mesmo diretório usa o cache:

```
ana@laptop:~/azure/deploy$ rm -rf .terraform && terraform init -input=false | grep -E 'Reusing|Using'
- Reusing version 3.10.0 of hashicorp/azuread from the dependency lock file
- Using hashicorp/azuread v3.10.0 from the shared cache directory
```

De volta à primeira transcrição. O segundo `validate` cita as quatro audiências que existem:
`AzureADMyOrg`, só este tenant; `AzureADMultipleOrgs`, qualquer tenant de trabalho ou de escola; e as
duas que acrescentam contas pessoais da Microsoft. **As ferramentas da própria empresa ficam com a
primeira**, e qualquer coisa mais ampla é uma decisão de produto, não um padrão. O último comando
devolve o arquivo ao que era.
