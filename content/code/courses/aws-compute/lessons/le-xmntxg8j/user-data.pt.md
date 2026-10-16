---
title: "User data: um script entregue no lançamento"
version: 1
---

Uma primeira imagem comum do user data é a de uma configuração que ajusta a instância, do jeito que
um launch template define o tipo dela. **Não é nada disso: user data é um pedaço de texto que o EC2
guarda ao lado da instância e devolve a ela quando ela pede.** O EC2 nunca o lê e nunca o roda.
Quem roda é um programa dentro da imagem, o **cloud-init** no Amazon Linux, no Ubuntu e em quase
toda outra AMI Linux publicada, que busca o texto logo no começo do primeiro boot e age sobre ele.

Essa divisão decide todo o resto desta seção. Os limites são do EC2, porque o EC2 guarda o texto.
O comportamento é do cloud-init, porque o cloud-init o roda. E quem pode lê-lo é quem puder
perguntar ao EC2 ou à instância, o que é mais gente do que a maioria dos autores de user data
imagina.

## Um script para o primeiro boot

Se o texto começa com `#!`, o cloud-init o roda como script, como root, uma vez. Aqui está um
para um pequeno servidor web no Amazon Linux 2023. Copie com o botão do bloco e salve como
`~/aws/first-boot.sh`:

```schooling-example
{"language": "sh", "file": "first-boot.sh", "parts": [{"code": "#!/bin/bash\nset -euo pipefail\n\n", "note": "Os dois primeiros caracteres dizem ao cloud-init que isto é um script para rodar, e não uma configuração para ler. `set -euo pipefail` para tudo no primeiro comando que falhar, para que uma instalação quebrada não siga adiante e deixe um servidor configurado pela metade."}, {"code": "dnf install -y nginx\n\n", "note": "O user data roda como root, então não há `sudo`. `dnf` é o gerenciador de pacotes do Amazon Linux 2023; numa imagem Ubuntu esta linha seria `apt-get`."}, {"code": "TOKEN=$(curl -sS -X PUT http://169.254.169.254/latest/api/token \\\n  -H 'X-aws-ec2-metadata-token-ttl-seconds: 300')\n", "note": "Um token de sessão do serviço de metadados da instância, válido por 300 segundos. A seção 04 diz por que um `PUT` vem antes de toda leitura."}, {"code": "ZONE=$(curl -sS -H \"X-aws-ec2-metadata-token: $TOKEN\" \\\n  http://169.254.169.254/latest/meta-data/placement/availability-zone)\n\n", "note": "A instância pergunta em que zona de disponibilidade está, com o token num cabeçalho. Nada sobre a zona foi escrito no script: cada instância lançada com ele descobre a própria."}, {"code": "echo \"<h1>served from $ZONE</h1>\" > /usr/share/nginx/html/index.html\nsystemctl enable --now nginx\n", "note": "A página diz a zona, então quando um balanceador de carga espalha os pedidos por várias instâncias dá para ver qual respondeu. `enable --now` inicia o nginx agora e em todo boot seguinte, o que importa porque este script não vai rodar de novo."}]}
```

Duas linhas dele leem os metadados da própria instância, que são o assunto das duas próximas
seções. Estão aí porque são o motivo comum de o user data existir: **um script, lançado em muitas
instâncias, cada uma das quais descobre os próprios fatos no boot** em vez de recebê-los
digitados. Um script com a zona escrita nele estaria certo numa instância e errado no resto.

O cloud-init também lê um segundo formato, um arquivo YAML que começa com `#cloud-config` e
declara pacotes, usuários e arquivos em vez de rodar comandos. É a escolha melhor para qualquer
coisa maior que este script, e o formato é do próprio cloud-init, não da AWS, documentado no site
do cloud-init. Tudo o que vem abaixo sobre como o EC2 guarda e entrega o texto vale para os dois.

## Entregando o script

A imagem é uma AMI do Amazon Linux 2023 do catálogo do moto; a aula 2 diz o que é esse catálogo e
como achar a que a AWS publica hoje. O script entra com `--user-data`:

```
ana@laptop:~/aws$ AMI=$(aws ec2 describe-images --owners amazon --filters Name=name,Values=al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64 --query "Images[0].ImageId" --output text)
ana@laptop:~/aws$ echo "$AMI"
ami-0629d059c178d0eac
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --user-data file://first-boot.sh --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ echo "$ID"
i-667121efeb55d85d5
```

