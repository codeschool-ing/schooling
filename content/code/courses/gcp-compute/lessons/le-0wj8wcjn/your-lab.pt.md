---
title: O seu laboratório, em resumo
version: 1
---

**Este curso é praticado no seu próprio computador, com a linha de comando real do Google Cloud e
sem conta no Google Cloud.** Nada nele é cobrado e nada chega ao Google. Os quatro cursos de
Google Cloud desta escola dividem um único ambiente, e o `gcp-foundations` o monta na lição 1, com
cada caminho explicado e uma seção sobre o que dá errado. Se você fez aquele curso e guardou o
laboratório, pule para a verificação perto do fim desta seção. Se não, os passos estão abaixo em
resumo, e montam a mesma coisa.

## O que faz as vezes do Google Cloud, e o que nada faz

**O Google não publica nenhuma imitação do seu plano de controle.** Nada que você instale responde
"crie uma máquina virtual", "publique um serviço no Cloud Run" ou "monte um cluster GKE" do jeito
que o Google responde, e este curso não finge o contrário. O que ele tem no lugar são quatro
ferramentas honestas sobre o que são:

- **gcloud**, a linha de comando do próprio Google. Tudo que ela faz no seu computador funciona: a
  configuração, a ajuda, as credenciais que ela escreve para o Docker. Tudo que ela mandaria ao
  Google para antes de sair, porque não há conta de onde mandar, e você vai ver essa recusa abaixo.
- **Terraform com o provider do Google.** O `terraform plan` calcula, no seu computador, cada
  atributo que um recurso teria e o que seria criado. É o mais perto da resposta do Compute Engine
  que dá para ter sem o Compute Engine, e a maior parte das lições sobre máquinas virtuais, grupos e
  clusters é praticada com ele.
- **Docker**, porque o Cloud Run, os jobs dele e o ambiente flexível do App Engine rodam
  contêineres, e um contêiner que cumpre o contrato do Google roda no seu laptop exatamente como
  rodaria lá.
- **Emuladores** para as lições de eventos: o emulador de Pub/Sub do próprio Google, o Functions
  Framework sobre o qual as funções do Cloud Run são feitas, e o fake-gcs-server, uma imitação de
  código aberto do Cloud Storage.

**O que nenhum deles dá é uma medição.** Uma partida a frio cronometrada no seu laptop é do seu
laptop; um preço nunca é calculado por nenhum deles. Todo preço deste curso vem das páginas de
preços publicadas pelo Google, reunidas num programa curto que a próxima seção mostra inteiro.

Quando uma lição ensina algo que nenhuma ferramenta daqui roda (uma atualização gradual em zonas
reais, uma preempção, o balanceador que o GKE monta), ela diz isso com todas as letras, mostra os
comandos documentados pelo Google e os marca como não executados. Nenhuma saída é escrita para
eles.

## Três jeitos de ter o laboratório

**Recomendado: instalar no Ubuntu 24.04**, no seu computador ou numa máquina virtual que você já
tenha. Precisa de uns 3 GB de disco, quase dois terços disso a imagem dos emuladores, e de nada
rodando em segundo plano além do Docker. Uma **máquina virtual** (VirtualBox, ou Multipass no
Windows e no macOS) custa uns 6 GB de disco e 4 GB de memória enquanto roda, e dá um Ubuntu limpo
para quebrar. Um **ambiente online** como o GitHub Codespaces dispensa instalação e já tem Docker,
ao preço de uma cota mensal de horas e de armazenamento que você deve conferir antes de depender
dele. A lição 1 do `gcp-foundations` percorre os três; os comandos abaixo são os mesmos em cada um.

## Os comandos

