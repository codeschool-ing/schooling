---
title: O pacote de implantação, e o que o Lambda guarda dele
version: 1
---

Uma função na AWS são duas coisas mantidas separadas: **o código, como um pacote que o Lambda
guarda, e uma configuração que diz como executá-lo**, ou seja, o runtime, o handler, a memória, o
timeout e o role. Você envia o pacote uma vez por mudança e edita a configuração quando quiser. Para
uma função Python o pacote é o mais simples que existe, um arquivo zip com o seu código na raiz.

## Um zip com o handler no topo

Em `~/aws/greet`:

```
ana@laptop:~/aws/greet$ zip function.zip app.py
  adding: app.py (deflated 46%)
ana@laptop:~/aws/greet$ unzip -l function.zip
Archive:  function.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
      510  2026-10-16 13:32   app.py
---------                     -------
      510                     1 file
ana@laptop:~/aws/greet$ aws lambda create-function --function-name greet --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://function.zip

aws: [ERROR]: An error occurred (InvalidParameterValueException) when calling the CreateFunction operation: The role defined for the function cannot be assumed by Lambda.
```

O zip tem um arquivo, `app.py`, na raiz, que é onde `app.handler` diz ao runtime para procurar: o
Lambda desempacota o pacote em `/var/task`, o diretório que o emulador tinha montado. Um zip cujos
arquivos estão dentro de uma pasta, `greet/app.py`, é o primeiro erro mais comum, e na AWS ele falha
na primeira invocação com o mesmo `Runtime.ImportModuleError` que a próxima seção produz de
propósito.

A recusa é a parte mais interessante. **Uma função não existe sem um role**, o role de execução que
a aula 9 de `aws-foundations` apresentou: o Lambda o assume para rodar o seu código, e tudo o que o
código faz na AWS ele faz com as permissões desse role. O moto confere, como a AWS confere, que o
role existe e que a política de confiança dele deixa o serviço Lambda assumi-lo. Então crie um, com
uma política de confiança que nomeia `lambda.amazonaws.com`, e tente de novo:

```
ana@laptop:~/aws/greet$ aws iam create-role --role-name greet-role --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query Role.Arn
"arn:aws:iam::123456789012:role/greet-role"
ana@laptop:~/aws/greet$ aws lambda create-function --function-name greet --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://function.zip --query "{State:State,CodeSize:CodeSize,MemorySize:MemorySize,Timeout:Timeout,Architectures:Architectures,EphemeralStorage:EphemeralStorage}"
{
    "State": "Active",
    "CodeSize": 438,
    "MemorySize": 128,
    "Timeout": 3,
    "Architectures": [
        "x86_64"
    ],
    "EphemeralStorage": {
        "Size": 512
    }
}
```

Agora existe uma função, e a configuração dela mostra **os padrões da AWS, que o moto copia**: 128
MB de memória, timeout de três segundos, arquitetura x86 e 512 MB de `/tmp`. Cada um é uma
configuração, e não um fato sobre o Lambda. A memória vai de 128 MB a 10.240 MB, e a capacidade de
processador que o Lambda dá a uma função cresce junto. O timeout vai até 900 segundos, quinze
minutos, o máximo que uma única invocação consegue rodar. `/tmp` vai até 10.240 MB. O role aqui não
tem política de permissão nenhuma, então na AWS a função rodaria e não conseguiria escrever o seu
log até que `AWSLambdaBasicExecutionRole`, ou uma política parecida, fosse anexada.

## Para onde o pacote foi

```
ana@laptop:~/aws/greet$ aws lambda get-function --function-name greet --query "Code"
{
    "RepositoryType": "S3",
    "Location": "https://awslambda-sa-east-1-tasks.s3.sa-east-1.amazonaws.com/greet-b5c47ccc-abc8-4f2e-8d04-caf6a96fabab"
}
```

