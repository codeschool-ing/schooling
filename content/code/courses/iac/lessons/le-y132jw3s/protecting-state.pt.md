---
title: Cifrar o estado antes de ele sair do laptop
version: 1
---

As três últimas seções mantêm segredos fora do estado onde um provider permite. Alguma coisa sempre
entra mesmo assim: um recurso sem argumento write-only, um data source que lê um segredo, uma chave
que um provider gera e devolve. Para esse resto, a proteção do próprio estado é a última linha, e a
seção "protecting" da aula 7 montou a maior parte dela: um bucket que ninguém de fora do time
consegue ler, acesso público bloqueado, versionamento e `encrypt = true`.

Essa última configuração merece um olhar preciso, porque soa como mais do que é. `encrypt = true`
pede ao S3 que cifre o objeto **nos discos do S3**. Quem o bucket deixa ler o objeto o recebe
decifrado, em texto puro, porque decifrar para leitores autorizados é o que o S3 faz. Uma chave KMS
própria (`kms_key_id` no backend) acrescenta uma segunda permissão de que o leitor precisa, o que
ajuda; um leitor com as duas continua recebendo texto puro, e o mesmo vale para toda cópia que sai do
bucket, como um `terraform state pull` no laptop de alguém.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma grade de duas linhas e três colunas. As colunas são três lugares por onde um estado passa: a memória do programa que roda o plan, o que recebe alguém que o bucket deixa ler, e os discos do próprio S3. Só com a criptografia do S3, o estado é texto puro nos dois primeiros e cifrado apenas nos discos. Com a criptografia de estado do OpenTofu, ele é texto puro só na memória do programa e cifrado nos outros dois.\"><text x=\"310.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">na memória do programa</text><text x=\"460.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">para quem lê o bucket</text><text x=\"610.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">nos discos do S3</text><text x=\"20.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">criptografia do S3</text><text x=\"20.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">encrypt = true</text><rect x=\"245\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">texto puro</text><rect x=\"395\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">texto puro</text><rect x=\"545\" y=\"60\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cifrado</text><text x=\"20.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">criptografia do OpenTofu</text><text x=\"20.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">encryption { }</text><rect x=\"245\" y=\"150\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">texto puro</text><rect x=\"395\" y=\"150\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cifrado</text><rect x=\"545\" y=\"150\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cifrado</text><text x=\"460.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a segunda linha move a fronteira uma coluna para a esquerda</text></svg>", "caption": "Onde um estado é texto puro. A criptografia do S3 protege os discos; a do OpenTofu protege tudo depois do programa."}
```

**O Terraform não tem como cifrar o estado antes de gravá-lo.** O OpenTofu, o fork que a aula 1
apresentou, tem: o estado é cifrado dentro do programa, e o backend, local ou S3, só guarda texto
cifrado. Este é o recurso que a aula 1 prometeu, e o laboratório tem o `tofu` para mostrá-lo.

## Ligando

Uma configuração pequena com uma senha gerada, rodada com `tofu`. O provider é nomeado pelo endereço
completo porque o espelho offline do laboratório arquiva os providers sob o registry do Terraform,
enquanto o OpenTofu usa o próprio por padrão; a aula 17 fala mais dos dois registries.

```hcl
terraform {
  required_providers {
    random = {
      source  = "registry.terraform.io/hashicorp/random"
      version = "~> 3.7"
    }
  }
}

resource "random_password" "db" {
  length = 20
}
```

```
ana@laptop:~/shop/tofu$ tofu apply -auto-approve -no-color | grep -E "^Apply"
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/tofu$ jq -r ".resources[0].instances[0].attributes.result" terraform.tfstate
<<k9VdD%LM0mWVF(m3&?
```

Um estado puro, senha legível, o ponto de partida de toda configuração existente. A Ana acrescenta a
criptografia num arquivo próprio:

```hcl
variable "state_passphrase" {
  type      = string
  sensitive = true
}

terraform {
  encryption {
    key_provider "pbkdf2" "passphrase" {
      passphrase = var.state_passphrase
    }

    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.passphrase
    }

    method "unencrypted" "migrate" {}

    state {
      method = method.aes_gcm.state

      fallback {
        method = method.unencrypted.migrate
      }
    }
  }
}
```

Quatro peças. O **key provider** `pbkdf2` deriva uma chave de uma frase-senha, e não precisa de mais
nada. O **method** `aes_gcm` cifra com essa chave. O bloco `state` diz que o estado é gravado com esse
método. E o **fallback** deixa esta execução ler o estado que ainda é puro: sem ele, o OpenTofu
tentaria decifrar um arquivo que nunca foi cifrado, e pararia.

A frase-senha é uma variável de propósito. Escrita no arquivo, seria mais um segredo no git; aqui ela
foi exportada no shell antes, como `TF_VAR_state_passphrase`, que é como um pipeline a entregaria a
partir do seu próprio cofre de segredos. Então o apply, e o arquivo que ele gravou:

```
ana@laptop:~/shop/tofu$ tofu apply -auto-approve -no-color | grep -E "^Apply"
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

