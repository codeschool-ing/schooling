---
title: Construindo uma imagem sua
version: 1
---

Construir uma imagem parece um tipo especial de trabalho, com ferramentas próprias. **Uma imagem sua
é uma instância que você configurou, salva.** Você lança uma a partir de uma imagem publicada,
instala e configura o que toda máquina precisa, e pede ao EC2 que transforme os discos dela numa AMI
nova. Toda ferramenta que constrói imagens, de um botão no console ao Packer, executa esses mesmos
três passos.

## Os três passos

A partir da imagem do Amazon Linux 2023 que o parâmetro aponta, uma instância pequena:

```
ana@laptop:~/aws$ BASE=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id "$BASE" --instance-type t3.micro --query "Instances[0].InstanceId" --output text)
```

**É aqui que o trabalho entraria**, e é o único passo que esta lição não consegue executar. Na AWS
você se conectaria à instância, ou daria a ela um user data, e instalaria o software: `sudo dnf
install -y nginx`, a configuração, a aplicação numa versão conhecida. O moto não inicia máquina
nenhuma, então não há onde se conectar e nada é instalado; a lição 7 é sobre user data, o jeito
scriptado de fazer esse passo. A imagem abaixo é feita de uma instância que tem exatamente o que a
imagem base tinha, e a descrição dela é um rótulo que escolhemos.

Depois, a própria imagem:

```
ana@laptop:~/aws$ IMG=$(aws ec2 create-image --instance-id "$ID" --name web-2026-10-16 --description "nginx on Amazon Linux 2023" --tag-specifications "ResourceType=image,Tags=[{Key=app,Value=web}]" --query ImageId --output text)
ana@laptop:~/aws$ aws ec2 describe-images --owners self
{
    "Images": [
        {
            "BlockDeviceMappings": [
                {
                    "Ebs": {
                        "DeleteOnTermination": false,
                        "SnapshotId": "snap-ea6b97d76b42a5e1a",
                        "VolumeSize": 15,
                        "VolumeType": "standard"
                    },
                    "DeviceName": "/dev/sda1"
                }
            ],
            "Description": "nginx on Amazon Linux 2023",
            "Name": "web-2026-10-16",
            "RootDeviceName": "/dev/sda1",
            "RootDeviceType": "standard",
            "Tags": [
                {
                    "Key": "app",
                    "Value": "web"
                }
            ],
            "VirtualizationType": "hvm",
            "BootMode": "uefi",
            "SourceInstanceId": "i-52f3615249060ee52",
            "ImageId": "ami-a9a13e442ffd8c0ff",
            "State": "available",
            "OwnerId": "123456789012",
            "CreationDate": "2026-10-16T16:25:26.000Z",
            "Public": false,
            "ProductCodes": [],
            "Architecture": "x86_64",
            "ImageType": "machine"
        }
    ]
}
```

O `create-image` devolveu um id de AMI, guardado aqui em `IMG`, e o registro tem a mesma forma do
da Amazon: `OwnerId` agora é a conta do moto, `123456789012`, `Public` é `false`, e
`SourceInstanceId` aponta a instância de onde ela foi feita. A tag foi aplicada à imagem na criação,
que é o jeito de dar a uma imagem a versão e o dono desde o início. O moto também renomeou o
dispositivo raiz para `/dev/sda1`, onde a imagem base dizia `/dev/xvda`, um detalhe dele e não da
AWS.

**Por padrão, o `create-image` reinicia a instância antes**, para que tudo o que o sistema
operacional tinha na memória seja gravado e o snapshot seja de um sistema de arquivos em repouso. O
`--no-reboot` pula isso, e a imagem passa a ter a consistência de uma queda de energia, como a seção
anterior disse de qualquer snapshot. É a opção certa só para uma máquina que você não pode
reiniciar e cujo disco não está sendo escrito.

## Do que a imagem é feita

O mapeamento aponta um snapshot, e o snapshot diz de onde veio:

