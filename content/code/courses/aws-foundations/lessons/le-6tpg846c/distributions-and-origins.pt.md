---
title: Distribuições, pontos de presença e origens
version: 1
---

**O CloudFront guarda cópias dos arquivos da loja nos pontos de presença da AWS, perto de quem os
pede**, e busca na loja só o que nenhuma cópia próxima tem. O lado da loja se chama **origem**
(*origin*). A configuração que liga as origens aos pontos de presença, com as regras do que é
guardado e por quanto tempo, é uma **distribuição** (*distribution*). A imagem errada comum é que o
CloudFront é uma cópia mais rápida do bucket. Ele é um cache na frente de qualquer coisa que
responda HTTP, e o trabalho dele é fazer a maioria das requisições nunca chegar à origem.

## Pontos de presença, e o cache entre eles e a loja

**Um ponto de presença (*edge location*) fica numa cidade**, um entre centenas pelo mundo, e é onde
a requisição de quem vê chega. O nome DNS de uma distribuição responde com um ponto de presença
perto de quem pergunta. Atrás deles ficam os **caches regionais** (*regional edge caches*), menos
numerosos e maiores, que guardam o que caiu dos caches menores dos pontos de presença. Uma
requisição que não acha nada no ponto de presença pergunta ao cache regional dele, e só uma falta
ali volta à origem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l23-edges\" aria-label=\"O caminho de uma requisição pelo CloudFront, da esquerda para a direita. Dois espectadores, em Manaus e em Recife, chegam cada um ao ponto de presença mais perto. Um acerto é respondido no ponto de presença. Uma falta vai a um cache regional, que os dois pontos de presença compartilham, e um acerto ali é respondido por ele. Só uma falta no cache regional chega à origem em sa-east-1, o bucket shop-assets ou o balanceador shop-web, e a transferência da origem para o CloudFront é grátis. A maioria das requisições para na primeira caixa.\"><defs><marker id=\"l23-edges-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l23-edges-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"68.0\" width=\"130.0\" height=\"44.0\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quem vê, em Manaus</text><rect x=\"200.0\" y=\"60.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ponto de presença</text><text x=\"265.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">acerto: responde aqui</text><path d=\"M152.0 90.0 L196.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-paper-dim)\"></path><path d=\"M332.0 90.0 L382.0 132.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-amber)\"></path><rect x=\"20.0\" y=\"188.0\" width=\"130.0\" height=\"44.0\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">quem vê, em Recife</text><rect x=\"200.0\" y=\"180.0\" width=\"130.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ponto de presença</text><text x=\"265.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">acerto: responde aqui</text><path d=\"M152.0 210.0 L196.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-paper-dim)\"></path><path d=\"M332.0 210.0 L382.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-amber)\"></path><text x=\"357.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falta</text><rect x=\"386.0\" y=\"115.0\" width=\"140.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"456.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cache regional</text><text x=\"456.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">maior, compartilhado</text><text x=\"456.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">acerto: responde aqui</text><path d=\"M528.0 150.0 L572.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l23-edges-af-ah-amber)\"></path><text x=\"550.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">falta</text><rect x=\"576.0\" y=\"50.0\" width=\"130.0\" height=\"200.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"590.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"590.0\" y=\"86.0\" width=\"102.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"641.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-assets</text><text x=\"641.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">bucket</text><rect x=\"590.0\" y=\"160.0\" width=\"102.0\" height=\"54.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"641.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-web</text><text x=\"641.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">balanceador</text><text x=\"641.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">origem</text><text x=\"550.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">origem ao CloudFront: grátis</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">quanto mais à direita uma requisição precisa ir, mais rara ela deve ser</text></svg>", "caption": "Duas camadas de cache ficam entre quem vê e a loja. Uma falta nas duas é a única requisição que a loja vê.", "same": ["bucket"]}
```

É esse arranjo que muda a fatura, além da velocidade. Um arquivo pedido um milhão de vezes por dia é
buscado na loja um punhado de vezes, uma por cache regional cada vez que a cópia expira. A rede da
AWS responde o resto. **Os bytes da origem para o CloudFront são grátis**, o que a oferta lida na
lição 1 diz numa linha própria, e a última seção desta lição imprime.

## Começando de uma AWS vazia

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. A distribuição precisa de duas origens: o bucket `shop-assets`, onde moram
as imagens e os scripts, e o balanceador de carga que a lição 22 construiu para as páginas. A
preparação cria os dois, e o balanceador recebe só as duas sub-redes de que um ALB precisa:

```sh
aws s3api create-bucket --bucket shop-assets \
  --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
