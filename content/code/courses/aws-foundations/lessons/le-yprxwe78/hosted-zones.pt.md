---
title: Zonas hospedadas, públicas e privadas
version: 1
---

**Uma zona hospedada (*hosted zone*) é o conjunto de registros que o Route 53 responde para um
domínio**, e ela vem em dois tipos. Uma zona **pública** responde a qualquer pessoa na internet que
pergunte por `shop.example.com`. Uma zona **privada** responde só dentro das VPCs associadas a ela.
A imagem errada comum é que criar uma zona pública põe o nome na internet. Não põe. Uma zona é um
conjunto de respostas esperando alguém perguntar. **Ninguém pergunta até o domínio pai mandar as
perguntas para lá**, que é a delegação do fim desta seção.

## Começando de uma AWS vazia

Reinicie o moto no primeiro terminal (Ctrl+C, depois `moto_server -p 4567`) para que esta lição
comece de uma AWS vazia. As lições 16 e 17 constroem a rede de produção da loja por inteiro. Esta
lição precisa só de um pedaço dela: a VPC `10.20.0.0/16`, duas sub-redes em duas zonas, e um
balanceador de carga para um registro apontar, que a lição 22 explica. Digite isto no segundo
terminal:

```sh
vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id "$vpc" --enable-dns-hostnames '{"Value": true}'
a=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.0.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
b=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
aws elbv2 create-load-balancer --name shop-web --subnets "$a" "$b" > /dev/null
```

Não imprime nada. `vpc`, `a` e `b` são **variáveis do shell**: elas vivem neste terminal, os comandos
abaixo leem `$vpc` dele, e um terminal novo não as teria.

## Uma zona pública

```
ana@laptop:~/aws$ aws route53 create-hosted-zone --name shop.example.com --caller-reference shop-public-2026-10-16
{
    "Location": "https://route53.amazonaws.com/2013-04-01/hostedzone/2NCCO4P25PQ1BWXHJIBIIS",
    "HostedZone": {
        "Id": "/hostedzone/2NCCO4P25PQ1BWXHJIBIIS",
        "Name": "shop.example.com.",
        "CallerReference": "shop-public-2026-10-16",
        "Config": {
            "PrivateZone": false
        },
        "ResourceRecordSetCount": 2
    },
    "ChangeInfo": {
        "Id": "/change/C1PA6795UKMFR9",
        "Status": "INSYNC",
        "SubmittedAt": "2026-10-16T16:00:21.362804+00:00"
    },
    "DelegationSet": {
        "Id": "",
        "CallerReference": "DelSet_shop.example.com.",
        "NameServers": [
            "ns-2048.awsdns-64.com",
            "ns-2049.awsdns-65.net",
            "ns-2050.awsdns-66.org",
            "ns-2051.awsdns-67.co.uk"
        ]
    }
}
```

Três coisas nessa resposta merecem leitura lenta.

**O endereço em `Location` não tem região.** O Route 53 é um serviço **global**: um único conjunto
de zonas para a conta inteira, seja qual for a região que o `env.sh` nomeia, servido de locais da
AWS pelo mundo todo. A linha de comando o envia para `route53.amazonaws.com` e o assina para
`us-east-1`, onde fica o plano de controle dele. O curso `cloud`, lição 9, conta o que isso
significa no dia em que a Virgínia tem uma tarde ruim.

**`DelegationSet` nomeia quatro servidores de nomes, em quatro domínios de topo**: `.com`, `.net`,
`.org` e `.co.uk`. Essas quatro máquinas vão responder pela zona. Espalhá-las por quatro domínios
faz com que uma falha num deles não leve o nome da loja junto. O moto imprime os mesmos quatro nomes
para toda zona. A AWS dá a cada zona o seu próprio conjunto, e **o conjunto é escolhido quando a
zona é criada**, o que importa mais abaixo.

**`--caller-reference` é uma proteção contra criar a zona duas vezes.** Um script que estoura o
tempo e tenta de novo envia a mesma referência. A AWS recusa a segunda com `HostedZoneAlreadyExists`
em vez de deixar duas zonas com o mesmo nome. O moto 5.2.3 não cumpre essa promessa: recebendo a
mesma referência de novo, ele criou uma segunda zona. Faça a referência única por zona, e não conte
com o moto para pegar uma repetição.

O id da zona é a alça que todo comando seguinte recebe, então guarde-o numa variável também. O seu
será outra sequência de letras, como todo id que o moto inventa:

```
ana@laptop:~/aws$ zone=$(aws route53 list-hosted-zones-by-name --dns-name shop.example.com --query "HostedZones[0].Id" --output text)
ana@laptop:~/aws$ echo $zone
/hostedzone/2NCCO4P25PQ1BWXHJIBIIS
```

Uma zona nova não é vazia. Ela já guarda os dois registros que fazem dela uma zona:

