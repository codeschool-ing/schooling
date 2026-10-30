---
title: Lendo de volta um blob arquivado
version: 1
---

**Um blob no tier archive não pode ser lido até ser reidratado.** Ele aparece na listagem, tem
tamanho, as propriedades respondem, e o download dos bytes é recusado. As pessoas esperam uma leitura
lenta; o que recebem é leitura nenhuma, e um passo separado que pede ao Azure para trazer o blob de
volta para o online, que no Azure termina horas depois. Hot, cool e cold não têm esse passo, e é isso
que faz do archive algo diferente em espécie, e não só em preço.

## Arquivando e pedindo

A cópia cool de setembro da seção anterior vai para o archive, e o download é tentado:

```
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/cool.csv --tier Archive
ana@laptop:~/azure$ az storage blob download -c orders-archive -n orders/2026-09/cool.csv -f back.csv --no-progress 2>&1 | grep -E "ERROR|ErrorCode"
ERROR: This operation is not permitted on an archived blob.
ErrorCode:BlobArchived
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "{tier:properties.blobTier, size:properties.contentLength}"
{
  "size": 64,
  "tier": "Archive"
}
```

**`BlobArchived` é a recusa**, e veio do Azurite, como viria do Azure. As propriedades ainda
respondem: o tier diz `Archive`, e os 64 bytes estão contados. Tudo o que descreve o blob continua
online; só o conteúdo é guardado.

## Reidratando no lugar

O primeiro jeito de voltar é trocar o tier, o que num blob arquivado inicia uma reidratação:

```
ana@laptop:~/azure$ az storage blob set-tier -c orders-archive -n orders/2026-09/cool.csv --tier Hot --rehydrate-priority Standard
WARNING: Argument '--rehydrate-priority' is in preview and under development. Reference and support levels: https://aka.ms/CLI_refstatus
ana@laptop:~/azure$ az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "properties.[blobTier, rehydrationStatus]" -o tsv
Hot
None
ana@laptop:~/azure$ az storage blob download -c orders-archive -n orders/2026-09/cool.csv -f back.csv --no-progress -o none && cat back.csv
order_id,customer_id,total_cents
09-1,c-17,4590
09-2,c-03,12800
```

**No Azurite a reidratação termina antes do próximo comando**: o tier já diz `Hot`,
`rehydrationStatus` está vazio, e o download que falhou um momento antes passa. Essa é a maior
diferença entre o Azurite e o Azure nesta lição. No Azure, segundo a documentação da Microsoft, o tier
continuaria dizendo `Archive` enquanto a reidratação corre, o status de archive do blob diria
`rehydrate-pending-to-hot`, e todo download continuaria falhando com `BlobArchived` até ela terminar.
O aviso de que `--rehydrate-priority` está em preview é a linha de comando descrevendo a própria
opção.

A prioridade é a única escolha que uma reidratação oferece:

| prioridade | a Microsoft documenta que termina |
|---|---|
| Standard | em até 15 horas |
| High | em menos de uma hora, para um blob menor que 10 GB |

Nada disso foi rodado aqui. A prioridade alta custa mais por gigabyte que a padrão, e a Microsoft
documenta que ela pode passar de uma hora para blobs grandes ou quando a demanda foge do normal. Uma
reidratação padrão pendente pode ser elevada para alta; uma alta não pode ser rebaixada.

## Copiando para fora do archive

O segundo jeito de voltar deixa o blob arquivado onde está e o copia para um nome novo num tier
online. É o jeito certo quando a cópia do archive precisa ficar, para um auditor ou porque os 180 dias
mínimos dela ainda não passaram. A linha de comando tem as opções para isso, `--tier` e
`--rehydrate-priority` em `az storage blob copy start`, e contra o Azurite falha num passo que não
tem nada a ver com tiers:

```
ana@laptop:~/azure$ az storage blob copy start -c orders-archive -b restored/cool.csv --source-container orders-archive --source-blob orders/2026-09/cool.csv --tier Hot --rehydrate-priority High 2>&1 | grep ErrorCode
ErrorCode:CannotVerifyCopySource
```

`CannotVerifyCopySource` é o Azurite falhando ao conferir o endereço de origem que a linha de comando
montou para ele, e o mesmo comando falha do mesmo jeito para um blob em hot. A biblioteca Python manda
a cópia do jeito certo, então este curso faz isso com um programa curto:

`rehydrate.py`:

```python
from azure.storage.blob import BlobServiceClient, RehydratePriority, StandardBlobTier

service = BlobServiceClient.from_connection_string("UseDevelopmentStorage=true")
archive = service.get_container_client("orders-archive")
source = archive.get_blob_client("orders/2026-09/audit.csv")
source.upload_blob(open("export/orders-2026-09.csv", "rb"), overwrite=True,
                   standard_blob_tier=StandardBlobTier.ARCHIVE)

target = archive.get_blob_client("restored/orders-2026-09.csv")
copy = target.start_copy_from_url(source.url, standard_blob_tier=StandardBlobTier.HOT,
                                  rehydrate_priority=RehydratePriority.HIGH)
print("copy:", copy["copy_status"])
for blob in (source, target):
    props = blob.get_blob_properties()
    print(blob.blob_name, props.blob_tier, props.size)
```

```
ana@laptop:~/azure$ python rehydrate.py
copy: success
orders/2026-09/audit.csv Archive 64
restored/orders-2026-09.csv Hot 64
```

**Dois blobs, um em cada tier.** A cópia de auditoria continua no archive e a restaurada está em hot,
com os mesmos 64 bytes. O Azurite informou a cópia como `success` na hora. No Azure a mesma chamada
responderia `pending`, e o destino ficaria legível quando a reidratação por trás da cópia terminasse,
no mesmo relógio da tabela acima.

## O archive e a redundância da conta

**A documentação da Microsoft, na época em que isto foi escrito, não oferece o tier archive em contas
replicadas com ZRS, GZRS ou RA-GZRS.** A lição 1 escolheu ZRS para a conta de exportações da
Quitanda, então essa conta não consegue arquivar nada. A declaração da seção anterior é uma segunda
conta, `stquitandaarchiveprd`, em LRS. O Azurite não tem replicação e aceitou todo tier acima, o que é
mais um sucesso que só prova que a requisição estava bem formada.
