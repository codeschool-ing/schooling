---
title: Anexar, aumentar e sobreviver a uma instância
version: 1
---

Como um volume EBS viaja pela rede, é fácil imaginá-lo acessível de qualquer lugar, como um
compartilhamento. **Um volume vive numa Availability Zone e só se anexa a instâncias dessa zona.**
Ele é replicado dentro da zona, o que o faz sobreviver a um disco com defeito. Não é replicado fora
dela, então uma zona que falha leva junto a disponibilidade dos volumes dela, e os snapshots da
lição 2 são o jeito de um volume mudar de lugar.

## Uma zona, e o moto não confere

Uma instância em `sa-east-1a`, um volume na mesma zona e um em `sa-east-1b`:

```
ana@laptop:~/aws$ ID=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.large --placement AvailabilityZone=sa-east-1a --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ DATA=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)
ana@laptop:~/aws$ OTHER=$(aws ec2 create-volume --availability-zone sa-east-1b --size 100 --volume-type gp3 --query VolumeId --output text)
ana@laptop:~/aws$ aws ec2 attach-volume --volume-id "$DATA" --instance-id "$ID" --device /dev/sdf
{
    "VolumeId": "vol-fd3ae45872843be39",
    "InstanceId": "i-f1a1f240dc0908e71",
    "Device": "/dev/sdf",
    "State": "attaching",
    "AttachTime": "2026-10-16T16:38:30+00:00"
}
ana@laptop:~/aws$ aws ec2 attach-volume --volume-id "$OTHER" --instance-id "$ID" --device /dev/sdg --query State --output text
attaching
ana@laptop:~/aws$ aws ec2 describe-volumes --volume-ids "$DATA" "$OTHER" --query "Volumes[].[VolumeId,AvailabilityZone,State,Attachments[0].Device]" --output text
vol-fd3ae45872843be39	sa-east-1a	in-use	/dev/sdf
vol-cd4c70eb907c35f3b	sa-east-1b	in-use	/dev/sdg
```

O primeiro anexo é o normal. **O segundo seria recusado na AWS** com `InvalidVolume.ZoneMismatch`,
porque o volume e a instância estão em zonas diferentes; o moto o anexou mesmo assim e o lista como
`in-use`. O jeito de dar àquela instância os dados do segundo volume é o que a lição 2 mostrou: tirar
um snapshot dele e criar um volume a partir do snapshot em `sa-east-1a`.

O nome de dispositivo do pedido, `/dev/sdf`, é mais uma sugestão que um nome. Nos tipos Nitro, que
são todas as gerações atuais, o sistema operacional vê um dispositivo NVMe como `/dev/nvme1n1`, e a
ordem em que os dispositivos aparecem não tem garantia de bater com a ordem em que você os anexou.
Dentro da instância um volume novo é um dispositivo de bloco vazio: é formatado uma vez com `mkfs`,
montado e citado no `/etc/fstab` pelo UUID do sistema de arquivos com a opção `nofail`, para que um
volume ausente não impeça a máquina de dar boot. Nada disso rodou aqui, porque a instância do moto
não tem sistema operacional onde rodar.

## Aumentando um volume em uso

Tamanho, IOPS e throughput podem ser mudados num volume anexado e em uso:

```
ana@laptop:~/aws$ aws ec2 modify-volume --volume-id "$DATA" --size 200 --iops 6000 --throughput 250
{
    "VolumeModification": {
        "VolumeId": "vol-fd3ae45872843be39",
        "ModificationState": "completed",
        "TargetSize": 200,
        "TargetIops": 6000,
        "TargetThroughput": 250,
        "OriginalSize": 100,
        "OriginalIops": 3000,
        "Progress": 100,
        "StartTime": "2026-10-16T16:38:35+00:00",
        "EndTime": "2026-10-16T16:38:35+00:00"
    }
}
```

O moto terminou a mudança na hora. **Na AWS uma modificação passa por `modifying` e `optimizing`
antes de `completed`**, o que leva de minutos a horas num volume grande, e o volume continua usável o
tempo todo, no desempenho antigo até a mudança valer. A AWS então pede que você espere seis horas
antes de modificar o mesmo volume de novo.

