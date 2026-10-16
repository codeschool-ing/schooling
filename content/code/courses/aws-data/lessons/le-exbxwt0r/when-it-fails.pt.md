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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Dois caminhos para um comando. Dentro do seu computador, aws s3 ls com AWS_ENDPOINT_URL definida vai para o moto_server em localhost:4567, que responde como a AWS responderia, para a conta 123456789012. Sem o endpoint, o mesmo comando vai pela internet até a AWS de verdade, em s3.sa-east-1.amazonaws.com, que recusa a chave test com InvalidAccessKeyId.\" data-fig=\"l01-endpoint\"><defs><marker id=\"l01-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><rect x=\"14\" y=\"14\" width=\"452\" height=\"232\" rx=\"8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 5\"/><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o seu computador</text><rect x=\"40\" y=\"96\" width=\"170\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"125\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">aws s3 ls</text><text x=\"125\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a linha de comando da AWS</text><rect x=\"290\" y=\"96\" width=\"156\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"/><text x=\"368\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">moto_server</text><text x=\"368\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">localhost:4567</text><line x1=\"210\" y1=\"118\" x2=\"288\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.6\" marker-end=\"url(#l01-ah)\"/><text x=\"249\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">com</text><text x=\"249\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">AWS_ENDPOINT_URL</text><text x=\"368\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">responde como a AWS</text><text x=\"368\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Account 123456789012</text><rect x=\"520\" y=\"96\" width=\"186\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"/><text x=\"613\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a AWS de verdade</text><text x=\"613\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">s3.sa-east-1.amazonaws.com</text><line x1=\"125\" y1=\"162\" x2=\"125\" y2=\"280\" stroke=\"var(--wire)\" stroke-width=\"1.6\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-ah)\"/><path d=\"M125,280 L540,280 L540,166\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-ah)\"/><text x=\"333\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem o endpoint: pela internet</text><text x=\"613\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recusa a chave test</text><text x=\"613\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">InvalidAccessKeyId</text></svg>", "caption": "Uma variável decide para onde vai cada requisição. Com ela, o moto responde; sem ela, a AWS de verdade recusa a chave."}
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