```
ana@laptop:~/aws$ SNAP=$(aws ec2 describe-images --image-ids "$IMG" --query "Images[0].BlockDeviceMappings[0].Ebs.SnapshotId" --output text)
ana@laptop:~/aws$ aws ec2 describe-snapshots --snapshot-ids "$SNAP" --query "Snapshots[].[SnapshotId,VolumeSize,Description]" --output text
snap-ea6b97d76b42a5e1a	15	Created by CreateImage(i-52f3615249060ee52) for ami-a9a13e442ffd8c0ff
```

O EC2 tirou um snapshot de cada volume da instância e escreveu o id da AMI na descrição, para que um
snapshot achado sozinho depois possa ser ligado de volta à imagem que é dona dele. Esse snapshot é o
que você paga enquanto a imagem existir.

## Lançando a partir dela

O id novo lança como qualquer outro, e toda máquina lançada a partir dele começa com os mesmos
bytes:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$IMG" --instance-type t3.micro --count 2 --query "Instances[].[InstanceId,ImageId]" --output text
i-ec83a4a0f45b85084	ami-a9a13e442ffd8c0ff
i-c8ee5215dcef0048f	ami-a9a13e442ffd8c0ff
```

**Essa igualdade é para que serve uma imagem.** Duas máquinas lançadas dela com um mês de diferença
são idênticas, enquanto duas máquinas que instalaram o software no boot pegam o que os espelhos de
pacotes tinham em cada dia. Uma imagem não muda depois de feita; uma correção é uma imagem nova com
um id novo, e as máquinas passam para ela sendo trocadas, o que o instance refresh da lição 4 faz
para um grupo inteiro.

## Embutir ou configurar no boot

Cada software de que uma máquina precisa pode entrar na imagem ou ser instalado quando a máquina
inicia. A troca, em resumo:

| | na imagem | no primeiro boot |
|---|---|---|
| tempo do launch até atender | o boot | o boot e cada instalação |
| depende, no launch, de | nada fora da instância | espelhos de pacotes, downloads |
| dois launches com um mês de diferença | os mesmos bytes | o que estava atual em cada dia |
| uma correção de segurança | uma imagem nova, depois trocar as máquinas | o próximo launch já pega |

A resposta usual é as duas coisas: **embuta o que é lento de instalar e muda pouco**, o runtime, os
pacotes e a aplicação numa versão. Configure no boot o que difere por máquina ou não pode ser
escrito numa imagem, como o ambiente a que ela pertence ou um segredo buscado no início. Um segredo
embutido numa imagem está em todo snapshot dela e em toda conta com que a imagem é compartilhada,
que é a próxima seção.

## As ferramentas que fazem isso por você

Feitos à mão, os três passos são uma lista em que alguém esquece uma linha. Duas ferramentas os
executam do mesmo jeito toda vez:

- **EC2 Image Builder** é o serviço gerenciado da AWS. Uma *recipe* aponta a imagem base e os
  *components*, cada um um documento de passos de build; um *pipeline* roda a recipe por agenda ou
  sob demanda, testa o resultado e distribui a AMI para as regiões e contas que nomeia. Ele não
  cobra nada por si; você paga as instâncias e os snapshots que ele usa. Ele não foi executado
  aqui, porque o moto não o implementa.
- **Packer**, da HashiCorp, funciona em várias nuvens, e a lição 20 do curso `iac` constrói uma
  imagem com ele. O builder `amazon-ebs` dele lança uma instância, roda os seus provisioners por
  SSH, chama o `create-image` e encerra a instância: os passos acima, num arquivo sob controle de
  versão.

Seja quem for que a construa, dê às imagens nomes que uma pessoa consiga ordenar: a aplicação e a
data, como `web-2026-10-16` faz aqui, com a versão e a build em tags. O launch template da lição 4 é
onde um nome assim é escolhido para um grupo de máquinas.
