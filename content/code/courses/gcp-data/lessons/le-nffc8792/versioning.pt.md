---
title: Versionamento, e a exclusão que guarda os bytes
version: 1
---

**Um bucket versionado nunca sobrescreve e nunca apaga, a não ser que você cite uma geração.** Todo
objeto no Cloud Storage tem uma geração, um número que o serviço lhe dá quando ele é escrito, e num
bucket versionado uma escrita num nome que já existe guarda a geração antiga como versão não atual em
vez de jogá-la fora. Uma exclusão sem geração faz o mesmo com a viva: o nome some das listagens e todo
byte que ele tinha continua no bucket e na conta. As pessoas ligam o versionamento para proteger dados
e se surpreendem duas vezes: primeiro porque um arquivo apagado pode voltar, e depois com o que custa
guardar todas as versões.

Esta aula começa de um fake-gcs-server vazio, como toda aula, rodando no terminal dele, com as linhas
de "Every time you open a terminal" da aula 1 digitadas neste. O bucket curated ganha versionamento
antes do primeiro objeto:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-curated-prod --location=southamerica-east1
Creating gs://quitanda-curated-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-curated-prod --format='value(versioning_enabled)'
False
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-curated-prod --versioning
  
Updating gs://quitanda-curated-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-curated-prod --format='value(versioning_enabled)'
True
```

Um bucket novo tem o versionamento desligado. `--versioning` o liga e `--no-versioning` o desliga de
novo, e esses são os dois únicos estados: o Cloud Storage não tem um terceiro, "suspenso".

## Duas escritas, duas gerações

A tabela de clientes curada da Quitanda é reescrita inteira toda noite. Escreva-a duas vezes, e olhe
o bucket de dois jeitos: com a linha de comando, e com um programa curto que pede ao emulador todas as
gerações diretamente. O programa é o motivo do segundo jeito, e a seção sobre onde o emulador é mais
fraco diz por que a linha de comando não é confiável aqui.

`versions.py`:

```python
"""Every generation of every object in a bucket of the local emulator."""
import json
import os
import sys
import urllib.request

host = os.environ['STORAGE_EMULATOR_HOST']
url = f'{host}/storage/v1/b/{sys.argv[1]}/o?versions=true'
for o in json.load(urllib.request.urlopen(url)).get('items', []):
    state = 'noncurrent since ' + o['timeDeleted'] if 'timeDeleted' in o else 'live'
    print(o['generation'], f"{o['size']:>3}", o['name'], state)
```

Ele lê o endereço do emulador de `STORAGE_EMULATOR_HOST`, que as linhas da aula 1 definem, e imprime
uma linha por geração: o número da geração, o tamanho, o nome, e se ela está viva.

```
ana@laptop:~/gcp$ printf 'customer_id,city\nc-17,Santos\n' > customers.csv && gcloud storage cp customers.csv gs://quitanda-curated-prod/customers/customers.csv
Copying file://customers.csv to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ printf 'customer_id,city\nc-17,Campinas\n' > customers.csv && gcloud storage cp customers.csv gs://quitanda-curated-prod/customers/customers.csv
Copying file://customers.csv to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ gcloud storage ls -a gs://quitanda-curated-prod/customers/
gs://quitanda-curated-prod/customers/customers.csv#1793385436988405
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385436988405  31 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-curated-prod/o/customers%2Fcustomers.csv?alt=media&generation=1793385435809152'
customer_id,city
c-17,Santos
```

**As duas gerações estão lá**, e o programa as mostra: 31 bytes vivos, Campinas, e 29 bytes não atuais
desde o momento em que a segunda escrita os substituiu, Santos. Uma leitura sem geração devolve a viva;
uma leitura que cita uma geração devolve aquela, e o último comando trouxe Santos de volta pelo número.
`gcloud storage ls -a`, que no Cloud Storage lista todas as gerações com o número depois de um `#`,
imprimiu só a viva aqui. No Cloud Storage teria imprimido as duas.

A geração não atual é cobrada exatamente como a viva: mesma classe, mesmo preço por GiB, enquanto
existir.

## Uma exclusão, e o caminho de volta

