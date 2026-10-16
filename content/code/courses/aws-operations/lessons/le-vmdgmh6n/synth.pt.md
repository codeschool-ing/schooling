---
title: A síntese, e ler o que ela escreveu
version: 1
---

`cdk synth` roda o programa e escreve o template que ele descreve. Nada é enviado a lugar nenhum: **a
síntese é um programa imprimindo um arquivo**, e pode rodar num notebook sem rede, num build ou num
teste.

```
ana@laptop:~/aws/cdk$ cdk synth --app "node app.js" > template.yaml
83 feature flags are not configured. Run 'cdk flags --unstable=flags' to learn more.
ana@laptop:~/aws/cdk$ wc -l app.js template.yaml
  37 app.js
  84 template.yaml
 121 total
ana@laptop:~/aws/cdk$ grep -E '^    Type: ' template.yaml | sort | uniq -c
      1     Type: AWS::CDK::Metadata
      1     Type: AWS::CloudWatch::Alarm
      1     Type: AWS::Logs::LogGroup
      1     Type: AWS::S3::Bucket
      1     Type: AWS::S3::BucketPolicy
      1     Type: AWS::SNS::Topic
      1     Type: AWS::SSM::Parameter::Value<String>
ana@laptop:~/aws/cdk$ ls cdk.out
ShopBase.assets.json
ShopBase.metadata.json
ShopBase.template.json
cdk.out
manifest.json
tree.json
validation-report.json
```

A linha sobre feature flags é um aviso na saída de erro: projetos criados com `cdk init` registram uma
lista de chaves de comportamento em `cdk.json`, e este app, escrito à mão, não tem nenhuma. Não muda
nada aqui.

**37 linhas de JavaScript viraram 84 linhas de template**, e os tipos dizem para onde foi a diferença.
Quatro recursos foram pedidos: o bucket, o grupo de logs, o tópico, o alarme. Apareceram mais três
entradas que ninguém escreveu:

- **`AWS::S3::BucketPolicy`**, da única linha `enforceSSL: true`;
- **`AWS::CDK::Metadata`**, um registro de qual versão da biblioteca fez a stack, que a AWS lê para
  contar o uso do CDK; `--no-version-reporting` o deixa de fora;
- **`AWS::SSM::Parameter::Value<String>`**, que nem é um recurso, e sim o tipo de um parâmetro, lido na
  próxima seção.

## No que uma linha virou

```
ana@laptop:~/aws/cdk$ sed -n '/UploadsPolicy/,/Version/p' template.yaml
  UploadsPolicy148F8199:
    Type: AWS::S3::BucketPolicy
    Properties:
      Bucket:
        Ref: Uploads4F6EB0FD
      PolicyDocument:
        Statement:
          - Action: s3:*
            Condition:
              Bool:
                aws:SecureTransport: "false"
            Effect: Deny
            Principal:
              AWS: "*"
            Resource:
              - Fn::GetAtt:
                  - Uploads4F6EB0FD
                  - Arn
              - Fn::Join:
                  - ""
                  - - Fn::GetAtt:
                        - Uploads4F6EB0FD
                        - Arn
                    - /*
        Version: "2012-10-17"
```

Essa é a política de que o template da lição 4 precisaria à mão: negar toda ação do S3 no bucket e em
todo objeto dele, para qualquer um, quando a requisição não veio por TLS. **O construct a escreveu
corretamente, com os dois recursos e tudo**, que é o caso dos constructs de nível 2: eles codificam uma
decisão uma vez, e todo bucket feito com a opção a recebe certa.

É também o argumento contra eles. A política está no template e na cabeça de ninguém; um revisor lendo
`app.js` vê `enforceSSL: true` e precisa saber no que isso se expande. **Leia o template sintetizado
na revisão**, pelo menos na primeira vez que um construct for usado, e sempre que a biblioteca for
atualizada, porque uma versão nova pode mudar o que uma opção escreve.

## Nomes que ninguém escolheu

Os ids lógicos terminam em hashes: `Uploads4F6EB0FD`, `UploadsPolicy148F8199`. O CDK deriva cada um do
caminho do construct na árvore (`ShopBase/Uploads/Resource`), para que dois constructs chamados
`Uploads` em lugares diferentes nunca colidam. A consequência importa em produção: **mudar um construct
de lugar na árvore muda o id lógico dele**, e para o CloudFormation um id lógico novo é um recurso novo,
então o bucket seria substituído. Um change set na esteira mostra isso antes de acontecer; o hábito de
ler change sets da lição 4 é o que pega uma refatoração que teria apagado os uploads.

## Os outros arquivos

`cdk.out` guarda o template em JSON, que é o que o deploy usa, e um `manifest.json` descrevendo o que
implantar onde. `ShopBase.assets.json` lista arquivos que a stack precisa ter enviados antes, como o
código de uma função Lambda ou uma imagem Docker. Este app não tem nenhum, e é isso que permite
implantá-lo no moto na próxima seção sem as ferramentas do próprio CDK.
