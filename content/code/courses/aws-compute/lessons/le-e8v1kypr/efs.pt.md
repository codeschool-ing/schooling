---
title: EFS, um sistema de arquivos para muitas instâncias
version: 1
---

Quando dois servidores web precisam dos mesmos arquivos enviados, a primeira ideia é um volume EBS
maior que os dois possam usar. **O EBS é um disco para uma instância numa zona; o EFS é um sistema de
arquivos para muitas, entre zonas.** Ele fala NFS, o protocolo de sistema de arquivos em rede que o
Linux tem há décadas, e uma instância o monta do jeito que montaria um compartilhamento de um
servidor de arquivos. Nada é provisionado: ele cresce conforme arquivos são escritos, encolhe
conforme são apagados, e é cobrado pelos bytes que guarda.

```schooling-figure
{"svg": "<svg id=\"fig-zones\" viewBox=\"0 0 720 344\" role=\"img\" aria-label=\"A região sa-east-1 com três zonas. Em sa-east-1a uma instância tem um volume EBS anexado. Um volume em sa-east-1b não pode ser anexado àquela instância: a AWS recusa um anexo vindo de outra zona. Cada zona tem um mount target do EFS com um endereço na própria sub-rede, 172.31.0.4, 172.31.16.4 e 172.31.32.4, e a instância de cada zona alcança o único sistema de arquivos EFS da região pelo target da sua zona.\"><defs><marker id=\"zones-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"12\" width=\"696\" height=\"320\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1, a região</text><rect x=\"28\" y=\"40\" width=\"208\" height=\"208\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"132\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1a</text><rect x=\"44\" y=\"68\" width=\"176\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"132\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instância</text><rect x=\"44\" y=\"196\" width=\"176\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"54\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">mount target</text><text x=\"212\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.0.4</text><line x1=\"188\" y1=\"108\" x2=\"188\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"132\" y1=\"234\" x2=\"132\" y2=\"266\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><rect x=\"44\" y=\"126\" width=\"84\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"86\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">volume EBS</text><rect x=\"256\" y=\"40\" width=\"208\" height=\"208\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1b</text><rect x=\"272\" y=\"68\" width=\"176\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instância</text><rect x=\"272\" y=\"196\" width=\"176\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"282\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">mount target</text><text x=\"440\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.16.4</text><line x1=\"416\" y1=\"108\" x2=\"416\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"360\" y1=\"234\" x2=\"360\" y2=\"266\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><rect x=\"272\" y=\"126\" width=\"84\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"314\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">volume EBS</text><rect x=\"484\" y=\"40\" width=\"208\" height=\"208\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"588\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1c</text><rect x=\"500\" y=\"68\" width=\"176\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"588\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">instância</text><rect x=\"500\" y=\"196\" width=\"176\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">mount target</text><text x=\"668\" y=\"215\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">172.31.32.4</text><line x1=\"644\" y1=\"108\" x2=\"644\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"588\" y1=\"234\" x2=\"588\" y2=\"266\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><line x1=\"72\" y1=\"108\" x2=\"72\" y2=\"124\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#zones-ah)\"></line><path d=\"M 256 146 L 208 104\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#zones-ah)\"></path><text x=\"314\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">recusado entre zonas</text><rect x=\"28\" y=\"268\" width=\"664\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360\" y=\"292\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">sistema de arquivos EFS: um por região, alcançado em toda zona</text></svg>", "caption": "Um volume nunca sai da zona. Um sistema de arquivos é alcançado de toda zona, pelo mount target de cada uma.", "same": ["mount target"]}
```

A figura é a diferença numa imagem só. Um volume e a instância que o usa ficam numa zona, e um anexo
vindo de outra zona é recusado. O sistema de arquivos pertence à região e é alcançado em cada zona
por um **mount target**, uma interface de rede com um endereço na sub-rede daquela zona. Uma
instância monta o target da própria zona, e toda instância vê os mesmos arquivos.

## Criando um

```
ana@laptop:~/aws$ FS=$(aws efs create-file-system --creation-token uploads-2026 --encrypted --tags Key=Name,Value=uploads --query FileSystemId --output text)
ana@laptop:~/aws$ aws efs describe-file-systems --file-system-id "$FS"
{
    "FileSystems": [
        {
            "OwnerId": "123456789012",
            "CreationToken": "uploads-2026",
            "FileSystemId": "fs-60519bb2",
            "FileSystemArn": "arn:aws:elasticfilesystem:sa-east-1:123456789012:file-system/fs-60519bb2",
            "CreationTime": "2026-10-16T13:38:47.212031-03:00",
            "LifeCycleState": "available",
            "Name": "uploads",
            "NumberOfMountTargets": 0,
            "SizeInBytes": {
                "Value": 0,
                "Timestamp": "2026-10-16T13:38:47.886142-03:00",
                "ValueInIA": 0,
                "ValueInStandard": 0
            },
            "PerformanceMode": "generalPurpose",
            "Encrypted": true,
            "ThroughputMode": "bursting",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "uploads"
                }
            ]
        }
    ]
}
```