a=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.0.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
b=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop-web --subnets "$a" "$b" > /dev/null
```

## Três tipos de origem

| origem | como o CloudFront chega a ela | na loja |
|---|---|---|
| um bucket do S3 | pelo nome regional do bucket, com o **Origin Access Control** assinando cada requisição | `shop-assets`, as imagens e os scripts |
| um balanceador de carga | pelo nome DNS, como origem personalizada por HTTPS | `shop-web`, as páginas e a API |
| qualquer outro servidor HTTP | pelo nome DNS, como origem personalizada | a página de status de um provedor de pagamento, um servidor no datacenter |

**O Origin Access Control (OAC) é como um bucket continua privado e ainda atende o mundo.** O
CloudFront assina cada requisição que faz ao bucket, e a política do próprio bucket permite essas
requisições assinadas e as de mais ninguém. Os arquivos então podem ser lidos pela distribuição e
nunca direto do S3. Um OAC é um objeto à parte, criado uma vez e citado na origem:

```
ana@laptop:~/aws$ aws cloudfront create-origin-access-control --origin-access-control-config Name=shop-assets-oac,SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3
{
    "ETag": "A0OWIEQ4SXBGK",
    "OriginAccessControl": {
        "Id": "ERHAWSV4GX0UT",
        "OriginAccessControlConfig": {
            "Name": "shop-assets-oac",
            "SigningProtocol": "sigv4",
            "SigningBehavior": "always",
            "OriginAccessControlOriginType": "s3"
        }
    }
}
```

## Uma distribuição

A configuração é um documento JSON. Salve-o como `~/aws/distribution.json`, com o `Id` do seu
próprio OAC no lugar de `ERHAWSV4GX0UT` se o seu for diferente:

```json
{
  "CallerReference": "shop-cdn-2026-10-16",
  "Comment": "the shop's pages, images and scripts",
  "Enabled": true,
  "PriceClass": "PriceClass_All",
  "Origins": {"Quantity": 2, "Items": [
    {"Id": "assets", "DomainName": "shop-assets.s3.sa-east-1.amazonaws.com",
     "OriginAccessControlId": "ERHAWSV4GX0UT",
     "S3OriginConfig": {"OriginAccessIdentity": ""}},
    {"Id": "web", "DomainName": "shop-web-1.sa-east-1.elb.amazonaws.com",
     "CustomOriginConfig": {"HTTPPort": 80, "HTTPSPort": 443,
                            "OriginProtocolPolicy": "https-only"}}
  ]},
  "DefaultCacheBehavior": {
    "TargetOriginId": "web",
    "ViewerProtocolPolicy": "redirect-to-https",
    "CachePolicyId": "4135ea2d-6df8-44a3-9df3-4b5a84be39ad",
    "OriginRequestPolicyId": "216adef6-5c7f-47e4-b989-5492eafa07d3"
  },
  "CacheBehaviors": {"Quantity": 1, "Items": [
    {"PathPattern": "/static/*", "TargetOriginId": "assets",
     "ViewerProtocolPolicy": "redirect-to-https",
     "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
     "Compress": true}
  ]},
  "ViewerCertificate": {"CloudFrontDefaultCertificate": true}
}
```

Leia de cima para baixo. **Duas origens**, cada uma com um `Id` a que os comportamentos se referem. **Um
comportamento padrão** manda tudo para o balanceador, sem guardar em cache, já que as páginas e a
API são diferentes para cada cliente. A próxima seção lê os três ids de política. **Mais um
comportamento** manda `/static/*` para o bucket, em cache, comprimido. E `redirect-to-https`
transforma a requisição HTTP simples de quem vê num redirecionamento, como o listener da porta 80 da
lição 22 fez.

```
ana@laptop:~/aws$ aws cloudfront create-distribution --distribution-config file://distribution.json --query "[Location,Distribution.Id,Distribution.DomainName,Distribution.Status]" --output text
https://cloudfront.amazonaws.com/2020-05-31/distribution/DOF70T4DOCRTU	DOF70T4DOCRTU	wtn4hbbp1mje6.cloudfront.net	InProgress
```

**A distribuição tem um nome próprio, sob `cloudfront.net`**, e é para ele que quem vê é mandado.
`InProgress` quer dizer que a AWS está copiando a configuração para todo ponto de presença, o que na
AWS leva minutos. O moto a chama de `Deployed` na próxima vez que alguém pergunta. Guarde o id:

```
ana@laptop:~/aws$ id=$(aws cloudfront list-distributions --query "DistributionList.Items[0].Id" --output text)
```

```
ana@laptop:~/aws$ aws cloudfront get-distribution --id $id --query "Distribution.DistributionConfig.Origins.Items[].[Id,DomainName,OriginAccessControlId]" --output text
assets	shop-assets.s3.sa-east-1.amazonaws.com	None
web	shop-web-1.sa-east-1.elb.amazonaws.com	None
```

**O moto descartou o OAC.** A origem do bucket voltou sem `OriginAccessControlId`, então o moto 5.2.3
guarda a origem e não a proteção dela. Na AWS o mesmo comando imprime o id.

## A metade do bucket no acordo

O OAC assina; **o bucket tem de concordar.** A política dele permite ao serviço CloudFront ler
objetos, e só em nome desta distribuição, que é o que a condição em `AWS:SourceArn` diz. Salve-a
como `~/aws/assets-policy.json`, com o id da sua própria distribuição no fim do ARN:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "OnlyThroughTheShopsDistribution",
    "Effect": "Allow",
    "Principal": {"Service": "cloudfront.amazonaws.com"},
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::shop-assets/*",
    "Condition": {"StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::123456789012:distribution/DOF70T4DOCRTU"}}
  }]
}
```

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket shop-assets --policy file://assets-policy.json
```

**O moto guarda uma política de bucket e não a julga**, o limite que a lição 1 citou, então nada
aqui prova que um estranho é recusado. Na AWS o **Block Public Access** do bucket continua ligado, e
nada na política é público. Uma requisição direta a
`shop-assets.s3.sa-east-1.amazonaws.com/static/logo.png` é recusada, enquanto o mesmo arquivo pela
distribuição é servido.

## Global, com a API na Virgínia

**O CloudFront não pertence a região nenhuma**, como o Route 53 na lição 21. Na AWS a linha de
comando manda toda chamada do CloudFront para um único endereço e a assina para `us-east-1`, onde
roda o plano de controle do serviço. As respostas mostram isso em três lugares. O `Location` acima é
`cloudfront.amazonaws.com`, sem região. O ARN tem o campo de região vazio,
`arn:aws:cloudfront::123456789012:…`. E `--region` não muda nada:

```
ana@laptop:~/aws$ aws cloudfront list-distributions --region ap-southeast-2 --query "DistributionList.Items[].[Id,DomainName]" --output text
DOF70T4DOCRTU	wtn4hbbp1mje6.cloudfront.net
```

**O único lugar em que a região não é opcional é o certificado.** Para servir `cdn.shop.example.com`
no lugar do nome `cloudfront.net`, a distribuição precisa do nome em `Aliases` e de um certificado
do ACM para ele. **O CloudFront só aceita certificados de `us-east-1`**, more a loja onde morar. Os
outros serviços presos a uma distribuição seguem a mesma regra: uma web ACL do WAF para o CloudFront
é criada em `us-east-1`, e as métricas do CloudFront caem no CloudWatch em `us-east-1`.

```
ana@laptop:~/aws$ aws acm request-certificate --domain-name cdn.shop.example.com --validation-method DNS --region us-east-1 --query CertificateArn --output text
arn:aws:acm:us-east-1:123456789012:certificate/fb5b7f04-8228-47c2-a212-0a76442e0d79
ana@laptop:~/aws$ aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[].DomainName" --output text
cdn.shop.example.com
ana@laptop:~/aws$ aws acm list-certificates --query "CertificateSummaryList[].DomainName" --output text
```

O último comando perguntou a São Paulo, e São Paulo não tem nenhum: um certificado vive na região que
o emitiu. **Este não foi preso à distribuição**, porque a AWS não o aceitaria até existir o registro
de DNS que o valida, e o moto o aceitaria na hora e não provaria nada. A distribuição fica com o nome
`cloudfront.net` neste laboratório.
