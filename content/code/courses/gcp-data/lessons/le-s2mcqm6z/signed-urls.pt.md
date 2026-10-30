---
title: URLs assinadas, e o que uma URL carrega
version: 1
---

**Uma URL assinada é uma requisição que alguém assinou com antecedência e entregou**: quem tiver a URL
pode fazer aquela requisição, com a autoridade de quem assinou, até ela expirar. É assim que a Quitanda
deixa um fornecedor baixar uma nota fiscal sem conta do Google, e não é um link para um objeto público.
O objeto continua privado. O que viaja é a permissão, escrita numa string.

A imagem errada é que a URL é conferida contra algo que o Cloud Storage guarda, uma lista dos links
emitidos. Nada é guardado. **A assinatura é calculada no computador de quem assina, a partir de uma
chave privada, e o Cloud Storage só a confere quando a URL é usada**, reconstruindo a mesma requisição
e verificando a assinatura com a chave pública de quem assinou. Fazer uma URL não manda nada para
ninguém.

## Uma chave para uma conta que não existe

Assinar exige uma chave privada, e uma chave real pertence a uma conta de serviço real. Este
laboratório não usa nenhuma das duas. **A chave abaixo é feita no seu laptop pelo `openssl`, para uma
conta de serviço inventada para esta aula, `report-signer@planner-dev.iam.gserviceaccount.com`, que
não existe em projeto nenhum.** O Google nunca viu a chave e nenhum serviço do Google aceitaria o que
ela assina; ela consegue assinar, que é tudo de que a aula precisa. Nunca use a chave de uma conta de
serviço real num exercício, e nunca cole uma num terminal que você está gravando: a aula 8 de
`gcp-foundations` trata de por que uma chave baixada é o último recurso mesmo para trabalho real.

```sh
openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out signer.pem
```

Isso é uma chave privada RSA de 2.048 bits em `signer.pem`. A biblioteca cliente lê chaves no formato
de um arquivo de chave de conta de serviço, um documento JSON, então um programa curto a embrulha num:

`make-key.py`:

```python
"""Wrap a key made on this laptop in the shape of a service account key file.

The account does not exist and Google has never seen this key. It can sign a
URL, and no Google service anywhere will accept what it signs.
"""
import json

json.dump({
    'type': 'service_account',
    'project_id': 'planner-dev',
    'private_key_id': 'local-only',
    'private_key': open('signer.pem').read(),
    'client_email': 'report-signer@planner-dev.iam.gserviceaccount.com',
    'client_id': '0',
    'token_uri': 'https://oauth2.googleapis.com/token',
}, open('signer-key.json', 'w'), indent=2)
print('wrote signer-key.json for report-signer@planner-dev.iam.gserviceaccount.com')
```

```
ana@laptop:~/gcp$ python3 make-key.py
wrote signer-key.json for report-signer@planner-dev.iam.gserviceaccount.com
ana@laptop:~/gcp$ python3 -c 'import json; k = json.load(open("signer-key.json")); print(k["client_email"], k["private_key"].splitlines()[0])'
report-signer@planner-dev.iam.gserviceaccount.com -----BEGIN PRIVATE KEY-----
```

**`signer-key.json` agora guarda uma chave privada, e é tratado como tal**: fica em `~/gcp`, nunca é
commitado em lugar nenhum, e o último comando imprimiu só a primeira linha dela, o cabeçalho PEM, para
mostrar que tipo de arquivo é. O resto da chave não vai para a tela.

## Assinando uma URL

O programa que assina, salvo como `~/gcp/sign.py`, recebe o nome de um objeto e um número de segundos:

