---
title: Onde o Azurite é mais fraco, e como ele avisa
version: 1
---

**O Azurite aceita a configuração de soft delete e não guarda o que é apagado.** Essa é a mais
perigosa das falhas que esta lição encontra, porque a configuração responde como se funcionasse. As
outras são recusas honestas. Cada uma está aqui para que um teste que passou num laptop não seja
confundido com uma proteção que existe.

## Soft delete: aceito, não cumprido

A retenção de blobs apagados é uma propriedade do serviço de blob que o plano de dados consegue
definir, então a linha de comando a manda ao Azurite com a cadeia de conexão, e o Azurite a guarda:

```
ana@laptop:~/azure$ az storage blob service-properties delete-policy update --enable true --days-retained 7
{
  "allowPermanentDelete": null,
  "days": 7,
  "enabled": true
}
ana@laptop:~/azure$ printf "date,rate\n2026-10-29,5.41\n" > rates.csv && az storage blob upload -c finance -n rates.csv -f rates.csv --no-progress -o none
ana@laptop:~/azure$ az storage blob delete -c finance -n rates.csv
ana@laptop:~/azure$ az storage blob list -c finance --include d --prefix rates.csv --query "[].{name:name, deleted:deleted}"
[]
ana@laptop:~/azure$ az storage blob undelete -c finance -n rates.csv 2>&1 | grep -E "ERROR|ErrorCode"
ERROR: Current API is not implemented yet. Please vote your wanted features to https://github.com/azure/azurite/issues
ErrorCode:APINotImplemented
```

**A política diz sete dias e ligada, e o blob apagado não está lá.** A listagem com `--include d` pede
os blobs apagados além dos atuais, e a resposta é uma lista vazia. Pedir o blob de volta é recusado
com `APINotImplemented`, o código do próprio Azurite para uma operação que ele não escreveu, e a
mensagem diz isso com todas as letras. No Azure a mesma listagem mostraria `rates.csv` com
`deleted: true` por sete dias, e o undelete o traria de volta.

## Versionamento: nenhum id de versão

O versionamento só pode ser ligado pelo plano de controle, então a linha de comando para antes de
chegar ao Azurite. Um programa curto depois escreve o mesmo blob duas vezes e pede as versões dele:

`versions.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
finance = service.get_container_client("finance")
blob = finance.get_blob_client("rates/eur-brl.csv")
first = blob.upload_blob(b"date,rate\n2026-10-29,6.27\n", overwrite=True)
second = blob.upload_blob(b"date,rate\n2026-10-30,6.29\n", overwrite=True)
print("version_id:", first.get("version_id"), second.get("version_id"))
print([(b.name, b.version_id) for b in finance.list_blobs(name_starts_with="rates/eur",
                                                           include=["versions"])])
```

```
ana@laptop:~/azure$ az storage account blob-service-properties update -n devstoreaccount1 --enable-versioning true 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ python versions.py
version_id: None None
[('rates/eur-brl.csv', None)]
```

`version_id` é `None` depois dos dois uploads, e a listagem que pede versões mostra um blob, o atual.
Um programa que lê `version_id` da resposta de um upload, e o guarda para restaurar depois, guarda
`None` aqui e um id de verdade no Azure, e o caminho do código que restaura uma versão nunca é
exercitado no laboratório.

## Imutabilidade: recusada

A imutabilidade por versão e os legal holds são postos num blob pelo plano de dados, então um programa
consegue pedi-los ao Azurite:

`protect.py`:

```python
import datetime
from azure.storage.blob import BlobServiceClient, ImmutabilityPolicy

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
record = service.get_blob_client("finance", "rates/eur-brl.csv")
until = datetime.datetime(2033, 10, 30, tzinfo=datetime.timezone.utc)

attempts = {
    "retention until 2033": lambda: record.set_immutability_policy(
        ImmutabilityPolicy(expiry_time=until, policy_mode="Unlocked")),
    "legal hold": lambda: record.set_legal_hold(True),
}
for name, attempt in attempts.items():
    try:
        attempt()
        print(name, "set")
    except Exception as refusal:
        print(name, "refused:", str(refusal).splitlines()[0])
```

```
ana@laptop:~/azure$ python protect.py
retention until 2033 refused: Operation returned an invalid status 'Current API is not implemented yet. Please vote your wanted features to https://github.com/azure/azurite/issues'
legal hold refused: Operation returned an invalid status 'Current API is not implemented yet. Please vote your wanted features to https://github.com/azure/azurite/issues'
```

**Duas recusas, e do tipo honesto**: um programa que tenta proteger um registro contra o Azurite
descobre na hora que não consegue. A mensagem é a que o `APINotImplemented` trouxe acima; a biblioteca
não achou código de erro nessa resposta para imprimir, então o programa imprime a primeira linha da
mensagem. A política no nível de contêiner da seção anterior é plano de controle, então o Azurite
nunca é perguntado sobre ela.

## O que o laboratório prova, então

| recurso | o que o Azurite faz | o que um teste que passa prova |
|---|---|---|
| soft delete | guarda a configuração, não guarda nada | que a requisição estava bem formada, e nada sobre recuperação |
| undelete | recusa, `APINotImplemented` | nada |
| versionamento | não dá ids de versão | nada |
| snapshots | guarda e restaura | a lógica de snapshot e de cópia |
| imutabilidade, legal hold | recusa, `APINotImplemented` | nada |
| política de ciclo de vida | não tem; plano de controle | nada; o Terraform confere a declaração |

**O caminho de restauração é o que nunca é ensaiado**, e é o que importa no dia ruim. Um desenho que
depende desses recursos é testado numa conta real, numa assinatura feita para testes, apagando algo de
propósito e trazendo de volta, depois de a lição 13 do `azure-foundations` ter posto um orçamento com
alerta nela. Nada neste curso faz isso, e o curso diz isso aqui em vez de deixar um teste verde dizer o
contrário.
