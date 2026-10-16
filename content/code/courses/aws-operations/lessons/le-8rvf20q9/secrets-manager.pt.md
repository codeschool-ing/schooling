---
title: Secrets Manager, versões e estágios
version: 1
---

Um segredo costuma ser um pequeno documento JSON com tudo de que uma conexão precisa:

```
ana@laptop:~/aws/secrets$ aws secretsmanager create-secret --name shop/prod/db --secret-string '{"username":"shop","password":"first-pass"}' --query ARN --output text
arn:aws:secretsmanager:sa-east-1:123456789012:secret:shop/prod/db-BdrPcr
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/db --query '[SecretString,VersionStages[0]]' --output text
{"username":"shop","password":"first-pass"}	AWSCURRENT
```

O ARN termina com um hífen e **seis caracteres aleatórios** que o Secrets Manager acrescenta ao nome. Uma
política que nomeia o segredo precisa levá-los em conta, `secret:shop/prod/db-*`, e a seção sobre acesso
volta a isso. O valor voltou com o estágio, `AWSCURRENT`.

## Versões e estágios

Escrever um valor novo cria uma versão nova, e os estágios se movem:

```
ana@laptop:~/aws/secrets$ aws secretsmanager put-secret-value --secret-id shop/prod/db --secret-string '{"username":"shop","password":"second-pass"}' --query VersionStages
[
    "AWSCURRENT"
]
ana@laptop:~/aws/secrets$ aws secretsmanager list-secret-version-ids --secret-id shop/prod/db --query 'Versions[].[VersionId,VersionStages[0]]' --output text
5458714e-f3cf-4d2f-b216-aa4da18c6ce6	AWSPREVIOUS
fe2de9d1-a408-4db9-a4a4-ade7b727a7ed	AWSCURRENT
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/db --version-stage AWSPREVIOUS --query SecretString --output text
{"username":"shop","password":"first-pass"}
```

`AWSCURRENT` é o que uma leitura sem estágio devolve; `AWSPREVIOUS` é a versão anterior, guardada
justamente para uma mudança poder ser desfeita, ou para diagnosticar um programa que ainda segura a senha
antiga. **Uma leitura nunca nomeia uma versão**; nomeia um estágio, ou nada, e o estágio decide.

O Secrets Manager também cria os próprios valores:

```
ana@laptop:~/aws/secrets$ aws secretsmanager get-random-password --password-length 24 --exclude-punctuation --query RandomPassword --output text
SHYyfBotp3gzwePXnDTXtuL0
```

Uma senha que ninguém escolheu e ninguém viu é a melhor que há, e esta fica só no laboratório, nunca
digitada em lugar nenhum.

## Rotação

**A rotação é uma função Lambda que o Secrets Manager chama num agendamento, em quatro passos**, como a
AWS documenta: `createSecret` cria uma senha nova e a guarda como `AWSPENDING`; `setSecret` a define no
banco; `testSecret` conecta com ela; `finishSecret` passa `AWSCURRENT` para ela, e a antiga vira
`AWSPREVIOUS`. Se qualquer passo falha, `AWSCURRENT` não se moveu, e a aplicação segue com a senha que
funciona. Para RDS e Aurora existe uma forma gerenciada, sem função a escrever, em que o serviço de banco é
dono do segredo da senha mestre e o rotaciona sozinho.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro passos em sequência. 1, createSecret: uma senha nova é guardada como AWSPENDING. 2, setSecret: ela é definida no banco, e a antiga ainda vale. 3, testSecret: a função conecta com AWSPENDING. 4, finishSecret: AWSCURRENT passa para a versão nova e a antiga vira AWSPREVIOUS. Abaixo: uma falha em qualquer passo deixa AWSCURRENT onde estava, e a aplicação segue com a senha que funciona. São os passos da função Lambda como a AWS os documenta, não executados no laboratório.\"><defs><marker id=\"rot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">createSecret</text><text x=\"95.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">senha nova guardada</text><text x=\"95.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">como AWSPENDING</text><text x=\"95\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">1</text><path d=\"M172 98 L194 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rot-ah)\"></path><rect x=\"196\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"271.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setSecret</text><text x=\"271.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">definida no banco</text><text x=\"271.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a antiga ainda vale</text><text x=\"271\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">2</text><path d=\"M348 98 L370 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rot-ah)\"></path><rect x=\"372\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">testSecret</text><text x=\"447.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conecta com</text><text x=\"447.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">AWSPENDING</text><text x=\"447\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">3</text><path d=\"M524 98 L546 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rot-ah)\"></path><rect x=\"548\" y=\"50\" width=\"150\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"623.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">finishSecret</text><text x=\"623.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AWSCURRENT muda</text><text x=\"623.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a antiga vira AWSPREVIOUS</text><text x=\"623\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4</text><path d=\"M20 176 L698 176\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"20\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Uma falha em qualquer passo deixa AWSCURRENT onde estava: a aplicação segue com a senha que funciona.</text><text x=\"20\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Passos da função Lambda, como a AWS os documenta; não executados no laboratório.</text></svg>", "caption": "O estágio muda por último, e só depois de uma conexão com a senha nova funcionar.", "same": ["AWSPENDING"]}
```

O moto não tem Lambda para rodar, e faz algo que a AWS não faria:

```
ana@laptop:~/aws/secrets$ aws secretsmanager create-secret --name shop/prod/smtp --secret-string smtp-pass --query Name
"shop/prod/smtp"
ana@laptop:~/aws/secrets$ aws secretsmanager rotate-secret --secret-id shop/prod/smtp --rotation-rules AutomaticallyAfterDays=30 --query Name
"shop/prod/smtp"
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/smtp --query SecretString

aws: [ERROR]: An error occurred (ResourceNotFoundException) when calling the GetSecretValue operation: Secrets Manager can't find the specified secret value for staging label: AWSCURRENT
```

**A AWS recusa uma rotação sem função para chamar**, para um segredo que nenhum serviço gerencia. O moto
aceita, cria uma versão nova sem valor, a torna `AWSCURRENT`, e a leitura seguinte falha. No laboratório
é uma curiosidade; também é um bom retrato de uma função de rotação que move o estágio sem definir o
valor, que é o único bug que uma função de rotação não pode ter.

## Apagar, com uma janela

```
ana@laptop:~/aws/secrets$ aws secretsmanager delete-secret --secret-id shop/prod/smtp --query DeletionDate --output text
2026-11-15T16:27:41.493292-03:00
ana@laptop:~/aws/secrets$ aws secretsmanager get-secret-value --secret-id shop/prod/smtp 2>&1 | tail -1
aws: [ERROR]: An error occurred (InvalidRequestException) when calling the GetSecretValue operation: An error occurred (InvalidRequestException) when calling the GetSecretValue operation: You tried to                 perform the operation on a secret that's currently marked deleted.
ana@laptop:~/aws/secrets$ aws secretsmanager restore-secret --secret-id shop/prod/smtp --query Name
"shop/prod/smtp"
```

Um segredo apagado não sumiu: ele espera **30 dias** por padrão, entre 7 e 30 conforme escolhido, e pode
ser restaurado até lá. Lê-lo falha nesse meio tempo, então uma aplicação que ainda usa um segredo que
alguém apagou quebra na hora, dentro da janela, quando restaurá-lo é um comando.
`--force-delete-without-recovery` pula a janela, e essa opção não é para produção.
