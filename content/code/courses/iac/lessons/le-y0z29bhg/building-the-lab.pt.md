---
title: Montando o laboratório, passo a passo
version: 1
---

Estes passos são para o **Ubuntu 24.04**, na máquina virtual que a seção anterior recomenda ou
instalado direto. Em outra versão do Debian ou do Ubuntu eles são os mesmos; no macOS e em outras
famílias de Linux os comandos de pacote mudam, e o fim desta seção diz como.

**A instalação inteira é um script.** Salve-o no seu diretório pessoal como `setup-iac.sh`:

```sh
#!/bin/sh
# ~/setup-iac.sh: the tools lessons 1 to 13 use, on Ubuntu 24.04.
set -e
sudo apt-get update -qq
sudo apt-get install -qq -y curl git gnupg jq lsb-release python3-venv tree unzip >/dev/null

# Terraform, from HashiCorp's own package repository, checked against its key
curl -fsSL https://apt.releases.hashicorp.com/gpg |
  sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" |
  sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
sudo apt-get update -qq
sudo apt-get install -qq -y terraform=1.16.4-1 >/dev/null

# moto and the AWS CLI, in a Python environment of their own
python3 -m venv ~/iac-venv
~/iac-venv/bin/pip install -q "moto[server]==5.2.3" "awscli==1.46.1"

terraform version
~/iac-venv/bin/aws --version
```

Três coisas nele são escolhas, e não necessidades. **As versões estão fixadas** nas que foram usadas
para gravar todas as transcrições deste curso, para que o que você vê bata com o que a página diz;
tire o `=1.16.4-1` e os dois `==` e você recebe as mais novas, que também funcionam e imprimem linhas
um pouco diferentes. **O moto e o AWS CLI vão para um ambiente virtual**, `~/iac-venv`, porque o
Ubuntu 24.04 não deixa o `pip` instalar no Python do próprio sistema, e tem razão. E **`jq`, `tree` e
`git`** não são do Terraform: as aulas os usam para ler JSON, para mostrar um diretório e para guardar
o histórico de cada configuração.

Rode o script. Ele pede a sua senha uma vez, para o `sudo`, e leva alguns minutos:

```
ana@laptop:~$ sh setup-iac.sh
Terraform v1.16.4
on linux_amd64
aws-cli/1.46.1 Python/3.12.3 Linux/6.18.44-fc-v77 botocore/1.43.62
```

O segundo arquivo é mais curto, e você vai usá-lo em todo terminal que abrir para este curso. Salve-o
como `iac-env.sh`:

```sh
# ~/iac-env.sh: read it into each terminal with ". ~/iac-env.sh"
. ~/iac-venv/bin/activate
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=sa-east-1
mkdir -p ~/.terraform.d/plugin-cache
export TF_PLUGIN_CACHE_DIR=~/.terraform.d/plugin-cache
```

Ele é lido com `.`, e não executado com `sh`, porque um script *executado* define as variáveis num
shell só dele, e elas morrem com ele. A primeira linha põe `aws` e `moto_server` no seu `PATH`; as
três seguintes definem as variáveis que a próxima seção explica. As duas últimas são sobre disco: o
provider da AWS é um programa de **789 MB**, e sem um cache o `terraform init` baixa uma cópia dele
em cada diretório que você inicializa. Com o cache, ele é baixado uma vez e cada diretório aponta
para ele. O seu prompt ganha `(iac-venv)` na frente quando a primeira linha roda; as transcrições
deste curso o deixam de fora.

**O moto ganha um terminal só dele.** Abra um segundo terminal e inicie-o lá:

```
ana@laptop:~$ . ~/iac-env.sh
ana@laptop:~$ moto_server -p 4566
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4566
Press CTRL+C to quit
```

Deixe-o rodando. Cada pedido que ele atende imprime uma linha nesse terminal, e vale a pena olhar
para ela quando um comando parece não fazer nada. De volta ao primeiro terminal, a conferência de que
a cadeia inteira funciona:

```
ana@laptop:~$ . ~/iac-env.sh
ana@laptop:~$ env | grep ^AWS_ | sort
AWS_ACCESS_KEY_ID=test
AWS_DEFAULT_REGION=sa-east-1
AWS_ENDPOINT_URL=http://localhost:4566
AWS_SECRET_ACCESS_KEY=test
ana@laptop:~$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-4052a1bd303dbea6e	172.31.0.0/16	True
```

O `env` mostra as quatro variáveis que o arquivo definiu. O `get-caller-identity` pergunta à AWS quem
é você, e o moto responde com a sua conta de exemplo. A VPC é a **VPC padrão** que toda região da AWS
traz, e o moto também cria uma; é a única coisa numa conta emulada que você não fez. Se você vê essas
três respostas, o laboratório está pronto para a aula 2.

**Em outros sistemas.** No **macOS**, instale o Terraform com o Homebrew,
`brew install hashicorp/tap/terraform`, e rode as linhas `python3 -m venv` e `pip` do script como
estão; o `iac-env.sh` funciona sem mudança. No **Windows**, instale o WSL 2 com o Ubuntu 24.04 e siga
esta seção dentro dele, palavra por palavra. No **Fedora** e parentes, a HashiCorp publica um
repositório `dnf`, e a página de downloads dela dá as duas linhas para ele.
