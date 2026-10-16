---
title: O que uma conta guarda, e o que ela mantém separado
version: 1
---

**Uma conta AWS é um contêiner, não um login.** A imagem errada vem de todo outro site, onde uma
conta é uma pessoa com nome e senha. Na AWS a conta é a caixa onde todo o resto fica, e pessoas são
só uma das coisas dentro dela. Ela tem um número de doze dígitos, um dono, uma fatura e paredes que
nada atravessa a não ser que alguém abra uma porta de propósito.

Cinco coisas vivem dentro dessas paredes, e cada uma delas é um motivo para ter mais de uma conta:

- **Identidades ficam na sua conta.** Os usuários, grupos e roles do IAM existem numa conta e não
  significam nada em outra; um usuário `bia` aqui e um usuário `bia` ali são dois estranhos que
  dividem um nome.
- **Recursos pertencem a exatamente uma conta.** Toda máquina, bucket, rede e fila tem um dono, e as
  outras contas não a enxergam, quanto mais alteram.
- **Cotas são contadas por conta**, e na maioria dos serviços também por região: quantas redes,
  endereços ou funções rodando ao mesmo tempo você pode ter.
- **A fatura é da conta.** O que um recurso custa é cobrado da conta que é dona dele, linha por
  linha.
- **O raio de estrago termina na parede.** O que um erro, uma chave vazada ou um script descontrolado
  alcança é, no máximo, a conta onde aconteceu.

## Perguntando em que conta você está

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para esta lição começar
de uma AWS vazia. Depois, no segundo, pergunte quem você é e crie duas coisas com nome:

```
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws sns create-topic --name shop-alerts
{
    "TopicArn": "arn:aws:sns:sa-east-1:123456789012:shop-alerts"
}
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
```

`sns create-topic` cria um canal de notificação, de que esta lição só precisa pelo nome; o
`create-user` do IAM cria um usuário, e a lição 6 diz para que serve um usuário. As duas respostas
carregam o número do primeiro comando, `123456789012`, que é a conta padrão do moto.

## Um ARN, desmontado