```schooling-example
{"language": "python", "file": "sign.py", "parts": [{"code": "\"\"\"Sign a V4 URL for one object of the curated bucket, on this laptop.\"\"\"\nimport datetime\nimport sys\n\nfrom google.cloud import storage\nfrom google.oauth2 import service_account\n\n", "note": "Duas bibliotecas do ambiente virtual do curso: o cliente do Cloud Storage, e a biblioteca de autenticação do Google, que lê um arquivo de chave."}, {"code": "key, seconds = sys.argv[1], int(sys.argv[2])\ncreds = service_account.Credentials.from_service_account_file('signer-key.json')\nclient = storage.Client(credentials=creds, project='planner-dev')\nblob = client.bucket('quitanda-curated-prod').blob(key)\n\n", "note": "**Nada aqui manda requisição.** Ler o arquivo de chave e dar nome a um bucket e a um objeto são passos locais; o cliente não pergunta se algum deles existe."}, {"code": "print(blob.generate_signed_url(version='v4', method='GET',\n                               expiration=datetime.timedelta(seconds=seconds)))\n", "note": "`generate_signed_url` monta a requisição que quem ler vai fazer, assina-a com a chave privada e a devolve como URL. Como `STORAGE_EMULATOR_HOST` está definida, o endereço é o do emulador; no Google seria `https://storage.googleapis.com/…`."}]}
```

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ printf 'day,orders,total_cents\n2026-10-29,412,5108840\n' > daily.csv && gcloud storage cp daily.csv gs://quitanda-curated-prod/reports/daily.csv
Copying file://daily.csv to gs://quitanda-curated-prod/reports/daily.csv
  

ana@laptop:~/gcp$ python3 sign.py reports/daily.csv 300 | tr '?&' '\n\n' | cut -c1-120
http://localhost:4443/quitanda-curated-prod/reports/daily.csv
X-Goog-Algorithm=GOOG4-RSA-SHA256
X-Goog-Credential=report-signer%40planner-dev.iam.gserviceaccount.com%2F20261030%2Fauto%2Fstorage%2Fgoog4_request
X-Goog-Date=20261030T185330Z
X-Goog-Expires=300
X-Goog-SignedHeaders=host
X-Goog-Signature=7975368cb0a13301b7547dbd2fc6bc2b4d27febd9c94a11ab2d3a1e1aff92efc3b93be9cd1e3e343b14a823b17398f702834d4a
```

**A URL é o endereço do objeto com seis parâmetros**, e eles são toda a permissão:

| parâmetro | o que diz |
|---|---|
| `X-Goog-Algorithm` | o método de assinatura: a assinatura V4 do Google, com chave RSA e SHA-256 |
| `X-Goog-Credential` | quem assinou, a data, o local e o serviço |
| `X-Goog-Date` | o momento em que foi assinada |
| `X-Goog-Expires` | quantos segundos depois desse momento ela continua válida |
| `X-Goog-SignedHeaders` | que cabeçalhos a assinatura cobre, aqui só `host` |
| `X-Goog-Signature` | a assinatura RSA sobre tudo isso, em hexadecimal, mostrada cortada na linha aqui |

Duas consequências saem dessa tabela. **A identidade de quem assinou está na URL**: uma URL assinada
colada num chat diz a todos que a leem que conta de serviço a assinou. A chave não está nela. E **a URL
não diz nada sobre quem pode usá-la**: nenhum endereço, nenhuma conta, nenhuma senha. Ter a URL é toda
a verificação. `auto` na credencial é o local que a biblioteca de Python escreve; a linha de comando,
mais abaixo, escreve a região do bucket, e o Cloud Storage aceita os dois.

## Usando a URL, e o que o emulador confere

```
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' "$(python3 sign.py reports/daily.csv 300)"
Not Found
404
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "$(python3 sign.py reports/daily.csv 300)"
day,orders,total_cents
2026-10-29,412,5108840
200
ana@laptop:~/gcp$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "$(python3 sign.py reports/no-such-report.csv 300)"
404
```

**O primeiro `curl` recebeu `Not Found`, e o segundo, com um cabeçalho a mais, recebeu o relatório.** O
fake-gcs-server só serve um endereço no formato `/bucket/objeto` quando a requisição diz que é para o
host do Google, `storage.googleapis.com`; a biblioteca cliente escreveu o endereço do emulador na URL,
e `-H 'Host: …'` põe o nome do Google de volta na requisição. Isso é um detalhe do emulador, e daqui em
diante toda requisição a uma URL assinada leva o cabeçalho. O terceiro comando usou uma URL para um
relatório que não existe: ela foi assinada sem reclamação, porque assinar não perguntou nada a
ninguém, e só o uso encontrou o `404`.

Agora as três requisições que o Cloud Storage existe para recusar:

