---
title: Unidades administrativas, e o diretório escrito num arquivo
version: 1
---

**Uma unidade administrativa é uma fatia do diretório a que o papel de um administrador pode ser
limitado.** Ela responde a uma pergunta que a árvore da lição 2 não alcança: os grupos de
gerenciamento dividem os recursos do Azure, e nada naquela árvore divide o diretório. Sem unidades
administrativas, quem do suporte redefine senhas redefine a de todo mundo, a do presidente da empresa
incluída.

A loja tem pessoal nos escritórios e pessoal nas lojas físicas, e as gerentes das lojas redefinem as
senhas do próprio pessoal. Então:

- uma unidade administrativa `au-shop-stores` guarda o pessoal das lojas;
- o papel **User Administrator** é dado às gerentes de loja **com escopo nessa unidade**, não no
  tenant;
- uma gerente de loja agora só consegue redefinir a senha da `bia` se a `bia` estiver na unidade, e
  ela não está.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l06-au-scope\" aria-label=\"O tenant da loja guarda o pessoal do escritório, entre eles bia, e uma unidade administrativa chamada au-shop-stores com o pessoal das lojas físicas. Uma gerente de loja tem o papel User Administrator com escopo na unidade. Uma seta da gerente entra na unidade e redefine senhas lá; uma segunda seta, na direção de bia, fora da unidade, é recusada.\"><defs><marker id=\"l06-au-scope-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-au-scope-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"14.0\" width=\"680.0\" height=\"272.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">tenant</text><text x=\"684.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop.example</text><rect x=\"270.0\" y=\"52.0\" width=\"180.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">gerente de loja</text><text x=\"360.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">User Administrator</text><rect x=\"44.0\" y=\"150.0\" width=\"250.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"169.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pessoal do escritório</text><rect x=\"70.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bia</text><rect x=\"175.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ana</text><rect x=\"420.0\" y=\"150.0\" width=\"256.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"548.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">au-shop-stores</text><rect x=\"448.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"493.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lia</text><rect x=\"553.0\" y=\"190.0\" width=\"90.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"598.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">rui</text><path d=\"M400.0 109.0 L500.0 149.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-au-scope-af-ah-amber)\"></path><text x=\"498.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">redefine senhas</text><path d=\"M320.0 109.0 L190.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l06-au-scope-af-ah-paper-dim)\"></path><text x=\"212.0\" y=\"124.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recusado: fora do escopo</text></svg>", "caption": "Um papel de diretório com escopo numa unidade alcança os membros dela e ninguém mais.", "same": ["tenant"]}
```

Três propriedades valem a pena saber. Uma unidade administrativa **não pode conter outra**: elas são
planas. Um usuário pode estar em várias. E uma unidade administrativa de **gerenciamento restrito**
vai além, impedindo que administradores cujo papel cobre o tenant inteiro mudem os membros dela, de
modo que só quem recebeu um papel na própria unidade consegue; é assim que uma empresa protege as
contas dos seus executivos do próprio suporte.

## Dois tipos de papel, que não têm nada em comum

**Os papéis do Entra ID e os papéis do Azure são dois sistemas separados**, e a mesma palavra esconde
isso. *User Administrator*, *Global Administrator* e os outros **papéis de diretório** decidem o que
alguém pode fazer com o diretório: criar usuários, redefinir senhas, registrar aplicações. Os **papéis
do Azure**, *Owner*, *Contributor*, *Reader* e o resto da lição 9, decidem o que alguém pode fazer com
recursos numa assinatura. Um Global Administrator não tem acesso a uma única máquina virtual até um
papel do Azure dizer que tem, e um Owner de todas as assinaturas não consegue redefinir uma senha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-two-role-systems\" aria-label=\"Dois sistemas de papéis separados, lado a lado. À esquerda, os papéis de diretório do Entra ID, como Global Administrator e User Administrator, agem sobre usuários, grupos e aplicações, com escopo no tenant ou numa unidade administrativa. À direita, os papéis do Azure, como Owner, Contributor e Reader, agem sobre recursos, com escopo num grupo de gerenciamento, numa assinatura, num grupo de recursos ou num recurso. Nada passa de um para o outro.\"><rect x=\"30.0\" y=\"20.0\" width=\"310.0\" height=\"210.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">papéis de diretório</text><rect x=\"70.0\" y=\"60.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Global Administrator</text><rect x=\"70.0\" y=\"94.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">User Administrator</text><text x=\"185.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">agem sobre usuários, grupos, aplicações</text><text x=\"185.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escopo: tenant ou unidade administrativa</text><rect x=\"380.0\" y=\"20.0\" width=\"310.0\" height=\"210.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">papéis do Azure</text><rect x=\"420.0\" y=\"60.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Owner</text><rect x=\"420.0\" y=\"94.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Contributor</text><rect x=\"420.0\" y=\"128.0\" width=\"230.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Reader</text><text x=\"535.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">agem sobre recursos</text><text x=\"535.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escopo: grupo, assinatura, recurso</text></svg>", "caption": "Um Global Administrator não lê máquina virtual até um papel do Azure permitir; um Owner não redefine senha."}
```

