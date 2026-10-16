---
title: "O serviço de metadados: uma instância perguntando sobre si mesma"
version: 1
---

O script da última seção fez uma pergunta com `curl` e recebeu de volta a sua zona de
disponibilidade, sem chave, sem assinatura e sem região. **Isso porque ele não estava chamando a
API do EC2.** Estava chamando o serviço de metadados da instância, um servidor HTTP em
`169.254.169.254` que toda instância alcança sem sair do seu host, e que responde a cada instância
sobre ela mesma e sobre nada mais.

A imagem errada é a de que este é mais um endpoint da AWS, como `ec2.sa-east-1.amazonaws.com` com
menos recursos. Um endpoint da AWS está na internet, recebe pedidos assinados e responde a quem
tiver a chave certa. **O serviço de metadados não recebe credencial nenhuma, porque a identidade
de quem chama é o lugar de onde o pedido veio.** `169.254.169.254` é um endereço link-local, que
nenhum roteador encaminha: um pedido para ele vindo da instância é respondido pelo host embaixo
dela, e o mesmo pedido vindo de qualquer outro lugar não chega a lugar nenhum.

## O que ele responde

O serviço é uma árvore de caminhos sob `/latest/`, e um caminho que termina em `/` lista o que há
embaixo dele. A AWS documenta uma lista longa; estes são os que um script procura:

| caminho | o que a AWS responde numa instância |
|---|---|
| `/latest/meta-data/instance-id` | o id da própria instância, `i-` e 17 caracteres |
| `/latest/meta-data/instance-type` | `t3.micro`, `m7g.large`, … |
| `/latest/meta-data/placement/availability-zone` | a zona, como `sa-east-1a` |
| `/latest/meta-data/local-ipv4` | o endereço privado dela na VPC |
| `/latest/meta-data/iam/security-credentials/` | o nome da role associada, se houver |
| `/latest/user-data` | o user data, decodificado |
| `/latest/dynamic/instance-identity/document` | um resumo em JSON do que está acima, assinado pela AWS |

A última linha é como uma instância prova quem é para um terceiro: o documento vem com uma
assinatura que a AWS publica os meios de conferir. A linha acima dela é o aviso da seção anterior
em forma concreta, já que qualquer processo na instância lê o user data de volta.

**O caminho que mais importa é o das credenciais.** Uma instância lançada com um instance profile,
como a aula 10 de `aws-foundations` montou, tem uma role, e em
`iam/security-credentials/<role>` o serviço entrega uma chave de acesso temporária, a chave secreta
e o token de sessão dessa role. A AWS faz o rodízio delas e deixa o próximo conjunto pronto antes
de o atual expirar. Todo SDK da AWS e a CLI procuram ali quando nada mais perto lhes dá
credenciais. As variáveis de ambiente e os arquivos em `~/.aws` vêm antes; o serviço de metadados
é o último lugar da cadeia, e numa instância é o que deve responder.

## O que o moto responde, e o que não responde

O moto não tem instâncias nem hosts, então nada neste laboratório consegue chamar
`169.254.169.254`. O que ele tem é um punhado desses caminhos servidos na própria porta, para que
um programa em teste ache credenciais do jeito que acharia numa instância:

```
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/; echo
iam
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/instance-id; echo
i-fake
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/placement/availability-zone; echo
us-east-1a
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/iam/security-credentials/; echo
default-role
ana@laptop:~/aws$ curl -s localhost:4567/latest/meta-data/iam/security-credentials/default-role; echo
{"AccessKeyId": "test-key", "SecretAccessKey": "test-secret-key", "Token": "test-session-token", "Expiration": "2026-10-17T16:06:37Z"}
```

**Leia isso como valores de enfeite, não como uma instância.** O id é `i-fake`, que não é
instância nenhuma que o moto lançou. A zona é `us-east-1a`, enquanto toda instância que este
laboratório lançou está em `sa-east-1a`. Há uma role chamada `default-role` embora nenhum instance
profile tenha sido associado a nada, e as chaves dela são as palavras `test-key` e
`test-secret-key`. As mesmas respostas voltam seja o que for lançado, e `instance-type`,
`local-ipv4` e `/latest/user-data` nem existem. Na AWS cada um desses caminhos responde com o
valor daquela instância, e diferente na próxima.

O que os valores de enfeite mostram de verdade é o lado do cliente. Tire do ambiente as duas
variáveis de credencial e diga à CLI onde está o serviço de metadados, que numa instância ela
sabe sem ninguém dizer. A CLI então sai procurando uma role:

```
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************-key     : iam-role         : 
secret_key : ****************-key     : iam-role         : 
region     : sa-east-1                : env              : ['AWS_REGION', 'AWS_DEFAULT_REGION']
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY AWS_EC2_METADATA_SERVICE_ENDPOINT=http://localhost:4567/ aws sts get-caller-identity --debug 2>&1 | grep -E "\"(PUT|GET) /latest|Found credentials" | sed "s/^.* - //"
http://localhost:4567 "PUT /latest/api/token HTTP/1.1" 200 17
http://localhost:4567 "GET /latest/meta-data/iam/security-credentials/ HTTP/1.1" 200 12
http://localhost:4567 "GET /latest/meta-data/iam/security-credentials/default-role HTTP/1.1" 200 134
Found credentials from IAM Role: default-role
```

`aws configure list` diz que as chaves vêm de `iam-role`, que é a cadeia caindo até o serviço de
metadados. As linhas do `--debug`, filtradas para os pedidos que foram até ele, mostram os três
passos da CLI: **primeiro um `PUT` em `/latest/api/token`**, depois um `GET` que lista a role, e
então um `GET` das credenciais dessa role. O pedido de token na primeira linha é o IMDSv2, e a CLI
o faz sem que ninguém peça. Por que existe um `PUT` é a próxima seção.