Na AWS esse `Location` é uma URL pré-assinada do S3, válida por dez minutos, de onde você consegue
baixar o pacote exato que a função roda. O moto imprime o formato de uma e guarda o zip na própria
memória. **O pacote pertence ao Lambda depois de enviado**: fica num armazenamento que a AWS
administra, e mudar um arquivo no seu laptop não muda nada até você enviar de novo.

## Mudando o código, e congelando uma versão

Uma edição é um zip novo e uma chamada. A configuração não é tocada:

```
ana@laptop:~/aws/greet$ sed -i "s/'hello, /'olá, /" app.py
ana@laptop:~/aws/greet$ zip -q function.zip app.py
ana@laptop:~/aws/greet$ aws lambda update-function-code --function-name greet --zip-file fileb://function.zip --query "[CodeSize,CodeSha256,Version]"
[
    441,
    "LRJpbyQkRSXJg6Gcp8aABFoi/aC17fsctkEzwCdC9Es=",
    "$LATEST"
]
ana@laptop:~/aws/greet$ aws lambda publish-version --function-name greet --query "[Version,CodeSha256]"
[
    "1",
    "LRJpbyQkRSXJg6Gcp8aABFoi/aC17fsctkEzwCdC9Es="
]
```

`CodeSha256` é o SHA-256 do zip em base64, e é como se descobre qual pacote uma função está rodando:
calcule o mesmo hash de um zip no seu laptop e compare. `$LATEST` é a única versão que muda, e toda
atualização cai nela. `publish-version` congela o código e a configuração atuais como a versão `1`,
que nunca mais muda; os aliases e a concorrência provisionada da aula 16 apontam para versões como
esta, nunca para `$LATEST`.

## Invocando pelo moto, aqui

A última coisa a tentar contra o moto é executá-la:

```
ana@laptop:~/aws/greet$ aws lambda invoke --function-name greet --cli-binary-format raw-in-base64-out --payload '{"name": "ana"}' out.json
{
    "StatusCode": 200,
    "FunctionError": "Handled"
}
ana@laptop:~/aws/greet$ cut -c1-150 out.json; echo
error running docker: 500 Server Error for http+docker://localhost/v1.56/images/create?tag=python3.12&fromImage=docker.io%2Fmlupin%2Fdocker-lambda: In
```

**`FunctionError: Handled` com status 200 é como o Lambda informa uma função que falhou**, e aqui a
falha é do moto, não da função: para rodar o código, o moto baixa do Docker Hub uma imagem
comunitária do runtime do Lambda e roda o handler nela, e esta máquina não conseguiu baixá-la. Num
computador que alcança o Docker Hub, o moto roda o handler desse jeito. Este curso usa a imagem base
da própria AWS, como na seção anterior, porque é o runtime que o próprio Lambda usa e porque já está
na sua máquina.

## Os limites, que o moto não mantém

Mais um envio, de um pacote que é quase todo sessenta megabytes de bytes aleatórios:

```
ana@laptop:~/aws/greet$ head -c 60000000 /dev/urandom > blob.bin
ana@laptop:~/aws/greet$ zip -q big.zip app.py blob.bin && stat -c '%s bytes' big.zip
60009740 bytes
ana@laptop:~/aws/greet$ aws lambda create-function --function-name big --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://big.zip --query CodeSize
60009740
```

**O moto aceitou, e a AWS não aceitaria.** As cotas documentadas do Lambda para um pacote são:

| | limite |
| --- | --- |
| um zip enviado diretamente, como aqui | 50 MB |
| um zip enviado a partir do S3 | sem limite para o zip em si |
| o pacote descompactado, incluindo todas as layers | 250 MB |
| uma imagem de contêiner | 10 GB, sem compressão |

Então um zip de 60 MB precisa passar pelo S3 (`--code S3Bucket=…,S3Key=…`), e mesmo assim precisa
descompactar em menos de 250 MB junto com as suas layers. Nenhuma dessas recusas foi executada aqui;
o moto não mantém nenhum dos quatro limites. Eles são o motivo de a próxima seção existir, e o
motivo de a seguinte falar de imagens.
