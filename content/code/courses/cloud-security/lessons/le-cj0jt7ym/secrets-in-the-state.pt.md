---
title: O arquivo de estado lembra o que a tela esconde
version: 1
---

**O Terraform mantém um arquivo de estado que registra cada atributo de cada recurso que ele gerencia,
e um atributo que é uma senha é registrado como qualquer outro: em texto claro.** Marcar uma variável
como `sensitive` a esconde da tela e de mais nada. Quem consegue ler o estado consegue ler o segredo,
e o estado costuma ficar num lugar que mais gente alcança do que o próprio segredo.

## A senha do banco de dados

A senha do banco de dados do sistema de agendamento pertence ao Secrets Manager, e o caio cria o
segredo com Terraform. Num diretório novo:

```sh
mkdir -p ~/aws/clinic-db && cd ~/aws/clinic-db
```

Salve isto como `main.tf`:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region = "sa-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
}

resource "aws_secretsmanager_secret" "db" {
  name = "clinic/db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = var.db_password
}
```

A senha entra por uma variável de ambiente, então não está em nenhum arquivo do repositório. O
Terraform lê toda variável chamada `TF_VAR_` seguida do nome de uma variável. Rode `terraform init`,
e depois:

```sh
export TF_VAR_db_password='Clinic-2019-Booking!'
```

```
ana@laptop:~/aws/clinic-db$ terraform apply -auto-approve -no-color | tail -1
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/clinic-db$ terraform state show -no-color aws_secretsmanager_secret_version.db | grep secret_string
    secret_string    = (sensitive value)
    secret_string_wo = (write-only attribute)
ana@laptop:~/aws/clinic-db$ grep -o '"secret_string": "[^"]*"' terraform.tfstate
"secret_string": "Clinic-2019-Booking!"
```

O `terraform state show` diz `(sensitive value)`, que é o que o `sensitive = true` compra. O arquivo de
onde ele leu diz a senha com todas as letras. **Todo o cuidado com o jeito como a senha chegou, por uma
variável de ambiente e em nenhum lugar do disco, foi desfeito pelo arquivo de estado**, que agora mora
no notebook do caio e, numa equipe, num backend compartilhado.

## Mantendo-a fora do estado

Versões recentes do Terraform, entre elas a 1.16.4 desta aula, conseguem passar um valor a um recurso
**sem registrá-lo**. O recurso oferece um argumento *write-only*, `secret_string_wo`, e um número de
versão ao lado que diz quando o valor mudou. A variável vira `ephemeral`, o que quer dizer que o
Terraform pode usá-la durante uma execução e nunca pode guardá-la. Substitua o `main.tf` por este:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region = "sa-east-1"
}

variable "db_password" {
  type      = string
  sensitive = true
  ephemeral = true
}

resource "aws_secretsmanager_secret" "db" {
  name = "clinic/db"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id                = aws_secretsmanager_secret.db.id
  secret_string_wo         = var.db_password
  secret_string_wo_version = 1
}
```

```
ana@laptop:~/aws/clinic-db$ terraform apply -auto-approve -no-color | grep -E 'will be|Apply complete'
  # aws_secretsmanager_secret_version.db will be updated in-place
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
ana@laptop:~/aws/clinic-db$ grep -c 'Clinic-2019-Booking' terraform.tfstate terraform.tfstate.backup
terraform.tfstate:0
terraform.tfstate.backup:1
ana@laptop:~/aws/clinic-db$ aws secretsmanager get-secret-value --secret-id clinic/db --query SecretString --output text
Clinic-2019-Booking!
```

O estado não guarda mais a senha, e o segredo ainda guarda, que é o único lugar onde ela deve estar. O
Terraform não vai perceber uma senha nova comparando valores que nunca guardou: quando a senha muda, o
`secret_string_wo_version` sobe um, e é isso que o manda escrever de novo.

**E o backup ainda tem a antiga.** O `terraform.tfstate.backup` é o estado como estava antes do último
apply, e o Terraform o mantém ao lado do estado sem ninguém pedir. Um backend compartilhado guarda o
próprio histórico do mesmo jeito, muitas vezes toda versão do estado já escrita. Então a correção para
uma senha que passou por um arquivo de estado é a mesma que para uma chave que passou por um
repositório: **esta senha precisa mudar**, e só depois importa onde estão as cópias antigas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l12-three-places\" aria-label=\"Três lugares por onde um valor passa quando a infraestrutura é escrita como código, e o que cada um faz com ele. O repositório: os arquivos atuais podem estar limpos enquanto o histórico guarda toda linha já commitada, inclusive uma chave removida. O plano na tela: um valor sensível aparece escondido, e um valor que depende de algo ainda não criado aparece como known after apply, então quem revisa não vê nenhum dos dois. O arquivo de estado: todo atributo em texto claro, inclusive uma senha que a tela escondeu, e um backup ao lado com a versão anterior ao último apply.\"><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o repositório</text><rect x=\"32.0\" y=\"66.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os arquivos de hoje</text><text x=\"120.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">limpos</text><rect x=\"32.0\" y=\"142.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o histórico</text><text x=\"120.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">access_key = &quot;AKIA…&quot;</text><text x=\"120.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">todo clone guarda o histórico</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o plano na tela</text><rect x=\"272.0\" y=\"66.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">secret_string</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">(sensitive value)</text><rect x=\"272.0\" y=\"142.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">policy</text><text x=\"360.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">(known after apply)</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">quem revisa não vê nenhum</text><rect x=\"500.0\" y=\"20.0\" width=\"200.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">o arquivo de estado</text><rect x=\"512.0\" y=\"66.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">terraform.tfstate</text><text x=\"600.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&quot;Clinic-2019-…&quot;</text><rect x=\"512.0\" y=\"142.0\" width=\"176.0\" height=\"64.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">terraform.tfstate.backup</text><text x=\"600.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o valor antigo</text><text x=\"600.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">quem o lê lê o segredo</text></svg>", "caption": "Um segredo marcado como sensível some da tela e fica guardado em todo o resto. Cada um dos três pede a sua resposta: trocar o que chegou ao histórico, tornar conhecíveis os valores do plano, manter segredos fora do estado."}
```

## Onde o estado mora

Duas decisões decorrem disso, e as aulas 7 e 12 do curso `iac` levam as duas adiante:

- **O estado é um segredo, então guarde-o como um.** Numa equipe ele mora num backend como um bucket
  S3, criptografado, com versionamento, legível só pelas pessoas e pelo pipeline que rodam o
  Terraform. Um bucket de estado legível pela equipe de engenharia inteira torna todo segredo dentro
  dele legível pela equipe inteira.
- **Prefira argumentos que mantêm segredos fora dele.** Argumentos write-only onde o recurso oferecer
  um; senão, deixe o próprio serviço gerar o segredo, para que ele nunca passe pelo Terraform.

Nada da metade do backend foi executado aqui: estas aulas mantêm o estado no notebook.
