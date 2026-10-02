---
title: Todo diretório é um módulo
version: 1
---

A palavra *módulo* sugere algo especial: um pacote que alguém publica, baixa e instala, como uma
biblioteca. **No Terraform, um módulo é qualquer diretório de arquivos `.tf`**, e você escreve
módulos desde a aula 2. O diretório em que você roda o `terraform` é o **root module**, o módulo
raiz. Um diretório que o root module chama é um **child module**, um módulo filho, e a chamada é um
bloco `module`.

A loja da Ana precisa de uma VPC com duas sub-redes, e logo de uma segunda rede ao lado para o time
de analytics. Em vez de escrever a VPC e as sub-redes duas vezes, ela as leva para um diretório
próprio:

```
ana@laptop:~/shop$ tree --noreport
.
├── main.tf
└── modules
    └── network
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
```

`modules/network` guarda uma configuração comum: recursos, variáveis e outputs, os mesmos blocos que
a aula 2 ensinou, e a próxima seção abre cada arquivo. O que muda é o `main.tf` do root. Ele não
declara mais uma VPC; ele pede uma:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

module "shop" {
  source = "./modules/network"

  name = "shop"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.20.1.0/24" }
    c = { az = "sa-east-1c", cidr = "10.20.2.0/24" }
  }
}
```

**O bloco `module` é uma chamada, e os argumentos dele são as variáveis do filho.** `name`, `cidr` e
`subnets` não são palavras-chave do Terraform; existem porque `modules/network/variables.tf` declara
três variáveis com esses nomes. `source` é o único argumento que pertence ao próprio Terraform: diz
onde estão os arquivos do filho. Alguns outros também são do Terraform, e você já viu a maioria
deles em recursos: `count`, `for_each` e `depends_on`, mais `providers` e `version`, que esta aula
alcança duas e três seções adiante.

Antes de qualquer plan, o filho precisa ser encontrado. Um plan logo depois de escrever o bloco
recusa:

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Module not installed
│ 
│   on main.tf line 14:
│   14: module "shop" {
│ 
│ This module is not yet installed. Run "terraform init" to install all
│ modules required by this configuration.
╵
```

**O `terraform init` instala módulos além de providers.** A aula 2 o rodou pelos providers; com um
bloco `module` na configuração ele ganha um segundo trabalho, e diz isso antes do primeiro:

```
ana@laptop:~/shop$ terraform init
Initializing the backend...

Initializing modules...
- shop in modules/network
```

`- shop in modules/network` é a instalação inteira de um diretório local: o Terraform anota onde
estão os arquivos da chamada e os lê dali. Ele guarda essa anotação num arquivo próprio:

```
ana@laptop:~/shop$ jq . .terraform/modules/modules.json
{
  "Modules": [
    {
      "Key": "",
      "Source": "",
      "Dir": "."
    },
    {
      "Key": "shop",
      "Source": "./modules/network",
      "Dir": "modules/network"
    }
  ]
}
```

Uma entrada por módulo, o root incluído como `Key: ""`. Num caminho local, `Dir` é o próprio
diretório, então uma edição em `modules/network/main.tf` aparece no próximo plan sem novo `init`. Um
módulo que vem de outro lugar é copiado para `.terraform/modules/`, e três seções adiante
você vê essa cópia sendo feita.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dois painéis. À esquerda, o root module em ~/shop, com dois blocos module, shop e analytics, e o security group web. À direita, o child module em modules/network: as variáveis name, cidr e subnets no alto, os recursos aws_vpc.this e aws_subnet.this no meio, os outputs vpc_id e subnet_ids embaixo. Uma seta leva valores do bloco module para as variáveis; outra traz os outputs de volta ao root, onde o security group lê module.shop.vpc_id. Nada mais atravessa entre os painéis.\"><defs><marker id=\"bd-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"bd-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"280\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">root module</text><text x=\"40.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">~/shop</text><rect x=\"40\" y=\"75\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">module \"shop\"</text><rect x=\"40\" y=\"135\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">module \"analytics\"</text><rect x=\"40\" y=\"205\" width=\"240\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.web</text><text x=\"160.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">module.shop.vpc_id</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">child module</text><text x=\"440.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">modules/network</text><rect x=\"440\" y=\"75\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">variáveis</text><text x=\"560.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">name · cidr · subnets</text><rect x=\"440\" y=\"135\" width=\"240\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">recursos, fora de alcance</text><text x=\"560.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_vpc.this</text><text x=\"560.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_subnet.this[…]</text><rect x=\"440\" y=\"205\" width=\"240\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outputs</text><text x=\"560.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">vpc_id · subnet_ids</text><path d=\"M282 97 L437 97\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bd-ah-phosphor)\"></path><text x=\"360.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">valores entram</text><path d=\"M438 230 L283 230\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bd-ah-amber)\"></path><text x=\"360.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">outputs saem</text></svg>", "caption": "Uma chamada de módulo: valores entram pelas variáveis e saem pelos outputs. Os recursos no meio ficam fora do alcance de quem chama.", "same": ["root module", "child module", "outputs"]}
```

A figura é o contrato em que todas as seções seguintes se apoiam. **Valores entram num módulo pelas
variáveis e saem pelos outputs, e nada mais atravessa a fronteira.** O root não consegue ler um
recurso dentro do filho, e o filho não consegue ler nada do root que não lhe tenha sido passado. É
essa fronteira que permite chamar o mesmo diretório duas vezes com valores diferentes, e é ela
também que faz da mudança de um módulo uma questão de cuidado: quem o chama depende exatamente
daqueles nomes.

Mais dois fatos para levar adiante. Todo recurso que um filho cria ganha um endereço com o nome da
chamada na frente, `module.shop.aws_vpc.this`, e é com ele que o state o registra. E um filho pode
chamar filhos próprios; os endereços simplesmente ganham mais um prefixo `module.`. A maioria dos
times para num nível, porque cada nível é mais um lugar que o leitor precisa abrir para descobrir o
que um plan vai fazer.
