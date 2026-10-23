---
title: Quem pode chamar a função
version: 1
---

**O papel de execução diz o que uma função pode fazer. Outro documento diz quem pode fazê-la rodar: a
política baseada em recurso da própria função e, para uma URL de função, o tipo de autenticação da
URL.** A seção anterior fechou a primeira borda. Esta é a borda voltada para a internet.

A crença errada comum é a de que uma função para a qual ninguém pôs um link é uma função que ninguém
chama. Uma URL de função é um endereço `https://` em `lambda-url.<region>.on.aws`, e um endereço que
responde acaba sendo achado: por um log, um histórico de navegador, uma captura de tela num chamado,
um scanner varrendo a internet. **Um endereço difícil de adivinhar não é controle de acesso.**

## Duas chaves, as duas em "qualquer um"

O moto 5.2.3 responde às requisições do Lambda com erros de assinatura quando a verificação está
ligada, então esta seção e a próxima rodam com a verificação desligada. Pare o moto com Ctrl+C e
inicie-o do jeito simples, vazio:

```sh
moto_server -p 4567
```

A função precisa do seu papel de novo, desta vez com a política de confiança que deveria ter tido
desde o começo, o `lambda-trust.json` da seção anterior. Salve o menor handler que existe como
`handler.py`:

```sh
cat > handler.py <<'EOF'
def handler(event, context):
    return {"statusCode": 200, "body": "export done"}
EOF
```

Crie o papel, empacote o handler num arquivo zip, que o Python sabe fazer sem nenhuma outra
ferramenta, e crie a função:

```
ana@laptop:~/aws$ aws iam create-role --role-name export-fn --assume-role-policy-document file://lambda-trust.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/export-fn
ana@laptop:~/aws$ python3 -m zipfile -c function.zip handler.py
ana@laptop:~/aws$ aws lambda create-function --function-name daily-export --runtime python3.12 --handler handler.handler --role arn:aws:iam::123456789012:role/export-fn --zip-file fileb://function.zip --query "[FunctionName,Runtime,State]" --output text
daily-export	python3.12	Active
```

O caio queria que o tablet da recepção disparasse uma exportação sem ninguém fazer login, então deu à
função uma URL cujo tipo de autenticação é `NONE` e permitiu que `"*"` a chamasse:

```
ana@laptop:~/aws$ aws lambda create-function-url-config --function-name daily-export --auth-type NONE --query "[FunctionUrl,AuthType]" --output text
https://01908989b9bb401ea800d33cc91a7c9e.lambda-url.sa-east-1.on.aws	NONE
ana@laptop:~/aws$ aws lambda add-permission --function-name daily-export --statement-id anyone --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE --query Statement --output text
{"Action": "lambda:InvokeFunctionUrl", "Principal": "*", "FunctionUrlAuthType": "NONE", "Effect": "Allow", "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:daily-export", "Sid": "anyone"}
ana@laptop:~/aws$ aws lambda get-policy --function-name daily-export --query Policy --output text | jq .
{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Action": "lambda:InvokeFunctionUrl",
      "Principal": "*",
      "FunctionUrlAuthType": "NONE",
      "Effect": "Allow",
      "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:daily-export",
      "Sid": "anyone"
    }
  ]
}
```

Leia a instrução como a AWS leria: **o principal é `*`, todo mundo; a ação é invocar a URL; e
`FunctionUrlAuthType: NONE` diz que nenhuma assinatura é exigida.** Uma requisição sem assinatura, de
qualquer lugar da internet, iniciaria a função, e cada início roda a exportação com as permissões do
papel e cai na conta da clínica. O moto não carrega tráfego nem roda função, então ninguém chamou
esse endereço aqui. O que você leu é a configuração que deixaria alguém chamar, que é exatamente o que
um revisor lê numa conta real.

## Fechando, e provando que fechou

Tire a instrução e faça a URL exigir assinatura:

```
ana@laptop:~/aws$ aws lambda remove-permission --function-name daily-export --statement-id anyone
ana@laptop:~/aws$ aws lambda update-function-url-config --function-name daily-export --auth-type AWS_IAM --query AuthType --output text
AWS_IAM
ana@laptop:~/aws$ aws lambda get-policy --function-name daily-export

aws: [ERROR]: An error occurred (ResourceNotFoundException) when calling the GetPolicy operation: The resource you requested does not exist.
```

`ResourceNotFoundException` é a resposta a ler: **a função não tem política baseada em recurso
nenhuma**, então ninguém de fora da conta tem permissão para chamá-la, e dentro da conta só
identidades cujas próprias políticas permitem `lambda:InvokeFunctionUrl` conseguem, com uma
requisição assinada. Contra a AWS, a mesma requisição sem assinatura que teria iniciado a exportação
agora recebe `403 Forbidden`. Essa última requisição **não foi executada aqui**, já que o moto não
serve URLs de função.

Se o tablet precisa mesmo disparar a exportação, dê uma identidade ao tablet, ou ponha a função atrás
de algo que autentique o tablet. Não entregue o endereço da função ao mundo.

## Quando um serviço chama a função

A maioria das funções não é chamada por pessoas. Um arquivo cai num bucket, e o S3 chama a função.
Aqui o principal é um serviço, e o perigo é mais discreto: `s3.amazonaws.com` nomeia **todo bucket de
toda conta**, então uma permissão que nomeia só o serviço deixa o bucket de qualquer pessoa,
configurado para notificar a sua função, fazê-la rodar. A AWS chama isso de problema do *confused
deputy*, o intermediário confuso. A correção é dizer qual bucket, e qual conta é dona dele:

```
ana@laptop:~/aws$ aws lambda add-permission --function-name daily-export --statement-id from-uploads --action lambda:InvokeFunction --principal s3.amazonaws.com --source-arn arn:aws:s3:::clinic-uploads --source-account 123456789012 --query Statement --output text | jq .
{
  "Action": "lambda:InvokeFunction",
  "Principal": {
    "Service": "s3.amazonaws.com"
  },
  "Effect": "Allow",
  "Resource": "arn:aws:lambda:sa-east-1:123456789012:function:daily-export",
  "Sid": "from-uploads",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:s3:::clinic-uploads"
    },
    "StringEquals": {
      "AWS:SourceAccount": "123456789012"
    }
  }
}
```

O bloco `Condition` é a parte que importa: a chamada só é permitida quando vem do bucket
`clinic-uploads` na conta `123456789012`. O moto guarda a condição e não a julga, já que ignora
condições em todo lugar; a AWS a julga a cada chamada. A conta importa mesmo com o bucket nomeado,
porque o nome de um bucket fica livre de novo quando o dono o apaga, e qualquer pessoa pode então
criar um com o mesmo nome em outra conta.