Os pacotes vêm do arquivo do próprio Ubuntu, e este é o único passo que precisa de `sudo`. A
última linha deixa você usar o Docker sem `sudo`; ela vale depois que você sair e entrar de novo:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq docker.io
sudo usermod -aG docker "$USER"
```

A linha de comando do Google Cloud, versão 591.0.0, e o Terraform 1.17.1, os dois desempacotados
na sua pasta pessoal. Num processador Arm, o que inclui uma máquina virtual num Mac com Apple
silicon, os nomes dos arquivos terminam em `arm` e `arm64` em vez de `x86_64` e `amd64`:

```sh
mkdir -p ~/gcp ~/.local/bin
cd ~/gcp
curl -sSO https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-591.0.0-linux-x86_64.tar.gz
tar -xzf google-cloud-cli-591.0.0-linux-x86_64.tar.gz -C ~/.local
rm google-cloud-cli-591.0.0-linux-x86_64.tar.gz
curl -sSO https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
unzip -q -o terraform_1.17.1_linux_amd64.zip terraform -d ~/.local/bin
rm terraform_1.17.1_linux_amd64.zip
```

O lado Python, num ambiente virtual próprio, para não mexer em mais nada da máquina: o Functions
Framework, a biblioteca cliente de Pub/Sub do Google e o gunicorn, um servidor web que as lições 8
e 19 usam:

```sh
python3 -m venv ~/gcp/venv
~/gcp/venv/bin/pip install -q functions-framework==3.10.2 google-cloud-pubsub==2.43.0 gunicorn==26.2.0
```

O provider de Terraform do Google, 8.9.0, baixado uma vez para uma pasta sua, e uma configuração do
Terraform que faz todo `terraform init` seguinte buscá-lo ali. Depois disso, nada que o Terraform
faz no curso precisa da internet:

```sh
mkdir -p ~/gcp/mirror && cd ~/gcp/mirror
cat > versions.tf <<'EOF'
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}
EOF
terraform providers mirror ~/.terraform.d/mirror
cd ~/gcp && rm -r ~/gcp/mirror
mkdir -p ~/.terraform.d/plugin-cache
cat > ~/.terraformrc <<EOF
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
provider_installation {
  filesystem_mirror {
    path = "$HOME/.terraform.d/mirror"
  }
}
EOF
```

As quatro imagens que as lições seguintes rodam. A primeira é do Google, com todos os emuladores
dentro; as outras três vêm do Docker Hub:

```sh
docker pull gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators
docker pull fsouza/fake-gcs-server:1.56.1
docker pull registry:3.1.2
docker pull python:3.12.13-slim
```

**Toda vez que você abrir um terminal para trabalhar**, estas linhas vêm primeiro. Elas põem as
ferramentas no caminho, dão nome ao projeto, à região e à zona do curso, e entregam ao Terraform
uma palavra para usar como token de acesso:

```sh
cd ~/gcp
source venv/bin/activate
export PATH="$HOME/.local/google-cloud-sdk/bin:$HOME/.local/bin:$PATH"
export CLOUDSDK_CORE_PROJECT=planner-dev
export CLOUDSDK_COMPUTE_REGION=southamerica-east1 CLOUDSDK_COMPUTE_ZONE=southamerica-east1-a
export GOOGLE_OAUTH_ACCESS_TOKEN=no-account
export CHECKPOINT_DISABLE=1
```

**`planner-dev` é o projeto do curso**, o mesmo que o `gcp-foundations` usa e que todo emulador
aceita como está escrito. `southamerica-east1` é São Paulo. `no-account` não é um token e o Google
o recusaria, e é essa a ideia: o Terraform precisa de alguma coisa antes de planejar, e essa coisa
nunca alcança uma conta real. `CHECKPOINT_DISABLE` impede o Terraform de perguntar à HashiCorp se
existe versão nova. O seu prompt ganha `(venv)` na frente; as transcrições o omitem.

## Verificando que responde

No seu terminal de trabalho:

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 591.0.0
bq 2.1.41
bundled-python3-unix 3.14.9
core 2026.10.26
gcloud-crc32c 1.0.0
gsutil 5.38
ana@laptop:~/gcp$ terraform version
Terraform v1.17.1
on linux_amd64

ana@laptop:~/gcp$ docker run --rm python:3.12.13-slim python3 --version
Python 3.12.13
ana@laptop:~/gcp$ gcloud config list
[compute]
region = southamerica-east1
zone = southamerica-east1-a
[core]
disable_usage_reporting = True
project = planner-dev

Your active configuration is: [default]
```

**A configuração veio das suas variáveis de ambiente, não de um arquivo**: `gcloud config list`
mostra o que está valendo, onde quer que tenha sido definido. E a única coisa que ele não mostra é
uma conta, que é onde o próximo comando esbarra:

```
ana@laptop:~/gcp$ gcloud compute machine-types list --zones=southamerica-east1-a
ERROR: (gcloud.compute.machine-types.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

Essa recusa acontece no seu computador, antes de qualquer coisa ser enviada. **Todo comando deste
curso que falaria com o Google termina ali**, e é por isso que as lições mostram esses comandos a
partir da documentação e os marcam, em vez de rodá-los.

## Quando não responde

Três falhas cobrem quase tudo. **O terminal é novo e as linhas acima não foram digitadas nele.** O
shell então responde que não encontra `gcloud` nem `terraform`; no Ubuntu com interface gráfica ele
pode sugerir a instalação de um pacote, sugestão que você deve ignorar, porque as ferramentas estão
instaladas e só falta o caminho. Digite as sete linhas de novo.

**O Terraform está sem token**, porque a linha `GOOGLE_OAUTH_ACCESS_TOKEN` foi pulada. Você
encontra essa na seção 04 desta lição, na primeira vez que roda um plan, e ela diz isso lá.

E **o Docker recusa você**, porque a mudança de grupo ainda não valeu nesta sessão:

```
ana@laptop:~/gcp$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Saia e entre de novo, ou reinicie a máquina virtual. O `id` lista `docker` entre os seus grupos
quando der certo.