A resposta tem a forma da AWS. Três coisas nela valem a leitura. `Encrypted` é `true` porque o pedido
pediu, e não dá para ligar depois; um sistema de arquivos criado sem criptografia fica assim.
`PerformanceMode` é `generalPurpose`, o que se escolhe a não ser que a orientação da AWS para uma
carga específica diga outra coisa. E `ThroughputMode` é `bursting`, o valor quando o pedido não cita
nenhum: o throughput então cresce com a quantidade guardada, que um sistema de arquivos pequeno tem
pouca. **A AWS recomenda `elastic` para cargas com picos ou imprevisíveis**, em que o throughput
acompanha a demanda e cada gigabyte lido ou escrito é cobrado, a um preço que a tabela não imprime.

`SizeInBytes` é 0, e no moto continua 0, porque o moto não serve NFS e não guarda arquivo nenhum.

## Mount targets, um por zona

Um mount target é alcançado pela rede na porta TCP 2049, então precisa de um security group que a
libere, e precisa de uma sub-rede em cada zona que vá montá-lo:

```
ana@laptop:~/aws$ VPC=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ SG=$(aws ec2 create-security-group --group-name efs-nfs --description "NFS from inside the VPC" --vpc-id "$VPC" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 2049 --cidr 172.31.0.0/16 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	2049	172.31.0.0/16
ana@laptop:~/aws$ for s in $(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" --query "Subnets[].SubnetId" --output text); do aws efs create-mount-target --file-system-id "$FS" --subnet-id "$s" --security-groups "$SG" --query "[MountTargetId,AvailabilityZoneName,IpAddress]" --output text; done
fsmt-191fccb7	sa-east-1a	172.31.0.4
fsmt-50da50b9	sa-east-1b	172.31.16.4
fsmt-22c08967	sa-east-1c	172.31.32.4
```

O security group deixa entrar a porta 2049 vinda de toda a VPC padrão, `172.31.0.0/16`; num deploy
real a origem seria o próprio security group dos servidores web, o padrão da lição 18 do
`aws-foundations`, e não uma faixa de endereços. Depois, um mount target por sub-rede da VPC padrão,
que tem uma sub-rede por zona, e cada target tem um endereço na faixa da sua zona.

**Um sistema de arquivos tem no máximo um mount target por zona**, e a AWS e o moto concordam nisso:

```
ana@laptop:~/aws$ A=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=availability-zone,Values=sa-east-1a --query "Subnets[0].SubnetId" --output text)
ana@laptop:~/aws$ aws efs create-mount-target --file-system-id "$FS" --subnet-id "$A" --security-groups "$SG"

aws: [ERROR]: An error occurred (MountTargetConflict) when calling the CreateMountTarget operation: mount target already exists in this AZ
ana@laptop:~/aws$ aws efs describe-file-systems --file-system-id "$FS" --query "FileSystems[0].[NumberOfMountTargets,ThroughputMode,SizeInBytes.Value]" --output text
3	bursting	0
```

Uma instância em `sa-east-1a` monta `172.31.0.4`, ou melhor, o nome DNS do sistema de arquivos, que
resolve em cada zona para o target daquela zona. Esse é o passo que esta lição não consegue
executar. Na AWS, com o auxiliar de montagem da própria Amazon, o `amazon-efs-utils`, instalado na
instância, é uma linha, e a opção `tls` criptografa o tráfego no caminho:

```sh
sudo dnf install -y amazon-efs-utils
sudo mkdir -p /mnt/uploads
sudo mount -t efs -o tls fs-0123456789abcdef0:/ /mnt/uploads
```

Esses comandos não foram executados; o moto não tem sistema de arquivos para montar nem instância
onde montá-lo. `fs-0123456789abcdef0` representa o id do seu sistema de arquivos, que na AWS tem
dezessete caracteres depois do `fs-`, onde o do moto tem oito.

## Quanto custa, e para que serve

A tabela de preços de 16 de outubro de 2026 dá ao EFS Standard **0,57 USD por GB-mês**, contra 0,152
do `gp3`: três vezes e três quartos por gigabyte. Duas coisas diminuem a distância. O EFS é cobrado
pelo que está guardado, enquanto um volume é cobrado pelo que foi provisionado. E é uma cópia para
todas as instâncias, enquanto volumes são um para cada:

| | guardado ou provisionado | por mês |
|---|---|---|
| EFS, 40 GB de uploads, compartilhados por quatro servidores web | 40 GB guardados | 22,80 USD |
| um volume `gp3` de 100 GB em cada um dos quatro | 400 GB provisionados | 60,80 USD |

Os volumes são mais baratos por gigabyte e mais caros no total, e não compartilham nada, que era o
requisito. O EFS também tem as classes de armazenamento Infrequent Access e Archive, a preços menores
que a tabela não traz, com uma política de ciclo de vida que move arquivos que ninguém leu por um
número definido de dias.

Ele serve para **arquivos que várias máquinas leem e escrevem**: uploads, a mídia de um gerenciador de
conteúdo, diretórios pessoais, um conjunto de dados que muitos workers leem, o volume compartilhado de
contêineres no ECS e no EKS, a que as lições 8 e 11 voltam. Serve mal para um banco: toda operação
atravessa a rede até um serviço regional, então cada uma demora mais que num dispositivo de bloco
local, e bancos são construídos justamente em torno dessa latência. Um banco fica no EBS, ou num
serviço de banco gerenciado.