**Todo recurso na AWS tem um nome completo, o seu ARN** (Amazon Resource Name), e é o nome que uma
política, uma linha de log e uma mensagem de erro usam. São seis campos separados por dois-pontos,
sempre na mesma ordem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l02-arn\" aria-label=\"Três ARNs da transcrição, cortados nos seus seis campos: prefixo, partição, serviço, região, conta e recurso. O tópico arn:aws:sns:sa-east-1:123456789012:shop-alerts preenche os seis. O usuário arn:aws:iam::123456789012:user/bia deixa a região vazia, porque o IAM é global dentro de uma conta. O bucket arn:aws:s3:::shop-assets deixa a região e a conta vazias, porque um nome de bucket não pertence a conta nenhuma. A coluna da conta está destacada: ela diz de quem é o recurso.\"><text x=\"76.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">prefixo</text><text x=\"138.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">partição</text><text x=\"206.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">serviço</text><text x=\"304.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">região</text><text x=\"436.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">conta</text><text x=\"591.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">recurso</text><rect x=\"54.0\" y=\"57.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">arn</text><text x=\"107.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"116.0\" y=\"57.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"169.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"178.0\" y=\"57.0\" width=\"56.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sns</text><text x=\"243.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"252.0\" y=\"57.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1</text><text x=\"365.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"374.0\" y=\"57.0\" width=\"124.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"436.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">123456789012</text><text x=\"507.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"516.0\" y=\"57.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-alerts</text><rect x=\"54.0\" y=\"115.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">arn</text><text x=\"107.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"116.0\" y=\"115.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"169.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"178.0\" y=\"115.0\" width=\"56.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">iam</text><text x=\"243.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"252.0\" y=\"115.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"304.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">vazio</text><text x=\"365.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"374.0\" y=\"115.0\" width=\"124.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"436.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">123456789012</text><text x=\"507.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"516.0\" y=\"115.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">user/bia</text><rect x=\"54.0\" y=\"173.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">arn</text><text x=\"107.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"116.0\" y=\"173.0\" width=\"44.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws</text><text x=\"169.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"178.0\" y=\"173.0\" width=\"56.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">s3</text><text x=\"243.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"252.0\" y=\"173.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"304.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">vazio</text><text x=\"365.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"374.0\" y=\"173.0\" width=\"124.0\" height=\"34.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"436.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">vazio</text><text x=\"507.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"516.0\" y=\"173.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-assets</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o IAM é global dentro da conta, então um usuário não tem região</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um nome de bucket não pertence a conta nenhuma, então o ARN não tem conta</text></svg>", "caption": "Seis campos, sempre nesta ordem. O quinto diz de quem é o recurso."}
```

O primeiro campo é sempre `arn`. O segundo é a partição: `aws` em todo lugar onde você vai
trabalhar, `aws-cn` na China e `aws-us-gov` no GovCloud, que são cópias separadas da AWS com contas
próprias. Depois vêm o serviço, a região e a conta, e por último o recurso, numa forma que cada
serviço escolhe.

**Um campo vazio é informação.** O usuário não tem região, porque o IAM é global dentro de uma
conta: `bia` existe em São Paulo e na Virgínia ao mesmo tempo. O ARN de um bucket,
`arn:aws:s3:::shop-assets`, não tem região e também não tem conta, que é a primeira pista de algo
que a próxima seção mede: o nome de um bucket não pertence à conta de ninguém.

Um detalhe da resposta do moto é do moto. Para um usuário, a AWS informa quem chama como
`arn:aws:iam::<account>:user/<name>`, com `iam` como serviço; o moto escreve `sts` e chama o seu
usuário padrão de `moto`. Para uma role assumida com `assume-role`, que a próxima seção faz, a AWS
também diz `sts`, e a próxima transcrição está certa nos dois pontos.

**Leia a conta de um ARN antes de qualquer outra coisa.** Quando uma política, uma linha de log ou
uma fatura cita um recurso, o quinto campo diz de quem ele é, e uma política que cita uma conta que
ninguém reconhece é a primeira coisa nela a questionar.

## Cotas são contadas por conta

**Uma cota é um limite que a AWS impõe a quanto de algo uma conta pode ter**, na maioria dos casos
por região. O serviço que as guarda é o Service Quotas, e o moto carrega a lista dele:

```
ana@laptop:~/aws$ aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE --query "Quota.[QuotaName,Value,Adjustable,GlobalQuota]" --output text
VPCs per Region	5.0	True	False
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-546fc35409a21e400	172.31.0.0/16	True
ana@laptop:~/aws$ for n in 1 2 3 4 5; do aws ec2 create-vpc --cidr-block 10.$n.0.0/16 --query Vpc.VpcId --output text; done
vpc-09904342f704201c3
vpc-d877b106d3b8c910b
vpc-01df613edaab9b4b0
vpc-595183274a283a4e6
vpc-ed78599abbf31f591
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "length(Vpcs)"
6
```

Cinco VPCs por região, ajustável, e não global, então a contagem recomeça em cada região. A conta já
tinha uma VPC, a VPC padrão que a AWS cria em cada região de uma conta nova, e o laço pediu mais
cinco. O moto criou as cinco e agora guarda seis.

**A AWS teria recusado a quinta.** A VPC padrão conta, então a padrão mais quatro é a cota, e o
`create-vpc` seguinte responde com o código de erro `VpcLimitExceeded`. O moto guarda o valor da cota
e não conta contra ele, então **essa recusa não foi rodada aqui**; é o comportamento documentado da
AWS. O valor pode ser aumentado, por um pedido ao Service Quotas para uma cota numa região de uma
conta. Outra conta recomeça do padrão, que é exatamente o ponto da próxima seção.

## O usuário root, e todos os outros

**Toda conta tem exatamente um usuário root**, a identidade que a abriu. Ele entra com o endereço de
e-mail da conta, pode fazer qualquer coisa nela, inclusive encerrá-la, e não pode ser limitado pelas
políticas do IAM da própria conta. A lição 1, em "Uma conta real", disse como protegê-lo; quem
trabalha na conta no dia a dia é uma identidade do IAM criada dentro dela, e a lição 6 organiza
essas identidades.

O que importa aqui é a contagem. **Dez contas são dez usuários root e dez endereços de e-mail**,
cada um único em toda a AWS, e é por isso que a loja dá a cada conta um endereço da forma
`aws+<account>@example.com`: uma caixa de correio, um endereço diferente por conta. Uma conta criada
dentro de uma organização, como na próxima seção, começa com um usuário root sem senha nenhuma, e a
conta de gerenciamento da organização pode remover de vez as credenciais do root das suas
contas-membro. A lição 5 põe isso na lista do que uma landing zone resolve.
