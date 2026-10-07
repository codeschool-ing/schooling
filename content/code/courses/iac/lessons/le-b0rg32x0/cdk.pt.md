---
title: O AWS CDK, um programa que escreve o template
version: 2
---

O AWS Cloud Development Kit permite descrever infraestrutura em TypeScript, JavaScript, Python, Java,
C# ou Go, e por isso é fácil imaginá-lo chamando a API da AWS como o Terraform faz. **Ele nunca
chama.** Um app do CDK é um programa cuja saída é um template do CloudFormation, e o CloudFormation
faz o resto. O CDK é um jeito melhor de escrever o YAML da seção anterior, com a stack, o change set e
o rollback todos inalterados por baixo.

## Instalando o Node.js e o CDK

O CDK é um programa Node.js, e a biblioteca para a qual o app desta seção foi escrito precisa do
Node.js 20 ou mais novo, enquanto o pacote do próprio Ubuntu 24.04 é a versão 18. Então o Node.js vem
da build do próprio projeto, desempacotada em `/usr/local`, e o comando `cdk` é instalado com o
gerenciador de pacotes do Node, o `npm`:

```sh
curl -fsSL https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz | sudo tar -xJ -C /usr/local --strip-components=1
sudo npm install -g aws-cdk@2.1144.0
```

Num computador ARM o arquivo é `node-v22.22.0-linux-arm64.tar.xz`. A biblioteca que o app importa
pertence ao projeto e não ao sistema, então ela é instalada no próprio diretório do app, onde o
`require` a procura:

```sh
mkdir -p ~/shop/cdk && cd ~/shop/cdk
npm init -y
npm install aws-cdk-lib@2.272.0 constructs@10
```

O `npm init -y` escreve um `package.json` com as respostas padrão, e o `npm install` põe os dois
pacotes em `node_modules`. As versões são aquelas com que as transcrições foram gravadas.

## Síntese

O primeiro app da Ana, em JavaScript, pede uma VPC com a faixa da loja espalhada por duas zonas de
disponibilidade:

```js
const { App, Stack } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
});
```

`ec2.Vpc` é um **construct**, uma classe que acrescenta recursos a uma stack quando é criada. O
`cdk synth` roda o programa e escreve o que ele acrescentou como um template:

```
ana@laptop:~/shop/cdk$ cdk synth --app "node app.js" > template.yaml
83 feature flags are not configured. Run 'cdk flags --unstable=flags' to learn more.
ana@laptop:~/shop/cdk$ head -n 13 template.yaml
Resources:
  Shop563325D0:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.20.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
      Tags:
        - Key: Name
          Value: ShopNetwork/Shop
    Metadata:
      aws:cdk:path: ShopNetwork/Shop/Resource
ana@laptop:~/shop/cdk$ ls cdk.out
ShopNetwork.assets.json
ShopNetwork.metadata.json
ShopNetwork.template.json
cdk.out
manifest.json
tree.json
validation-report.json
```

A linha no erro padrão é um aviso sobre feature flags, configurações que um projeto criado com
`cdk init` registra num `cdk.json`; este app não tem nenhum dos dois e não perde nada com isso. O
template está em `template.yaml` e em `cdk.out`, e o primeiro recurso dele é a VPC, com um logical id
que o CDK derivou do caminho do construct. Ninguém na AWS foi consultado: a síntese roda offline.

A surpresa é o tamanho. Contando por tipo:

```
ana@laptop:~/shop/cdk$ jq -r ".Resources[].Type" cdk.out/ShopNetwork.template.json | sort | uniq -c
      1 AWS::CDK::Metadata
      2 AWS::EC2::EIP
      1 AWS::EC2::InternetGateway
      2 AWS::EC2::NatGateway
      4 AWS::EC2::Route
      4 AWS::EC2::RouteTable
      4 AWS::EC2::Subnet
      4 AWS::EC2::SubnetRouteTableAssociation
      1 AWS::EC2::VPC
      1 AWS::EC2::VPCGatewayAttachment
```

**Um programa de dez linhas produziu 24 recursos**, e entre eles há dois NAT gateways com um elastic
IP cada. Os padrões do construct `Vpc` são uma sub-rede pública e uma privada em cada zona e um NAT
gateway por zona, para que as privadas alcancem a internet. São padrões razoáveis, e um NAT gateway
também é cobrado por cada hora em que existe, o tipo de custo de que trata a aula 16. Os padrões de um
construct são decisões que outra pessoa tomou por você, e **o template sintetizado é onde você as
revisa.**

Constructs vêm em níveis. Os chamados `Cfn…`, como `ec2.CfnVPC`, correspondem um a um a um tipo do
CloudFormation e não decidem nada. `ec2.Vpc` é o nível acima, com padrões. Acima dele ficam padrões
que montam vários serviços de uma vez. A Ana declara o que a loja precisa, sub-redes públicas `/24` e
nenhum NAT gateway, e põe tags em tudo o que há na stack:

```js
const { App, Stack, Tags } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
  natGateways: 0,
  subnetConfiguration: [
    { name: "web", subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 },
  ],
});

Tags.of(stack).add("Project", "shop");
```