Um volume maior não faz um sistema de arquivos maior. A partição e o sistema de arquivos lá dentro
continuam no tamanho antigo até serem aumentados de dentro da instância: `growpart` para a partição,
depois `xfs_growfs` para XFS, que é o que o Amazon Linux usa, ou `resize2fs` para ext4. Esse passo
também não foi executado aqui.

A outra direção é de novo a tolerância do moto:

```
ana@laptop:~/aws$ aws ec2 modify-volume --volume-id "$DATA" --size 50 --query "VolumeModification.[ModificationState,OriginalSize,TargetSize]" --output text
completed	200	50
```

Ele encolheu o volume de 200 para 50 GiB. **A AWS nunca encolhe um volume EBS**, e recusa o pedido;
um disco menor é um volume novo e uma cópia dos arquivos, feita dentro do sistema operacional.

## Apagar no encerramento

Todo anexo leva uma opção que decide o que acontece com o volume quando a instância é encerrada:

```
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].BlockDeviceMappings[].[DeviceName,Ebs.VolumeId,Ebs.DeleteOnTermination]" --output text
/dev/sda1	vol-76af8a3bd7f326bb3	True
/dev/sdf	vol-fd3ae45872843be39	False
/dev/sdg	vol-cd4c70eb907c35f3b	False
```

O volume raiz, feito da imagem quando a instância foi lançada, tem `DeleteOnTermination` em `True`.
Os dois anexados depois têm `False`, que é o padrão para qualquer volume anexado a uma instância em
execução. Encerrar a instância mostra o que isso significa:

```
ana@laptop:~/aws$ ROOT=$(aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" --output text)
ana@laptop:~/aws$ aws ec2 terminate-instances --instance-ids "$ID" --query "TerminatingInstances[0].CurrentState.Name" --output text
shutting-down
ana@laptop:~/aws$ aws ec2 describe-volumes --volume-ids "$DATA" --query "Volumes[].[VolumeId,State,Size]" --output text
vol-fd3ae45872843be39	available	50
ana@laptop:~/aws$ aws ec2 describe-volumes --volume-ids "$ROOT"

aws: [ERROR]: An error occurred (InvalidVolume.NotFound) when calling the DescribeVolumes operation: The volume '{'vol-76af8a3bd7f326bb3'}' does not exist.
```

O volume raiz se foi, e o volume de dados está `available`, desanexado e intacto, com tudo o que tem
nele, que é em geral o que você quer para dados. **Ele também continua sendo cobrado.** Um volume
`gp3` de 100 GB esquecido custa 15,20 USD por mês na tabela de preços de 16 de outubro de 2026, e uma
conta em que toda instância de teste encerrada deixou um para trás os acumula em silêncio. Achá-los é
`aws ec2 describe-volumes --filters Name=status,Values=available`, e uma equipe que roda isso toda
semana descobre de quem é cada um.

A opção pode ser mudada numa instância em execução, por dispositivo:

```
ana@laptop:~/aws$ ID2=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.large --placement AvailabilityZone=sa-east-1a --query "Instances[0].InstanceId" --output text)
ana@laptop:~/aws$ aws ec2 attach-volume --volume-id "$DATA" --instance-id "$ID2" --device /dev/sdf --query State --output text
attaching
ana@laptop:~/aws$ aws ec2 modify-instance-attribute --instance-id "$ID2" --block-device-mappings "DeviceName=/dev/sdf,Ebs={DeleteOnTermination=true}"
ana@laptop:~/aws$ aws ec2 describe-instances --instance-ids "$ID2" --query "Reservations[0].Instances[0].BlockDeviceMappings[].[DeviceName,Ebs.DeleteOnTermination]" --output text
/dev/sda1	True
/dev/sdf	True
```

O volume de dados, anexado a uma instância nova, agora vai ser apagado junto com ela. Use assim para
volumes de rascunho que não significam nada sem a instância, e deixe `False` para tudo o que você
gostaria de recuperar. Um auto scaling group, na lição 4, lança toda instância a partir de um
template, e o mapeamento do template é onde essa escolha é feita para uma frota inteira.

## Reiniciar, parar e encerrar, para um volume

| | reiniciar | parar | encerrar |
|---|---|---|---|
| a instância | reinicia no mesmo host | desligada, host liberado | apagada |
| um volume EBS anexado | mantido, anexado | mantido, anexado, ainda cobrado | apagado se a opção dele mandar, senão fica `available` |
| instance store | mantido | apagado | apagado |

A última linha é a próxima seção.
