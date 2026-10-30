---
title: Versionamento, e o primo manual dele, o snapshot
version: 1
---

**Com o versionamento ligado, toda escrita num blob guarda o conteúdo anterior como uma versão.** Nada
escrito se perde numa sobrescrita. Cada versão tem um id, um carimbo de tempo até o décimo
milionésimo de segundo no formato do `2026-10-30T19:00:35.1940000Z` do snapshot mais abaixo, e o nome
comum do blob sempre lê a atual. Uma exclusão também não destrói nada: o conteúdo atual vira uma
versão anterior, e o nome para de responder até alguém restaurá-lo. Restaurar é uma cópia: a versão
desejada é copiada sobre o nome do blob, e essa cópia já é uma nova versão atual.

A metade sobre versionamento desta seção foi escrita a partir da documentação da Microsoft, porque o
Azurite não dá ids de versão, como mostra a última seção da lição; os snapshots do fim rodaram no
Azurite. A declaração que o liga é a linha `versioning_enabled = true` da seção anterior.

## O que custa

**Toda versão é cobrada enquanto é guardada**, e é essa a linha que cresce sem ninguém olhar. As
regras de cobrança da Microsoft contam os dados que diferem entre um blob e suas versões, então um log
grande que ganha algumas linhas por dia soma pouco. Um arquivo reescrito inteiro toda noite não
compartilha nada com a noite anterior, e cada versão é uma cópia inteira: uma tabela de 50 GB
reescrita toda noite por um ano numa conta com versionamento são cerca de 18 TB de versões atrás de
50 GB de dados atuais. É por isso que o versionamento vem junto com a regra de ciclo de vida da
próxima seção, cujo bloco `version` apaga versões depois de um número de dias.

O versionamento não vem ligado, e só pode ser ligado pelo plano de controle, e é por isso que, na
última seção, `az storage account blob-service-properties update --enable-versioning` para e pede
login. Soft delete e versionamento funcionam juntos: com os dois ligados, a Microsoft documenta que
apagar uma versão a apaga de forma reversível, então até uma versão removida por engano tem os dias
de retenção da seção anterior.

## Snapshots, que o Azurite tem

Antes do versionamento havia os **snapshots**: uma cópia só de leitura de um blob num momento, feita a
pedido em vez de a cada escrita. Eles ainda existem, um programa ainda os cria, e o Azurite os
implementa, então eles mostram num laptop o mecanismo que o versionamento automatiza. O financeiro da
Quitanda mantém um arquivo pequeno de taxas de câmbio que uma pessoa edita à mão; um programa tira um
snapshot antes de cada edição:

`snapshot.py`:

```python
from azure.storage.blob import BlobServiceClient

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
container = service.get_container_client("finance")
if not container.exists():
    container.create_container()
rates = container.get_blob_client("rates/usd-brl.csv")

rates.upload_blob(b"date,rate\n2026-10-29,5.41\n", overwrite=True)
before = rates.create_snapshot()["snapshot"]
print("snapshot taken:", before)

rates.upload_blob(b"date,rate\n2026-10-29,54.1\n", overwrite=True)
print("now:", rates.download_blob().readall().decode().splitlines()[1])

old = container.get_blob_client("rates/usd-brl.csv", snapshot=before)
print("snapshot:", old.download_blob().readall().decode().splitlines()[1])
print("listed:", [(b.name, b.snapshot) for b in container.list_blobs(include=["snapshots"])])

rates.start_copy_from_url(old.url)
print("restored:", rates.download_blob().readall().decode().splitlines()[1])
```

```
ana@laptop:~/azure$ python snapshot.py
snapshot taken: 2026-10-30T19:00:35.1940000Z
now: 2026-10-29,54.1
snapshot: 2026-10-29,5.41
listed: [('rates/usd-brl.csv', None), ('rates/usd-brl.csv', '2026-10-30T19:00:35.1940000Z')]
restored: 2026-10-29,5.41
```

**O snapshot guardou 5.41 enquanto o blob era sobrescrito com uma vírgula fora do lugar, 54.1.** A
listagem mostra duas entradas com um nome só: o snapshot, com seu carimbo de tempo, e o blob atual, sem
nenhum. A restauração copiou a URL do snapshot sobre o nome do próprio blob, que é exatamente como uma
versão é restaurada, e a taxa voltou a estar certa. Com o versionamento ligado, a chamada a
`create_snapshot` não seria necessária: cada upload teria deixado uma versão para trás sem ninguém
pedir.
