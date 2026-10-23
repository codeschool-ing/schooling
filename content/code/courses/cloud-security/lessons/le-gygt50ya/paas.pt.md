---
title: PaaS, onde o runtime é do provedor e a versão dele é sua
version: 1
---

**Numa plataforma, o provedor aplica as correções do sistema operacional e do runtime da linguagem
debaixo do seu código, e você escolhe qual versão de runtime o seu código pede. Quando essa versão
chega ao fim da vida, as correções param, e a função continua rodando como se nada tivesse
acontecido.** O exemplo aqui é o AWS Lambda; o mesmo vale para o App Service no Azure e as Cloud Run
functions no Google Cloud.

A imagem errada é a de que no PaaS "o provedor mantém tudo atualizado". Ele mantém, **dentro da versão
que você escolheu**. Passar para a próxima versão é uma mudança no ambiente do seu código, pode quebrar
o seu código, e por isso é sua.

## Uma função num runtime velho

Deixe rodando o moto da seção anterior. A primeira versão da etapa de confirmação do sistema de
agendamento do caio é uma função. Ela precisa de um arquivo de código e de um papel com que a função
roda. O código tem três linhas:

```sh
cat > app.py <<'EOF'
def handler(event, context):
    return {"statusCode": 200, "body": "booking confirmed"}
EOF
python3 -m zipfile -c confirm.zip app.py
```

O papel diz só que o Lambda pode usá-lo, e a aula 13 trata do que permitir que ele faça:

```
ana@laptop:~/aws$ aws iam create-role --role-name booking-confirm --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' --query Role.Arn --output text
arn:aws:iam::123456789012:role/booking-confirm
```

O código foi copiado de um projeto antigo, e o comando que cria a função também, runtime incluído:

```
ana@laptop:~/aws$ aws lambda create-function --function-name booking-confirm --runtime python3.7 --handler app.handler --role arn:aws:iam::123456789012:role/booking-confirm --zip-file fileb://confirm.zip --query "[FunctionName,Runtime,State]" --output text
booking-confirm	python3.7	Active
```

**O moto aceitou, e a AWS não teria aceitado.** A AWS descontinuou o runtime `python3.7` do Lambda no
fim de 2023: dali em diante ele não recebeu mais correções de segurança, e algumas semanas depois a AWS
parou de aceitar funções novas nele. **Não executado aqui.** Na AWS este comando falha, e esse é o caso
fácil. O caso difícil é a função criada em 2022 que ainda roda hoje: a AWS não a para, manda avisos aos
contatos da conta, e a função segue respondendo num runtime que ninguém corrige.

## Achando, e corrigindo

A pergunta que a encontra é um inventário, feito a todas as funções:

```
ana@laptop:~/aws$ aws lambda list-functions --query "Functions[].[FunctionName,Runtime]" --output text
booking-confirm	python3.7
```

Uma função aqui; numa conta real a mesma consulta lista todas, e qualquer uma num runtime que passou
do fim da vida é um achado. A correção é uma requisição, e num sistema real ela vem **depois** de o
código ser testado na versão nova, já que trocar o runtime é trocar de Python:

```
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name booking-confirm --runtime python3.12 --query "[FunctionName,Runtime]" --output text
booking-confirm	python3.12
ana@laptop:~/aws$ aws lambda list-functions --query "Functions[].[FunctionName,Runtime]" --output text
booking-confirm	python3.12
```

## O que mais fica na lista de PaaS

A versão do runtime é o item que uma função divide com uma máquina virtual, num formato menor. Os
outros não têm equivalente em IaaS e são o assunto da aula 13:

| no IaaS você perguntava | no PaaS você pergunta |
|---|---|
| quais portas estão abertas para a internet | quem pode invocar a função |
| quais pacotes o sistema operacional tem | quais bibliotecas o código leva junto |
| o que o papel da máquina pode fazer | o que o papel da função pode fazer |

**O formato mudou e as perguntas não foram embora.** Uma função não tem porta 22 para deixar aberta, e
tem uma permissão de invocação que pode dizer "qualquer um". Não tem kernel para corrigir, e tem um
`requirements.txt` que fixa uma biblioteca com uma falha conhecida. Uma lista mais curta é uma lista
diferente, não uma lista vazia.