```
ana@laptop:~/shop/cdk$ cdk synth --app "node app.js" > template.yaml 2>/dev/null
ana@laptop:~/shop/cdk$ jq -r ".Resources[].Type" cdk.out/ShopNetwork.template.json | sort | uniq -c
      1 AWS::CDK::Metadata
      1 AWS::EC2::InternetGateway
      2 AWS::EC2::Route
      2 AWS::EC2::RouteTable
      2 AWS::EC2::Subnet
      2 AWS::EC2::SubnetRouteTableAssociation
      1 AWS::EC2::VPC
      1 AWS::EC2::VPCGatewayAttachment
```

Doze recursos, e ela sabe dizer para que serve cada um.

## O deploy, e o diff

Um deploy do CDK precisa antes de um **bootstrap**, uma vez por conta e região: uma stack chamada
`CDKToolkit` com o que o CDK usa para fazer deploy, como um bucket para os arquivos que um app envia.
Depois o `cdk deploy` sintetiza, entrega o template ao CloudFormation por um change set e espera:

```
ana@laptop:~/shop/cdk$ cdk bootstrap --app "node app.js" 2>&1 | grep "^CDKToolkit"
CDKToolkit: creating CloudFormation changeset...
CDKToolkit |  0/15 | 8:28:12 AM | CREATE_IN_PROGRESS      | AWS::CloudFormation::Stack | CDKToolkit User Initiated
CDKToolkit |  1/15 | 8:28:12 AM | CREATE_COMPLETE         | AWS::CloudFormation::Stack | CDKToolkit 
ana@laptop:~/shop/cdk$ cdk deploy --app "node app.js" --require-approval never 2>&1 | grep "^ShopNetwork"
ShopNetwork: start: Building ShopNetwork Template
ShopNetwork: success: Built ShopNetwork Template
ShopNetwork: start: Publishing ShopNetwork Template (current_account-current_region-c4015989)
ShopNetwork: success: Published ShopNetwork Template (current_account-current_region-c4015989)
ShopNetwork: creating CloudFormation changeset...
ShopNetwork: deploying... [1/1]
ShopNetwork |  0/13 | 8:28:16 AM | CREATE_IN_PROGRESS      | AWS::CloudFormation::Stack            | ShopNetwork User Initiated
ShopNetwork |  1/13 | 8:28:16 AM | CREATE_COMPLETE         | AWS::CloudFormation::Stack            | ShopNetwork 
ana@laptop:~/shop/cdk$ aws ec2 describe-subnets --filters Name=tag:Project,Values=shop --query "Subnets[].CidrBlock" --output text
10.20.0.0/24	10.20.1.0/24
```

As linhas de evento são do moto, que informa a stack e não cada recurso dentro dela; numa conta real
há uma linha por recurso. As duas sub-redes são as `/24` que o app pediu.

A Ana acrescenta uma linha no fim do app, uma segunda tag, e pergunta o que mudaria. O `app.js`
inteiro agora é:

```js
const { App, Stack, Tags } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
  natGateways: 0,
  subnetConfiguration: [
    { name: "web", subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 },
  ],
});

Tags.of(stack).add("Project", "shop");
Tags.of(stack).add("Owner", "ana");
```

O `cdk diff` compara o template que o app sintetiza agora com aquele a partir do qual a stack
foi implantada:

```
ana@laptop:~/shop/cdk$ cdk diff --app "node app.js" --method=template
Stack ShopNetwork (aws://123456789012/sa-east-1)
Resources
[~] AWS::EC2::VPC Shop Shop563325D0
 └─ [~] Tags
     └─ @@ -4,6 +4,10 @@
        [ ]   "Value": "ShopNetwork/Shop"
        [ ] },
        [ ] {
        [+]   "Key": "Owner",
        [+]   "Value": "ana"
        [+] },
        [+] {
        [ ]   "Key": "Project",
        [ ]   "Value": "shop"
        [ ] }
```

```
ana@laptop:~/shop/cdk$ cdk diff --app "node app.js" --method=template 2>&1 | grep -F "[~] AWS"
[~] AWS::EC2::VPC Shop Shop563325D0
[~] AWS::EC2::Subnet Shop/webSubnet1/Subnet ShopwebSubnet1Subnet697C84D9
[~] AWS::EC2::RouteTable Shop/webSubnet1/RouteTable ShopwebSubnet1RouteTable7465C0F7
[~] AWS::EC2::Subnet Shop/webSubnet2/Subnet ShopwebSubnet2Subnet45249714
[~] AWS::EC2::RouteTable Shop/webSubnet2/RouteTable ShopwebSubnet2RouteTable50B3D37F
[~] AWS::EC2::InternetGateway Shop/IGW ShopIGWE4EB83B3
```

Uma linha no programa alcança seis recursos, porque `Tags.of(stack)` vale para tudo na stack que
aceita tag. Por padrão o `cdk diff` também pede um change set ao CloudFormation, para saber quais
mudanças exigem substituição; o moto não consegue criar um para uma stack existente, então estes
comandos passam `--method=template` e comparam só os templates.

O state é a stack, como na seção anterior. O `cdk.out` é saída de build que o próximo synth reescreve,
e fica fora do controle de versão, como o `node_modules`. O que vai para o git é o programa, que é a razão de ser do CDK:
**laços, funções e classes para a descrição, com o CloudFormation ainda fazendo o deploy.**
