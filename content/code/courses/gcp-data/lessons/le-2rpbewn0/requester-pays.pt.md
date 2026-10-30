---
title: Requester Pays, e para quem vai a conta
version: 1
---

**Por padrão, o projeto dono de um bucket paga por tudo que é feito nele, inclusive por outros.** Um
parceiro em `us-east1` que copia os 5 TiB de histórico de pedidos da Quitanda, com o acesso que a
Quitanda concedeu, tira 5 TiB da América Latina, e os 716,80 da seção anterior caem na conta da
Quitanda. **Requester Pays** é a configuração do bucket que passa a maior parte dos medidores para
quem pede.

Num bucket com Requester Pays ligado, como a documentação do Google o descreve (cloud.google.com,
"Requester Pays", nos guias do Cloud Storage):

- **quem pede paga as operações, a transferência de rede e as taxas de recuperação**; o dono continua
  pagando o armazenamento, e a exclusão antecipada da aula 2;
- **toda requisição precisa nomear o projeto a cobrar**: `userProject` como parâmetro na API JSON, o
  cabeçalho `x-goog-user-project` na API XML, `--billing-project` na linha de comando. Uma requisição
  que não nomeia nenhum é recusada com HTTP 400;
- **quem chama precisa de permissão para cobrar daquele projeto**, `serviceusage.services.use` nele,
  então uma requisição sem identidade Google por trás não tem a quem cobrar e não consegue ler o
  bucket. Um bucket com Requester Pays não pode ser também público no sentido da aula 4.

Serve para dados compartilhados com outras empresas que os leem no ritmo delas: um conjunto de dados
vendido a parceiros, ou um conjunto de pesquisa cujo dono paga só para mantê-lo. Não serve para nada
que os próprios times da Quitanda leem, já que as cobranças passariam de um projeto da Quitanda para
outro e nada seria economizado; essa divisão é a exportação de faturamento da aula 14 de
`gcp-foundations`, feita com labels.

## No fake-gcs-server

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ printf 'order_id,customer_id,total_cents\nord-01-1,c-17,4590\n' > history.csv && gcloud storage cp --no-user-output-enabled history.csv gs://quitanda-curated-prod/shared/history.csv
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-curated-prod --requester-pays --log-http 2>&1 | grep -A1 '^== body start'
== body start ==
{"billing": {"requesterPays": true}, "name": "quitanda-curated-prod"}
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-curated-prod --format=json | grep -c -i requester
0
ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-curated-prod/shared/history.csv
order_id,customer_id,total_cents
ord-01-1,c-17,4590
```

**O `--log-http` mostra a requisição que o `gcloud` mandou**, e ela é a certa: um `PATCH` do bucket
com `{"billing": {"requesterPays": true}}`, o campo que a API JSON documenta. **O fake-gcs-server
aceitou e não guardou nada.** A descrição depois não tem linha nenhuma falando disso, onde o Cloud
Storage imprimiria `requester_pays: true`, e uma leitura que não nomeia projeto de faturamento deu
certo, onde o Cloud Storage a recusaria. O emulador deste curso não implementa a configuração.

O que ele consegue mostrar é a requisição que um cliente manda quando nomeia um projeto, que é a
metade do Requester Pays que cabe a quem lê:

```
ana@laptop:~/gcp$ gcloud storage cat --billing-project=planner-dev gs://quitanda-curated-prod/shared/history.csv --log-http 2>&1 | grep -c -i 'x-goog-user-project'
0
ana@laptop:~/gcp$ : > requests.log
ana@laptop:~/gcp$ python3 -c 'from google.cloud import storage; b = storage.Client().bucket("quitanda-curated-prod", user_project="planner-dev"); print(b.blob("shared/history.csv").download_as_text(), end="")'
order_id,customer_id,total_cents
ord-01-1,c-17,4590
ana@laptop:~/gcp$ grep -o 'GET /download[^ ]*' requests.log
GET /download/storage/v1/b/quitanda-curated-prod/o/shared%2Fhistory.csv?alt=media&userProject=planner-dev
```

**O `gcloud` não mandou projeto de faturamento aqui, e o motivo é este laboratório.** Ele põe o
cabeçalho `X-Goog-User-Project` junto das credenciais que anexa a uma requisição, e a terceira linha de
"Toda vez que você abrir um terminal", da aula 1, disse a ele para não anexar nenhuma. Num projeto de
verdade, com credenciais, o mesmo comando leva o cabeçalho. **O cliente Python põe isso no endereço**,
`userProject=planner-dev`, que é a linha do log do emulador acima, e que é o que um bucket com Requester
Pays lê para decidir em que conta vai o download.

Então nada do Requester Pays foi imposto aqui. O que ele faz com uma conta é a aritmética das seções
anteriores com o pagador trocado: a cópia de 5 TiB do parceiro para `us-east1` custa 716,80 seja quem
for que pague, e a configuração decide em que fatura de projeto ela aparece.