```
ana@laptop:~/aws$ aws route53 list-resource-record-sets --hosted-zone-id $zone --query "ResourceRecordSets[].[Type,TTL,join(' ', ResourceRecords[].Value)]" --output text
NS	172800	ns-2048.awsdns-64.com ns-2049.awsdns-65.net ns-2050.awsdns-66.org ns-2051.awsdns-67.co.uk
SOA	900	{'Value': 'ns-2048.awsdns-64.com. hostmaster.example.com. 1 7200 900 1209600 86400'}
```

**O registro NS lista os servidores de nomes da própria zona**, os mesmos quatro do conjunto de
delegação, com um TTL de 172.800 segundos: dois dias. **O registro SOA, *start of authority*,
descreve a zona em si.** Os sete campos dele começam pelo servidor de nomes primário, pela caixa de
correio do administrador escrita como um nome e por um número de série. Depois vêm três
temporizadores para servidores secundários, 7.200, 900 e 1.209.600 segundos. O último, 86.400,
limita por quanto tempo um resolvedor pode lembrar que um nome **não** existe. O TTL do próprio SOA
é 900, e o resolvedor fica com o menor dos dois, então uma resposta "esse nome não existe" é
lembrada por quinze minutos.

**As chaves em volta desse valor do SOA são do moto.** Ele guarda o registro como um pequeno
dicionário do Python e imprime o dicionário. A AWS responde com os sete campos puros. Os números são
os padrões que a AWS documenta. Não mude nenhum dos dois registros numa zona real sem motivo. O NS
tem de continuar batendo com o que o domínio pai diz, e os temporizadores do SOA são o que todo
resolvedor da internet ouviu.

## Uma zona privada

Uma zona privada responde **só a máquinas dentro das VPCs associadas a ela**. Os servidores da loja
podem então achar `db.shop.internal` sem que esse nome exista em lugar algum onde um estranho possa
consultá-lo.

```
ana@laptop:~/aws$ aws route53 create-hosted-zone --name shop.internal --caller-reference shop-private-2026-10-16 --vpc VPCRegion=sa-east-1,VPCId=$vpc --hosted-zone-config PrivateZone=true,Comment="inside shop-prod" --query "[HostedZone.Name,HostedZone.Config.PrivateZone]" --output text
shop.internal.	True
```

**A associação é o ponto**, e ela pode ser perguntada pelo lado da VPC tanto quanto pelo da zona:
quais zonas esta rede enxerga?

```
ana@laptop:~/aws$ aws route53 list-hosted-zones-by-vpc --vpc-id $vpc --vpc-region sa-east-1 --query "HostedZoneSummaries[].[HostedZoneId,Name]" --output text
30N3SH0VOW90OXXX40SLW9	shop.internal.
```

Dentro da VPC, uma máquina manda as perguntas de DNS para o **Route 53 Resolver**, no endereço base
da VPC mais dois, `10.20.0.2` aqui. O Resolver responde primeiro pelas zonas privadas associadas à
VPC, e pela internet pública para todo o resto. Ele só faz isso enquanto os atributos
`enableDnsSupport` e `enableDnsHostnames` da VPC estão os dois ligados. Por isso a preparação acima
ligou o segundo: uma VPC nova começa com ele desligado. **Nada disso foi rodado aqui.** O moto
guarda a associação e não tem Resolver nem máquina para perguntar a ele, então a metade que responde
é o comportamento documentado da AWS.

Dois detalhes que poupam uma tarde. Uma zona privada pode ser associada a mais VPCs depois, com
`associate-vpc-with-hosted-zone`, inclusive uma VPC de outra conta, depois que essa conta é
autorizada. E uma zona pública e uma privada podem ter **o mesmo nome**: dentro da VPC responde a
privada, fora dela a pública. Esse arranjo se chama DNS de horizonte dividido (*split-horizon*). É
assim que um nome pode levar a um endereço interno para as máquinas da própria loja e a um público
para todo o resto.

O moto 5.2.3 também precisa de `PrivateZone=true` escrito por extenso. Recebendo só `--vpc`, ele
criou uma zona pública.

## Registrar o domínio, e entregá-lo

**Nada nesta parte foi rodado**, por dois motivos. Registrar um domínio custa dinheiro e exige uma
conta. E ninguém pode registrar `example.com`: ele é reservado para documentação, e é por isso que
todo curso o usa.

Um domínio é comprado de um **registrador**, e o registrador o inscreve no **registro** do domínio
de topo. É a Verisign para `.com` e o Registro.br para `.com.br`, que é onde uma loja de São Paulo
mais provavelmente compraria o nome. O Route 53 também é registrador, pela API `route53domains`,
cujo endpoint existe só em `us-east-1`. Registrado lá, o domínio ganha uma zona hospedada e os
servidores de nomes configurados para você.

