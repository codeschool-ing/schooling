---
title: O laboratório em que este curso roda
version: 1
---

Todo comando deste curso foi executado, e toda linha de saída é o que o comando imprimiu. **Nenhuma
conta de nuvem foi usada em nada disso**, e nada aqui foi cobrado de ninguém. A AWS com que o
Terraform conversa nestas aulas é o **moto**, o mesmo emulador que o curso de nuvem usou para o S3. É um programa em Python que responde às APIs da AWS numa porta do notebook, guarda na memória o que lhe
dizem e esquece tudo quando para.

```
ana@laptop:~/shop-tf$ terraform version
Terraform v1.16.4
on linux_amd64
+ provider registry.terraform.io/hashicorp/aws v6.67.0
ana@laptop:~/shop-tf$ aws --version
aws-cli/1.46.1 Python/3.11.15 Linux/6.18.44-fc-v51 botocore/1.43.62
ana@laptop:~/shop-tf$ env | grep ^AWS_ | sort
AWS_ACCESS_KEY_ID=test
AWS_DEFAULT_REGION=sa-east-1
AWS_ENDPOINT_URL=http://localhost:4566
AWS_SECRET_ACCESS_KEY=test
ana@laptop:~/shop-tf$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
```

As quatro variáveis `AWS_` são o truque inteiro, e são o motivo de os arquivos de Terraform das
aulas serem iguaizinhos aos escritos para uma conta real. `AWS_ENDPOINT_URL` manda cada chamada que o
AWS CLI e o provider da AWS fazem para o moto em vez de para a Amazon; o par de chaves é a palavra
`test`, que o moto aceita e a AWS recusaria; a região é São Paulo. A conta como a qual o moto
responde, `123456789012`, é o valor de exemplo que a própria AWS usa na documentação.

**O que o moto é, e o que não é.** Ele é uma imitação fiel da *API*: confere argumentos, inventa
ids, lembra o que foi criado e responde perguntas sobre isso. Não roda máquina nenhuma nem carrega
pacote nenhum. Uma instância que ele "liga" é um registro com um id e um estado, que é exatamente o
que o Terraform lê de volta; então todo plano, apply, arquivo de estado e erro destas aulas é o que o
Terraform produziria. O que você não vai ver é um servidor web respondendo numa máquina que o
Terraform criou; as aulas 18 a 20, que precisam de máquinas que rodam, usam contêineres no notebook,
e dizem isso.

**Todo o resto é o programa de verdade.** Terraform, OpenTofu, Terragrunt, Packer, Ansible e os
scanners são as versões lançadas, e cada provider é o que a HashiCorp publica. O único arranjo que
você não teria em casa é de onde vêm os providers: o notebook em que estas aulas foram gravadas não alcançava o Terraform Registry. Os providers foram baixados do site de releases da HashiCorp,
conferidos contra os checksums publicados e servidos de um diretório local. O `terraform init`
imprime as mesmas linhas de um jeito ou de outro; a aula 2 mostra o único arquivo em que a diferença
aparece.

## Fazendo no seu computador

Você precisa de Terraform, Python 3 e o AWS CLI, em Linux, macOS ou Windows com WSL:

1. **Terraform**, da página de downloads da HashiCorp ou do gerenciador de pacotes do seu sistema.
   As aulas foram gravadas na versão impressa acima, e os poucos recursos que exigem uma versão
   recente dizem isso onde aparecem.
2. **moto e o AWS CLI**, num ambiente virtual de Python: `pip install "moto[server]" awscli`.
3. **Ligue o moto** num terminal só dele, `moto_server -p 4566`, e deixe rodando.
4. **No terminal em que você trabalha**, exporte as quatro variáveis mostradas acima. Depois
   acrescente `s3_use_path_style = true` ao bloco do provider da AWS em qualquer configuração que
   crie um bucket, porque o SDK da AWS endereça um bucket como `<nome>.localhost` e a maioria dos
   computadores não resolve esse nome. O laboratório usou um pequeno servidor DNS para o mesmo fim.

**Quando algo não responde, o endpoint é o primeiro suspeito.** Sem nada escutando no endereço, o CLI
diz isso numa linha:

```
ana@laptop:~/shop-tf$ AWS_ENDPOINT_URL=http://localhost:4567 aws sts get-caller-identity

Could not connect to the endpoint URL: "http://localhost:4567/"
```

Confira se o `moto_server` continua rodando no terminal dele e se a porta em `AWS_ENDPOINT_URL` é a
que ele imprimiu ao ligar. Já um erro de credenciais quer dizer que as variáveis não estão definidas no terminal em que você
está digitando, e a chamada foi para outro lugar. Com `test`
como chave, um endpoint real da AWS a recusa, que é a segurança que você quer.

**E quando você passar para uma conta real**, as configurações destas aulas funcionam sem mudança:
desfaça `AWS_ENDPOINT_URL`, configure credenciais reais, e lembre que dali em diante cada `apply`
cria algo que custa dinheiro até um `destroy` removê-lo. A aula 16 é sobre esse custo.
