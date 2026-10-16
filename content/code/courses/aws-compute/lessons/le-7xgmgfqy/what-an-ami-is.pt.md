---
title: O que é uma AMI, e como achar a certa
version: 1
---

Uma AMI costuma ser imaginada como um arquivo, uma imagem de disco que alguém enviou, do jeito que
uma ISO é um arquivo. **Uma AMI é um registro que aponta para snapshots.** O registro diz do que a
máquina precisa para dar boot: a arquitetura do processador, como ela inicia, qual dispositivo é o
disco raiz. Os snapshots guardam os bytes. Lançar uma instância lê o registro, cria um volume EBS
novo a partir de cada snapshot que ele aponta e dá boot pelo volume raiz.

```schooling-figure
{"svg": "<svg id=\"fig-ami-anatomy\" viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Dentro da região sa-east-1, uma AMI é um registro: arquitetura x86_64, modo de boot uefi, dispositivo raiz /dev/xvda e um mapeamento de dispositivos de bloco. O mapeamento aponta um snapshot, que guarda os blocos do disco raiz. Um launch cria um volume EBS a partir do snapshot dentro de uma zona, sa-east-1a, e a instância dá boot desse volume.\"><defs><marker id=\"ami-anatomy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"688\" height=\"262\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">sa-east-1, a região</text><rect x=\"36\" y=\"56\" width=\"220\" height=\"156\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"146\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">a AMI, um registro</text><text x=\"50\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Architecture: x86_64</text><text x=\"50\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BootMode: uefi</text><text x=\"50\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">RootDeviceName: /dev/xvda</text><text x=\"50\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BlockDeviceMappings:</text><text x=\"50\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">  SnapshotId: snap-…</text><line x1=\"256\" y1=\"160\" x2=\"298\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ami-anatomy-ah)\"></line><text x=\"277\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aponta</text><rect x=\"300\" y=\"126\" width=\"150\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"375\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">snapshot</text><text x=\"375\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os blocos do disco raiz</text><text x=\"375\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um launch cria um volume</text><text x=\"375\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a partir dele, numa zona</text><rect x=\"478\" y=\"46\" width=\"210\" height=\"214\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"490\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1a, uma zona</text><rect x=\"498\" y=\"82\" width=\"170\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"583\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">volume EBS</text><text x=\"583\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">feito do snapshot</text><line x1=\"450\" y1=\"160\" x2=\"496\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ami-anatomy-ah)\"></line><line x1=\"583\" y1=\"140\" x2=\"583\" y2=\"184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ami-anatomy-ah)\"></line><text x=\"592\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">como raiz</text><rect x=\"498\" y=\"186\" width=\"170\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"583\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instância</text><text x=\"583\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dá boot desse volume</text></svg>", "caption": "Uma AMI não guarda bytes próprios. Ela descreve a máquina e aponta os snapshots; um launch transforma cada snapshot num volume na zona escolhida.", "same": ["snapshot"]}
```

Essa divisão explica dois fatos que de outro modo parecem arbitrários. Uma AMI pertence a **uma
região**, porque os snapshots dela ficam guardados naquela região, e o id dela não significa nada em
outro lugar. E uma AMI custa dinheiro enquanto os snapshots dela existirem, que é a última seção
desta lição.

## Lendo uma