Comprado em outro lugar, o passo é seu, e é o passo que **delega** o nome. No formulário do
registrador, troque os servidores de nomes dele pelos quatro do conjunto de delegação da zona. O
registro então publica registros NS para `shop.example.com` na zona `.com`. Dali em diante, um
resolvedor em qualquer lugar que pergunte pela loja é mandado ao Route 53.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l21-delegation\" aria-label=\"Como um resolvedor encontra a loja, desenhado como uma sequência com o tempo correndo para baixo. Quatro colunas: um resolvedor, os servidores raiz, os servidores de .com, e o Route 53, cujo servidor de nomes é ns-2048.awsdns-64.com. Passo 1, o resolvedor pergunta à raiz por www.shop.example.com; passo 2, a raiz responde: pergunte a .com. Passo 3, ele pergunta aos servidores de .com; passo 4, eles respondem: pergunte a ns-2048.awsdns-64.com. Passo 5, ele pergunta ao Route 53; passo 6, o Route 53 responde com o registro, 203.0.113.25. Sob a coluna de .com, o registrador, que escreveu os quatro nomes NS com que o passo 4 responde. Só o passo 6 lê a zona hospedada.\"><defs><marker id=\"l21-delegation-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l21-delegation-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l21-delegation-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um resolvedor</text><path d=\"M90.0 66.0 L90.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"200.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"280.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a raiz</text><path d=\"M280.0 66.0 L280.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"370.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">os servidores de .com</text><path d=\"M450.0 66.0 L450.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"540.0\" y=\"20.0\" width=\"160.0\" height=\"44.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Route 53</text><text x=\"620.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ns-2048.awsdns-64.com</text><path d=\"M620.0 66.0 L620.0 300.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.0\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M92.0 95.0 L277.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"102.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mail.shop.example.com?</text><circle cx=\"56.0\" cy=\"95.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"95.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M278.0 125.0 L95.0 125.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"270.0\" y=\"116.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pergunte a .com</text><circle cx=\"56.0\" cy=\"125.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"125.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M92.0 165.0 L447.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"102.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mail.shop.example.com?</text><circle cx=\"56.0\" cy=\"165.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M448.0 195.0 L95.0 195.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"440.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">pergunte a ns-2048.awsdns-64.com</text><circle cx=\"56.0\" cy=\"195.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"195.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">4</text><path d=\"M92.0 235.0 L617.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-paper-dim)\"></path><text x=\"102.0\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">mail.shop.example.com?</text><circle cx=\"56.0\" cy=\"235.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"235.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">5</text><path d=\"M618.0 265.0 L95.0 265.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-phosphor)\"></path><text x=\"610.0\" y=\"256.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o registro: 203.0.113.25</text><circle cx=\"56.0\" cy=\"265.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"56.0\" y=\"265.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">6</text><rect x=\"370.0\" y=\"322.0\" width=\"160.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"450.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o registrador</text><text x=\"450.0\" y=\"357.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">escreveu os quatro NS</text><path d=\"M450.0 319.0 L450.0 304.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l21-delegation-af-ah-amber)\"></path><text x=\"360.0\" y=\"392.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o tempo corre para baixo; só o passo 6 lê a zona hospedada</text></svg>", "caption": "Criar uma zona é o passo 6. Os passos 3 e 4 são a delegação, e quem os escreve é o registrador.", "same": ["Route 53"]}
```

**A delegação nomeia servidores, não uma zona**, e essa é a armadilha. Apague a zona hospedada e
crie de novo, e a zona nova ganha um novo conjunto de quatro. O registro continua apontando para os
antigos, que agora não respondem por nada. O nome da loja para de funcionar em todo lugar à medida
que as cópias dos resolvedores expiram. Antes de apagar uma zona pública, olhe o que o registrador
diz.

## Quanto custa uma zona

```
ana@laptop:~/aws$ python3 price.py AmazonRoute53 20260911124504 aws-other HostedZone
AmazonRoute53 20260911124504, published 2026-09-11, USD
HostedZone
          0 to        25 HostedZone 0.5000
         25 to       Inf HostedZone 0.1000
```

**A oferta do Route 53 guarda os preços globais sob o código de região `aws-other`**, porque uma
zona hospedada não pertence a região nenhuma. O arquivo `sa-east-1` da mesma oferta guarda só o que
roda numa região, os endpoints do Resolver e o firewall de DNS. Na lista que a AWS publicou em **11
de setembro de 2026**: 0,50 dólar por mês para cada uma das primeiras 25 zonas, 0,10 para cada uma
depois disso. A página de preços da AWS acrescenta duas regras que as linhas não trazem. A cobrança
mensal não é dividida por dia, e uma zona apagada em até 12 horas depois de criada não é cobrada. As
duas zonas da loja custam um dólar por mês antes que alguém pergunte qualquer coisa a elas. As
respostas têm preço próprio, que a última seção desta lição lê.
