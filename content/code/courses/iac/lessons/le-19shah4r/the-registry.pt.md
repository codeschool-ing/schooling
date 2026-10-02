---
title: O registry, e ler um módulo antes de confiar nele
version: 1
---

Uma URL Git serve para módulos que a sua própria empresa escreve. Para módulos que outras pessoas
publicam, existe o **Terraform Registry** em `registry.terraform.io`, o mesmo serviço a que o
`terraform init` pede os providers. Um source de registry tem três partes, `NAMESPACE/NAME/PROVIDER`,
e um argumento `version` separado que aceita uma restrição como a de um provider:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "shop"
  cidr = "10.20.0.0/16"
}
```

`terraform-aws-modules` é quem publica, `vpc` o módulo e `aws` o provider a que ele se destina.
`~> 6.0` quer dizer qualquer `6.x` a partir de `6.0`, e não `7.0`: ao instalar o módulo, o Terraform
escolhe a versão mais nova que o registry lista dentro dessa faixa. **Esta é a única transcrição da
aula que precisa da internet**, e o laboratório não tem, então aqui está o que o `init` faz quando
não alcança o registry:

```
ana@laptop:~/try-registry$ terraform init
Initializing the backend...

Initializing modules...
╷
│ Error: Error accessing remote module registry
│ 
│   on main.tf line 1:
│    1: module "vpc" {
│ 
│ Failed to retrieve available versions for module "vpc" (main.tf:1) from
│ registry.terraform.io: failed to request discovery document: GET
│ https://registry.terraform.io/.well-known/terraform.json giving up after 4
│ attempt(s): Get "https://registry.terraform.io/.well-known/terraform.json":
│ dial tcp: lookup registry.terraform.io on 127.0.0.1:53: server misbehaving.
╵
```

Ela mostra o primeiro passo do protocolo. O Terraform pede ao host o `/.well-known/terraform.json`,
um documento pequeno que diz onde ficam as APIs de módulos e de providers daquele host; com a
resposta, ele listaria as versões do módulo, escolheria uma e perguntaria de onde baixá-la. O DNS do
laboratório não conhece nenhum `registry.terraform.io`, então a primeira pergunta nunca saiu do
laptop. Num computador com rede, o mesmo `init` imprime `Downloading` e a versão escolhida, e o
módulo cai em `.terraform/modules/vpc` como a cópia do Git caiu duas seções atrás.

**Nada desse módulo aparece nesta aula**, porque nada dele foi baixado aqui. As entradas, as saídas
e o que ele cria estão na página dele no registry, que é onde lê-los.

Um endereço de registry também pode ter quatro partes, com um nome de host na frente:
`app.terraform.io/shop/network/aws`. Isso é um **registry privado**, como o que o HCP Terraform dá a
uma organização, e é por isso que o erro de duas seções atrás dizia que um endereço de registry tem "three
or four" componentes. Publicar no registry público tem regras próprias: um repositório público no
GitHub chamado `terraform-<PROVIDER>-<NAME>`, releases marcadas com versões semânticas, e a
organização de arquivos que a próxima seção descreve. As tags viram as versões que o registry lista.

## Um módulo roda com as suas credenciais

**Chamar o módulo de alguém é rodar o código dessa pessoa com o seu acesso à sua conta.** Tudo o que
ele declara, ele cria, muda ou destrói como você. O registry mostra quem publicou um módulo e quantas
vezes ele foi baixado; nenhuma das duas coisas diz que o código faz só o que a página descreve, e um
módulo popular continua sendo um módulo cuja próxima versão você não leu.

Então, antes de um módulo de terceiros entrar numa configuração, leia-o como leria um pull request.
Depois de instalado, `.terraform/modules` guarda os arquivos que o `init` buscou, e a leitura pode
começar por uma lista de tudo o que o módulo declara:

```
ana@laptop:~/shop$ grep -rhE "^(resource|data|module|provider)" --include="*.tf" .terraform/modules/shop
resource "aws_vpc" "this" {
resource "aws_subnet" "private" {
ana@laptop:~/shop$ grep -rnE "provisioner|\"external\"|\"http\"" --include="*.tf" .terraform/modules/shop || echo "none"
none
```

Aqui é o módulo de rede vindo do Git, dois recursos e nada surpreendente. O segundo comando procura
as três coisas que deixam um módulo fazer mais do que criar recursos: um `provisioner`, que roda
comandos, um data source `external`, que roda um programa durante o plan, e um data source `http`,
que busca uma URL. Nenhum deles é errado em si, e cada um merece uma pergunta.

Depois, fixe a versão. **O `.terraform.lock.hcl` registra providers e não módulos**, então uma faixa
é resolvida de novo a cada `init` do zero, no laptop de um colega ou num pipeline, e dois deles podem
pegar duas versões. Para um módulo que você não controla, um `version = "…"` exato é mais seguro: uma
versão nova só chega à sua configuração quando você muda a linha, e o plan depois dessa mudança é a
revisão. Ao atualizar, leia primeiro o changelog, depois o plan, e procure substituições como na
seção anterior.