```
ana@laptop:~/shop/tofu$ jq "keys" terraform.tfstate
[
  "encrypted_data",
  "encryption_version",
  "lineage",
  "meta",
  "serial"
]
ana@laptop:~/shop/tofu$ jq -r ".encrypted_data" terraform.tfstate | cut -c 1-64
qbFmTxtO+mzpi0/71keIGUxl5WFBLvhCeUr2osANv3cJMCXNu5XTC3TClvm5ZD0B
ana@laptop:~/shop/tofu$ grep -c "\"result\"" terraform.tfstate
0
ana@laptop:~/shop/tofu$ jq -r ".meta[]" terraform.tfstate | base64 -d; echo
{"salt":"MjbK6Nj6UlGm+3KPiShY2cJK8CvC1R9fXxFjBKjxV3I=","iterations":600000,"hash_function":"sha512","key_length":32}
```

O estado agora é um envelope curto: um serial e uma lineage, deixados às claras, e `encrypted_data`,
que é o estado propriamente dito. A palavra `result` não aparece em lugar nenhum do arquivo. A entrada
`meta` guarda o necessário para derivar a chave de novo a partir da frase-senha (um salt aleatório, o
número de iterações, o hash), e não a chave. O OpenTofu lê o estado como antes:

```
ana@laptop:~/shop/tofu$ tofu state list
random_password.db
ana@laptop:~/shop/tofu$ tofu plan | tail -n 3

No changes. Your infrastructure matches the configuration.
```

## Depois da migração

O fallback cumpriu o papel dele, e se ficasse também aceitaria um estado puro que alguém colocasse de
volta no bucket. A Ana o remove, junto com o método `unencrypted`, para que o bloco `state` seja só o
método, e roda o plan mais uma vez:

```
ana@laptop:~/shop/tofu$ sed -n "/state {/,/^    }/p" encryption.tf
    state {
      method = method.aes_gcm.state
    }
ana@laptop:~/shop/tofu$ tofu plan | tail -n 3

No changes. Your infrastructure matches the configuration.
```

Agora as duas falhas que importam. A frase-senha errada:

```
ana@laptop:~/shop/tofu$ TF_VAR_state_passphrase='a-different-passphrase-entirely' tofu plan
Acquiring state lock. This may take a few moments...
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: failed to write backup file: decryption failed for all
│ provided methods
│ attempted decryption failed for state: decryption failed: cipher: message
│ authentication failed
│ 
│ OpenTofu acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
```

A mensagem chega embrulhada num erro de lock, porque a primeira coisa que o backend local faz é um
backup do estado, e ele não consegue ler o que deveria copiar. A linha que importa é `message
authentication failed`: o AES-GCM não decifra para lixo, ele recusa. E o Terraform, chamado a
trabalhar no mesmo diretório e depois a ler uma cópia do mesmo arquivo:

```
ana@laptop:~/shop/tofu$ terraform init
Initializing the backend...

╷
│ Error: Terraform encountered problems during initialisation, including problems
│ with the configuration, described below.
│ 
│ The Terraform configuration must be valid before initialization so that
│ Terraform can determine which modules and providers need to be installed.
│ 
│ 
╵
╷
│ Error: Unsupported block type
│ 
│   on encryption.tf line 7, in terraform:
│    7:   encryption {
│ 
│ Blocks of type "encryption" are not expected here.
╵
╷
│ Error: Unsupported block type
│ 
│   on encryption.tf line 7, in terraform:
│    7:   encryption {
│ 
│ Blocks of type "encryption" are not expected here.
╵
ana@laptop:~/shop/tofu-copy$ cp ../tofu/terraform.tfstate . && terraform state list
Failed to load state: Unsupported state file format: The state file does not have a "version" attribute, which is required to identify the format version.
```

O Terraform não conhece o bloco `encryption`, e lê o arquivo cifrado como um estado sem versão. Daí
vêm duas consequências. **Esta configuração agora pertence ao OpenTofu**, e voltar ao Terraform exige
decifrar o estado com o `tofu` antes. E **a frase-senha passa a ser o segredo mais importante desta
configuração.** Perdê-la é perder o estado, inclusive cada versão gravada desde a migração, porque
cada uma foi cifrada com ela. Um time que usa isso a sério usa um key provider apoiado num serviço de
chaves, como o `aws_kms`, para que a chave seja uma permissão concedida pelo IAM e não um texto que
alguém precisa guardar.

Duas pontas soltas. As versões que o bucket guardou de antes da migração continuam lá, ainda em texto
puro, então são apagadas, e qualquer segredo que elas tinham é trocado. E o mesmo bloco `encryption`
aceita um bloco `plan` ao lado do `state`, que cifra o arquivo de plan salvo, a cópia três de
"where-they-leak".