```
ana@laptop:~/gcp$ url=$(python3 sign.py reports/daily.csv 1); sleep 3; curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "$url"
day,orders,total_cents
2026-10-29,412,5108840
200
ana@laptop:~/gcp$ url=$(python3 sign.py reports/daily.csv 300); curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' "${url%?}x"
day,orders,total_cents
2026-10-29,412,5108840
200
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' -H 'Host: storage.googleapis.com' http://localhost:4443/quitanda-curated-prod/reports/daily.csv
day,orders,total_cents
2026-10-29,412,5108840
200
```

**Uma URL válida por um segundo foi usada três segundos depois, e o emulador serviu o relatório.** A
URL com o último caractere da assinatura trocado por `x` também foi servida, e o endereço puro sem
assinatura nenhuma também. O fake-gcs-server não lê a assinatura: ele serve qualquer objeto a
qualquer requisição. No Cloud Storage as três seriam recusadas: a primeira com um erro dizendo que a
requisição expirou, a segunda com um dizendo que a assinatura não confere, e a terceira porque o
objeto é privado e a requisição não foi assinada por ninguém. Nenhuma dessas respostas foi produzida
aqui; elas são o comportamento documentado em cloud.google.com/storage/docs/access-control/signed-urls.

**Então, neste laboratório, uma URL assinada mostra a forma e nada sobre a segurança.**

## Os limites, que são conferidos antes de qualquer envio

```
ana@laptop:~/gcp$ python3 sign.py reports/daily.csv 604801 2>&1 | tail -1
ValueError: Max allowed expiration interval is seven days 604800
ana@laptop:~/gcp$ gcloud storage sign-url gs://quitanda-curated-prod/reports/daily.csv --private-key-file=signer-key.json --duration=8d 2>&1 | head -1
ERROR: (gcloud.storage.sign-url) argument -d/--duration: value must be less than or equal to 7d; received: 8d
ana@laptop:~/gcp$ gcloud storage sign-url gs://quitanda-curated-prod/reports/daily.csv --private-key-file=signer-key.json --duration=10m 2>&1 | cut -c1-100 | head -6
---
expiration: '2026-10-30 19:03:37'
http_verb: GET
resource: gs://quitanda-curated-prod/reports/daily.csv
signed_url: https://quitanda-curated-prod.storage.googleapis.com/reports/daily.csv?x-goog-signature=
ERROR: gcloud crashed (ConnectionError): HTTPSConnectionPool(host='quitanda-curated-prod.storage.goo
```

**Sete dias é o máximo que uma assinatura V4 pode viver**, 604.800 segundos, e tanto a biblioteca
quanto a linha de comando recusam um segundo a mais no seu laptop, antes que exista qualquer
requisição. O último comando assina com a linha de comando, e a saída mostra duas coisas. A URL que ele
imprimiu está no formato do Google, `https://quitanda-curated-prod.storage.googleapis.com/…`, porque o
`sign-url` não segue as variáveis do emulador. E o `ERROR` depois dela é a linha de comando tentando,
depois de imprimir a URL, chegar ao Google com uma segunda URL válida por 60 segundos, para conferir
que quem assina consegue ler o objeto. Num laptop sem rota até o Google essa verificação falha; a URL
acima dela estava completa antes de a verificação começar.

## O que torna uma URL assinada segura

Os hábitos vêm da documentação do Google, e são baratos:

- **a menor validade que resolve**: minutos para um download que uma pessoa clica agora, nunca dias;
- **quem assina só pode ler aquilo para o que assina**. O Cloud Storage confere as permissões de quem
  assinou quando a URL é usada, então uma conta de serviço que só pode ler `reports/` assina URLs que
  valem um prefixo. Tirar essa permissão, ou apagar a chave, faz todas as URLs que ela assinou
  pararem de funcionar de uma vez;
- **nenhum arquivo de chave, onde der.** `gcloud storage sign-url --impersonate-service-account`
  assina pelo serviço de credenciais do IAM do Google, sem chave privada em disco nenhum; a própria
  ajuda da linha de comando limita essas URLs a 12 horas, porque a chave que o Google usa para elas
  pode não continuar válida por mais tempo;
- **nunca uma URL num lugar que fica guardado**: um chamado, uma linha de log, um commit. A URL é a
  permissão, enquanto viver.
