---
title: URLs pré-assinadas, e o que uma URL carrega
version: 1
---

**Uma URL pré-assinada é uma requisição que alguém assinou de antemão e entregou**: quem tiver a URL
pode fazer aquela requisição, com a autoridade de quem assinou, até ela expirar. É assim que a
Quitanda deixa um fornecedor baixar uma nota fiscal sem conta na AWS, e não é um link para um objeto
público. O objeto continua privado. O que viaja é a permissão, escrita numa string.

A imagem errada é a de que a URL é conferida contra algo guardado no S3, uma lista de links emitidos.
Nada é guardado. A linha de comando calcula a URL no seu computador a partir da sua chave, e o S3 só a
confere quando ela é usada, repetindo a mesma conta.

Esta lição começa com o moto vazio, com o moto rodando no terminal dele e as quatro linhas de "Seu
laboratório, em resumo", da lição 1, digitadas neste. Ponha um relatório no bucket curado e
pré-assine-o:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ printf 'day,orders,total_cents\n2026-10-15,412,5108840\n' > daily.csv && aws s3 cp daily.csv s3://quitanda-curated-prod/reports/daily.csv
upload: ./daily.csv to s3://quitanda-curated-prod/reports/daily.csv
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 300
http://localhost:4567/quitanda-curated-prod/reports/daily.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162605Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=028918085b4b621becb5ef8e0c0a01321cd2584af9492daecd84bc72d688ed21
ana@laptop:~/aws$ curl -s 'http://localhost:4567/quitanda-curated-prod/reports/daily.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162606Z&X-Amz-Expires=300&X-Amz-SignedHeaders=host&X-Amz-Signature=f1740fdcd82ed153929e93419e54eed0c820607234d007841ef57143557e848b'
day,orders,total_cents
2026-10-15,412,5108840
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 300 | tr '?&' '\n\n'
http://localhost:4567/quitanda-curated-prod/reports/daily.csv
X-Amz-Algorithm=AWS4-HMAC-SHA256
X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request
X-Amz-Date=20261016T162606Z
X-Amz-Expires=300
X-Amz-SignedHeaders=host
X-Amz-Signature=f1740fdcd82ed153929e93419e54eed0c820607234d007841ef57143557e848b
```

**A URL é o endereço do objeto com seis parâmetros**, e eles são a permissão inteira:

| parâmetro | o que diz |
|---|---|
| `X-Amz-Algorithm` | o método de assinatura, a Signature Version 4 |
| `X-Amz-Credential` | o id da chave de quem assinou, a data, a região e o serviço |
| `X-Amz-Date` | o momento da assinatura |
| `X-Amz-Expires` | quantos segundos depois desse momento ela continua valendo |
| `X-Amz-SignedHeaders` | quais cabeçalhos a assinatura cobre, aqui só `host` |
| `X-Amz-Signature` | a assinatura sobre tudo isso, feita com a chave secreta |

Duas consequências saem dessa tabela. **O id da chave está na URL**, aqui `test`, e na AWS esse é um
id de chave de acesso real, então uma URL pré-assinada colada num chat conta a todo mundo que a ler
qual chave a assinou. A chave secreta não está nela. E **a URL não diz nada sobre quem pode usá-la**:
nem endereço, nem conta, nem senha. Ter a URL é a conferência inteira.

## Fazer uma URL não confere nada

```
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/no-such-report.csv
http://localhost:4567/quitanda-curated-prod/reports/no-such-report.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162607Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=ae0e056e32c1c1300a8c83be665e207aa60963eed821ee57918a512c2b7c2aeb
ana@laptop:~/aws$ curl -s -o /dev/null -w '%{http_code}\n' 'http://localhost:4567/quitanda-curated-prod/reports/no-such-report.csv?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=test%2F20261016%2Fsa-east-1%2Fs3%2Faws4_request&X-Amz-Date=20261016T162608Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=36757897347ff035fa98212ceb794e46b6062834693319ded7ab3ecb36201c16'
404
```

**Uma URL para uma chave que não existe saiu sem reclamação**, porque fazê-la não mandou requisição
nenhuma. Só usá-la perguntou ao moto, que respondeu `NoSuchKey`. O mesmo vale para permissões: na AWS,
um usuário que não pode ler o bucket ainda consegue produzir uma URL bem formada, e a URL falha quando
usada, porque o S3 confere **as permissões de quem assinou no momento do uso**. Revogue o acesso de
quem assinou, ou desative a chave que assinou, e toda URL assinada por ela para de funcionar.

## A expiração, na AWS e no moto

O `--expires-in` recebe segundos e o padrão é 3600, uma hora. Na AWS, uma URL assinada com a chave de
longo prazo de um usuário do IAM pode viver até sete dias, 604.800 segundos. Uma assinada com
credenciais temporárias, as de um papel, para de funcionar quando essas credenciais expiram, diga o
`X-Amz-Expires` o que disser, e para a sessão de um papel isso costuma ser uma hora ou poucas. Depois
de expirada, o S3 responde `403` com `Request has expired`.

O moto não aplica nada disso:

```
ana@laptop:~/aws$ url=$(aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 1); sleep 3; curl -s -w '%{http_code}\n' "$url"
day,orders,total_cents
2026-10-15,412,5108840
200
ana@laptop:~/aws$ url=$(aws s3 presign s3://quitanda-curated-prod/reports/daily.csv); curl -s -w '%{http_code}\n' "${url%?}x"
day,orders,total_cents
2026-10-15,412,5108840
200
ana@laptop:~/aws$ aws s3 presign s3://quitanda-curated-prod/reports/daily.csv --expires-in 604801 | grep -o 'X-Amz-Expires=[0-9]*'
X-Amz-Expires=604801
```

**Uma URL válida por um segundo foi usada três segundos depois, e o moto entregou o relatório.** A
URL com o último caractere da assinatura trocado por um `x` também foi atendida, onde o S3 responderia
`SignatureDoesNotMatch`. E a linha de comando produziu uma URL válida por 604.801 segundos, um a mais
que o limite, porque o limite é do S3 aplicar quando a URL é usada, não da linha de comando quando ela é
feita. Nenhuma dessas respostas do S3 foi produzida aqui; são o comportamento documentado da AWS.

**Então neste laboratório uma URL pré-assinada mostra a forma e nada sobre a segurança.** Os hábitos
que a tornam segura vêm da documentação, e são baratos. Use a menor expiração que resolve: minutos
para um download que uma pessoa clica agora, nunca dias. Assine com um papel que só lê aquele prefixo
e mais nada, para que uma URL vazada valha um prefixo. E nunca ponha uma URL num lugar que fica
guardado, como um chamado, um log ou um commit, porque a URL é a permissão.
