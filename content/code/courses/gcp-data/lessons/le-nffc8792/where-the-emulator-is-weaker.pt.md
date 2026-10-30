---
title: Onde o emulador é mais fraco que o Cloud Storage
version: 1
---

**O fake-gcs-server guarda versões e devolve várias delas errado.** As seções anteriores mostraram o
que ele ignora de vez: a configuração de ciclo de vida, a política de retenção, as retenções
temporárias. Esta mostra as partes que ele implementa e erra, porque essas são piores. Uma
configuração ignorada reprova um teste no momento em que o teste a lê de volta. Uma configuração meio
guardada pode aprovar um teste e enganá-lo, e duas das três abaixo erram na direção perigosa.

## A listagem que esconde versões não atuais

`gcloud storage ls -a` mostrou uma geração onde o bucket tinha duas, na primeira seção. O motivo é uma
grafia. A linha de comando pede todas as gerações com `versions=True` na query string, e o emulador só
entende `versions=true`, em minúsculas:

```
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-curated-prod/o?versions=True' | grep -o '"generation"' | wc -l
1
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-curated-prod/o?versions=true' | grep -o '"generation"' | wc -l
3
```

**Mesmo bucket, mesma requisição, uma letra diferente: uma geração ou três.** A biblioteca cliente de
Python pede do mesmo jeito que a linha de comando, então um programa que lista versões com ela vê só as
vivas aqui. É por isso que o `versions.py` desta aula monta a requisição ele mesmo. Um script de limpeza
testado contra o emulador não encontraria versões antigas para limpar, e no Cloud Storage daria com
todas elas.

## A geração antiga que é lida como a nova

Ler uma geração não atual pelo número funcionou com `curl` na primeira seção. A linha de comando pede de
outro jeito, e recebe outra coisa:

```
ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-curated-prod/customers/customers.csv#1793385435809152
customer_id,city
c-17,SorocabERROR: (gcloud.storage.cat) Source hash qI/uqz6hnJWXM58h9wVE7w== does not match destination hash uWdDzi0lSTK1t8mLdxXZKw== for object -.
```

**O emulador serviu os bytes do objeto vivo, cortados no tamanho do antigo**: `Sorocab`, os primeiros
29 bytes da versão viva de 31 bytes, onde a geração de 29 bytes pedida tem `Santos`. A linha de comando
só percebeu porque confere o hash MD5 do que recebe contra o que os metadados do objeto declaram, e os
dois não batem. A verificação é da linha de comando, não do emulador, e é o motivo para mantê-la ligada:
um programa que baixa sem conferir o hash teria guardado o arquivo errado e informado sucesso.

## A exclusão que remove a geração errada

Esta é a perigosa. Apague uma geração não atual pelo número, o único tipo de exclusão no Cloud Storage
que remove algo de vez:

```
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385444118716  31 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-curated-prod/customers/customers.csv#1793385435809152
Removing objects:
  
Removing gs://quitanda-curated-prod/customers/customers.csv#1793385435809152...
ERROR: 'NoneType' object has no attribute 'items'
.
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**A versão viva sumiu e a geração citada continua lá.** Antes do comando, o bucket tinha Sorocaba viva
e duas gerações não atuais; depois dele, as duas não atuais continuam, a primeira delas exatamente o
número que o comando citou. O fake-gcs-server 1.54.0 ignora a geração numa exclusão e remove a versão
viva do nome no lugar. No Cloud Storage o mesmo comando remove exatamente a geração citada, e o objeto
vivo não é tocado. Um script que poda versões antigas, rodado contra este emulador, apagaria os dados
atuais e guardaria o histórico.

## Exclusão reversível, retenção, holds e ciclo de vida

As configurações das seções anteriores, lado a lado, das transcrições acima e desta:

```
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-archive-prod --format='value(soft_delete_policy)'

ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-archive-prod --soft-delete-duration=30d
  
Updating gs://quitanda-archive-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-archive-prod --format='value(soft_delete_policy)'

ana@laptop:~/gcp$ gcloud storage ls --soft-deleted 'gs://quitanda-archive-prod/**'
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
```

**A duração da exclusão reversível foi aceita e não foi guardada, como tudo nesta lista**: a política
volta vazia antes e depois de `--soft-delete-duration=30d`, e a nota fiscal apagada antes neste bucket
não está entre objetos excluídos de forma reversível, porque não há nenhum. No Cloud Storage um bucket
novo mostraria uma política de sete dias antes de alguém definir uma, e depois trinta dias.

| configuração | o emulador | o Cloud Storage |
|---|---|---|
| versionamento | guardado, listado só com `versions=true` | guardado e listado com `ls -a` |
| ler uma geração | certo com `curl`, bytes errados com `gcloud storage cat` | a geração citada |
| apagar uma geração | remove a versão viva no lugar | remove a geração citada |
| regras de ciclo de vida | aceitas, não guardadas, nunca aplicadas | guardadas, aplicadas em cerca de um dia |
| política de retenção e trava | aceitas, não guardadas | impostas; uma trava é permanente |
| holds | aceitos, não guardados | impostos até a liberação |
| exclusão reversível | aceita, não guardada | ligada por padrão, sete dias |

## Então, o que um teste aqui prova?

Que as requisições estão bem formadas: um bucket foi criado, uma opção foi escrita corretamente, um
arquivo JSON passou na análise. Não prova nada sobre se uma versão sobrevive, se uma exclusão apaga a
coisa certa, ou se uma trava segura. **Teste a forma de uma proteção contra o emulador e acredite na
documentação do Google quanto à força dela.** E mantenha a única verificação que pegou um erro real
aqui: o hash que a linha de comando compara em todo download, do qual nenhum emulador consegue te
convencer a abrir mão.