```
ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-curated-prod/customers/customers.csv
Removing objects:
  
Removing gs://quitanda-curated-prod/customers/customers.csv...
ERROR: 'NoneType' object has no attribute 'items'

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-curated-prod/customers/
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**O nome sumiu da listagem, e nada foi removido.** `gcloud storage rm` sem geração tornou a versão viva
não atual, então agora as duas gerações são não atuais e o nome responde como ausente. A linha `ERROR`
depois da remoção é a linha de comando falhando ao ler a resposta do emulador, e ela aparece depois de
todo `rm` neste laboratório; a exclusão em si aconteceu, como a listagem mostra. No Cloud Storage o
mesmo comando imprime a remoção e nenhum erro.

Não existe marcador de exclusão no Cloud Storage, o que vale dizer porque outros armazenamentos de
objetos têm um. Um nome apagado num bucket versionado é só um nome sem geração viva. Trazê-lo de volta
é uma cópia da geração que você quer sobre o nome:

```
ana@laptop:~/gcp$ gcloud storage cp gs://quitanda-curated-prod/customers/customers.csv#1793385435809152 gs://quitanda-curated-prod/customers/customers.csv
Copying gs://quitanda-curated-prod/customers/customers.csv#1793385435809152 to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ gcloud storage cat gs://quitanda-curated-prod/customers/customers.csv
customer_id,city
c-17,Santos
ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385441037210  29 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**A cópia fez uma terceira geração, viva, com os 29 bytes de Santos**, e as duas mais antigas continuam
não atuais atrás dela. Só uma exclusão que cita uma geração, `gcloud storage rm gs://…#GENERATION`,
remove algo de vez, e remove aquela geração e nada mais. **O IAM não distingue as duas exclusões**: a
permissão `storage.objects.delete` permite as duas, e substituir um objeto também precisa dela. Um
pipeline que só acrescenta nomes novos pode rodar com `roles/storage.objectCreator`, que não tem
exclusão nenhuma; qualquer coisa que reescreve nomes também pode destruir gerações, e a proteção contra
isso é a política de retenção, três seções adiante, não um papel.

## Desligar mantém o que foi guardado

```
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-curated-prod --no-versioning
  
Updating gs://quitanda-curated-prod/...

ana@laptop:~/gcp$ printf 'customer_id,city\nc-17,Sorocaba\n' > customers.csv && gcloud storage cp customers.csv gs://quitanda-curated-prod/customers/customers.csv
Copying file://customers.csv to gs://quitanda-curated-prod/customers/customers.csv
  

ana@laptop:~/gcp$ python3 versions.py quitanda-curated-prod
1793385444118716  31 customers/customers.csv live
1793385435809152  29 customers/customers.csv noncurrent since 2026-10-30T15:37:16.988406-03:00
1793385436988405  31 customers/customers.csv noncurrent since 2026-10-30T15:37:19.065211-03:00
```

**Desligar o versionamento mantém todas as versões não atuais que ele tinha**, aqui as duas de antes.
O que muda é a próxima escrita: Sorocaba substituiu a geração viva sem guardá-la, que é o que um bucket
sem versionamento faz, e a cópia restaurada de Santos se foi. Desligar o versionamento para o
crescimento; não encolhe o que está guardado. Remover gerações antigas exige uma exclusão por geração,
ou a regra de ciclo de vida da seção depois da próxima.

## Exclusão reversível, que está ligada você pedindo ou não

O versionamento é uma configuração que você escolhe. **A exclusão reversível (soft delete) é uma
segunda proteção, separada, e o Google a liga em buckets novos**, com retenção de sete dias. A
documentação do Google sobre ela, cloud.google.com/storage/docs/soft-delete, a descreve assim: um
objeto apagado ou substituído é guardado, sem poder ser lido nem aparecer nas listagens comuns, pela
duração da exclusão reversível, e pode ser trazido de volta com `gcloud storage restore` nesse tempo.
`gcloud storage ls --soft-deleted` os lista. A duração pode ser definida entre 7 e 90 dias com
`--soft-delete-duration`, ou a exclusão reversível desligada com `--clear-soft-delete`.

As duas proteções se somam. Num bucket versionado, uma versão apagada de vez, por você ou por uma
regra, passa a ficar excluída de forma reversível. Num bucket sem versionamento, toda sobrescrita e
toda exclusão deixam os bytes antigos excluídos de forma reversível. **Objetos excluídos de forma
reversível são cobrados ao preço da sua classe** pelos dias em que são guardados, e a próxima seção põe
um número nisso. O fake-gcs-server não guarda nada disso, e a seção sobre onde ele é mais fraco mostra.
