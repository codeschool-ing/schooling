---
title: Copiando, compartilhando e aposentando uma imagem
version: 1
---

Uma imagem parece pronta quando já lança. **Uma imagem tem uma vida depois de construída**: é
copiada para as regiões que precisam dela, compartilhada com as contas que a lançam, marcada como
velha quando uma mais nova a substitui e, por fim, desregistrada. O último passo é o que as pessoas
acertam pela metade, porque desregistrar uma imagem não apaga aquilo que você estava pagando.

## Copiando para outra região

Um id de AMI só significa algo numa região, então uma máquina na Virgínia do Norte não consegue
lançar a imagem construída em São Paulo. Ela precisa ser copiada:

```
ana@laptop:~/aws$ aws ec2 copy-image --source-region sa-east-1 --source-image-id "$IMG" --region us-east-1 --name web-2026-10-16
{
    "ImageId": "ami-fafccb322fa427951"
}
ana@laptop:~/aws$ aws ec2 describe-images --owners self --region us-east-1 --query "Images[].[ImageId,Name,State]" --output text
ami-fafccb322fa427951	web-2026-10-16	available
```

A cópia tem um id próprio, e é uma imagem separada, com **snapshots separados, guardados e cobrados
na segunda região**. Nada liga as duas depois: desregistrar a original deixa a cópia, e uma correção
numa não é correção na outra. Uma cópia também é o momento de criptografar uma imagem que não era,
citando uma chave KMS com `--encrypted --kms-key-id`; os snapshots da cópia passam a ser
criptografados com essa chave.

## Compartilhando com outra conta

É comum uma organização construir imagens numa conta e lançá-las em outras: desenvolvimento,
staging, produção. Uma imagem é privada do dono até que uma **launch permission** cite outra conta:

```
ana@laptop:~/aws$ aws ec2 modify-image-attribute --image-id "$IMG" --launch-permission "Add=[{UserId=111122223333}]"
ana@laptop:~/aws$ aws ec2 describe-image-attribute --image-id "$IMG" --attribute launchPermission
{
    "ImageId": "ami-a9a13e442ffd8c0ff",
    "LaunchPermissions": [
        {
            "UserId": "111122223333"
        }
    ]
}
```

`111122223333` é o id de conta de exemplo que a AWS usa na documentação. Uma vez citada, essa conta
pode lançar a imagem pelo id, e não vira dona dela: não pode mudar as permissões da imagem nem
desregistrá-la, e se você a desregistrar, o próximo launch dela falha, embora as instâncias que ela
já roda continuem. Para ter uma cópia sua, a outra conta copia a imagem, o que a torna dona da cópia.

Três coisas dão errado aqui na AWS, e o moto não confere nenhuma delas:

- **Uma imagem criptografada com a chave padrão gerenciada pela AWS não pode ser compartilhada.**
  Essa chave é privada da conta. Imagens feitas para compartilhar são criptografadas com uma chave
  KMS gerenciada pelo cliente, e a política da chave concede à outra conta o uso dela, que é a
  gramática de políticas da lição 7 do `aws-foundations` aplicada a uma chave.
- **Compartilhar com todo mundo** é o mesmo comando com `Group=all`, e publica cada byte da imagem,
  inclusive qualquer segredo que alguém tenha embutido nela. A AWS tem uma configuração por conta,
  *block public access for AMIs*, que recusa isso; confira se está ligada em toda conta que constrói
  imagens.
- **Compartilhar com uma organização** cita um ARN do AWS Organizations em vez de uma conta, então
  uma conta nova nela pode lançar a imagem no dia em que é criada.

## Marcando como velha

Quando uma imagem mais nova substitui esta, nada avisa quem ainda lança o id antigo. A resposta da
AWS é uma **data de descontinuação**:

```
ana@laptop:~/aws$ aws ec2 enable-image-deprecation --image-id "$IMG" --deprecate-at 2027-04-16T00:00:00Z

aws: [ERROR]: Unable to parse response (syntax error: line 1, column 0), invalid XML received. Further retries may succeed:
b'<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
```

O moto não implementa isso e falha com um erro dele mesmo, então o que segue é o comportamento
documentado da AWS, não executado aqui. Depois da data, a imagem deixa de aparecer quando outras
contas listam ou procuram imagens, a não ser que peçam também as descontinuadas. Ela **continua
lançando** para quem tem o id, então nada que dependa dela quebra no dia. Esse é o propósito: quem é
novo para de achá-la, quem já usa continua funcionando, e quem lê um template tem uma data para
discutir.

## Aposentando

Uma imagem é removida desregistrando-a. Tente apagar o snapshot dela antes, e a AWS e o moto
concordam:

```
ana@laptop:~/aws$ aws ec2 delete-snapshot --snapshot-id "$SNAP"

aws: [ERROR]: An error occurred (InvalidSnapshot.InUse) when calling the DeleteSnapshot operation: The snapshot snap-ea6b97d76b42a5e1a is currently in use by ami-a9a13e442ffd8c0ff
```

O snapshot pertence a uma imagem registrada, então não pode sair primeiro. Desregistrar a imagem é o
próximo passo, e a imagem some na hora:

```
ana@laptop:~/aws$ aws ec2 deregister-image --image-id "$IMG"
{
    "Return": true
}
ana@laptop:~/aws$ aws ec2 describe-images --image-ids "$IMG"
{
    "Images": []
}
ana@laptop:~/aws$ aws ec2 describe-snapshots --snapshot-ids "$SNAP" --query "Snapshots[].[SnapshotId,VolumeSize,Description]" --output text
snap-ea6b97d76b42a5e1a	15	Created by CreateImage(i-52f3615249060ee52) for ami-a9a13e442ffd8c0ff
```

**O snapshot continua lá, e continua sendo cobrado.** Desregistrar remove o registro e deixa os
blocos, porque a AWS não tem como saber se você queria guardá-los. Uma conta onde imagens foram
desregistradas por um ano e os snapshots nunca apagados paga por cada um deles. A 0,068 USD por
GB-mês na tabela de preços de 16 de outubro de 2026, 365 imagens noturnas de 15 GB cada, se cada
snapshot fosse guardado inteiro, dariam 372,30 USD por mês por nada que alguém consiga lançar.

O moto então mostra mais uma tolerância:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id "$IMG" --instance-type t3.micro --query "Instances[0].[InstanceId,ImageId]" --output text
i-e34f66e3291d7cc0a	ami-a9a13e442ffd8c0ff
```

Ele lançou uma instância a partir de uma imagem que não existe mais. **A AWS recusa um launch de uma
imagem desregistrada.** Depois, o snapshot, que agora pode sair:

```
ana@laptop:~/aws$ aws ec2 delete-snapshot --snapshot-id "$SNAP"
ana@laptop:~/aws$ aws ec2 describe-snapshots --snapshot-ids "$SNAP"

aws: [ERROR]: An error occurred (InvalidSnapshot.NotFound) when calling the DescribeSnapshots operation: None
```

A ordem é portanto fixa: desregistrar a imagem, depois apagar os snapshots que o mapeamento dela
apontava, e é por isso que vale ler o mapeamento antes de desregistrar, como a seção anterior fez. O
Image Builder e a maioria dos pipelines de imagem fazem as duas coisas por agenda, guardando as
últimas imagens e removendo o resto. A lição 4 é onde você descobre quais imagens ainda estão em uso,
porque um launch template que cita uma imagem desregistrada falha no próximo scale-out, não no
momento em que a imagem foi removida.
