---
title: O launch template e suas versões
version: 1
---

Um launch template parece um formulário salvo: as respostas do `run-instances`, guardadas com um
nome para ninguém ter de digitá-las de novo. Essa imagem acerta no que ele guarda e erra em como ele
muda. **Um launch template é uma série numerada de versões, e uma versão nunca muda.** Você não
edita um template; você acrescenta uma versão a ele, e um ponteiro diz qual versão o nome significa
quando alguém o usa sem número. Tudo nesta lição, e boa parte da próxima, depende desse ponteiro.

## O que uma versão guarda

Uma versão guarda o que uma instância é: a imagem, o tipo de instância, os discos, as configurações
de metadata, as tags e, opcionalmente, os security groups, o instance profile, um par de chaves e o
user data. Ela não guarda quantas instâncias existem, nem em quais subnets elas entram. Isso é de
quem lança a partir dela, e nesta lição é um grupo de auto scaling.

Esta é a primeira versão que a Ana escreve, num arquivo que a linha de comando lê. **Copie-o com o
botão do bloco e salve como `~/aws/template.json`**; as notas ao lado não são copiadas.

```schooling-example
{"language": "json", "file": "template.json", "parts": [{"code": "{\n  \"ImageId\": \"ami-0629d059c178d0eac\",\n  \"InstanceType\": \"t3.micro\",\n", "note": "A imagem e o tipo, as duas coisas de que todo lançamento precisa. O id da imagem é uma das imagens Amazon Linux 2023 do catálogo do moto, que a lição 2 explica; na AWS a mesma imagem tem um id diferente em cada região, então um template é escrito por região."}, {"code": "  \"BlockDeviceMappings\": [\n    {\n      \"DeviceName\": \"/dev/xvda\",\n      \"Ebs\": {\"VolumeSize\": 20, \"VolumeType\": \"gp3\", \"DeleteOnTermination\": true}\n    }\n  ],\n", "note": "O volume raiz: 20 GB de gp3, o tipo de volume que a lição 3 precifica, apagado junto com a instância. Num grupo isso importa, porque o grupo termina instâncias por conta própria, e um volume esquecido para cada uma é uma conta que ninguém pediu."}, {"code": "  \"MetadataOptions\": {\"HttpTokens\": \"required\", \"HttpEndpoint\": \"enabled\"},\n", "note": "Metadata da instância só com um token de sessão, que é o IMDSv2. A lição 7 diz o que o token impede; o template é onde ele é exigido, uma vez, para toda instância que o grupo vier a lançar."}, {"code": "  \"TagSpecifications\": [\n    {\"ResourceType\": \"instance\", \"Tags\": [{\"Key\": \"app\", \"Value\": \"shop\"}]}\n  ]\n}\n", "note": "Uma tag posta em toda instância lançada a partir desta versão. Instâncias num grupo vêm e vão com ids que ninguém escolheu, então uma tag é como uma pessoa, uma conta ou um filtro as encontra."}]}
```

Ele não cita nenhum security group. Na AWS, uma instância lançada numa VPC sem grupo indicado recebe
o security group padrão da VPC, que raramente é o que você quer; um template de verdade cita, em
`SecurityGroupIds`, o grupo que a lição 18 de `aws-foundations` constrói.

