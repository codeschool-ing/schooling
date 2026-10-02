---
title: Levando o estado para o S3
version: 1
---

Onde o estado mora é decidido pelo **backend**. Até agora foi o padrão, `local`: um arquivo no
diretório de trabalho, e é por isso que um segundo diretório não tinha estado e construiu uma segunda
rede. Um backend remoto guarda a única cópia num lugar que toda execução alcança, e o Terraform a lê
no começo de um comando e a grava de volta no fim, exatamente como fazia com o arquivo. Para uma
empresa na AWS, o lugar de costume é um bucket S3.

**O bucket vem primeiro, e não desta configuração.** Uma configuração não pode guardar o estado num
bucket que ela mesma cria: no primeiro `init` o bucket ainda não existe, e um `destroy` apagaria o
bucket que guarda o registro do que destruir. Então o bucket é feito uma vez, por fora: à mão, como
aqui, ou por uma configuração pequena e separada cujo estado fica local. A Ana dá a ele o nome da
conta, porque nomes de bucket são globais entre todos os clientes da AWS:

```
ana@laptop:~/shop$ aws s3api create-bucket --bucket shop-tfstate-123456789012 --create-bucket-configuration LocationConstraint=sa-east-1
{
    "Location": "/shop-tfstate-123456789012"
}
ana@laptop:~/shop$ aws s3api put-bucket-versioning --bucket shop-tfstate-123456789012 --versioning-configuration Status=Enabled
ana@laptop:~/shop$ aws s3api put-public-access-block --bucket shop-tfstate-123456789012 --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/shop$ aws s3api get-bucket-versioning --bucket shop-tfstate-123456789012
{
    "Status": "Enabled"
}
```

Dois desses comandos não são opcionais. O **versionamento** guarda todas as versões de todos os
objetos, então cada gravação do estado deixa a anterior recuperável; "protecting" usa isso.
**Bloquear o acesso público** garante que nenhuma política ou ACL posterior publique o bucket por
engano, e o que há no estado é o motivo de isso importar.

Depois, o bloco de backend, num arquivo próprio ao lado do `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "shop/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

`key` é o caminho do objeto de estado dentro do bucket; um bucket pode guardar os estados de muitas
configurações, cada um sob a sua key, e a aula 8 usa isso. `encrypt` pede ao S3 que criptografe o
objeto em repouso. `use_lockfile` é o assunto da próxima seção. **Nenhum desses valores pode vir de
uma variável**: o backend é configurado antes de qualquer outra coisa da configuração ser avaliada,
então ele é escrito literalmente, ou passado ao `terraform init` com `-backend-config`.

Trocar o backend é trabalho do `init`, e o Terraform percebe que há um estado local para levar junto.
Ele pergunta antes de copiar:

```
ana@laptop:~/shop$ terraform init -migrate-state
Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.67.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

O que ficou no diretório, e o que está no bucket:

```
ana@laptop:~/shop$ ls -l terraform.tfstate*
-rw-r--r-- 1 ana ana    0 Oct  2 00:51 terraform.tfstate
-rw-r--r-- 1 ana ana 5828 Oct  2 00:50 terraform.tfstate.1790913034.backup
-rw-r--r-- 1 ana ana 5835 Oct  2 00:50 terraform.tfstate.1790913055.backup
-rw-r--r-- 1 ana ana 5835 Oct  2 00:51 terraform.tfstate.backup
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 00:51:41       5835 shop/terraform.tfstate
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.public_a
aws_vpc.shop
ana@laptop:~/shop$ rm terraform.tfstate terraform.tfstate.*
```

O `terraform.tfstate` local agora está **vazio**, zero bytes, e o backup mais novo tem o mesmo
tamanho do objeto no bucket. O bucket guarda o estado sob a key que a Ana escolheu, e o
`terraform state list` imprimiu os três endereços depois de lê-los do S3: nada local participa mais.
Os backups antigos são cópias de um estado que agora mora em outro lugar, e mantê-los por perto só
convida alguém a restaurar um deles, então eles vão embora.

O experimento de "losing-it" de novo, agora que o `backend.tf` está commitado. Um clone novo, um
`init`, um plan:

```
ana@laptop:~$ git clone -q shop shop-2
ana@laptop:~/shop-2$ terraform init
Initializing the backend...

Successfully configured the backend "s3"! Terraform will automatically
use this backend unless the backend configuration changes.
```

```
ana@laptop:~/shop-2$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

**O mesmo repositório, um diretório novinho, e `No changes`.** Os ids nas linhas `Refreshing state`
são os originais: o clone leu o mesmo estado que o diretório da Ana, porque só existe um. Qualquer
laptop, qualquer colega e qualquer job de CI que tenha o repositório e consiga ler o bucket agora
planeja contra o mesmo registro.

Compartilhar um estado resolve a rede duplicada e abre na hora outro problema: dois desses leitores
agora podem tentar *gravá-lo* no mesmo instante.
