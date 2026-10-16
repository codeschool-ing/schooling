---
title: Quando o laboratório não responde
version: 1
---

Estas são as falhas encontradas enquanto esta lição foi gravada, na ordem em que um aluno as
encontra, com o que cada uma diz e o que significa. Quase todas são uma linha esquecida.

**O `aws` não é encontrado.** Um terminal novo começa sem `~/.local/bin` no caminho:

```
ana@laptop:~/aws$ PATH=/usr/bin:/bin; aws --version
bash: line 1: aws: command not found
```

A segunda linha de "Toda vez que abrir um terminal" o devolve. O `moto_server` some do mesmo jeito
quando o ambiente virtual não está ativo, e a mesma linha resolve.

**Nenhuma credencial.** O terminal tem o caminho e não a terceira linha, então a linha de comando não
tem chave para assinar e para antes de enviar qualquer coisa:

```
ana@laptop:~/aws$ env -u AWS_ACCESS_KEY_ID -u AWS_SECRET_ACCESS_KEY aws s3 ls

aws: [ERROR]: An error occurred (NoCredentials): Unable to locate credentials. You can configure credentials by running "aws login".
```

**O moto não está rodando.** As variáveis estão definidas e nada escuta na porta, porque o outro
terminal foi fechado, ou o `Ctrl+C` parou o servidor:

```
ana@laptop:~/aws$ aws s3 ls

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

Ligue-o de novo no terminal dele. Ele volta vazio, e a lição em que você estava reconstrói o que
precisa a partir do primeiro comando.

**A porta está ocupada.** Um segundo `moto_server -p 4567`, num terceiro terminal, ou um que ficou
para trás quando um terminal foi fechado sem pará-lo:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567 2>&1 | tail -2
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

`Address already in use` quer dizer que já há um moto respondendo, então não há nada a consertar, a
não ser que você quisesse um vazio. Para parar o antigo, ache o processo e encerre: `pgrep -af
moto_server` imprime o número dele, e `kill` seguido desse número o para.

**O endpoint ficou de fora, e a requisição foi para a Amazon.** Esta é a que vale reconhecer, porque é
a única falha aqui que sai do seu computador. Com as chaves valendo `test` e sem `AWS_ENDPOINT_URL`, a
linha de comando faz exatamente o que foi feita para fazer, e pergunta à AWS de verdade:

```
ana@laptop:~/aws$ env -u AWS_ENDPOINT_URL aws s3 ls

aws: [ERROR]: An error occurred (InvalidAccessKeyId) when calling the ListBuckets operation: The AWS Access Key Id you provided does not exist in our records.
ana@laptop:~/aws$ env -u AWS_ENDPOINT_URL aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

**A AWS recusou a palavra `test` como chave, e essa é a resposta certa**: não existe essa chave, e não
há conta por trás dela. Nada foi criado e nada foi cobrado. Daí saem duas coisas. Se você vir
`InvalidAccessKeyId` ou `InvalidClientTokenId` neste curso, falta a linha do endpoint naquele
terminal. E se um comando der certo sem o endpoint, o seu terminal tem credenciais reais vindas de
outro lugar, um arquivo `~/.aws/credentials` ou uma variável de outro curso, e o comando acabou de
rodar contra uma conta de verdade. `aws sts get-caller-identity` diz qual é a conta; a do moto é
sempre `123456789012`.

**O `moto_server` para com um traceback dizendo que falta um módulo.** O ambiente virtual foi criado
com um Python de fora do próprio Ubuntu, ou o `pip` foi interrompido. Apague `~/aws/venv` e rode de
novo as duas linhas de "O moto, num ambiente virtual"; nada mais mora nessa pasta.