**O EC2 guarda o user data codificado em base64**, e quem codificou foi a AWS CLI: `file://` lê
o arquivo e a CLI o codifica no caminho. Pedir de volta mostra a forma guardada, e decodificar
mostra o script:

```
ana@laptop:~/aws$ aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | cut -c1-60
IyEvYmluL2Jhc2gKc2V0IC1ldW8gcGlwZWZhaWwKCmRuZiBpbnN0YWxsIC15
ana@laptop:~/aws$ aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | base64 -d | head -4
#!/bin/bash
set -euo pipefail

dnf install -y nginx
ana@laptop:~/aws$ wc -c < first-boot.sh
395
ana@laptop:~/aws$ base64 -w0 first-boot.sh | wc -c
528
```

Os 395 bytes do script viraram 528 caracteres de base64, que é o quatro-por-três que o base64
sempre custa. **O limite que a AWS documenta é de 16 KB de user data na forma crua, antes da
codificação**, então não são os 528 caracteres que contam para ele. O moto não cobra o limite, e
lança com um script de 20.000 bytes:

```
ana@laptop:~/aws$ yes "echo padding" | head -c 20000 > big.sh
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$AMI" --instance-type t3.micro --user-data file://big.sh --query "Instances[0].State.Name" --output text
pending
```

A AWS recusa esse lançamento. Um script que precisa de mais de 16 KB está dizendo para você
embutir o software numa imagem, que é o que a aula 2 faz, ou para ter um script pequeno que baixa
o resto.

## Ele roda uma vez

**O cloud-init roda um script de user data no primeiro boot de cada instância, e não num reboot
nem num stop e start.** Ele registra que a instância já fez isso, então um reboot pula o script.
É o comportamento certo para instalar pacotes, e o lugar errado para qualquer coisa que tenha de
acontecer a cada início: isso pertence a um serviço que o script instala, e é por isso que o
exemplo habilita o nginx em vez de só iniciá-lo.

Também quer dizer que **mudar o user data de uma instância em execução não muda nada do que já
aconteceu.** A AWS só deixa substituí-lo com a instância parada. Mesmo assim o cloud-init não vai
rodar o script novo no próximo início, porque a instância já teve o primeiro boot. O moto não
confere nenhuma das duas coisas. Ele aceitou uma substituição numa instância no estado
`running`:

```
ana@laptop:~/aws$ printf "#!/bin/bash\necho changed\n" > second.sh
ana@laptop:~/aws$ aws ec2 modify-instance-attribute --instance-id "$ID" --attribute userData --value "$(base64 -w0 second.sh)"
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].State.Name" --output text
running
ana@laptop:~/aws$ aws ec2 describe-instance-attribute --instance-id "$ID" --attribute userData --query UserData.Value --output text | base64 -d
#!/bin/bash
echo changed
```

Na AWS essa chamada é recusada até a instância parar. O jeito de dar um script novo a uma frota não
é editar as instâncias antigas, mas lançar instâncias novas com ele, que é o que uma versão de
launch template e um instance refresh fazem na aula 4.

Quando um primeiro boot dá errado, o log da própria instância é onde olhar. O cloud-init escreve o
que o script imprimiu em `/var/log/cloud-init-output.log`, e `cloud-init status --wait` espera
o primeiro boot terminar e diz se falhou. O moto não roda nada, então nenhum dos dois existe aqui.

## Não é segredo

A decodificação acima só precisou da permissão de descrever a instância. **Quem tem permissão de
`ec2:DescribeInstanceAttribute` na conta lê o user data por inteiro**, e na instância qualquer
processo que alcance o serviço de metadados também o lê, em `/latest/user-data`. Uma senha de
banco de dados ou uma chave de API escrita no user data fica escrita num lugar que muita coisa
lê, e fica lá pela vida inteira da instância.

O script acima não leva segredo nenhum, e esse é o padrão a manter. O que uma instância precisa
para se autenticar vem da role associada a ela, que a aula 10 de `aws-foundations` associou como
instance profile, e um segredo propriamente dito é buscado no boot no Secrets Manager com a
permissão dessa role, que a aula 17 de `aws-operations` ensina. Os dois passam pelo serviço de
metadados, que é onde a próxima seção começa.