O Amazon Linux 2023 é a distribuição da própria AWS, e a próxima seção mostra como achar a imagem
atual dele. Aqui está o registro dessa imagem, inteiro:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-0b44997419d0b0d38
{
    "Images": [
        {
            "BlockDeviceMappings": [
                {
                    "Ebs": {
                        "DeleteOnTermination": false,
                        "SnapshotId": "snap-ff7826474c5a02103",
                        "VolumeSize": 15,
                        "VolumeType": "standard"
                    },
                    "DeviceName": "/dev/xvda"
                }
            ],
            "Description": "Amazon Linux 2023 AMI 2023.12.20260727.0 x86_64 HVM kernel-6.1",
            "Hypervisor": "xen",
            "ImageOwnerAlias": "amazon",
            "Name": "al2023-ami-2023.12.20260727.0-kernel-6.1-x86_64",
            "RootDeviceName": "/dev/xvda",
            "RootDeviceType": "ebs",
            "Tags": [],
            "VirtualizationType": "hvm",
            "BootMode": "uefi",
            "ImageId": "ami-0b44997419d0b0d38",
            "State": "available",
            "OwnerId": "137112412989",
            "CreationDate": "2026-10-16T16:25:15.000Z",
            "Public": true,
            "ProductCodes": [],
            "Architecture": "x86_64",
            "ImageType": "machine"
        }
    ]
}
```

Os campos que decidem se um launch funciona são estes:

| campo | aqui | o que decide |
|---|---|---|
| `Architecture` | `x86_64` | em que tipos ela roda; a lição 1 mostrou o que o moto deixa passar |
| `BootMode` | `uefi` | como o firmware a inicia; alguns tipos antigos só dão boot em `legacy-bios` |
| `VirtualizationType` | `hvm` | virtualização completa do hardware, que todo tipo atual usa |
| `RootDeviceName` | `/dev/xvda` | qual dos discos mapeados é o raiz |
| `BlockDeviceMappings` | um, com um `SnapshotId` | os discos que uma instância nova recebe, e de que cada um é feito |
| `OwnerId` | `137112412989` | a conta que a publicou, aqui a da Amazon |
| `Public` | `true` | qualquer conta pode lançá-la |

**O mapeamento de dispositivos de bloco é a AMI.** Todo o resto é descrição; o mapeamento é o que
vira disco. Ele leva um tamanho, um tipo de volume e se o volume é apagado quando a instância é
encerrada, e um launch pode trocar qualquer um deles na própria cópia: um volume raiz maior, ou
`gp3` em vez do que a imagem diz.

É também aqui que a cópia do moto deixa de ser a da AWS. O registro do moto mapeia um volume de
15 GB do tipo `standard`, mantido no encerramento, e data a imagem no segundo em que o moto
iniciou; a build de 2023 no nome diz quando a Amazon de fato a fez. **O registro da própria AWS para
esta imagem mapeia um raiz `gp3` de 8 GiB, apagado junto com a instância.** A estrutura é a que a
AWS devolve; os valores nela são do moto.

## Achando a atual: o parâmetro público

O id de uma AMI muda toda vez que quem a publica a reconstrói, o que para uma distribuição mantida
acontece a cada poucas semanas, com as correções de segurança mais recentes. Um id escrito num
template é portanto a cópia de um fato que deixa de ser verdade. **A AWS publica o id atual sob um
nome que não muda**, como um parâmetro público do Parameter Store do Systems Manager, e qualquer um
pode lê-lo:

```
ana@laptop:~/aws$ aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text
ami-0b44997419d0b0d38
```

Esse nome vai responder com outro id no mês que vem, e é essa a ideia: o parâmetro anda, o template
que o lê não. Um launch template pode citar o parâmetro em vez do id, com `resolve:ssm:` na frente, e
resolvê-lo a cada launch; a lição 4 monta um. O moto traz uma cópia desses parâmetros do Amazon
Linux, e é por isso que a chamada acima respondeu.

A Canonical faz o mesmo para o Ubuntu, sob um caminho próprio. O moto não tem cópia desse:

```
ana@laptop:~/aws$ aws ssm get-parameter --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id

aws: [ERROR]: An error occurred (ParameterNotFound) when calling the GetParameter operation: Parameter /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id not found.
```

**Na AWS o mesmo comando devolve a imagem atual do Ubuntu 24.04 para `sa-east-1`.** Ele não foi
executado aqui, e o caminho é o que a Canonical documenta para a build `amd64` com raiz `gp3`; uma
build `arm64` tem o caminho dela ao lado.

## Achando uma pelo dono e pelo nome

Antes de os parâmetros existirem, o jeito de achar uma imagem era filtrar o catálogo pelo dono e
pelo nome e pegar a mais nova. Isso ainda funciona na AWS, e vale conhecer porque você vai
encontrá-lo em scripts antigos:

```
ana@laptop:~/aws$ aws ec2 describe-images --query "length(Images)"
1155
ana@laptop:~/aws$ aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/*" --query "sort_by(Images,&CreationDate)[].[ImageId,CreationDate,Name]" --output text
ami-1e749f67	2026-10-16T16:25:15.000Z	ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-20170727
ami-785db401	2026-10-16T16:25:15.000Z	ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-20170721
```

O catálogo do moto tem 1.155 imagens, e para a conta da Canonical, `099720109477`, tem duas: Ubuntu
14.04 e 16.04, feitas em 2017. As duas são fixtures do moto e nenhuma é algo que você lançaria hoje.
Olhe as datas também. **Toda imagem que o moto traz é datada no momento em que o moto iniciou**,
então ordenar por `CreationDate`, o truque todo do idioma, não ordena nada aqui. Na AWS a data é
quando a imagem foi registrada, e a ordenação funciona.

**Filtre sempre pelo dono.** Um filtro só de nome casa com toda imagem pública cujo nome começa
igual, e qualquer um pode publicar uma imagem pública chamada `ubuntu/images/…` na própria conta. O
id do dono é o que diz que foi a Canonical que a fez. O parâmetro evita a questão por completo, e
esse é o argumento mais forte a favor dele.
