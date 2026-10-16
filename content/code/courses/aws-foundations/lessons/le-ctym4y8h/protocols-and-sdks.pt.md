---
title: Quatro protocolos de rede, e um SDK que os esconde
version: 1
---

**Os serviços da AWS não falam todos o mesmo dialeto de HTTP.** Os mais antigos recebem um
formulário e respondem em XML; a maioria dos mais novos recebe JSON; o S3 usa a própria URL como
endereço daquilo sobre o que age. A assinatura é a mesma em todos. Um SDK sabe que dialeto cada
serviço fala, e o programa que o usa nunca precisa saber.

A imagem errada é que existe uma API da AWS com um formato. **São quatro protocolos**, e uma
requisição montada à mão no protocolo errado é recusada, por mais bem assinada que esteja:

| protocolo | como a ação é nomeada | corpo | resposta | serviços |
|---|---|---|---|---|
| query | `Action=` e `Version=` num formulário | campos de formulário | XML | EC2, IAM, STS, os mais antigos |
| JSON | um cabeçalho `X-Amz-Target` | JSON | JSON | Organizations, DynamoDB, a maioria dos mais novos |
| REST-XML | o método e o caminho | XML, quando há um | XML | S3, CloudFront, Route 53 |
| REST-JSON | o método e o caminho | JSON | JSON | Lambda, API Gateway e outros |

## Três deles, medidos

O mesmo `--debug` e `grep` de antes, em três serviços. O Organizations fala JSON:

```
ana@laptop:~/aws$ aws organizations create-organization --feature-set ALL --debug 2>&1 | grep -oE "method=POST, url=[^,]*|'(Content-Type|X-Amz-Target)': b'[^']*'"
method=POST, url=http://localhost:4567/
'X-Amz-Target': b'AWSOrganizationsV20161128.CreateOrganization'
'Content-Type': b'application/x-amz-json-1.1'
```

**A ação está num cabeçalho**, `X-Amz-Target`, junto com a versão da API do serviço, `20161128`, e
toda chamada vai para `/`. O S3 é REST: o bucket é o caminho, e criar um é um `PUT` nele com um
corpo XML:

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket shop-assets --create-bucket-configuration LocationConstraint=sa-east-1 --debug 2>&1 | grep -oE "method=PUT, url=[^,]*|b'<CreateBucketConfiguration[^']*'"
b'<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><LocationConstraint>sa-east-1</LocationConstraint></CreateBucketConfiguration>'
method=PUT, url=http://localhost:4567/shop-assets
```

O XML também nomeia a versão do S3, `2006-03-01`, no namespace. Na AWS o bucket costuma ir para o
nome do host, `shop-assets.s3.sa-east-1.amazonaws.com`; com um endpoint próprio como o do moto, a
linha de comando o põe no caminho. O EC2 fala query, como o STS:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --debug 2>&1 | grep -oE "'body': \{[^}]*\}"
'body': {'Action': 'DescribeVpcs', 'Version': '2016-11-15'}
```

**Todo serviço traz uma versão de API, e ela é uma data.** A do STS é `2011-06-15` e a do EC2
`2016-11-15`. A AWS acrescenta operações e campos sob a mesma versão e mantém os antigos
funcionando, e é por isso que um script de quinze anos ainda roda; uma data de versão nova é rara, e
o SDK a nomeia por você. O REST-JSON do Lambda não foi medido aqui.

## O boto3, já no laboratório

**O boto3 é o SDK da AWS para Python**, e a linha de comando é construída sobre a camada de baixo
dele, o botocore. O laboratório o tem desde a lição 1, como uma das dependências do próprio moto:

```
ana@laptop:~/aws$ python3 -m pip show boto3 | grep -E "^(Name|Version|Required-by)"
Name: boto3
Version: 1.43.114
Required-by: moto
ana@laptop:~/aws$ which python3
/opt/awslab/home/ana/aws/venv/bin/python3
```

O `env.sh` ativou o `~/aws/venv`, então o `python3` é o do ambiente virtual, e o boto3 lê as mesmas
variáveis que a linha de comando: as chaves de teste, a região, e o `AWS_ENDPOINT_URL`, que o manda
para o moto. Este programa faz três perguntas ao laboratório com ele. Salve-o como
`~/aws/shop-check.py`:

```schooling-example
{"language": "python", "file": "shop-check.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Asks the lab three questions with boto3, the SDK the command line is built on.\n\n    python3 shop-check.py\n\"\"\"\nimport boto3\nfrom botocore.config import Config\n\nconfig = Config(region_name='sa-east-1', retries={'mode': 'standard', 'max_attempts': 3})\n\n", "note": "O `Config` guarda o que a linha de comando tira de opções e perfis. A região é a do laboratório, e as configurações de nova tentativa são as que a linha de comando usou por padrão na transcrição da próxima seção, escritas por extenso."}, {"code": "sts = boto3.client('sts', config=config)\nme = sts.get_caller_identity()\nprint('signed as', me['Arn'])\n\n", "note": "Um cliente por serviço. O nome do método é o da ação, na grafia do Python, e a resposta é um dicionário em vez de XML: o boto3 fez a leitura que a linha de comando faz. Nada aqui nomeia uma chave ou um endpoint, porque os dois vêm do ambiente, pela cadeia da lição 10."}, {"code": "s3 = boto3.client('s3', config=config)\ns3.put_object(Bucket='shop-assets', Key='hello.txt', Body=b'hello from boto3\\n')\nbody = s3.get_object(Bucket='shop-assets', Key='hello.txt')['Body'].read()\nprint('read back', body)\n\n", "note": "O S3 fala REST-XML e o STS fala query, e o código tem a mesma cara: essa diferença é o SDK que tem de saber. O objeto vai para o bucket que a linha de comando criou há pouco."}, {"code": "iam = boto3.client('iam', config=config)\npages = policies = 0\nfor page in iam.get_paginator('list_policies').paginate(Scope='AWS'):\n    pages += 1\n    policies += len(page['Policies'])\nprint(policies, 'policies in', pages, 'pages')\n", "note": "Um paginador segue os marcadores como a linha de comando fez na lição 25. Num SDK as páginas ficam visíveis: cada volta é uma requisição."}]}
```

```
ana@laptop:~/aws$ python3 shop-check.py
signed as arn:aws:sts::123456789012:user/moto
read back b'hello from boto3\n'
1544 policies in 16 pages
```

**Mesma identidade, mesmo bucket, as mesmas 16 páginas** da linha de comando, porque é a mesma
biblioteca fazendo as mesmas requisições. Todo outro SDK, para Java, JavaScript, Go, .NET e o resto,
é construído a partir das mesmas descrições de serviço, e é por isso que os métodos e os campos
deles têm os mesmos nomes.