A imagem é do moto, e a linha de comando diz qual é antes que alguém a use:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-0629d059c178d0eac --query "Images[].[Name,Architecture]" --output text
al2023-ami-2023.12.20260727.0-kernel-6.12-x86_64	x86_64
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name web --version-description "t3.micro, first" --launch-template-data file://template.json
{
    "LaunchTemplate": {
        "LaunchTemplateId": "lt-420bf22b86d1ab21b",
        "LaunchTemplateName": "web",
        "CreateTime": "2026-10-16T16:25:46+00:00",
        "CreatedBy": "arn:aws:iam::123456789012:root",
        "DefaultVersionNumber": 1,
        "LatestVersionNumber": 1,
        "Tags": []
    }
}
```

A resposta traz dois números que são o assunto inteiro desta seção: `DefaultVersionNumber` e
`LatestVersionNumber`. Com uma versão, os dois valem 1.

## Uma versão nova, e o que o moto deixa de fora

A loja precisa de uma máquina maior. Na AWS, o caminho curto é basear uma versão nova numa antiga e
mandar só o que muda: `--source-version 1` copia tudo o que a versão 1 guarda, e o
`--launch-template-data` passado junto sobrescreve o tipo de instância. Este é o comando, e o que o
moto fez dele:

```
ana@laptop:~/aws$ aws ec2 create-launch-template-version --launch-template-name web --source-version 1 --version-description t3.medium --launch-template-data '{"InstanceType": "t3.medium"}' --query LaunchTemplateVersion.VersionNumber
2
ana@laptop:~/aws$ aws ec2 describe-launch-template-versions --launch-template-name web --versions 2 --query "LaunchTemplateVersions[].LaunchTemplateData"
[
    {
        "InstanceType": "t3.medium"
    }
]
```

**Essa resposta é do moto, não da AWS.** A AWS mostraria a versão 2 com a imagem, o disco, as opções
de metadata e as tags da versão 1, e `t3.medium` no lugar de `t3.micro`. O moto 5.2.3 ignora o
`--source-version` e guarda só o que foi enviado, então a versão 2 dele não tem imagem nenhuma, e uma
instância lançada a partir dela neste laboratório volta com o `ImageId` vazio.

A versão 2 não tem conserto, e essa é a outra metade da lição. Uma versão também é imutável na AWS:
ela pode ser apagada com `delete-launch-template-versions`, mas nunca editada. Então o caminho é uma
versão 3, escrita inteira. O `jq` gera o arquivo a partir do primeiro, mudando um campo, e esta é a
forma que se comporta igual no moto e na AWS:

```
ana@laptop:~/aws$ jq '.InstanceType = "t3.medium"' template.json > template-medium.json
ana@laptop:~/aws$ aws ec2 create-launch-template-version --launch-template-name web --version-description "t3.medium, whole" --launch-template-data file://template-medium.json --query LaunchTemplateVersion.VersionNumber
3
ana@laptop:~/aws$ aws ec2 describe-launch-templates --launch-template-names web --query "LaunchTemplates[].[DefaultVersionNumber,LatestVersionNumber]" --output text
1	3
```

Padrão 1, última 3. Nada foi lançado da versão 3 ainda, e nada será até alguém pedi-la pelo número
ou mover o padrão.

## Dois nomes que não são números

Quem lança a partir de um template pode indicar uma versão pelo número, ou por um de dois nomes.

- **`$Latest` é o número mais alto.** Ele se move sozinho, toda vez que alguém acrescenta uma versão.
- **`$Default` é a versão que o template diz.** Ele só se move quando alguém roda
  `modify-launch-template --default-version`, que é uma decisão com um nome ao lado no log.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um launch template chamado web com as versões 1, 2 e 3, e um espaço tracejado para uma versão 4 que alguém pode acrescentar. A versão 1 é t3.micro; as versões 2 e 3 são t3.medium. O nome $Latest aponta para a versão 3 e, tracejado, para o espaço da versão 4, porque se move sozinho. O nome $Default aponta para a versão 1, e um grupo de auto scaling que diz Version=$Default aponta para esse nome.\"><defs><marker id=\"lt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"16\" width=\"300\" height=\"268\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"46\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">launch template web</text><rect x=\"46\" y=\"50\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"60\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">versão 4</text><text x=\"300\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quem a acrescentar</text><rect x=\"46\" y=\"106\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão 3</text><text x=\"300\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">t3.medium</text><rect x=\"46\" y=\"162\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão 2</text><text x=\"300\" y=\"184\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">t3.medium</text><rect x=\"46\" y=\"218\" width=\"268\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">versão 1</text><text x=\"300\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">t3.micro</text><rect x=\"410\" y=\"106\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"465\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">$Latest</text><path d=\"M410 128 L320 128\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lt-ah)\"></path><path d=\"M440 106 L440 72 L320 72\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#lt-ah)\"></path><text x=\"410\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">move quando alguém cria uma versão</text><rect x=\"410\" y=\"218\" width=\"110\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"465\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">$Default</text><path d=\"M410 240 L320 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lt-ah)\"></path><text x=\"410\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">só move quando alguém o define</text><rect x=\"560\" y=\"196\" width=\"144\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"632\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">grupo de auto scaling</text><text x=\"632\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Version=$Default</text><path d=\"M560 240 L526 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lt-ah)\"></path></svg>", "caption": "Três versões e dois nomes. $Latest acompanha sozinho o número mais alto, então um grupo que o usa lança a partir do que foi criado por último; $Default fica onde alguém o pôs. Uma versão, depois de escrita, nunca é editada.", "same": ["launch template web"]}
```

A diferença é invisível no dia em que você a escreve e decisiva no dia em que alguém acrescenta uma
versão para testar alguma coisa. **Um grupo que diz `$Latest` lança a partir desse experimento no
próximo lançamento**, seja um aumento de escala às três da manhã ou a substituição de uma instância
que falhou, enquanto um grupo que diz `$Default` continua lançando a versão que alguém escolheu. Em
nenhum dos dois casos algo muda nas instâncias que já estão rodando, e esse é o assunto da última
seção desta lição. O grupo da próxima seção usa `$Default`.

## Launch configurations, que você ainda vai encontrar

Antes dos launch templates havia as **launch configurations**: um conjunto de respostas, sem
versões, que só um grupo podia usar. Mudar uma significava criar uma cópia com outro nome e apontar o
grupo para ela. A AWS vem aposentando-as. Elas não oferecem os tipos de instância lançados desde o
início de 2023, e contas criadas depois de 1º de outubro de 2024 não conseguem criá-las. Você ainda
vai encontrá-las em contas antigas e em Terraform antigo, e a migração é sempre a mesma: um launch
template com as mesmas respostas, e o grupo trocado para ele.