**Existe uma ponte, e ela é para emergências.** Um Global Administrator pode ligar o *elevate access* e
virar User Access Administrator sobre todas as assinaturas do tenant, que é como uma empresa recupera
uma assinatura cujos donos foram todos embora. A chave fica registrada nos logs do tenant, e deve ser
desligada de novo no mesmo dia. Unidades administrativas dão escopo a papéis de diretório; os escopos
da lição 9 são as caixas da lição 2.

## O diretório da loja, em Terraform

O provider do Azure da lição 2 não alcança o diretório: o Entra ID tem um provider só dele, o
`azuread`, que escreve no Microsoft Graph. Salve isto como `main.tf` em `~/azure/entra`:

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

resource "azuread_user" "bia" {
  user_principal_name = "bia@shop.example"
  display_name        = "Bia Souza"
  department          = "Engineering"
}

resource "azuread_group" "engineering" {
  display_name     = "grp-shop-engineering"
  security_enabled = true
  types            = ["DynamicMembership"]

  dynamic_membership {
    enabled = true
    rule    = "user.department -eq \"Engineering\""
  }
}

resource "azuread_administrative_unit" "stores" {
  display_name = "au-shop-stores"
  description  = "Staff of the physical stores"
}

resource "azuread_invitation" "accountant" {
  user_email_address = "carla@accounting.example"
  redirect_url       = "https://myapps.microsoft.com"
}
```

Um usuário, o grupo dinâmico com a regra acima, a unidade administrativa, e um convite para a
contadora, que vira convidada quando o aceita. Pôr o papel de uma gerente de loja na unidade é mais
um recurso, `azuread_administrative_unit_role_member`, deixado de fora para o arquivo ficar curto.
**Não há senha no arquivo, de propósito**: uma senha numa configuração é uma senha no histórico do
repositório e no state do Terraform. Numa empresa, a maioria dos usuários nem é criada aqui; eles
chegam do sistema de RH ou do diretório próprio do escritório, que é a lição 12. Depois:

```
ana@laptop:~/azure/entra$ terraform init -input=false
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
ana@laptop:~/azure/entra$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/entra$ terraform plan -input=false

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

O `init` baixou o segundo provider do curso, aquele que a lição 1 disse que esta lição ia acrescentar.
O `validate` conferiu cada bloco contra o esquema do Graph como o provider o conhece. **Ele não
conferiu a regra**: `user.department -eq "Engineering"` é um texto para o Terraform, e um atributo
digitado errado nela seria recusado pelo Entra ID quando o grupo fosse criado, não aqui. E o `plan`
parou onde todo plan deste laboratório para, no login, porque o que existe no diretório quem diz é o
Microsoft Graph.
