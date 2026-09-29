---
title: Credenciais numa máquina
version: 1
---

Um programa que chama uma API de nuvem precisa de credenciais, exatamente como uma pessoa. O jeito
óbvio de dar algumas a ele é o errado: criar uma chave de acesso, colar no código ou num arquivo de
configuração e publicar. **Uma chave de acesso escrita em qualquer coisa que é copiada é uma chave
entregue a quem receber uma cópia.**

- Um repositório guarda o histórico. Uma chave commitada e apagada no commit seguinte continua no
  primeiro, para todo mundo que clonar.
- Uma imagem de contêiner guarda todo arquivo de toda camada com que foi construída, então uma chave
  copiada para dentro e apagada num passo seguinte continua dentro da imagem.
- Um arquivo de configuração num servidor está nos backups e nos snapshots de disco dele, e nas
  imagens da aula 4 feitas a partir desse servidor.

E uma chave num repositório público é encontrada por gente que vasculha repositórios públicos atrás
exatamente desse formato de texto. Ninguém do seu lado precisa perceber o vazamento para outra
pessoa usar a chave.

## A máquina recebe uma role no lugar

O provedor já sabe qual máquina é qual, então pode entregar credenciais direto à máquina. Você anexa
uma role à máquina virtual, e um programa nela pede credenciais num endereço que só responde de dentro
daquela máquina: o **serviço de metadados da instância**, em `169.254.169.254`. É um endereço
link-local, que nunca é roteado para fora da rede em que está. A resposta é um conjunto de
credenciais temporárias da role, e o provedor as troca antes de expirarem. Nada fica escrito no
código nem na imagem, nada precisa de rotação, e uma cópia do disco não contém chave nenhuma.

A versão atual do serviço de metadados da AWS pede primeiro um token de sessão, obtido com um pedido
`PUT`, antes de responder. O motivo é um ataque específico: uma aplicação web enganada para buscar
uma URL a mando de um atacante pode ser levada a buscar o endereço de metadados, e um `GET` simples
bastava para entregar as credenciais da role. Um pedido que exige um `PUT` e um token antes é muito
mais difícil de arrancar de uma aplicação.

Uma função funciona do mesmo jeito pela sua role de execução, que a aula 8 usa, e um contêiner
rodando num serviço gerenciado tem um endpoint equivalente próprio.

## Como um programa acha as credenciais

A CLI e os SDKs não olham num lugar só: eles percorrem uma cadeia de fontes numa ordem fixa e usam a
primeira que responde. Dá para ver a busca num laptop com a AWS CLI e nenhuma credencial. Nada aqui
chega a uma conta AWS; o ambiente e o diretório home estão vazios de propósito, como o `captures.sh`
da aula prepara.

```
ana@laptop:~/cloud$ aws --version
aws-cli/2.37.4 Python/3.14.6 Linux/6.18.44-fc-v37 exe/x86_64.ubuntu.24
ana@laptop:~/cloud$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : <not set>                : None             : None
secret_key : <not set>                : None             : None
region     : <not set>                : None             : None
ana@laptop:~/cloud$ aws sts get-caller-identity

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
```

O `aws configure list` informa, para cada configuração, o valor encontrado e a fonte de onde veio.
Toda linha diz `<not set>` e `None`, porque não há fonte. A chamada seguinte,
`sts get-caller-identity`, é a que pergunta "quem sou eu?", e a própria CLI a recusa: `NoCredentials`
quer dizer que ela não achou nada com que assinar o pedido, então **ela nunca enviou o pedido**.

A saída do `--debug` mostra a busca:

```
ana@laptop:~/cloud$ aws sts get-caller-identity --debug 2>&1 | grep -o 'Looking for credentials via: .*'
Looking for credentials via: env
Looking for credentials via: assume-role
Looking for credentials via: assume-role-with-web-identity
Looking for credentials via: sso
Looking for credentials via: shared-credentials-file
Looking for credentials via: login
Looking for credentials via: custom-process
Looking for credentials via: config-file
Looking for credentials via: ec2-credentials-file
Looking for credentials via: boto-config
Looking for credentials via: container-role
Looking for credentials via: iam-role
```

Doze fontes, e a ordem é a aula. **O ambiente vem primeiro**: variáveis como `AWS_ACCESS_KEY_ID`
vencem tudo abaixo delas. Depois vêm os arquivos de configuração e de credenciais em `~/.aws`,
incluindo as formas de um perfil ali apontar para uma role, para um login pelo navegador (`sso`,
`login`) ou para um programa que busca credenciais (`custom-process`). As duas últimas são da
própria máquina: `container-role` para o endpoint de um contêiner e `iam-role` para o serviço de
metadados da instância. **Numa máquina virtual com uma role de escopo perfeito, um
`AWS_ACCESS_KEY_ID` esquecido no ambiente vence**, e toda chamada passa a rodar em silêncio como o
dono daquela chave.

É assim que uma chave de longa duração aparece quando alguém de fato a põe num arquivo. O par é o
exemplo que a AWS imprime na própria documentação e não pertence a ninguém:

```
ana@laptop:~/cloud$ cat ~/.aws/credentials
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
ana@laptop:~/cloud$ aws configure list
NAME       : VALUE                    : TYPE             : LOCATION
profile    : <not set>                : None             : None
access_key : ****************MPLE     : shared-credentials-file : 
secret_key : ****************EKEY     : shared-credentials-file : 
region     : <not set>                : None             : None
```

O mesmo comando agora aponta `shared-credentials-file` como a fonte e esconde tudo menos os quatro
últimos caracteres. O id começa com `AKIA`, o prefixo de uma chave de longa duração; as credenciais
temporárias que uma role entrega começam com `ASIA`. Quem ler esse arquivo, ou um backup dele, tem a
chave até alguém desativá-la.
